param(
  [switch]$Execute,
  [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[utf8-pr] $Message"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$status = git status --short
if (-not $AllowDirty -and -not [string]::IsNullOrWhiteSpace($status)) {
  throw "Worktree com alteracoes. Rode este script em branch separada e limpa, ou use -AllowDirty conscientemente."
}

Write-Step "Validando UTF-8 antes da renormalizacao..."
powershell -ExecutionPolicy Bypass -File .\scripts\check_utf8.ps1

Write-Step "Preview dos comandos da PR separada:"
Write-Host "  git checkout -b codex/utf8-renormalize"
Write-Host "  git add --renormalize ."
Write-Host "  git status --short"
Write-Host "  git diff --cached --stat"

if (-not $Execute) {
  Write-Step "Modo preview concluido. Use -Execute para aplicar a renormalizacao no index."
  exit 0
}

Write-Step "Aplicando git add --renormalize ."
git add --renormalize .

Write-Step "Resumo da renormalizacao:"
git status --short
git diff --cached --stat
