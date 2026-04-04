# CI/CD Web Backoffice

Atualizado em: 2026-03-30

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
2. Manualmente via `workflow_dispatch` (staging).

A etapa atual valida secrets e prepara o caminho para deploy SSH:
1. `VPS_HOST`
2. `VPS_USER`
3. `VPS_SSH_KEY`

Se o segredo nao existir, o workflow nao falha e informa que o deploy foi ignorado.

## Segredos recomendados
1. `VPS_HOST`
2. `VPS_USER`
3. `VPS_SSH_KEY`
4. `NEXT_PUBLIC_API_BASE_URL` (se decidir injetar via pipeline)
5. `WEB_APP_ENV` (opcional)

## Proximos ajustes quando escolher provedor
1. Vercel: substituir deploy por SSH por action oficial ou CLI.
2. Azure Static Web Apps: usar action oficial da Microsoft.
3. AWS (Amplify/Elastic Beanstalk/ECS): trocar etapa de deploy por CLI/terraform.
