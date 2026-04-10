> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Deve ser lido em conjunto com `README.md`, `GEMINI.md` e os backlogs taticos de mobile/integracao/backoffice.

# Backlog Front/Web (Experiencia e Operacao)

Atualizado em: 2026-04-08

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
| 4 | FW-004 | Tela de configuracao dinamica check-in (sections publish/edit/rollback) | Em andamento (baseline operacional entregue em 2026-04-08) | Critica | Publicacao e rollback por tenant sem fallback estrutural |
| 5 | FW-005 | Painel de observabilidade de integracao (p95, erro, retry, backlog) | Em andamento (control tower operacional entregue em 2026-04-08) | Alta | Operacao diagnostica falha sem abrir logs brutos |
| 6 | FW-006 | Workspace web de intake/valuation (validar/rejeitar) | Em andamento (baseline operacional entregue em 2026-04-08) | Alta | Analista fecha intake por UI e gera trilha de decisao |
| 7 | FW-007 | Workspace web de laudo basico (gerar/revisar/aprovar) | Em andamento (baseline operacional entregue em 2026-04-08) | Alta | Revisor opera ciclo Draft -> ReadyForSign por UI |
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

## Adendo 2026-04-08 - Agrupamento operacional em 2 macro-pacotes

### Macro-pacote A - Go-Live Core Web-Mobile
- FW-004 permanece como item web critico desta rodada.
- Papel do item no pacote: permitir publicacao, edicao e rollback de configuracao operacional por tenant sem depender de fallback estrutural no app.
- Dependencias cruzadas principais: BOW-121, INT-003, INT-004 e BOW-130.
- Criterio de saida do item no pacote: publicacao real no backoffice refletindo no mobile por versao e rollback.

### Macro-pacote B - Backoffice Operational Closure
- FW-005, FW-006 e FW-007 passam a compor o fechamento operacional do backoffice.
- Papel dos itens no pacote:
  1. FW-005: observabilidade de integracao para operacao;
  2. FW-006: intake/valuation via UI;
  3. FW-007: ciclo basico de laudo via UI.
- Dependencias cruzadas principais: BOW-140 e BOW-141.

### Ordem de execucao web
1. Concluir FW-004 dentro do Macro-pacote A.
2. Somente depois abrir FW-005/FW-006/FW-007 como frente principal.

## Adendo 2026-04-08 - Pos-release v1.2.40+60

- FW-004 permanece em andamento, mas saiu do estado de painel solto e passou a ter operacao dedicada em `/backoffice/config`, com teste de rota/pagina e reaproveitamento do backend operacional ja existente.
- FW-006 avancou para baseline operacional real com `/backoffice/valuation`, proxies Next.js para valuation e intake validation ligados ao backend e build/test/lint verdes no release `v1.2.40+60`.
- FW-007 avancou para baseline operacional real com `/backoffice/reports`, proxies Next.js para generate/review/detail ligados ao backend e validacao automatizada verde no mesmo release.
- FW-005 avancou para baseline operacional real com `/backoffice/operations`, proxy Next.js dedicado e consumo de agregados reais de control tower do backend.

## Adendo 2026-04-08 - Control tower operacional entregue

- FW-005 deixou de ser somente proposta de backlog e passou a expor cards de requests/erros/retries/backlog, tabela de metricas por endpoint, alertas ativos, retention manual e drill-down recente por `correlationId`/`protocolId`/`jobId`/`processId`/`reportId`.
- A home do backoffice agora aponta para `/backoffice/operations`, consolidando o papel do web como superficie principal de operacao do fluxo integrado.

## Adendo 2026-04-10 - Compass FW-004 com sessao real

- FW-004 deixou de aceitar `tenantId`, `actorId` e `actorRole` confiados do cliente nas rotas Next.js de `/api/config/*`.
- As rotas de pacotes, approve, rollback, resolve e audit passam a exigir sessao web real e encaminham `Authorization`, `X-Tenant-Id`, `X-Actor-Id` e `X-Actor-Role` derivados do cookie de login.
- O painel `/backoffice/config` inicializa o tenant a partir de `/api/auth/me`, preparando a publicacao de configuracao operacional do tenant Compass apos o handoff administrativo do Pacote A.

## Adendo 2026-04-10 - Jobs e cases com sessao real

- Os proxies Next.js de jobs e cases deixam de aceitar `tenantId`/`actorId` confiados via query/header e passam a exigir cookie de login web.
- As chamadas ao backend operacional passam a encaminhar `Authorization`, `X-Tenant-Id`, `X-Actor-Id` e correlation id derivados da sessao, removendo o fallback operacional `tenant-default` neste recorte.
