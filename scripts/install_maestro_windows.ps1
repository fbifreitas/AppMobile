param(
  [switch]$SkipJava,
  [switch]$SkipAdb,
  [switch]$SkipMaestro
)

$ErrorActionPreference = "Stop"

function Test-CommandAvailable {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-Winget {
  if (-not (Test-CommandAvailable -Name "winget")) {
    throw "winget nao encontrado. Instale App Installer da Microsoft Store e tente novamente."
  }
}

function Install-JavaIfNeeded {
  if ($SkipJava) { return }
  if (Test-CommandAvailable -Name "java") {
    Write-Host "[setup] Java ja disponivel."
    return
  }

  Write-Host "[setup] Instalando Java 17..."
  winget install --id Microsoft.OpenJDK.17 --source winget --accept-source-agreements --accept-package-agreements --silent
}

function Install-AdbIfNeeded {
  if ($SkipAdb) { return }
  if (Test-CommandAvailable -Name "adb") {
    Write-Host "[setup] adb ja disponivel."
    return
  }

  Write-Host "[setup] Instalando Android Platform-Tools (adb)..."
  winget install --id Google.PlatformTools --source winget --accept-source-agreements --accept-package-agreements --silent

  $winGetLinks = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
  if (Test-Path $winGetLinks) {
    $env:PATH = "$winGetLinks;$env:PATH"
  }
}

function Install-MaestroIfNeeded {
  if ($SkipMaestro) { return }

  $maestroExe = Join-Path $HOME ".maestro\bin\maestro.exe"
  $maestroBat = Join-Path $HOME ".maestro\bin\maestro.bat"
  if ((Test-Path $maestroExe) -or (Test-Path $maestroBat) -or (Test-CommandAvailable -Name "maestro")) {
    Write-Host "[setup] Maestro ja disponivel."
    return
  }

  $maestroDir = Join-Path $HOME ".maestro"
  $tmpDir = Join-Path $maestroDir "tmp"
  $zipPath = Join-Path $tmpDir "maestro.zip"
  $extractPath = Join-Path $tmpDir "extract"

  Write-Host "[setup] Instalando Maestro CLI..."
  New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
  if (Test-Path $extractPath) {
    Remove-Item -Recurse -Force $extractPath
  }

  $downloadUrl = "https://github.com/mobile-dev-inc/maestro/releases/latest/download/maestro.zip"
  curl.exe -L -o $zipPath $downloadUrl | Out-Null

  Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

  $sourceRoot = Join-Path $extractPath "maestro"
  if (-not (Test-Path $sourceRoot)) {
    throw "Estrutura inesperada no zip do Maestro."
  }

  $binDir = Join-Path $maestroDir "bin"
  $libDir = Join-Path $maestroDir "lib"
  if (Test-Path $binDir) { Remove-Item -Recurse -Force $binDir }
  if (Test-Path $libDir) { Remove-Item -Recurse -Force $libDir }

  Copy-Item -Recurse -Force (Join-Path $sourceRoot "*") $maestroDir

  $maestroBinForPath = Join-Path $HOME ".maestro\bin"
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ([string]::IsNullOrWhiteSpace($userPath)) {
    [Environment]::SetEnvironmentVariable("Path", $maestroBinForPath, "User")
  } elseif (-not ($userPath.Split(';') -contains $maestroBinForPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$maestroBinForPath", "User")
  }

  Remove-Item -Recurse -Force $tmpDir
}

function Configure-UserEnvironment {
  $javaHomeDir = Get-ChildItem "C:\Program Files\Microsoft\" -Directory -Filter "jdk-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1 -ExpandProperty FullName

  if ($javaHomeDir) {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHomeDir, "User")
  }

  $adbExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "adb.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
  $adbDir = if ($adbExe) { Split-Path -Parent $adbExe } else { $null }

  $maestroDir = Join-Path $HOME ".maestro\bin"
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if (-not [string]::IsNullOrWhiteSpace($userPath)) {
    $parts += $userPath.Split(';') | Where-Object { $_.Trim().Length -gt 0 }
  }

  $javaBinDir = $null
  if ($javaHomeDir) {
    $javaBinDir = Join-Path $javaHomeDir "bin"
  }

  $maestroBinDir = $null
  if (Test-Path $maestroDir) {
    $maestroBinDir = $maestroDir
  }

  foreach ($candidate in @($javaBinDir, $adbDir, $maestroBinDir)) {
    if ($candidate -and -not ($parts -contains $candidate)) {
      $parts += $candidate
    }
  }

  [Environment]::SetEnvironmentVariable("Path", ($parts -join ';'), "User")
}

function Validate-Tooling {
  Write-Host "[setup] Validando ferramentas..."

  # Reconstroi PATH da sessao com Machine + User para evitar shell sem cmd/java.
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:PATH = "$machinePath;$userPath"

  if (Test-CommandAvailable -Name "java") {
    java -version | Out-Host
  } else {
    $javaExe = Get-ChildItem "C:\Program Files\Microsoft\" -Directory -Filter "jdk-*" -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending |
      Select-Object -First 1 |
      ForEach-Object { Join-Path $_.FullName "bin\java.exe" }

    if ($javaExe -and (Test-Path $javaExe)) {
      & $javaExe -version | Out-Host
    } else {
      Write-Warning "java nao encontrado."
    }
  }

  if (Test-CommandAvailable -Name "adb") {
    adb version | Out-Host
  } else {
    $adbExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "adb.exe" -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty FullName

    if ($adbExe -and (Test-Path $adbExe)) {
      & $adbExe version | Out-Host
    } else {
      Write-Warning "adb nao encontrado."
    }
  }

  if (Test-CommandAvailable -Name "maestro") {
    maestro --version | Out-Host
  } else {
    $maestroBat = Join-Path $HOME ".maestro\bin\maestro.bat"
    if (Test-Path $maestroBat) {
      & $maestroBat --version | Out-Host
    } else {
      Write-Warning "maestro nao encontrado."
    }
  }
}

Ensure-Winget
Install-JavaIfNeeded
Install-AdbIfNeeded
Install-MaestroIfNeeded
Configure-UserEnvironment
Validate-Tooling

Write-Host "[setup] Instalacao concluida."
