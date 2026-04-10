# Decisoes Multiagente - Compass

## 2026-04-10 - Divisao de Frente

- IA-Mobile fica dona de mobile/distribuicao/branding nativo.
- IA-Backend-Web fica dona de backend/web/operacao/homolog.
- Release/governanca pode ser terceira frente sem alterar codigo produtivo.

## 2026-04-10 - Janela Big Bang Solo

- Como a IA-Backend-Web so retomara as 18:00 BRT, Codex assume temporariamente implantacao integrada Compass na branch `codex/docs-governance-20260409`.
- O objetivo deixa de ser paralelismo estrito e passa a ser fechar o maior conjunto coerente de homolog em uma janela controlada.
- Commits continuam pequenos por frente, mas podem cruzar mobile/backend/web/docs quando a dependencia for direta.
- A retomada multiagente deve ocorrer por leitura obrigatoria de `HANDOFF_LOG.md` e reconciliacao de locks.
- Nao integrar `origin/main`, rebasear ou promover release sem decisao explicita do usuario e runbook oficial.

## 2026-04-10 - Contrato Mobile Compass

- Compass mobile usa `APP_API_BASE_URL` para ativar backend real.
- Compass mobile usa `APP_TENANT_ID=tenant-compass` no build de homolog.
- Login mobile usa `/auth/login` e `/auth/me`.
- Sessao mobile usa `/auth/refresh` para renovacao e `/auth/logout` para revogacao best-effort.
- Jobs mobile Compass usam `GET /api/mobile/jobs` com:
  - `X-Tenant-Id`
  - `X-Actor-Id`
  - `X-Correlation-Id`
  - `X-Api-Version`
  - `Authorization: Bearer <accessToken>`
- Firebase App Distribution separado:
  - Kaptur: `FIREBASE_APP_ID_ANDROID`
  - Compass: `FIREBASE_APP_ID_ANDROID_COMPASS`

## 2026-04-10 - Pendencias Conhecidas

- `BL-068` ainda precisa fechamento nativo iOS no projeto Xcode, alem do guia existente.
- Android ja possui splash/adaptive icon por flavor e `processCompassDebugResources` passou localmente.
- iOS foi parametrizado por xcconfig, mas scheme/target Compass ainda exige validacao em ambiente Xcode.
