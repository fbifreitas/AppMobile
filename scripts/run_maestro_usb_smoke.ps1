param(
  [string]$AppId = "com.example.myapp",
  [string]$Flow = "maestro/flows/smoke_post_publish.yaml",
  [string]$DeviceId = "",
  [switch]$SkipBuild,
  [switch]$SkipInstall,
  [int]$MaestroTimeoutSec = 900,
  [string]$LogDir = "maestro-debug",
  [switch]$NoAdbMonitor
)

$ErrorActionPreference = "Stop"

function Resolve-ExecutablePath {
  param(
    [string]$CommandName,
    [string[]]$Fallbacks = @()
  )

  $resolved = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($resolved) {
    return $resolved.Source
  }

  foreach ($candidate in $Fallbacks) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "Executavel '$CommandName' nao encontrado."
}

function Resolve-DeviceId {
  param(
    [string]$RequestedId,
    [string]$AdbPath
  )

  if ($RequestedId.Trim().Length -gt 0) {
    return $RequestedId
  }

  $lines = & $AdbPath devices | Select-Object -Skip 1
  $devices = @()
  foreach ($line in $lines) {
    if ($line -match "^(\S+)\s+device$") {
      $devices += $Matches[1]
    }
  }

  if ($devices.Count -eq 0) {
    throw "Nenhum dispositivo Android conectado e autorizado via USB."
  }

  return $devices[0]
}

function Start-AdbLogcatCapture {
  param(
    [string]$AdbPath,
    [string]$TargetDeviceId,
    [string]$OutputDir
  )

  if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
  }

  $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
  $logcatFile = Join-Path $OutputDir "adb-logcat-$timestamp.log"
  $stdoutFile = Join-Path $OutputDir "adb-logcat-runner-$timestamp.out.log"
  $stderrFile = Join-Path $OutputDir "adb-logcat-runner-$timestamp.err.log"

  & $AdbPath -s $TargetDeviceId logcat -c | Out-Null

  $runnerArgs = @(
    "-NoProfile",
    "-Command",
    "& `"$AdbPath`" -s `"$TargetDeviceId`" logcat -v time"
  )

  $runner = Start-Process \
    -FilePath "powershell" \
    -ArgumentList $runnerArgs \
    -PassThru \
    -NoNewWindow \
    -RedirectStandardOutput $logcatFile \
    -RedirectStandardError $stderrFile

  return [PSCustomObject]@{
    Process = $runner
    LogcatFile = $logcatFile
    StdoutFile = $stdoutFile
    StderrFile = $stderrFile
  }
}

function Stop-ProcessSafe {
  param([System.Diagnostics.Process]$Process)

  if ($null -eq $Process) {
    return
  }

  try {
    if (-not $Process.HasExited) {
      $Process.Kill()
      $Process.WaitForExit()
    }
  } catch {
    Write-Warning "Nao foi possivel encerrar processo de monitoramento: $($_.Exception.Message)"
  }
}

function Ensure-JavaRuntime {
  $javaResolved = Get-Command java -ErrorAction SilentlyContinue
  if ($javaResolved) {
    return
  }

  $jdkPath = Get-ChildItem "C:\Program Files\Microsoft" -Directory -Filter "jdk-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1 -ExpandProperty FullName

  if (-not $jdkPath) {
    throw "Java nao encontrado. Rode scripts/install_maestro_windows.ps1 para instalar o JDK."
  }

  $env:JAVA_HOME = $jdkPath
  $env:PATH = "$jdkPath\bin;$env:PATH"
}

Write-Host "[maestro] Validando pré-requisitos..."

Ensure-JavaRuntime

$flutterExe = Resolve-ExecutablePath -CommandName "flutter" -Fallbacks @(
  "C:\src\flutter\bin\flutter.bat"
)

$adbExe = Resolve-ExecutablePath -CommandName "adb" -Fallbacks @(
  "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
)

$maestroExe = Resolve-ExecutablePath -CommandName "maestro" -Fallbacks @(
  "$HOME\.maestro\bin\maestro.bat"
)

$resolvedDeviceId = Resolve-DeviceId -RequestedId $DeviceId -AdbPath $adbExe
Write-Host "[maestro] Dispositivo selecionado: $resolvedDeviceId"

if (-not $SkipBuild) {
  Write-Host "[maestro] Build debug APK..."
  & $flutterExe build apk --debug --target-platform android-arm64
}

if (-not $SkipInstall) {
  $apkPath = "build/app/outputs/flutter-apk/app-debug.apk"
  if (-not (Test-Path $apkPath)) {
    throw "APK não encontrado em $apkPath. Rode sem -SkipBuild ou gere o APK antes."
  }

  Write-Host "[maestro] Instalando APK no device..."
  $installOutput = & $adbExe -s $resolvedDeviceId install -r $apkPath 2>&1 | Out-String
  if (-not [string]::IsNullOrWhiteSpace($installOutput)) {
    Write-Host $installOutput.Trim()
  }

  if ($LASTEXITCODE -ne 0 -and $installOutput -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
    Write-Host "[maestro] Assinatura diferente detectada. Reinstalando pacote de teste..."
    & $adbExe -s $resolvedDeviceId uninstall $AppId | Out-Host
    $reinstallOutput = & $adbExe -s $resolvedDeviceId install -r $apkPath 2>&1 | Out-String
    if (-not [string]::IsNullOrWhiteSpace($reinstallOutput)) {
      Write-Host $reinstallOutput.Trim()
    }
    if ($LASTEXITCODE -ne 0) {
      throw "Falha ao reinstalar APK no device (codigo $LASTEXITCODE)."
    }
  } elseif ($LASTEXITCODE -ne 0) {
    throw "Falha ao instalar APK no device (codigo $LASTEXITCODE)."
  }
}

Write-Host "[maestro] Executando fluxo: $Flow"
$maestroArgs = @(
  "--device",
  $resolvedDeviceId,
  "test",
  $Flow,
  "-e",
  "APP_ID=$AppId"
)

$logsRoot = Resolve-Path -Path "."
$executionLogDir = Join-Path $logsRoot $LogDir
if (-not (Test-Path $executionLogDir)) {
  New-Item -ItemType Directory -Path $executionLogDir -Force | Out-Null
}

$runTimestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$maestroStdout = Join-Path $executionLogDir "maestro-$runTimestamp.out.log"
$maestroStderr = Join-Path $executionLogDir "maestro-$runTimestamp.err.log"

$adbMonitor = $null
if (-not $NoAdbMonitor) {
  Write-Host "[maestro] Iniciando monitoramento adb logcat..."
  $adbMonitor = Start-AdbLogcatCapture -AdbPath $adbExe -TargetDeviceId $resolvedDeviceId -OutputDir $executionLogDir
  Write-Host "[maestro] Logcat: $($adbMonitor.LogcatFile)"
}

$maestroProcess = $null
try {
  $maestroProcess = Start-Process \
    -FilePath $maestroExe \
    -ArgumentList $maestroArgs \
    -PassThru \
    -NoNewWindow \
    -RedirectStandardOutput $maestroStdout \
    -RedirectStandardError $maestroStderr

  $startTime = Get-Date
  $lastHeartbeat = $startTime

  while (-not $maestroProcess.HasExited) {
    Start-Sleep -Seconds 2
    $maestroProcess.Refresh()

    $now = Get-Date
    $elapsed = $now - $startTime
    if (($now - $lastHeartbeat).TotalSeconds -ge 20) {
      Write-Host "[maestro] Em execucao ha $([int]$elapsed.TotalSeconds)s..."
      $lastHeartbeat = $now
    }

    if ($elapsed.TotalSeconds -ge $MaestroTimeoutSec) {
      Stop-ProcessSafe -Process $maestroProcess
      throw "Timeout de $MaestroTimeoutSec segundos ao executar Maestro."
    }
  }

  if ($maestroProcess.ExitCode -ne 0) {
    throw "Maestro retornou código $($maestroProcess.ExitCode)."
  }
} finally {
  if ($adbMonitor -ne $null) {
    Stop-ProcessSafe -Process $adbMonitor.Process
  }
}

Write-Host "[maestro] Logs stdout: $maestroStdout"
Write-Host "[maestro] Logs stderr: $maestroStderr"
Write-Host "[maestro] Smoke test finalizado com sucesso."
