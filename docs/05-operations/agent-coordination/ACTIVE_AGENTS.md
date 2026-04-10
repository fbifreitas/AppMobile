# Agentes Ativos

Atualizado em: 2026-04-10

## IA-Mobile

- Status: ativo
- Responsavel atual: Codex nesta sessao
- Branch: `codex/docs-governance-20260409`
- Frente: mobile, distribuicao Android/iOS, branding nativo Compass
- Objetivo atual: fechar `Pacote B - Mobile Compass Brand Build`
- Fonte principal: `docs/05-operations/runbooks/LANCAMENTO_COMPASS_CAMINHO_CRITICO.md`
- Escopo permitido: `lib/`, `test/`, `android/`, `ios/`, `.github/workflows/android_*`, docs diretamente relacionados a mobile/distribuicao/branding
- Ultimo commit conhecido: `3b44004 [Compass Pacote B] fix: renovar sessao mobile autenticada`
- Proximo foco: `BL-068` nativo, principalmente iOS target/scheme/bundle id e launcher/splash por marca

## IA-Backend-Web

- Status: reservado para outra IA
- Responsavel atual: aguardando inicio
- Branch sugerida: `codex/compass-platform-operacao-20260410`
- Frente: backend, web-backoffice, operacao/homolog
- Objetivo atual: validar dependencias reais para smoke Compass com tenant/admin/usuario e endpoints mobile
- Fonte principal: `docs/05-operations/runbooks/LANCAMENTO_COMPASS_CAMINHO_CRITICO.md`
- Escopo permitido: `apps/backend/`, `apps/web-backoffice/`, docs de backend/web/integracao/operacao
- Proximo foco: tenant/admin/usuario provisionado, smoke JWT real, `GET /api/mobile/jobs`, config e sync por sessao real

## IA-Release-Governanca

- Status: opcional, nao iniciado
- Branch sugerida: `codex/compass-release-governance-20260410`
- Frente: release, evidencias, checklist
- Escopo permitido: `docs/05-operations/runbooks/`, `docs/05-operations/release-governance/`, checklists sem alterar codigo produtivo
- Objetivo: consolidar evidencias Pacote A/B/C e preparar promocao conforme fluxo oficial
