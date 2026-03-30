# CI/CD Web Backoffice

Atualizado em: 2026-03-29

## Workflows criados
1. `.github/workflows/web_ci.yml`
2. `.github/workflows/web_deploy.yml`

## web_ci.yml
Executa em push/PR na branch `main` quando houver mudanca em `apps/web-backoffice/**`.

Etapas:
1. install
2. lint
3. test
4. build
5. upload de artifact de build

## web_deploy.yml
Executa:
1. Automaticamente em push na `main` (staging).
2. Manualmente via `workflow_dispatch` para `staging` ou `production`.

O deploy usa webhook opcional por segredo:
1. `WEB_DEPLOY_HOOK_URL_STAGING`
2. `WEB_DEPLOY_HOOK_URL_PRODUCTION`

Se o segredo nao existir, o workflow nao falha, apenas informa que o deploy automatico foi ignorado.

## Segredos recomendados
1. `WEB_DEPLOY_HOOK_URL_STAGING`
2. `WEB_DEPLOY_HOOK_URL_PRODUCTION`
3. `NEXT_PUBLIC_API_BASE_URL` (se decidir injetar via pipeline)
4. `WEB_APP_ENV` (opcional)

## Proximos ajustes quando escolher provedor
1. Vercel: substituir webhook por action oficial ou CLI.
2. Azure Static Web Apps: usar action oficial da Microsoft.
3. AWS (Amplify/Elastic Beanstalk/ECS): trocar etapa de deploy por CLI/terraform.
