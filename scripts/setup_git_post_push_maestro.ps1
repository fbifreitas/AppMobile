$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "[hook-setup] Configurando core.hooksPath para tools/git-hooks..."
git config core.hooksPath tools/git-hooks

Write-Host "[hook-setup] Verificando configuração..."
$hooksPath = git config --get core.hooksPath
if ($hooksPath -ne "tools/git-hooks") {
  throw "Falha ao configurar core.hooksPath. Valor atual: $hooksPath"
}

Write-Host "[hook-setup] Hooks configurados com sucesso."

Write-Host "[hook-setup] Instalando pre-requisitos (Java, adb e Maestro)..."
powershell -ExecutionPolicy Bypass -File "scripts/install_maestro_windows.ps1"
if ($LASTEXITCODE -ne 0) {
  throw "Falha ao instalar/validar pre-requisitos do Maestro (exit code $LASTEXITCODE)."
}

Write-Host "[hook-setup] Ambiente pronto para fluxo de homologacao USB + PR para main."
