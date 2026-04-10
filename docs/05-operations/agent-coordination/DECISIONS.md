# Decisoes Multiagente - Compass

## 2026-04-10 - Divisao de Frente

- IA-Mobile fica dona de mobile/distribuicao/branding nativo.
- IA-Backend-Web fica dona de backend/web/operacao/homolog.
- Release/governanca pode ser terceira frente sem alterar codigo produtivo.

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
- Launcher/splash nativos por marca precisam verificacao final.
- Build Android Compass local nao foi validado neste ambiente por timeout.
