param(
    [bool]$Detach = $true,
    [string]$PostgresSecretName = 'AppMobile/PostgresPassword',
    [string]$RedisSecretName = 'AppMobile/RedisPassword'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PlainSecretFromSecureString {
    param([Security.SecureString]$SecureValue)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Resolve-SecretValue {
    param(
        [string]$EnvName,
        [string]$SecretName,
        [string]$PromptLabel
    )

    $fromEnv = [Environment]::GetEnvironmentVariable($EnvName, 'Process')
    if ([string]::IsNullOrWhiteSpace($fromEnv)) {
        $fromEnv = [Environment]::GetEnvironmentVariable($EnvName, 'User')
    }
    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) {
        return $fromEnv
    }

    $getSecret = Get-Command Get-Secret -ErrorAction SilentlyContinue
    if ($null -ne $getSecret) {
        try {
            $vaultValue = Get-Secret -Name $SecretName -AsPlainText -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($vaultValue)) {
                return $vaultValue
            }
        }
        catch {
        }
    }

    $secureValue = Read-Host -AsSecureString -Prompt $PromptLabel
    return Get-PlainSecretFromSecureString -SecureValue $secureValue
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$infraRoot = Join-Path $repoRoot 'infra'
$envFile = Join-Path $infraRoot '.env'

if (-not (Test-Path $envFile)) {
    throw "Arquivo nao encontrado: $envFile"
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
        return
    }

    $parts = $line -split '=', 2
    if ($parts.Count -ne 2) {
        return
    }

    $name = $parts[0].Trim()
    $value = $parts[1]

    if ($name -in @('POSTGRES_PASSWORD', 'REDIS_PASSWORD')) {
        return
    }

    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

$postgresPassword = Resolve-SecretValue -EnvName 'POSTGRES_PASSWORD' -SecretName $PostgresSecretName -PromptLabel 'Digite a senha do Postgres para o ambiente local'
$redisPassword = Resolve-SecretValue -EnvName 'REDIS_PASSWORD' -SecretName $RedisSecretName -PromptLabel 'Digite a senha do Redis para o ambiente local'

[Environment]::SetEnvironmentVariable('POSTGRES_PASSWORD', $postgresPassword, 'Process')
[Environment]::SetEnvironmentVariable('REDIS_PASSWORD', $redisPassword, 'Process')

$dockerCli = 'docker'
$dockerCliAbsolute = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
if (Test-Path $dockerCliAbsolute) {
    $dockerCli = $dockerCliAbsolute
}

$composeArgs = @('compose', 'up')
if ($Detach) {
    $composeArgs += '-d'
}

Push-Location $infraRoot
try {
    & $dockerCli @composeArgs
}
finally {
    Pop-Location
}