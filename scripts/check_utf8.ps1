param(
  [string[]]$Roots = @("lib", "test", "apps/backend", "apps/web-backoffice", "docs", ".github", "scripts"),
  [string[]]$Extensions = @(
    ".dart",
    ".md",
    ".txt",
    ".json",
    ".yml",
    ".yaml",
    ".xml",
    ".java",
    ".kt",
    ".properties",
    ".gradle",
    ".sh",
    ".ps1",
    ".bat",
    ".csv"
  )
)

$ErrorActionPreference = "Stop"

$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$failed = New-Object System.Collections.Generic.List[string]

function Test-Utf8File {
  param([string]$Path)

  try {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    [void]$utf8Strict.GetString($bytes)
    return $true
  } catch {
    return $false
  }
}

$files = foreach ($root in $Roots) {
  if (-not (Test-Path $root)) {
    continue
  }

  Get-ChildItem -Path $root -Recurse -File |
    Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }
}

foreach ($file in $files) {
  if (-not (Test-Utf8File -Path $file.FullName)) {
    $failed.Add($file.FullName)
  }
}

if ($failed.Count -gt 0) {
  Write-Host "[utf8] Arquivos fora de UTF-8 detectados:" -ForegroundColor Red
  foreach ($path in $failed) {
    Write-Host " - $path"
  }
  exit 1
}

Write-Host "[utf8] Todos os arquivos verificados estao em UTF-8 valido."
