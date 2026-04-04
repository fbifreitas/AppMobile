> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Deve ser lido em conjunto com `README.md`, `GEMINI.md` e os backlogs taticos de mobile/integracao/backoffice.

# Backlog Front/Web (Experiencia e Operacao)

Atualizado em: 2026-04-04

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

## Backlog priorizado (FW)

| Seq | ID | Item | Status | Prioridade | Criterio de pronto |
|---|---|---|---|---|---|
| 1 | FW-001 | Tela Jobs (lista + filtro + paginacao) | Pendente | Critica | Operador lista jobs por tenant/status e acessa detalhe |
| 2 | FW-002 | Tela Job detalhe + timeline + acoes (assign/cancel) | Pendente | Critica | Acao operacional completa sem chamada manual de API |
| 3 | FW-003 | Tela Cases (criacao/consulta minima) | Pendente | Alta | Case e job inicial criados pelo fluxo web com rastreabilidade |
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