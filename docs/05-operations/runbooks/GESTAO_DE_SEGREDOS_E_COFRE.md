# GESTAO DE SEGREDOS E COFRE

> [RUNBOOK ATIVO]
> Este documento define como segredos devem ser armazenados, acessados e exigidos em `dev`, `homolog` e `prod`.

## Objetivo

Eliminar segredos hardcoded no codigo e tornar o uso de cofre ou secret manager um requisito formal de ambiente.

## Regra Central

Segredos nao devem viver em:
- codigo fonte
- arquivo versionado
- documentacao com valor real
- script commitado com valor embutido

Segredos devem vir de:
1. variavel de ambiente
2. cofre local aprovado
3. secret manager do ambiente

## Segredos Minimos Deste Projeto

Hoje, no minimo, estes segredos devem ser tratados como secretos:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `AUTH_JWT_SECRET`
- `INTEGRATION_CONFIG_SIGNING_HMAC_KEY`
- `R2_ACCESS_KEY`
- `R2_SECRET_KEY`
- `VPS_SSH_KEY`

## Requisitos Por Ambiente

### Dev local

Permitido:
1. variavel de ambiente de sessao
2. cofre local do PowerShell via `Get-Secret`
3. prompt seguro no bootstrap local

Proibido:
1. salvar senha real em `infra/.env`
2. salvar senha real em `infra.env`

Estado atual suportado pelo projeto:
- [start_local_stack.ps1](C:\src\AppMobile\infra\scripts\start_local_stack.ps1) ja resolve:
  - `POSTGRES_PASSWORD`
  - `REDIS_PASSWORD`
  - `AUTH_JWT_SECRET`
  - `INTEGRATION_CONFIG_SIGNING_HMAC_KEY`
  usando:
  - env var
  - `Get-Secret`
  - prompt seguro

### Homolog

Obrigatorio:
1. segredos provisionados por secret manager ou secrets do CI
2. sem defaults fracos
3. `AUTH_JWT_REQUIRE_SECRET=true`
4. `INTEGRATION_CONFIG_SIGNING_REQUIRE_SECRET=true`

### Producao

Obrigatorio:
1. secret manager ou cofre corporativo
2. rotacao controlada
3. acesso restrito
4. inventario de dono do segredo
5. evidencia de provisionamento antes de release

## Cofre Local Recomendado No Windows

O caminho mais simples no ambiente atual e usar:
- modulo PowerShell SecretManagement
- modulo SecretStore

Exemplo de instalacao:

```powershell
Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
```

Exemplo de cadastro:

```powershell
Set-Secret -Name AppMobile/PostgresPassword
Set-Secret -Name AppMobile/RedisPassword
Set-Secret -Name AppMobile/JwtSecret
Set-Secret -Name AppMobile/IntegrationConfigSigningHmacKey
```

Exemplo de leitura:

```powershell
Get-Secret -Name AppMobile/JwtSecret -AsPlainText
```

## Regras Operacionais

1. `infra/.env.example` pode conter apenas placeholders.
2. `infra.env` pode conter apenas placeholders.
3. `application.yml` nao deve conter senha real nem default inseguro de producao.
4. Testes podem usar segredos de teste isolados em arquivos de teste.
5. Em homolog/prod, o backend deve falhar cedo se segredo obrigatorio nao estiver provisionado.

## Checklist De Revisao Em Release

Antes de promover:
1. confirmar que nao ha segredo real commitado
2. confirmar que `AUTH_JWT_SECRET` esta provisionado
3. confirmar que `INTEGRATION_CONFIG_SIGNING_HMAC_KEY` esta provisionado
4. confirmar que o ambiente nao esta subindo por default inseguro
5. registrar evidencia no ciclo de release

