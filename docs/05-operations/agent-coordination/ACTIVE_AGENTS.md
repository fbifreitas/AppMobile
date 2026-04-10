# Agentes Ativos

Atualizado em: 2026-04-10

## Codex Big Bang Compass

- Status: ativo
- Responsavel atual: Codex nesta sessao
- Branch: `codex/docs-governance-20260409`
- Frente: implantacao integrada Compass em janela solo
- Objetivo atual: acelerar fechamento integrado dos Pacotes A/B/C necessarios para homolog, priorizando o caminho critico
- Fonte principal: `docs/05-operations/runbooks/LANCAMENTO_COMPASS_CAMINHO_CRITICO.md`
- Escopo permitido durante janela big bang: mobile, backend, web-backoffice, integracao, operacao e docs Compass
- Ultimo commit conhecido: `c67c4dd [Compass Pacote B] feat: parametrizar identidade nativa por marca`
- Proximo foco: fechar pendencias de homolog integradas e registrar evidencias para handoff das 18:00 BRT

## IA-Backend-Web

- Status: pausado ate 2026-04-10 18:00 BRT
- Responsavel atual: aguardando retomada
- Branch sugerida: `codex/compass-platform-operacao-20260410`
- Frente: backend, web-backoffice, operacao/homolog
- Objetivo ao retomar: revisar o handoff big bang e assumir pendencias backend/web remanescentes
- Fonte principal: `docs/05-operations/runbooks/LANCAMENTO_COMPASS_CAMINHO_CRITICO.md`
- Escopo permitido: `apps/backend/`, `apps/web-backoffice/`, docs de backend/web/integracao/operacao
- Proximo foco: tenant/admin/usuario provisionado, smoke JWT real, `GET /api/mobile/jobs`, config e sync por sessao real

## IA-Release-Governanca

- Status: opcional, nao iniciado
- Branch sugerida: `codex/compass-release-governance-20260410`
- Frente: release, evidencias, checklist
- Escopo permitido: `docs/05-operations/runbooks/`, `docs/05-operations/release-governance/`, checklists sem alterar codigo produtivo
- Objetivo: consolidar evidencias Pacote A/B/C e preparar promocao conforme fluxo oficial
