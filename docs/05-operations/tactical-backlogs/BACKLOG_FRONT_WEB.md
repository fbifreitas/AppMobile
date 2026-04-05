> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Deve ser lido em conjunto com `README.md`, `GEMINI.md` e os backlogs taticos de mobile/integracao/backoffice.

# Backlog Front/Web (Experiencia e Operacao)

Atualizado em: 2026-04-05

## Objetivo
Controlar o backlog de experiencia web (UI, navegacao, telas operacionais e usabilidade) sem misturar com backlog de dominio backend.

## Escopo
1. Dashboard e navegacao operacional.
2. Telas de users (list/create/import/pending/audit).
3. Telas de inspections (lista, filtros, detalhe tecnico).
4. Telas faltantes para MVP web (jobs/cases/config operacional/valuation workspace/observabilidade).

## Inventario atual de telas implementadas
1. `/` dashboard inicial
2. `/backoffice/users`
3. `/backoffice/users/create`
4. `/backoffice/users/import`
5. `/backoffice/users/pending`
6. `/backoffice/users/audit`
7. `/backoffice/inspections`
8. `/backoffice/jobs`
9. `/backoffice/cases`

## Backlog priorizado (FW)

| Seq | ID | Item | Status | Prioridade | Criterio de pronto |
|---|---|---|---|---|---|
| 1 | FW-001 | Tela Jobs (lista + filtro + paginacao) | Entregue | Critica | Operador lista jobs por tenant/status e acessa detalhe |
| 2 | FW-002 | Tela Job detalhe + timeline + acoes (assign/cancel) | Entregue | Critica | Acao operacional completa sem chamada manual de API |
| 3 | FW-003 | Tela Cases (criacao/consulta minima) | Entregue | Alta | Case e job inicial criados pelo fluxo web com rastreabilidade |
| 4 | FW-004 | Tela de configuracao dinamica check-in (sections publish/edit/rollback) | Em andamento | Critica | Publicacao e rollback por tenant sem fallback estrutural |
| 5 | FW-005 | Painel de observabilidade de integracao (p95, erro, retry, backlog) | Pendente | Alta | Operacao diagnostica falha sem abrir logs brutos |
| 6 | FW-006 | Workspace web de intake/valuation (validar/rejeitar) | Pendente | Alta | Analista fecha intake por UI e gera trilha de decisao |
| 7 | FW-007 | Workspace web de laudo basico (gerar/revisar/aprovar) | Pendente | Alta | Revisor opera ciclo Draft -> ReadyForSign por UI |
| 8 | FW-008 | Hardening UX mobile-first e acessibilidade base | Pendente | Media | Fluxos principais AA basico e sem regressao de navegacao |

## Vinculos obrigatorios
- Backoffice/plataforma: `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md`
- Mobile app: `docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md`
- Integracao: `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`
- Estrategico negocio: `docs/BACKLOG_V2_PRIORIDADES.md`

## Checkpoint 2026-04-05 - Release v1.2.32+52 (Checkpoint C web)
- FW-001 entregue em codigo com `/backoffice/jobs` + proxy `GET /api/jobs` para lista filtravel/paginada por tenant/status.
- FW-002 entregue em codigo com detalhe de job, timeline e acoes `assign/cancel` via proxies `GET /api/jobs/{id}`, `GET /api/jobs/{id}/timeline`, `POST /api/jobs/{id}/assign` e `POST /api/jobs/{id}/cancel`.
- FW-003 entregue em codigo com `/backoffice/cases` + proxy `POST /api/cases` para criacao minima e rastreabilidade imediata do case/job criado.
- Cobertura adicionada em `apps/web-backoffice/test/jobs_api_routes.test.ts`.
- Validacao executada via PowerShell + Docker Desktop com `node:20-alpine`:
  - `npm test` verde;
  - `npm run lint` verde;
  - `npm run build` verde.
