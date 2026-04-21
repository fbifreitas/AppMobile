param(
    [object]$Detach = $true,
    [string]$PostgresSecretName = 'AppMobile/PostgresPassword',
    [string]$RedisSecretName = 'AppMobile/RedisPassword',
    [string]$PlatformAdminPasswordSecretName = 'AppMobile/PlatformBootstrapAdminPassword',
    [string]$AiGatewayApiKeySecretName = 'AppMobile/AiGatewayApiKey',
    [string]$GeminiApiKeySecretName = 'AppMobile/GeminiApiKey'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:SecretStoreUnlocked = $false

function Convert-ToBoolean {
    param(
        [object]$Value,
        [bool]$DefaultValue = $true
    )

    if ($null -eq $Value) {
        return $DefaultValue
    }

    if ($Value -is [bool]) {
        return [bool]$Value
    }

    if ($Value -is [int]) {
        return ([int]$Value -ne 0)
    }

    if ($Value -is [string]) {
        $normalized = $Value.Trim().ToLowerInvariant()
        if ($normalized -in @('true', '1', 'yes', 'y', 'sim', 's')) {
            return $true
        }
        if ($normalized -in @('false', '0', 'no', 'n', 'nao')) {
            return $false
        }
    }

    throw "Valor invalido para Detach: '$Value'. Use true/false, 1/0, $true/$false."
}

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

    $getSecret = Get-Command Get-Secret -ErrorAction SilentlyContinue
    $setSecret = Get-Command Set-Secret -ErrorAction SilentlyContinue
    if ($null -ne $getSecret) {
        Ensure-SecretStoreUnlocked
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
    $plainValue = Get-PlainSecretFromSecureString -SecureValue $secureValue

    if ([string]::IsNullOrWhiteSpace($plainValue)) {
        throw "$EnvName nao foi informado."
    }

    if ($null -ne $setSecret) {
        try {
            Set-Secret -Name $SecretName -Secret $secureValue -ErrorAction Stop
        }
        catch {
            throw "Falha ao gravar '$SecretName' no vault local: $($_.Exception.Message)"
        }
    }
    elseif ($null -eq $getSecret) {
        throw "PowerShell SecretManagement nao esta disponivel. Instale/configure o vault local antes de subir a stack."
    }

    return $plainValue
}

function Ensure-SecretStoreUnlocked {
    if ($script:SecretStoreUnlocked) {
        return
    }

    $unlockSecretStore = Get-Command Unlock-SecretStore -ErrorAction SilentlyContinue
    if ($null -eq $unlockSecretStore) {
        return
    }

    try {
        Unlock-SecretStore -ErrorAction Stop | Out-Null
        $script:SecretStoreUnlocked = $true
    }
    catch {
        throw "Falha ao desbloquear o Vault LocalStore. Execute Unlock-SecretStore e informe a senha do cofre local."
    }
}

function Set-ComposeEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function New-ComposeEnvFile {
    param(
        [string]$BaseEnvFile,
        [string]$OutputPath,
        [hashtable]$Overrides
    )

    $values = @{}
    foreach ($rawLine in Get-Content $BaseEnvFile) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }

        $parts = $line -split '=', 2
        if ($parts.Count -ne 2) {
            continue
        }

        $values[$parts[0].Trim()] = $parts[1]
    }

    foreach ($key in $Overrides.Keys) {
        $values[$key] = [string]$Overrides[$key]
    }

    $lines = foreach ($key in ($values.Keys | Sort-Object)) {
        "$key=$($values[$key])"
    }

    Set-Content -Path $OutputPath -Value $lines -Encoding ASCII
}

function Invoke-DockerCompose {
    param(
        [string]$DockerCli,
        [string]$InfraRoot,
        [string]$EnvFilePath,
        [string[]]$Arguments
    )

    Push-Location $InfraRoot
    try {
        & $DockerCli compose --env-file $EnvFilePath @Arguments
    }
    finally {
        Pop-Location
    }
}

function Wait-ForComposeServiceHealth {
    param(
        [string]$DockerCli,
        [string]$InfraRoot,
        [string]$ServiceName,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $containerId = ''
        Push-Location $InfraRoot
        try {
            $containerId = (& $DockerCli compose ps -q $ServiceName | Select-Object -First 1).Trim()
        }
        finally {
            Pop-Location
        }

        if (-not [string]::IsNullOrWhiteSpace($containerId)) {
            $status = (& $DockerCli inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $containerId).Trim()
            if ($status -eq 'healthy') {
                return
            }
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    throw "Timeout aguardando o servico '$ServiceName' ficar healthy."
}

function Sync-PostgresUserPassword {
    param(
        [string]$DockerCli,
        [string]$InfraRoot,
        [string]$PostgresUser,
        [string]$PostgresPassword
    )

    $escapedPassword = $PostgresPassword.Replace("'", "''")
    $escapedUser = $PostgresUser.Replace('"', '""')
    $sql = "ALTER USER ""$escapedUser"" WITH PASSWORD '$escapedPassword';"

    Push-Location $InfraRoot
    try {
        & $DockerCli compose exec -T db psql -U $PostgresUser -d postgres -v ON_ERROR_STOP=1 -c $sql | Out-Null
    }
    finally {
        Pop-Location
    }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$infraRoot = Join-Path $repoRoot 'infra'
$envFile = Join-Path $infraRoot '.env'
$composeEnvFile = Join-Path $infraRoot '.env.compose.local'

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

    if ($name -in @('POSTGRES_PASSWORD', 'REDIS_PASSWORD', 'PLATFORM_BOOTSTRAP_ADMIN_PASSWORD')) {
        return
    }

    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

$postgresPassword = Resolve-SecretValue -EnvName 'POSTGRES_PASSWORD' -SecretName $PostgresSecretName -PromptLabel 'Digite a senha do Postgres para o ambiente local'
$redisPassword = Resolve-SecretValue -EnvName 'REDIS_PASSWORD' -SecretName $RedisSecretName -PromptLabel 'Digite a senha do Redis para o ambiente local'

[Environment]::SetEnvironmentVariable('POSTGRES_PASSWORD', $postgresPassword, 'Process')
[Environment]::SetEnvironmentVariable('REDIS_PASSWORD', $redisPassword, 'Process')

$aiGatewayEnabled = Convert-ToBoolean -Value ([Environment]::GetEnvironmentVariable('AI_GATEWAY_ENABLED', 'Process')) -DefaultValue $false
$aiGatewayRequireSecret = Convert-ToBoolean -Value ([Environment]::GetEnvironmentVariable('AI_GATEWAY_REQUIRE_SECRET', 'Process')) -DefaultValue $true
if ($aiGatewayEnabled -and $aiGatewayRequireSecret) {
    $aiGatewayApiKey = Resolve-SecretValue -EnvName 'AI_GATEWAY_API_KEY' -SecretName $AiGatewayApiKeySecretName -PromptLabel 'Digite a chave do AI Gateway para o ambiente local'
    [Environment]::SetEnvironmentVariable('AI_GATEWAY_API_KEY', $aiGatewayApiKey, 'Process')

    $geminiApiKey = Resolve-SecretValue -EnvName 'GEMINI_API_KEY' -SecretName $GeminiApiKeySecretName -PromptLabel 'Digite a chave do Gemini para o ambiente local'
    [Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $geminiApiKey, 'Process')
}
else {
    $currentAiGatewayApiKey = [Environment]::GetEnvironmentVariable('AI_GATEWAY_API_KEY', 'Process')
    if ($null -eq $currentAiGatewayApiKey) {
        $currentAiGatewayApiKey = ''
    }
    [Environment]::SetEnvironmentVariable('AI_GATEWAY_API_KEY', $currentAiGatewayApiKey, 'Process')

    $currentGeminiApiKey = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Process')
    if ($null -eq $currentGeminiApiKey) {
        $currentGeminiApiKey = ''
    }
    [Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $currentGeminiApiKey, 'Process')
}

$platformBootstrapEnabled = Convert-ToBoolean -Value ([Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_ENABLED', 'Process')) -DefaultValue $false
if ($platformBootstrapEnabled) {
    $platformTenantId = [Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_TENANT_ID', 'Process')
    $platformTenantSlug = [Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_TENANT_SLUG', 'Process')
    $platformTenantName = [Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_TENANT_NAME', 'Process')
    $platformAdminEmail = [Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_ADMIN_EMAIL', 'Process')
    $platformAdminName = [Environment]::GetEnvironmentVariable('PLATFORM_BOOTSTRAP_ADMIN_NAME', 'Process')

    foreach ($requiredValue in @(
        @{ Name = 'PLATFORM_BOOTSTRAP_TENANT_ID'; Value = $platformTenantId },
        @{ Name = 'PLATFORM_BOOTSTRAP_TENANT_SLUG'; Value = $platformTenantSlug },
        @{ Name = 'PLATFORM_BOOTSTRAP_TENANT_NAME'; Value = $platformTenantName },
        @{ Name = 'PLATFORM_BOOTSTRAP_ADMIN_EMAIL'; Value = $platformAdminEmail },
        @{ Name = 'PLATFORM_BOOTSTRAP_ADMIN_NAME'; Value = $platformAdminName }
    )) {
        if ([string]::IsNullOrWhiteSpace($requiredValue.Value)) {
            throw "Bootstrap da plataforma habilitado, mas $($requiredValue.Name) nao esta configurado."
        }
    }

    $platformAdminPassword = Resolve-SecretValue `
        -EnvName 'PLATFORM_BOOTSTRAP_ADMIN_PASSWORD' `
        -SecretName $PlatformAdminPasswordSecretName `
        -PromptLabel 'Digite a senha do PLATFORM_ADMIN bootstrap do ambiente local'

    if ([string]::IsNullOrWhiteSpace($platformAdminPassword)) {
        throw 'Bootstrap da plataforma habilitado, mas PLATFORM_BOOTSTRAP_ADMIN_PASSWORD nao foi informado.'
    }

    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_ENABLED' -Value 'true'
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_ID' -Value $platformTenantId
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_SLUG' -Value $platformTenantSlug
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_NAME' -Value $platformTenantName
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_EMAIL' -Value $platformAdminEmail
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_NAME' -Value $platformAdminName
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_PASSWORD' -Value $platformAdminPassword
}
else {
    Set-ComposeEnvironmentVariable -Name 'COMPOSE_PLATFORM_BOOTSTRAP_ENABLED' -Value 'false'
    foreach ($composeEnvName in @(
        'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_ID',
        'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_SLUG',
        'COMPOSE_PLATFORM_BOOTSTRAP_TENANT_NAME',
        'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_EMAIL',
        'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_NAME',
        'COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_PASSWORD'
    )) {
        Set-ComposeEnvironmentVariable -Name $composeEnvName -Value ''
    }
}

Set-ComposeEnvironmentVariable -Name 'COMPOSE_AUTH_FIRST_ACCESS_EXPOSE_DEBUG_OTP' -Value 'true'

$dockerCli = 'docker'
$dockerCliAbsolute = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
if (Test-Path $dockerCliAbsolute) {
    $dockerCli = $dockerCliAbsolute
}

$detachEnabled = Convert-ToBoolean -Value $Detach -DefaultValue $true
$composeUpArgs = @('compose', 'up')
if ($detachEnabled) {
    $composeUpArgs += '-d'
}
$composeUpArgs += '--force-recreate'

$composeOverrides = @{
    POSTGRES_PASSWORD = $postgresPassword
    REDIS_PASSWORD = $redisPassword
    AI_GATEWAY_ENABLED = [Environment]::GetEnvironmentVariable('AI_GATEWAY_ENABLED', 'Process')
    AI_GATEWAY_BASE_URL = [Environment]::GetEnvironmentVariable('AI_GATEWAY_BASE_URL', 'Process')
    AI_GATEWAY_API_KEY = [Environment]::GetEnvironmentVariable('AI_GATEWAY_API_KEY', 'Process')
    AI_GATEWAY_MODEL = [Environment]::GetEnvironmentVariable('AI_GATEWAY_MODEL', 'Process')
    AI_GATEWAY_RESEARCH_PATH = [Environment]::GetEnvironmentVariable('AI_GATEWAY_RESEARCH_PATH', 'Process')
    AI_GATEWAY_REQUIRE_SECRET = [Environment]::GetEnvironmentVariable('AI_GATEWAY_REQUIRE_SECRET', 'Process')
    GEMINI_API_KEY = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Process')
    GEMINI_MODEL = [Environment]::GetEnvironmentVariable('GEMINI_MODEL', 'Process')
    GEMINI_ENABLED = [Environment]::GetEnvironmentVariable('GEMINI_ENABLED', 'Process')
    GEMINI_GROUNDING_ENABLED = [Environment]::GetEnvironmentVariable('GEMINI_GROUNDING_ENABLED', 'Process')
    GEMINI_TIMEOUT_MS = [Environment]::GetEnvironmentVariable('GEMINI_TIMEOUT_MS', 'Process')
    GEMINI_BASE_URL = [Environment]::GetEnvironmentVariable('GEMINI_BASE_URL', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_ENABLED = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_ENABLED', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_TENANT_ID = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_TENANT_ID', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_TENANT_SLUG = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_TENANT_SLUG', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_TENANT_NAME = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_TENANT_NAME', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_EMAIL = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_EMAIL', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_NAME = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_NAME', 'Process')
    COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_PASSWORD = [Environment]::GetEnvironmentVariable('COMPOSE_PLATFORM_BOOTSTRAP_ADMIN_PASSWORD', 'Process')
    COMPOSE_AUTH_FIRST_ACCESS_EXPOSE_DEBUG_OTP = [Environment]::GetEnvironmentVariable('COMPOSE_AUTH_FIRST_ACCESS_EXPOSE_DEBUG_OTP', 'Process')
}
New-ComposeEnvFile -BaseEnvFile $envFile -OutputPath $composeEnvFile -Overrides $composeOverrides

Invoke-DockerCompose -DockerCli $dockerCli -InfraRoot $infraRoot -EnvFilePath $composeEnvFile -Arguments @('up', '-d', '--force-recreate', 'db', 'cache', 'ai-gateway', 'web')
Wait-ForComposeServiceHealth -DockerCli $dockerCli -InfraRoot $infraRoot -ServiceName 'db'
Sync-PostgresUserPassword -DockerCli $dockerCli -InfraRoot $infraRoot -PostgresUser ([Environment]::GetEnvironmentVariable('POSTGRES_USER', 'Process')) -PostgresPassword $postgresPassword
Invoke-DockerCompose -DockerCli $dockerCli -InfraRoot $infraRoot -EnvFilePath $composeEnvFile -Arguments @('up', '-d', '--force-recreate', 'api', 'proxy')
