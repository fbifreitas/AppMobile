> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

> [31/03/2026] **Ajuste operacional:**
> Esteira de distribuiÃ§Ã£o Android ajustada para garantir que builds automÃ¡ticos sejam enviados apenas ao grupo "prod-testers" no Firebase App Distribution. Builds manuais permitem seleÃ§Ã£o de grupo, com padrÃ£o "testers-internos". MudanÃ§a documentada para rastreabilidade e prevenÃ§Ã£o de erros operacionais. (Ver detalhes no plano operacional e workflows)
# Backlog de Funcionalidades Nao Implementadas

Atualizado em: 2026-04-01

## Objetivo
Registrar funcionalidades pendentes para evolucao do AppMobile, com foco em priorizacao de produto e previsibilidade tecnica.

## Backlog complementar de backoffice web
Para planejamento do sistema web de backoffice (APIs, painÃ©is e configuraÃ§Ãµes para suportar o app mobile), consultar `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md`.

## Backlog complementar de integraÃ§Ã£o web-mobile
Para seguranÃ§a, contratos e comunicaÃ§Ã£o bidirecional entre app e backoffice, consultar `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

## Adendo 2026-04-20 - Modo de captura livre

- o app mobile passou a suportar `modo de captura livre` como variante operacional incremental
- regras consolidadas:
  - `check-in etapa 1` continua obrigatorio
  - ativacao real em `Configuracoes`
  - no `check-in`, existe aviso e ciencia, sem novo toggle local
  - a camera captura sem classificar no app
  - a revisao/finalizacao do mobile nao bloqueiam por obrigatoriedade nesse modo
  - a cobranca migra para a web em `/backoffice/inspections`
- follow-up funcional correto:
  - estabilizar smoke ponta a ponta
  - validar classificacao manual posterior e obrigatoriedades na web

## Plano de execucao (proximos 30 dias)
Para transformar backlog em entrega com marcos semanais, ownership e criterios de aceite, consultar `docs/05-operations/runbooks/PLANO_EXECUCAO_30_DIAS_WEB_MOBILE.md`.

## Cabecalho executavel (padrao)

Usar este cabecalho nos itens priorizados:
- Camada
- Dominio
- Area
- Objetivo
- Arquivos provaveis
- Dependencias
- Testes obrigatorios
- Evidencia esperada
- Docs que precisam ser atualizados
- Criterio de pronto

## Rastreabilidade retroativa de documentacao (governanca)

### DOC-001 â€” Migracao documental V2 (registro retroativo)
- Camada: corporate
- Dominio: cross-domain
- Area: governanca documental
- Objetivo: registrar formalmente a migracao da documentacao ativa para a direcao V2
- Arquivos provaveis: `README.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `docs/00-overview/*`, `docs/03-architecture/*`
- Dependencias: nenhuma
- Testes obrigatorios: validacao de coerencia de links e ausencia de contradicao ativa
- Evidencia esperada: commits `e5224d7`, `a2009e4`, `412dcc4`, `2ad389c`, `f9823d3`, `5d5ef8a` e PR #11
- Docs que precisam ser atualizados: backlog tatico e backlog estrategico V2
- Criterio de pronto: rastreabilidade registrada e vinculada aos commits/PR

Status: Concluido (registro retroativo)

### DOC-002 â€” Reclassificacao operacional ativa (registro retroativo)
- Camada: corporate
- Dominio: cross-domain
- Area: taxonomia documental operacional
- Objetivo: registrar restauracao de docs operacionais ativos em `docs/05-operations`
- Arquivos provaveis: `docs/05-operations/*`, `README.md`, `docs/00-overview/*`, `docs/99-legacy/LEGACY_MIGRATION_MAP.md`
- Dependencias: DOC-001
- Testes obrigatorios: validacao de ponteiros ativos e preservacao do snapshot legado
- Evidencia esperada: commits `1ab93d5`, `ed59f07`, `67fd452` e PR #11
- Docs que precisam ser atualizados: backlog tatico e checklist de sincronizacao
- Criterio de pronto: operacao ativa clara sem duplicidade ativa contraditoria

Status: Concluido (registro retroativo)

### DOC-003 â€” Consolidacao operacional do agente (registro retroativo)
- Camada: corporate
- Dominio: cross-domain
- Area: autonomia operacional do agente
- Objetivo: registrar criacao do sistema operacional do agente e padronizacao inicial dos backlogs taticos
- Arquivos provaveis: `docs/05-operations/AGENT_OPERATING_SYSTEM.md`, `SOURCE_OF_TRUTH_MATRIX.md`, `TASK_BRIEF_TEMPLATE.md`, `DONE_CHECKLIST_BY_WORK_TYPE.md`, `WHEN_TO_STOP_AND_ASK.md`, pivots e backlogs taticos
- Dependencias: DOC-002
- Testes obrigatorios: validacao de ponteiros + validacao de links operacionais sem caminhos legados ativos
- Evidencia esperada: commits `1d81a66`, `480c6a3`, `3999f8c`, `d989bf4`, `696e034`
- Docs que precisam ser atualizados: backlog estrategico V2 e governanca backlog/board
- Criterio de pronto: agente com trilha de leitura, fonte oficial por tema, checklist de pronto e regra de parada

Status: Concluido (registro retroativo)

## ðŸŽ¯ Roadmap de PriorizaÃ§Ã£o

A sequÃªncia de implementaÃ§Ã£o foi definida considerando:
- **DependÃªncias tÃ©cnicas**: itens que desbloqueiam outros
- **CrÃ­tica para NBR**: conformidade regulatÃ³ria nÃ£o Ã© negociÃ¡vel
- **Impacto no fluxo**: validaÃ§Ã£o em checkin/revisÃ£o

**Fluxo de implementaÃ§Ã£o recomendado:**

```
Step 1ï¸âƒ£ (CRÃTICA) â†’ BL-012 + BL-001
    â†“
Step 2ï¸âƒ£ (ALTA) â†’ BL-002 + BL-008 + BL-015
    â†“
Step 3ï¸âƒ£ (ALTA) â†’ BL-003 + BL-006
    â†“
Step 4ï¸âƒ£ (ALTA) â†’ BL-010
    â†“
Step 5ï¸âƒ£ (MÃ‰DIA) â†’ BL-004, BL-005, BL-007, BL-009, BL-016, BL-037, BL-038, BL-039
  â†“
Step 6ï¸âƒ£ (DÃ‰BITO TÃ‰CNICO) â†’ BL-013 + BL-014 + BL-036
  â†“
Step 7ï¸âƒ£ (BOAS PRÃTICAS) â†’ BL-017, BL-018, BL-019, BL-020, BL-021, BL-022, BL-023, BL-024, BL-025, BL-026, BL-027, BL-028
  â†“
Step 8ï¸âƒ£ (BACKEND BLOQUEADO â€” aguarda Onda 1 BOW) â†’ BL-031 (depende de BOW-100 + BOW-101 + BOW-102), BL-032, BL-033, BL-034, BL-035, BL-029, BL-030
```

---

## Itens Priorizados

| Seq | ID | Funcionalidade | Status | Prioridade | Criterio de pronto |
|---|---|---|---|---|---|
| **1ï¸âƒ£ AGORA** | **BL-012** | **Menus de checkin etapa 1 e 2 dinamicos via backend (sessoes NBR)** | Em andamento | ðŸ”´ **CRÃTICA** | Sessoes de captura (fachada, ambiente, elemento) com requisitos obrigatorio/desejavel configuravel via API, sem hardcoding |
| **2ï¸âƒ£ AGORA** | **BL-001** | **Integracao de envio do JSON final da vistoria para sistema web (API real)** | Em andamento | ðŸ”´ **CRÃTICA** | JSON de encerramento enviado para endpoint autenticado com retentativa e log de sucesso/erro |
| 3ï¸âƒ£ | BL-002 | Fila offline para exportacao/sincronizacao de vistorias finalizadas | Concluido | ðŸŸ  Alta | Se sem internet, arquivo entra em fila local e sincroniza automaticamente ao reconectar |
| 4ï¸âƒ£ | BL-008 | Auditoria de fallback por etapa (checkin, step2, camera, review) | Concluido | ðŸŸ  Alta | Relatorio interno mostra consistencia de payload, retomada por etapa e pilha de navegacao ao retomar vistoria |
| 5ï¸âƒ£ | BL-015 | Associar capturas iniciadas na camera com checkin etapa 2 e revisao | ConcluÃ­do | ðŸŸ  Alta | Captura iniciada fora da etapa 2 atualiza cards/pendencias obrigatorias no checkin e preserva fotos anteriores na revisao |
| 6ï¸âƒ£ | BL-003 | Tela de detalhes da vistoria concluida (somente leitura) | Concluido | ðŸŸ  Alta | Aba Vistorias permite abrir detalhes completos sem edicao |


### BL-080 — Programa incremental de backend/plataforma para enrichment, OCR, reconciliacao, smart app derivado e analytics-ready trail
- Camada: platform + shared foundations + domain-inspection
- Dominio: cross-domain com especializacao inicial em inspection/real-estate
- Area: orchestration, storage, OCR, reconciliation, mobile return ingestion, execution plan, report basis
- Objetivo: evoluir a plataforma para orquestrar enrichment, OCR documental, reconciliacao de fatos, geracao/publicacao de execution hints e recebimento do retorno do App Mobile, preparando base progressiva do report e trilha analytics-ready sem recentralizar a inteligencia no canal mobile
- Arquivos provaveis:
  `docs/02-product/03_INCREMENTO_BACKEND_ORQUESTRACAO_ENRICHMENT_OCR_SMART_APP.md`
  `docs/03-architecture/13_INCREMENTO_BACKEND_ORQUESTRACAO_ENRICHMENT_OCR.md`
  `docs/03-architecture/14_INCREMENTO_STORAGE_RECONCILIATION_AND_ANALYTICS_TRAIL.md`
  `docs/03-architecture/15_INCREMENTO_SMART_APP_AS_DERIVED_EXECUTION_PLAN.md`
  `docs/06-analysis-design/02_INCREMENTO_USE_CASES_BACKEND_ORCHESTRATION.md`
  `docs/06-analysis-design/03_INCREMENTO_CANONICAL_ARTIFACTS_AND_PAYLOADS.md`
  `docs/05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md`
  `apps/backend/*`
  `apps/web-backoffice/*`
  `lib/services/*inspection*`
  `lib/models/*inspection*`
- Dependencias:
  manter Clean Architecture, SOLID, Clean Code e TDD como guardrails obrigatorios
  preservar o case canonico existente
  separar capabilities horizontais de especializacao imobiliaria/NBR
- Testes obrigatorios:
  contract tests dos payloads publicados para mobile e retornados pelo app
  testes de use case do backend/plataforma para enrichment, OCR, reconciliation e execution plan
  testes de integracao da fila de manual resolution
  validacao do storage `raw/normalized/curated`
- Evidencia esperada:
  backend/plataforma como orquestrador documentado e implementavel
  storage preparado para receber input, research, documents, job-config, inspection-return e field-evidence
  smart app documentado como saida derivada
  trilha pronta para analytics futura
- Docs que precisam ser atualizados:
  este backlog
  `docs/05-operations/runbooks/PAINEL_MILESTONES_FLUXO_CONFIGURAVEL_VISTORIA.md`
  docs incrementais criados neste pacote
- Criterio de pronto:
  arquitetura incremental documentada
  milestones M1..Mx publicados
  backlog implementavel por ciclos longos de desenvolvimento

Status: Planejado
### BL-053 â€” Consolidacao final da i18n como camada unica de UI
- Camada: mobile app
- Dominio: cross-domain
- Area: interface, i18n, branding
- Objetivo: concluir a migracao para que todo texto visivel ao usuario seja resolvido pela i18n, evitando texto final vindo de branding/config e eliminando hardcodes residuais PT/EN nas telas do app
- Arquivos provaveis:
  `lib/screens/checkin_capture_screen.dart`
  `lib/screens/inspection_menu_screen.dart`
  `lib/screens/inspection_review_screen.dart`
  `lib/widgets/review/inspection_review_section_widgets.dart`
  `lib/widgets/review/inspection_review_technical_widgets.dart`
  `lib/screens/go_live_readiness_screen.dart`
  `lib/screens/field_operations_center_screen.dart`
  `lib/screens/fallback_audit_center_screen.dart`
  `lib/screens/data_governance_center_screen.dart`
  `lib/screens/clean_code_maturity_screen.dart`
  `lib/screens/clean_code_audit_center_screen.dart`
  `lib/screens/mock_data_control_screen.dart`
  `lib/widgets/operational_center_list_card.dart`
  `lib/widgets/remote_config_list_card.dart`
- Dependencias:
  manter `AppStrings` como camada unica de resolucao de idioma
  branding deve fornecer apenas dados de marca ou copy integrada a locale via i18n
- Testes obrigatorios:
  `C:\src\flutter\bin\flutter.bat analyze --no-pub`
  `C:\src\flutter\bin\flutter.bat test --no-pub`
  smoke manual em `EN` e `PT` nas telas de login, home, jobs, proposals, review e inspection menu
- Evidencia esperada:
  nao haver uso de `config.copyText(...)` ou `copyTextOrNull(...)` como texto final visivel ao usuario fora da camada de i18n
  nao haver textos hardcoded inconsistentes com locale ativo nas telas priorizadas
- Docs que precisam ser atualizados:
  este backlog
  se houver mudanca estrutural adicional, `docs/04-engineering/07_LANGUAGE_MIGRATION_DASHBOARD.md`
- Criterio de pronto:
  app respeita o locale ativo de forma consistente
  branding nao atua como mini-i18n paralela
  testes existentes permanecem verdes

Status: Parcialmente concluido
Progresso atual:
- concluido: base estrutural da integracao i18n + branding, login, home, jobs, proposals, navegacao inferior, alguns centros e cards principais
- pendente: lote residual de telas com hardcodes visiveis ou arquivos com historico de encoding que exigem passe dedicado
| 7ï¸âƒ£ | BL-006 | Modo desenvolvedor: editor completo de mocks para menus dinamicos da camera | Concluido | ðŸŸ  Alta | Painel dev permite editar cenarios e menus dinamicos sem alterar codigo |
| 8ï¸âƒ£ | BL-010 | Endurecimento de bloqueio de recursos dev em release final | Concluido | ðŸŸ  Alta | Recursos dev nao aparecem para usuario final sem desbloqueio autorizado |
| 9ï¸âƒ£ | BL-004 | Exibir protocolo/ID externo no card e no historico de vistorias | Concluido | ðŸŸ¡ Media | Card mostra ID do job e protocolo externo quando existir |
| ðŸ”Ÿ | BL-005 | Regras de retencao e limpeza de arquivos JSON exportados | ConcluÃ­do | ðŸŸ¡ Media | Politica configuravel (ex.: manter ultimos N dias) com limpeza segura |
| 1ï¸âƒ£1ï¸âƒ£ | BL-016 | Diretorio de exportacao JSON configuravel para conferencia operacional | Concluido | ðŸŸ¡ Media | Export permite alternar destino (interno/externo) sem perder rastreabilidade e fluxo de sync |
| 1ï¸âƒ£2ï¸âƒ£ | BL-037 | Matriz de pendencia tecnica com linguagem operacional e acao guiada | Concluido | ðŸŸ  Alta | Matriz apresenta texto simples e link/acao direta para levar o usuario ao ponto exato da pendencia no fluxo |
| 1ï¸âƒ£3ï¸âƒ£ | BL-038 | Preservar classificacao revisada ao retornar da camera para revisao | Concluido | ðŸŸ  Alta | Fotos ja classificadas nao regressam para status laranja ao adicionar nova captura e voltar para revisao |
| 1ï¸âƒ£4ï¸âƒ£ | BL-039 | Agrupar revisao no topo por fotos obrigatorias e fotos capturadas | Concluido | ðŸŸ¡ Media | Topo da revisao exibe agrupadores claros de obrigatorias e capturadas, alinhado ao bloco de pendencias |
| 1ï¸âƒ£5ï¸âƒ£ | BL-007 | Seed de cenarios de QA por perfil (1, 3, 10 vistorias; ativas/concluidas) | Pendente | ðŸŸ¡ Media | Um toque aplica cenarios pre-definidos para homologacao |
| 1ï¸âƒ£6ï¸âƒ£ | BL-009 | Telemetria de fluxo (inicio, retomada, conclusao, falhas de integracao) | Pendente | ðŸŸ¡ Media | Eventos minimos registrados para diagnostico operacional |
| â¸ï¸  | BL-011 | Flavors de distribuicao (prod, internal, dev) | Adiado | ðŸŸ¡ Media | Entrypoints e pipeline separados para builds internos e producao |
| âš¡ | BL-036 | Cache de Flutter/pub no pipeline CI (dÃ©bito tÃ©cnico) | Pendente | ðŸ”µ Baixa (pos-funcional) | Pipeline reduz tempo de build cacheando `.pub-cache` e `.dart_tool` com chave baseada em `pubspec.lock` |
| ðŸ”§ | BL-013 | Auditoria de Clean Code e SOLID (dÃ©bito tÃ©cnico) | Planejado | ðŸ”µ Baixa (pos-funcional) | Relatorio tÃ©cnico com achados, plano de refatoracao e aplicacao incremental por modulo sem regressao funcional |
| ðŸ§ª | BL-014 | EvoluÃ§Ã£o da suÃ­te de testes com prÃ¡tica TDD (dÃ©bito tÃ©cnico) | Em andamento | ðŸ”µ Baixa (pos-funcional) | Cobertura de testes ampliada por fluxo crÃ­tico, com testes criados/atualizados a cada entrega funcional |
| ðŸ§± | BL-017 | Contract testing de APIs mobile-backend | Planejado | ðŸŸ  Alta | Contratos de request/response validados em CI para endpoints crÃ­ticos (config dinÃ¢mica e sync) |
| ðŸ§¬ | BL-018 | Mutation testing para regras crÃ­ticas | Planejado | ðŸŸ¡ Media | Mutation score mÃ­nimo definido e monitorado para serviÃ§os crÃ­ticos |
| ðŸ“ˆ | BL-019 | Quality gate de cobertura por mÃ³dulo | Planejado | ðŸŸ  Alta | CI bloqueia merge quando cobertura mÃ­nima por mÃ³dulo regredir |
| ðŸ§­ | BL-020 | Fronteiras de arquitetura e inversÃ£o de dependÃªncia | Planejado | ðŸŸ  Alta | Camadas desacopladas com interfaces explÃ­citas entre domÃ­nio, aplicaÃ§Ã£o e infraestrutura |
| âš ï¸ | BL-021 | EstratÃ©gia padronizada de tratamento de erros | Planejado | ðŸŸ  Alta | Erros tipados, mensagens consistentes e ausÃªncia de catch silencioso nos fluxos crÃ­ticos |
| ðŸ”— | BL-022 | Observabilidade com correlation id por vistoria | Planejado | ðŸŸ¡ Media | Eventos de ponta a ponta rastreÃ¡veis por job/correlation id |
| ðŸ” | BL-023 | Hardening de seguranÃ§a e gestÃ£o de secrets | Em andamento | ðŸŸ  Alta | Segredos fora do cÃ³digo, validaÃ§Ã£o de configuraÃ§Ã£o e checklist de seguranÃ§a em release |
| âš¡ | BL-024 | Performance budgets em fluxos crÃ­ticos | Planejado | ðŸŸ¡ Media | Metas de tempo por etapa monitoradas com alerta de regressÃ£o |
| ðŸ§© | BL-057 | SemÃ¢ntica canÃ´nica Ãºnica para labels e aliases do fluxo de inspection | Em andamento | ðŸŸ  Alta | Coordinator, cÃ¢mera e revisÃ£o deixam de depender de vocabulÃ¡rio legado como regra operacional |
| ðŸ§­ | BL-058 | Estado canÃ´nico inicial/current/resume fora da UI | Em andamento | ðŸŸ  Alta | Bootstrap, operaÃ§Ã£o e retomada passam a trafegar por objeto coeso compatÃ­vel com payload legado |
| ðŸ·ï¸ | BL-059 | Ambientes repetidos como aÃ§Ã£o contextual estÃ¡vel | Em andamento | ðŸŸ  Alta | `Novo Quarto`/`Quarto 2` persistem ponta a ponta sem submenu nem regra paralela em tela |
| ðŸ§± | BL-060 | Quebra incremental do concentrador de menus/configuraÃ§Ã£o | Em andamento | ðŸŸ  Alta | Loader, merge, prefs, catÃ¡logo, inteligÃªncia e ranking deixam de viver no mesmo service |
| ðŸ§° | BL-061 | EspecializaÃ§Ã£o inspection sobre core configurÃ¡vel reutilizÃ¡vel | Em andamento | ðŸŸ  Alta | Taxonomia imobiliÃ¡ria fica no domÃ­nio e nÃ£o volta a contaminar a semÃ¢ntica global |
| ðŸ“¦ | BL-025 | GovernanÃ§a de dependÃªncias e vulnerabilidades | Planejado | ðŸŸ¡ Media | Rotina de atualizaÃ§Ã£o com scanner e polÃ­tica de correÃ§Ã£o de CVEs |
| ðŸ§¾ | BL-026 | ADRs para decisÃµes arquiteturais | Planejado | ðŸŸ¡ Media | DecisÃµes tÃ©cnicas relevantes registradas com contexto e trade-offs |
| ðŸš© | BL-027 | Ciclo de vida de feature flags | Planejado | ðŸŸ¡ Media | Processo de criaÃ§Ã£o, auditoria e remoÃ§Ã£o de flags sem acÃºmulo tÃ©cnico |
| âœ… | BL-028 | Definition of Done reforÃ§ada | Planejado | ðŸŸ  Alta | Entrega sÃ³ conclui com testes, observabilidade mÃ­nima, documentaÃ§Ã£o e checklist QA |
| ðŸ—“ï¸ | BL-029 | Agenda em calendÃ¡rio com jobs agendados do usuÃ¡rio | Concluido | ðŸŸ  Alta | Aba Agenda exibe calendÃ¡rio mensal/semanal com jobs por data e navegaÃ§Ã£o para detalhes |
| ðŸ”” | BL-030 | Sininho de mensagens com central backend-app e push | Concluido | ðŸ”´ CrÃ­tica | Mensagens vinculadas a job/proposta aparecem na central e geram notificaÃ§Ã£o no celular mesmo com app fechado |
| ðŸ” | BL-031 | Tela de login e autenticaÃ§Ã£o do App | Em andamento | ðŸ”´ CrÃ­tica | UsuÃ¡rio autentica com backend, sessÃ£o persistida com expiraÃ§Ã£o/renovaÃ§Ã£o, controle de tentativas, MFA readiness e logout seguro |
| ðŸ§¾ | BL-032 | Onboarding de usuÃ¡rios CLT e PJ no app | Concluido | ðŸ”´ CrÃ­tica | Fluxo coleta dados obrigatÃ³rios por tipo (CLT/PJ), incluindo dados pessoais e bancÃ¡rios para PJ |
| â³ | BL-033 | Estado aguardando aprovaÃ§Ã£o do cadastro (backoffice) | Concluido | ðŸŸ  Alta | ApÃ³s onboarding, usuÃ¡rio sem aprovaÃ§Ã£o visualiza tela estÃ¡tica de aguardando aprovaÃ§Ã£o com atualizaÃ§Ã£o de status |
| âš™ï¸ | BL-034 | ConfiguraÃ§Ãµes para atualizaÃ§Ã£o de dados cadastrais | Concluido | ðŸŸ  Alta | Menu configuraÃ§Ãµes permite editar os mesmos dados do onboarding com validaÃ§Ã£o e envio ao backend |
| ðŸ§‘ | BL-035 | Foto do usuÃ¡rio no topo com captura e atualizaÃ§Ã£o | Concluido | ðŸŸ  Alta | Foto do onboarding aparece no topo da Home e pode ser atualizada por captura de cÃ¢mera (sem galeria) |
| 4ï¸âƒ£0ï¸âƒ£ | BL-040 | Corrigir consistÃªncia NBR: obrigatoriedade de Entorno no Checkin Etapa 2 e RevisÃ£o | ConcluÃ­do | ðŸ”´ CrÃ­tica | Entorno obrigatÃ³rio deve ser consistente em Checkin Etapa 2 e PendÃªncias TÃ©cnicas; aÃ§Ã£o "Ir para pendÃªncia" nÃ£o pode travar fluxo |
| 4ï¸âƒ£1ï¸âƒ£ | BL-041 | Reorganizar RevisÃ£o de Fotos com acordeÃµes de obrigatÃ³rias e capturadas no bloco inferior | ConcluÃ­do | ðŸŸ  Alta | Bloco "RevisÃ£o de Fotos ObrigatÃ³rias" deve ficar abaixo, com dois acordeÃµes independentes e estados visuais OK/NOK |
| 4ï¸âƒ£2ï¸âƒ£ | BL-042 | Exibir ID do JOB em Novas Propostas e simular aceite por deslize com movimentaÃ§Ã£o de card | ConcluÃ­do | ðŸŸ  Alta | Card de proposta mostra ID do job e, ao aceitar, sai de propostas e entra em "Meus Jobs Agendados" via mock atualizado |
| 4ï¸âƒ£3ï¸âƒ£ | BL-043 | Remover overlay fixo de comandos rÃ¡pidos por voz na cÃ¢mera | ConcluÃ­do | ðŸŸ¡ Media | Componente de voz nÃ£o pode cobrir a Ã¡rea principal de captura/classificaÃ§Ã£o |
| 4ï¸âƒ£4ï¸âƒ£ | BL-044 | Adicionar colapso lateral dos menus dinÃ¢micos da cÃ¢mera com abertura padrÃ£o expandida | ConcluÃ­do | ðŸŸ  Alta | Menu lateral inicia expandido e permite ocultar/mostrar via controle lateral sem impactar captura |
| 4ï¸âƒ£5ï¸âƒ£ | BL-045 | Mover exportaÃ§Ã£o da vistoria de ConfiguraÃ§Ãµes para Hub Operacional | ConcluÃ­do | ðŸŸ¡ Media | Entrada de exportaÃ§Ã£o deve estar no Hub Operacional e removida de ConfiguraÃ§Ãµes |
| 4ï¸âƒ£6ï¸âƒ£ | BL-046 | Corrigir logout em ConfiguraÃ§Ãµes com retorno para tela de login (mock) | ConcluÃ­do | ðŸ”´ CrÃ­tica | AÃ§Ã£o "Sair da conta" limpa sessÃ£o mock e retorna para login consistentemente |
| 4ï¸âƒ£7ï¸âƒ£ | BL-047 | Ajustar onboarding do app para fluxo exclusivamente PJ com validaÃ§Ãµes de CNPJ/AgÃªncia/Conta/Banco | ConcluÃ­do | ðŸ”´ CrÃ­tica | Tela inicial nÃ£o deve pedir CLT/PJ e campos PJ devem validar formato e consistÃªncia mÃ­nima |
| 4ï¸âƒ£8ï¸âƒ£ | BL-048 | Criar aÃ§Ã£o no Hub Operacional para resetar mock de onboarding | ConcluÃ­do | ðŸŸ  Alta | Operador deve conseguir zerar estado de onboarding para reteste sem reinstalar app |
| 4ï¸âƒ£9ï¸âƒ£ | BL-049 | Consolidar GitHub Project como fonte primÃ¡ria do backlog com sincronizaÃ§Ã£o total dos itens BL | Em andamento | ðŸŸ  Alta | Todos os BL (pendentes, em andamento, concluÃ­dos e adiados) devem existir no board com status e critÃ©rios atualizados |
| 5ï¸âƒ£0ï¸âƒ£ | BL-050 | Corrigir botÃ£o "Concluir" do onboarding encoberto pelo rodapÃ© do Android | ConcluÃ­do | ðŸŸ  Alta | BotÃ£o final do onboarding deve permanecer totalmente visÃ­vel em Android (botÃµes/gestos), permitindo concluir o fluxo sem obstruÃ§Ã£o |
| 5ï¸âƒ£1ï¸âƒ£ | BL-051 | Unificar persistÃªncia dinÃ¢mica de obrigatoriedade e polÃ­tica de fotos (mÃ­n/mÃ¡x) entre Checkin, CÃ¢mera, RevisÃ£o e Menu | Em andamento | ðŸ”´ CrÃ­tica | Mesma regra dinÃ¢mica deve governar validaÃ§Ã£o e indicadores em todas as telas, com suporte a mÃ­nimo/mÃ¡ximo de fotos sem divergÃªncia de payload |
| 5ï¸âƒ£2ï¸âƒ£ | BL-052 | Unificar pacote de parametrizaÃ§Ã£o operacional do HUB para Check-in e CÃ¢mera por nÃ­veis | Em andamento | ðŸ”´ CrÃ­tica | Mesmo documento do modo desenvolvedor deve definir menus do check-in e nÃ­veis da cÃ¢mera, incluindo material e estado, sem contratos paralelos |
| 5ï¸âƒ£3ï¸âƒ£ | BL-054 | UX progressiva no Check-in etapa 1 e 2 com acordeÃµes por pergunta e resumo inline da resposta | Em andamento | ðŸŸ  Alta | Exibir apenas a prÃ³xima pergunta pendente, colapsar respostas jÃ¡ preenchidas com status visual OK/NOK e manter feedback de progresso x/y durante o preenchimento |
| 5ï¸âƒ£4ï¸âƒ£ | BL-055 | Revisar hierarquia visual e regras de casing por nÃ­vel no Menu de Vistoria e Check-in Etapa 2 | ConcluÃ­do | ðŸŸ  Alta | NÃ­vel 1 em Title Case, nÃ­vel 2 em CAIXA ALTA, nÃ­vel 3 em Title Case, com acordeÃµes iniciando recolhidos conforme regra operacional |
| 5ï¸âƒ£5ï¸âƒ£ | BL-056 | Tela dedicada de onboarding de permissÃµes Android e iOS com reentrada obrigatÃ³ria para usuÃ¡rios sem etapa de onboarding (ex.: CLTs criados via web) | Concluido | ðŸ”´ CrÃ­tica | UsuÃ¡rio concede permissÃµes essenciais no onboarding inicial e, quando autenticado sem onboarding concluÃ­do, Ã© redirecionado para tela de permissÃµes antes de usar fluxos operacionais |
| 5ï¸âƒ£6ï¸âƒ£ | BL-057 | Alinhar semÃ¢ntica canÃ´nica do fluxo de captura Ã  arquitetura V2 da plataforma | Planejado | ðŸ”´ CrÃ­tica | Labels diferentes por tela continuam possÃ­veis, mas Check-in, CÃ¢mera, RevisÃ£o e Menu passam a apontar para a mesma dimensÃ£o semÃ¢ntica canÃ´nica, sem inspection definir o core global |
| 5ï¸âƒ£7ï¸âƒ£ | BL-058 | Separar estado inicial sugerido, estado atual e estado de retomada da captura | Planejado | ðŸ”´ CrÃ­tica | O fluxo mantÃ©m bootstrap do check-in, operaÃ§Ã£o corrente e retomada como estados distintos, com recovery compatÃ­vel e sem travar a cÃ¢mera no contexto inicial |
| 5ï¸âƒ£8ï¸âƒ£ | BL-059 | Tratar duplicaÃ§Ã£o de ambiente repetido como aÃ§Ã£o contextual do nÃ­vel atual | Planejado | ðŸ”´ CrÃ­tica | A cÃ¢mera permite `Trocar` e `Novo <ambiente>` sem criar novo nÃ­vel na Ã¡rvore principal, preservando revisÃ£o/retomada e matching de obrigatÃ³rios |
| 5ï¸âƒ£9ï¸âƒ£ | BL-060 | Quebrar o service concentrador de configuraÃ§Ã£o em fatias coesas e compatÃ­veis com V2 | Planejado | ðŸŸ  Alta | Carregamento, merge, fallback, histÃ³rico e prediction deixam de ficar concentrados em um Ãºnico service, mantendo a API pÃºblica estÃ¡vel na migraÃ§Ã£o |
| 6ï¸âƒ£0ï¸âƒ£ | BL-061 | Isolar especializaÃ§Ã£o do domÃ­nio inspection sobre um core reutilizÃ¡vel de fluxo configurÃ¡vel | Planejado | ðŸŸ  Alta | Taxonomia imobiliÃ¡ria, instÃ¢ncias operacionais e labels de inspection permanecem no domain layer, desacopladas do core/plataforma e sem rename cego |
| 6ï¸âƒ£1ï¸âƒ£ | BL-075 | Arquitetura modular de onboarding white label por marca/produto | Em andamento (slice Compass iniciado em 2026-04-10) | ðŸ”´ CrÃ­tica | Substituir o onboarding Ãºnico por resolver de fluxo por brand/productMode, reaproveitando core e separando jornadas Kaptur/Compass |
| 6ï¸âƒ£2ï¸âƒ£ | BL-076 | Primeiro acesso Compass para usuÃ¡rio provisionado com OTP e criaÃ§Ã£o de senha | Em andamento (baseline local entregue em 2026-04-10) | ðŸ”´ CrÃ­tica | Compass deve localizar cadastro prÃ©vio, validar OTP em contato cadastrado, criar senha e seguir pendÃªncias mÃ­nimas sem auto-cadastro |
| 6ï¸âƒ£3ï¸âƒ£ | BL-077 | Cadastro Kaptur marketplace PF/MEI/PJ com mÃ³dulos fiscais, atuaÃ§Ã£o e repasse | Planejado | ðŸ”´ CrÃ­tica | Kaptur deve evoluir o cadastro atual PJ para jornada completa de prestador, com campos condicionais e aprovaÃ§Ã£o |
| 6ï¸âƒ£4ï¸âƒ£ | BL-078 | PermissÃµes progressivas por recurso e por marca | Planejado | ðŸŸ  Alta | Tela atual de permissÃµes vira mÃ³dulo explicativo; cÃ¢mera/localizaÃ§Ã£o/microfone sÃ£o solicitados no momento certo e microfone fica condicional |
| 6ï¸âƒ£5ï¸âƒ£ | BL-079 | Pocket training e termos versionados por app | Planejado | ðŸŸ  Alta | Tutorial, LGPD, confidencialidade e conduta passam a ser mÃ³dulos reutilizÃ¡veis com conteÃºdo e obrigatoriedade por marca |

---

## Descricoes dos Itens

### Bloco executavel prioritario (inicio)

#### BL-012
- Camada: experience-layer
- Dominio: domain-inspection
- Area: mobile check-in
- Objetivo: menus check-in etapa 1 e 2 dinamicos via backend
- Arquivos provaveis: `lib/screens/*checkin*`, `lib/services/*config*`, `lib/state/*`
- Dependencias: BOW-008, INT-003
- Testes obrigatorios: widget tests de fluxo check-in + validacao de contrato de config
- Evidencia esperada: telas e payload final coerentes com configuracao dinamica
- Docs a atualizar: este backlog e backlog de integracao relacionado
- Criterio de pronto: sem hardcoding de sessoes obrigatorias no fluxo critico

#### BL-001
- Camada: experience-layer
- Dominio: domain-inspection
- Area: mobile sync/integracao
- Objetivo: envio do JSON final para API real com rastreabilidade
- Arquivos provaveis: `lib/services/*sync*`, `lib/repositories/*`, `lib/state/*`
- Dependencias: BOW-010, INT-006, INT-007
- Testes obrigatorios: testes de sync com sucesso/falha/retry
- Evidencia esperada: protocolo de retorno persistido e exibido
- Docs a atualizar: este backlog e backlog de integracao
- Criterio de pronto: sync real autenticado com retentativa e log de resultado

### BL-012
Tornar os menus de checkin etapa 1 e etapa 2 dinamicos via backend, permitindo adicionar/remover sessoes e definir obrigatoriedade (NBR) sem novo deploy do app.

Observacao 2026-03-30 (Em andamento): adicionado fallback de configuracao dinamica por modo desenvolvedor, com documento JSON local configuravel no painel de dados mock. Fluxo de leitura agora prioriza mock local quando habilitado, depois API, depois cache, e por ultimo fallback hardcoded.

Observacao 2026-04-10 (PARCIAL - Compass Pacote C): smoke E2E de homolog valida que pacote operacional Compass publicado/aprovado pelo backoffice chega ao mobile via `GET /api/mobile/checkin-config` autenticado, incluindo politica de fotos e feature flags.

### BL-001
Enviar o JSON final da vistoria para a API web oficial com autenticacao, registro de sucesso/erro e rastreabilidade por job.

Observacao 2026-03-30: payloads de origem financeira para criacao de processo devem ser tratados e normalizados no backoffice/integracao (docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md e docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md). O app mobile consome apenas campos operacionais expostos pelas APIs internas (jobs/config/sync), evitando acoplamento ao contrato externo bruto.

Observacao 2026-03-30 (Em andamento): sincronizacao final passou a interpretar metadados de resposta da API (ex.: process_id/process_number/status) e a expor protocolo no feedback de conclusao. Adicionado tambem modo desenvolvedor para resposta mock de sync quando a integracao web definitiva ainda nao estiver disponivel.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): entrypoint Compass passou a carregar jobs via `GET /api/mobile/jobs` com contexto autenticado (`X-Tenant-Id`, `X-Actor-Id`, bearer). Fallback mock permanece apenas quando `APP_API_BASE_URL` nao esta configurado.
Observacao 2026-04-10 (PARCIAL - Compass Pacote C): smoke E2E de homolog cobre envio de vistoria finalizada Compass com bearer, idempotencia e correlacao, confirmando recebimento no backoffice e criacao do fluxo de valuation/report.

### BL-002
Criar fila offline para armazenar vistorias finalizadas quando nao houver conectividade e sincronizar automaticamente quando a rede retornar.

### BL-008
Implementar auditoria de fallback por etapa (checkin, step2, camera e review) para identificar inconsistencias de payload e problemas de retomada.

### BL-015
Garantir que capturas iniciadas diretamente pela camera (fora do fluxo da etapa 2) sejam conciliadas automaticamente com os requisitos do checkin etapa 2 e com as pendencias da revisao final.

Observacao 2026-03-30: ajustada a persistencia do status das fotos obrigatorias do check-in na revisao/menu de vistoria, reconstruindo o indicador tambem a partir do payload salvo da etapa 2 para evitar perda visual do status OK ao voltar no fluxo.

Observacao 2026-03-30 (CORRIGIDO): bug do status verde desaparecendo ao voltar para Menu de Vistoria - `InspectionMenuScreen` agora consulta tambem `appState.step2Payload` (nao apenas `InspectionSession`) para recalcular status das fotos obrigatorias, garantindo persistencia mesmo quando sessao nao foi sincronizada. Adicionado metodo `_countCompletedMandatoryFields()` que reconstroi indicador a partir de ambas fontes de dados.

Observacao 2026-03-30: iniciada a centralizacao da navegacao do fluxo Home -> Check-in -> Camera -> Revisao com coordinator injetavel, reduzindo acoplamento entre telas e abrindo caminho para testes estaveis de retorno da camera e retomada da pilha.

Observacao 2026-03-30: estendida a centralizacao para hubs secundarios (Home, Hub operacional e Centro de integracao), concentrando o despacho de atalhos e centrais em um coordinator unico para reduzir switches duplicados e facilitar testes de navegacao.

Observacao 2026-03-30: a tela Menu de Vistoria passou a delegar a abertura da revisao ao coordinator do fluxo, e a cobertura automatizada agora valida tambem os atalhos do header da Home e os entrypoints secundarios de navegacao.

### BL-003
Disponibilizar tela de detalhes da vistoria concluida em modo somente leitura, acessivel pela aba Vistorias, sem qualquer possibilidade de edicao.

### BL-006
Expandir o painel de modo desenvolvedor para editar mocks completos, incluindo menus dinamicos de camera e cenarios de teste sem alteracao de codigo.

Observacao 2026-03-30 (CONCLUIDO): painel de mock ganhou presets QA (1/3/10), edicao de JSON de configuracao dinamica, resposta de sync e editor avancado para agenda e mensagens com aplicacao em runtime.

### BL-010
Fortalecer bloqueios de recursos de desenvolvimento em build de release para impedir exposicao acidental de funcionalidades internas ao usuario final.

Observacao 2026-03-30 (CONCLUIDO): acesso a recursos dev bloqueado em release no estado global, com feedback de bloqueio nas configuracoes e protecao de tela no painel de mocks sem desbloqueio autorizado.

Observacao 2026-03-31: bloqueio de acesso em release esta concluido, mas a remocao fisica do modulo desenvolvedor do binario final ainda nao foi aplicada.

### BL-004
Exibir identificadores operacionais (ID do job e protocolo externo) no card da home e no historico, facilitando rastreio e suporte.

Observacao 2026-03-30 (CONCLUIDO): card da Home e lista de Vistorias concluidas passaram a exibir ID externo e Protocolo quando disponiveis. Fluxo de conclusao da revisao agora persiste referencias externas recebidas do backend no job atual, e testes cobrem a renderizacao no card ativo e no historico.

### BL-005
Definir politica de retencao e limpeza dos JSONs exportados, com regras seguras para manter historico util sem crescimento indefinido de armazenamento.

Observacao 2026-03-31 (CONCLUIDO): configuracao de retencao (dias) adicionada ao Hub Operacional junto da configuracao de exportacao, com acao de limpeza imediata e politica persistida em preferencias. Servico de exportacao aplica limpeza segura por idade dos arquivos JSON de vistoria.

### BL-016
Permitir configuracao do diretorio de exportacao do JSON final (interno e/ou externo para conferencia operacional), mantendo consistencia com fila offline e rastreabilidade por job.

Observacao 2026-03-30 (CONCLUIDO): adicionada configuracao em `Configuracoes` para destino da exportacao (interno/externo) e subdiretorio customizavel. A resolucao efetiva aplica fallback automatico para interno quando externo nao estiver disponivel, preservando o fluxo de sincronizacao e a rastreabilidade por job.

Observacao 2026-03-30: apos revisao UX do Menu de Vistoria, os itens BL-037, BL-038 e BL-039 foram priorizados para entrar na sequencia do BL-016.

### BL-037
Evoluir a matriz de pendencia tecnica para linguagem comum ao usuario operacional, com mensagens objetivas e acao guiada por pendencia.

Observacao 2026-03-30 (CONCLUIDO): matriz atualizada com linguagem mais operacional e atalho "Ir para pendencia" para navegacao direta dentro da tela de revisao. Cobertura de regressao adicionada para garantir a renderizacao da acao guiada.

Detalhamento:
1. Reescrever descricoes tecnicas em texto orientado a tarefa.
2. Adicionar link/botao "ir para pendencia" para levar ao ponto correto do fluxo (check-in, camera ou revisao).
3. Exibir contexto minimo: o que falta, onde resolver e como confirmar conclusao.

### BL-038
Garantir preservacao da classificacao ja revisada quando o usuario retorna da camera com novas fotos.

Observacao 2026-03-30 (CONCLUIDO): revisao passou a persistir e reidratar capturas revisadas no draft de recovery, mantendo classificacoes existentes ao voltar da camera para a revisao. Testes de regressao validam que a captura ja revisada permanece classificada enquanto novas capturas entram como pendentes ate revisao.

Detalhamento:
1. Reconciliar capturas novas sem resetar classificacao existente.
2. Manter status verde dos itens ja classificados quando nao houver alteracao de conteudo/classificacao.
3. Cobrir com testes de navegacao e regressao do fluxo revisao -> camera -> revisao.

### BL-039
Reorganizar o topo da revisao de fotos com agrupadores equivalentes ao bloco de pendencias.

Observacao 2026-03-30 (CONCLUIDO): topo da revisao atualizado com agrupadores de "Fotos obrigatorias" e "Fotos capturadas", com contadores de progresso por grupo. Cobertura automatizada adicionada para preservar a leitura do resumo no topo.

Observacao 2026-04-01 (Em andamento): retomada de ajustes UX no Menu de Vistoria para deduplicar itens obrigatorios com mesmo titulo (ex.: Fachada), exibir progresso x/y por bloco e reforcar navegacao do atalho "Ir para pendencia" com foco direto na secao correspondente.

Observacao 2026-04-01 (Em andamento): estrutura visual do Menu de Vistoria padronizada por secoes em accordion (Pendencias tecnicas por etapa, Revisao de fotos e Encerramento), mantendo compatibilidade com validacoes automatizadas existentes.

Observacao 2026-04-01 (Em andamento): padrao de texto aplicado no menu e telas irmas com primeiro nivel em caixa alta e niveis internos em Title Case para leitura operacional consistente.

Observacao 2026-04-01 (CONCLUIDO): pendencias tecnicas passaram a refletir contagem por obrigatoriedade (x/y), com exibicao da etapa de Finalizacao e alinhamento do fluxo Maestro ao novo titulo em caixa alta no Menu de Vistoria.

Detalhamento:
1. Separar "Fotos obrigatorias" e "Fotos capturadas" no topo da tela.
2. Mostrar totais e progresso por agrupador para leitura rapida.
3. Alinhar semantica visual com a secao "Ver pendencias de vistoria".

### BL-007
Criar seeds de QA pre-definidos (ex.: 1, 3 e 10 vistorias, ativas e concluidas) para acelerar homologacao e testes de apresentacao.

### BL-009
Registrar telemetria minima do fluxo de vistoria (inicio, retomada, conclusao e falhas de integracao) para diagnostico operacional.

### BL-011
Estruturar flavors de distribuicao (prod, internal e dev) para separar pacotes e pipelines quando estiver proximo ao go-live.

Observacao 2026-03-31: item mantido como pre-requisito tecnico para reduzir tamanho real do pacote removendo codigo/dev tools do artefato de producao.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): CI/homologacao Android passam a buildar explicitamente `kaptur` com `lib/main_kaptur.dart` e `compass` com `lib/main_compass.dart`, publicando artefato Compass separado. Build Compass usa `APP_TENANT_ID=tenant-compass` e `COMPASS_APP_API_BASE_URL` como variavel de ambiente do GitHub Actions.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): distribuicao Android manual passa a aceitar `brand=compass`/`all` e exige `FIREBASE_APP_ID_ANDROID_COMPASS` para publicar Compass em Firebase App Distribution separado da Kaptur.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): Android ganhou recursos nativos por flavor para splash/adaptive icon. iOS ganhou xcconfigs por marca e Info.plist parametrizado; validacao final de scheme/target Compass permanece pendente em ambiente Xcode.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): iOS ganhou schemes compartilhados `kaptur` e `compass` e configuracoes `Debug/Release/Profile` por flavor, apontando para xcconfigs de marca. Validacao local em Windows cobriu XML dos schemes e `flutter analyze --no-pub`; build iOS real segue pendente de macOS/Xcode.


### BL-080 — Programa incremental de backend/plataforma para enrichment, OCR, reconciliacao, smart app derivado e analytics-ready trail
- Camada: platform + shared foundations + domain-inspection
- Dominio: cross-domain com especializacao inicial em inspection/real-estate
- Area: orchestration, storage, OCR, reconciliation, mobile return ingestion, execution plan, report basis
- Objetivo: evoluir a plataforma para orquestrar enrichment, OCR documental, reconciliacao de fatos, geracao/publicacao de execution hints e recebimento do retorno do App Mobile, preparando base progressiva do report e trilha analytics-ready sem recentralizar a inteligencia no canal mobile
- Arquivos provaveis:
  `docs/02-product/03_INCREMENTO_BACKEND_ORQUESTRACAO_ENRICHMENT_OCR_SMART_APP.md`
  `docs/03-architecture/13_INCREMENTO_BACKEND_ORQUESTRACAO_ENRICHMENT_OCR.md`
  `docs/03-architecture/14_INCREMENTO_STORAGE_RECONCILIATION_AND_ANALYTICS_TRAIL.md`
  `docs/03-architecture/15_INCREMENTO_SMART_APP_AS_DERIVED_EXECUTION_PLAN.md`
  `docs/06-analysis-design/02_INCREMENTO_USE_CASES_BACKEND_ORCHESTRATION.md`
  `docs/06-analysis-design/03_INCREMENTO_CANONICAL_ARTIFACTS_AND_PAYLOADS.md`
  `docs/05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md`
  `apps/backend/*`
  `apps/web-backoffice/*`
  `lib/services/*inspection*`
  `lib/models/*inspection*`
- Dependencias:
  manter Clean Architecture, SOLID, Clean Code e TDD como guardrails obrigatorios
  preservar o case canonico existente
  separar capabilities horizontais de especializacao imobiliaria/NBR
- Testes obrigatorios:
  contract tests dos payloads publicados para mobile e retornados pelo app
  testes de use case do backend/plataforma para enrichment, OCR, reconciliation e execution plan
  testes de integracao da fila de manual resolution
  validacao do storage `raw/normalized/curated`
- Evidencia esperada:
  backend/plataforma como orquestrador documentado e implementavel
  storage preparado para receber input, research, documents, job-config, inspection-return e field-evidence
  smart app documentado como saida derivada
  trilha pronta para analytics futura
- Docs que precisam ser atualizados:
  este backlog
  `docs/05-operations/runbooks/PAINEL_MILESTONES_FLUXO_CONFIGURAVEL_VISTORIA.md`
  docs incrementais criados neste pacote
- Criterio de pronto:
  arquitetura incremental documentada
  milestones M1..Mx publicados
  backlog implementavel por ciclos longos de desenvolvimento

Status: Planejado
### BL-053
Remover modulo desenvolvedor do pacote final (empacotamento enxuto para producao).

Status: Pendente
Prioridade: Alta
Criterio de pronto: build de producao sem telas/servicos/mock dev vinculados, validado por analise de tamanho de APK/AAB e checklist de regressao.

Observacao 2026-03-31: fluxo Git atualizado para impedir push direto na main e exigir homologacao em `release/*`/`homolog/*` com smoke Maestro USB antes de PR.

### BL-036
Adicionar cache de dependÃªncias Flutter/pub ao workflow do GitHub Actions (`android_ci.yml`) usando `actions/cache@v4`, cacheando `.pub-cache` e `.dart_tool` com chave baseada em `pubspec.lock`. Reduz o tempo de execuÃ§Ã£o do job de build (atualmente 8-15 min) eliminando o download repetido de pacotes a cada run.

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      .dart_tool
    key: ${{ runner.os }}-pub-${{ hashFiles('pubspec.lock') }}
```

### BL-013
Realizar auditoria arquitetural e de qualidade de codigo (Clean Code e SOLID), consolidando debitos tecnicos e plano de refatoracao para execucao quando o backlog funcional estiver menor.

### BL-014
Evoluir a suÃ­te de testes do app com prÃ¡tica TDD contÃ­nua, cobrindo regras de negÃ³cio crÃ­ticas, fluxos de fallback/retomada e integraÃ§Ãµes, evitando avanÃ§o funcional sem proteÃ§Ã£o de testes.

Observacao 2026-03-31 (Em andamento): iniciada migracao da automacao E2E para Maestro para reduzir fragilidade operacional de execucao local e estabilizar fluxo critico de login em dispositivo fisico.

### BL-054
Aplicar UX progressiva no Check-in etapa 1 e etapa 2, exibindo somente a prÃ³xima pergunta pendente, mantendo as respostas preenchidas em modo colapsado com resumo na linha e status visual operacional.

Observacao 2026-04-01 (Em andamento): iniciada implementacao de acordeoes por pergunta no check-in para reduzir deslocamento vertical e reforcar percepÃ§Ã£o de seguranca durante o preenchimento.

### BL-055
Aplicar revisÃ£o de taxonomia visual dos menus no fluxo de vistoria, corrigindo o entendimento de nÃ­veis de tÃ­tulo e padronizando comportamento de collapse inicial por seÃ§Ã£o.

Observacao 2026-04-01 (ConcluÃ­do): ajuste aplicado no Menu de Vistoria (NÃ­vel 1 em Title Case; divisÃµes da tela em CAIXA ALTA; subtÃ­tulos em Title Case) e na Etapa 2 com acordeÃµes independentes iniciando recolhidos, mantendo compatibilidade com configuraÃ§Ã£o dinÃ¢mica vinda do sistema web. Cobertura de regressÃ£o atualizada para os novos comportamentos de expansÃ£o.

### BL-056
Adicionar tela especÃ­fica de onboarding para coleta/concessÃ£o de permissÃµes obrigatÃ³rias (Android e iOS), cobrindo tanto o primeiro acesso apÃ³s instalaÃ§Ã£o quanto usuÃ¡rios que entram por login sem ter passado pelo onboarding (ex.: CLTs cadastrados via mÃ³dulo web).

Detalhamento:
1. Listar permissÃµes operacionais obrigatÃ³rias por plataforma (localizaÃ§Ã£o, cÃ¢mera, microfone e notificaÃ§Ãµes quando aplicÃ¡vel).
2. Bloquear acesso ao fluxo principal atÃ© concluir a etapa de permissÃµes mÃ­nimas obrigatÃ³rias.
3. Implementar verificaÃ§Ã£o de estado no login para redirecionar usuÃ¡rios sem onboarding/permissÃµes concluÃ­das para a nova tela.

Observacao 2026-04-10 (CONCLUIDO - Compass Pacote B): regra de roteamento ajustada para nao exibir onboarding de permissoes antes do login. A etapa passa a bloquear somente usuario autenticado/ativo sem permissao concluida, cobrindo o primeiro acesso de usuario provisionado via backoffice.
Observacao 2026-04-10 (CONCLUIDO - Compass Pacote B): adicionada auditoria automatizada entre catalogo de permissoes, `AndroidManifest.xml` e `Info.plist`, protegendo camera, localizacao, microfone e reconhecimento de fala usados pelo onboarding.

### BL-075
Criar arquitetura modular de onboarding white label por marca/produto, substituindo o fluxo unico atual por um `OnboardingFlowResolver` baseado em brand/productMode.

- Fonte funcional: `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Area: mobile / arquitetura white label
- Objetivo: Kaptur e Compass usam apps e jornadas distintas, compartilhando apenas modulos funcionais reutilizaveis.
- Escopo MVP: resolver de fluxo, perfil `marketplace_provider` para Kaptur, perfil `corporate_first_access` para Compass, retomada de etapa pendente e preservacao de usuarios legados.
- Criterio de pronto: app Kaptur nao cai no fluxo Compass; app Compass nao exibe cadastro aberto de vistoriador; modulos compartilhados possuem contrato de entrada/saida.
- Dependencias: BL-031, BL-056, BL-068, INT-031, BOW-212.
- Observacao 2026-04-10 (PARCIAL - Compass): flavor Compass passou a redirecionar `AppAuthStatus.onboarding` para tela dedicada de primeiro acesso e o login passou a expor CTA `Primeiro acesso`, sem reaproveitar o onboarding PJ/Kaptur.

### BL-076
Implementar primeiro acesso Compass para usuario provisionado pelo backoffice, com lookup seguro, OTP e criacao de senha.

- Fonte funcional: `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Area: mobile/auth
- Objetivo: ativar usuario Compass ja cadastrado sem auto-cadastro e sem autenticar apenas por CPF/data de nascimento.
- Fluxo: Gate Compass -> Primeiro acesso -> CPF + data nascimento + identificador adicional -> OTP em contato ja cadastrado -> criar senha -> selfie/complementos minimos -> termos -> permissoes -> Home ou aguardando aprovacao.
- Criterio de pronto: CPF/data nascimento apenas localizam cadastro; OTP e obrigatorio; mensagens nao enumeram usuarios; contato so pode ser alterado pelo backoffice.
- Dependencias: BL-031, INT-031, BOW-212.
- Observacao 2026-04-10 (PARCIAL - baseline local): backend recebeu `/auth/first-access/start` e `/auth/first-access/complete` com OTP temporario, resposta neutra para cadastro inexistente, criacao de senha somente apos OTP e emissao de sessao no fim do fluxo. Mobile Compass recebeu tela dedicada com CPF + data de nascimento + identificador, OTP e criacao de senha. Evidencia local: `flutter test --no-pub test/screens/compass_first_access_screen_test.dart` passou no terminal nativo; backend compilou com `mvn -q -f apps/backend/pom.xml -DskipTests compile` e `AuthIntegrationTest.class` foi gerado apos `test-compile`.

### BL-077
Evoluir cadastro Kaptur marketplace para prestador PF/MEI/PJ com dados fiscais, area de atuacao, equipamentos, dados bancarios/PIX e aprovacao.

- Fonte funcional: `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Area: mobile onboarding
- Objetivo: substituir o cadastro PJ curto atual por jornada de prestador adequada ao app Kaptur.
- Escopo MVP: gate Kaptur com `Criar minha conta de Vistoriador`, identificacao inicial, OTP, tipo de prestador PF/MEI/PJ, termos, permissao e aguardando aprovacao.
- Fase 2: dados fiscais completos, area/disponibilidade, equipamentos, antecedentes, bancarios/PIX com titularidade.
- Criterio de pronto: Kaptur permite novo cadastro; CNPJ deixa de ser obrigatorio para todos; dados bancarios ficam restritos a Kaptur/repasse.
- Dependencias: BL-031, BL-032, BL-033, INT-031, BOW-211.

### BL-078
Evoluir permissoes do sistema para solicitacao progressiva por recurso e por marca.

- Fonte funcional: `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Area: mobile permissoes
- Objetivo: preservar tela explicativa, mas solicitar camera, localizacao, microfone e notificacoes no momento de valor.
- Regra: camera antes de selfie/foto; localizacao antes de check-in/geofence; microfone apenas se voz estiver habilitada; notificacoes em fase posterior.
- Criterio de pronto: negativa simples permite nova tentativa; negativa permanente oferece abrir Ajustes; microfone nao e solicitado para Compass/Kaptur quando voz estiver desabilitada.
- Dependencias: BL-056, BL-075.

### BL-079
Criar modulos reutilizaveis de termos e pocket training por app.

- Fonte funcional: `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Area: mobile/produto
- Objetivo: versionar aceite de LGPD/confidencialidade/conduta e entregar tutorial curto por marca.
- Escopo MVP: termos versionados por app e treinamento curto antes da Home.
- Criterio de pronto: Compass e Kaptur podem ter textos e obrigatoriedade distintos sem fork de tela.
- Dependencias: BL-075, BOW-212.

### BL-017
Adicionar contract tests entre mobile e backend para validar schemas e evitar quebra silenciosa de integraÃ§Ãµes crÃ­ticas.

### BL-018
Aplicar mutation testing em serviÃ§os crÃ­ticos para medir efetividade real da suÃ­te de testes alÃ©m da cobertura tradicional.

### BL-019
Estabelecer quality gates por mÃ³dulo para impedir regressÃ£o de cobertura em serviÃ§os, estados e fluxos principais.

### BL-020
Fortalecer fronteiras arquiteturais com inversÃ£o de dependÃªncia, reduzindo acoplamento entre UI e infraestrutura.

### BL-021
Padronizar tratamento de erros com tipagem e mensagens consistentes para usuÃ¡rio, suporte e observabilidade.

### BL-022
Implantar correlation id por vistoria para rastrear eventos de inÃ­cio, retomada, exportaÃ§Ã£o, sync e falhas.

### BL-023
Endurecer seguranÃ§a operacional do app e pipeline com polÃ­tica de secrets, validaÃ§Ãµes e checklist de release seguro.

Observacao 2026-03-30 (Em andamento): workflows de deploy backend/web ajustados para validar `VPS_HOST`, `VPS_USER` e `VPS_SSH_KEY` antes da etapa SSH, com skip explicito quando os segredos nao estiverem configurados. Em revisao final de compatibilidade no parser do GitHub Actions.

### BL-024
Definir performance budgets por fluxo crÃ­tico e monitorar regressÃµes de tempo no ciclo de entrega.

### BL-025
Criar governanÃ§a contÃ­nua de dependÃªncias, atualizaÃ§Ãµes e vulnerabilidades com critÃ©rios de resposta.

### BL-026
Adotar ADRs para registrar decisÃµes arquiteturais e reduzir retrabalho em mudanÃ§as estruturais.

### BL-027
Padronizar ciclo de vida de feature flags para evitar acÃºmulo de cÃ³digo morto e inconsistÃªncias de comportamento.

### BL-028
ReforÃ§ar Definition of Done com critÃ©rios obrigatÃ³rios de teste, qualidade tÃ©cnica, QA e documentaÃ§Ã£o.

Lista bÃ¡sica operacional (obrigatÃ³ria para todo pacote):
1. Registrar demanda no backlog antes de implementar e manter status atualizado.
2. Ler contexto completo do projeto e limitar mudanÃ§as ao escopo solicitado.
3. NÃ£o remover cÃ³digo/arquivos fora do requisito explÃ­cito.
4. Escrever/atualizar testes para o comportamento alterado (TDD sempre que viÃ¡vel).
5. Executar `flutter analyze` antes de commit/push.
6. Executar `flutter test` antes de commit/push.
7. Validar e incrementar `version` no `pubspec.yaml` antes de merge/push/publicaÃ§Ã£o.
8. Usar mensagem de commit/publicaÃ§Ã£o no padrÃ£o acordado: `[versÃ£o] - [tipo alteraÃ§Ã£o]: [resumo curto em portuguÃªs]`.
9. Atualizar documentaÃ§Ã£o e observaÃ§Ãµes do backlog no fechamento da entrega.

Observacao 2026-03-31: checklist operacional dedicado publicado em `docs/qa/CHECKLIST_OPERACIONAL_PRE_PUSH.md` para padronizar gate de backlog, testes, analyze, versionamento e padrÃ£o de commit antes do push.

### BL-029
Implementar a aba Agenda com visualizaÃ§Ã£o em calendÃ¡rio para o usuÃ¡rio consultar os jobs agendados por dia, semana e mÃªs.

Observacao 2026-03-30 (CONCLUIDO): criada aba Agenda com grade mensal, marcacao de dias com jobs e lista de compromissos por dia selecionado.

### BL-030
Evoluir o sininho de mensagens para central de comunicaÃ§Ã£o backend-app, sempre vinculada a job ou proposta, com push notification mesmo com aplicativo fechado.

Observacao 2026-03-30 (CONCLUIDO): central de mensagens implementada com contador de nao lidas no header, marcacao individual/geral de leitura e alimentacao por mocks do painel dev para simulacao de push/backend.

### BL-031
Introduzir autenticaÃ§Ã£o com tela de login, gerenciamento de sessÃ£o e proteÃ§Ã£o de acesso Ã s Ã¡reas internas do app.

Observacao 2026-03-30 (PARCIAL): fluxo de autenticacao com estado persistido localmente, logout seguro e roteamento condicional para login/onboarding/aguardando aprovacao/home.
Observacao 2026-03-31 (EM ANDAMENTO): reforcada a testabilidade da tela de login para automacao Maestro com identificadores semanticos estaveis em campos e botao de submit.
Observacao 2026-04-02 (REPLANEJADO): validado que o app ainda nao autentica contra backend real; passam a ser obrigatorios neste item o login backend-first, refresh/revogacao de sessao, trilha de auditoria de acesso, controle de tentativas/lockout e readiness para MFA/FIDO2.
Observacao 2026-04-03 (SEQUENCIAMENTO): BL-031 depende dos cards de backend BOW-100 (Tenant+Membership), BOW-101 (User entity retrofit) e BOW-102 (JWT auth backend). NÃ£o iniciar o lado mobile enquanto o backend nÃ£o tiver JWT funcional com GET /auth/me retornando tenant context correto.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): app mobile ganhou cliente backend-first para `POST /auth/login` + `GET /auth/me`, ativado por `--dart-define=APP_API_BASE_URL=...` e `--dart-define=APP_TENANT_ID=tenant-compass`. Quando a API nao esta configurada, o fluxo mock legado permanece como fallback local.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): contexto operacional mobile passou a priorizar a sessao autenticada (`auth_tenant_id`, `auth_user_id`, `auth_access_token`) para chamadas de configuracao dinamica e sincronizacao de vistoria, mantendo overrides/env apenas como fallback tecnico.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): sessao mobile passa a persistir expiracao do access token, executar refresh automatico ao restaurar sessao expirada e revogar refresh token no logout via `/auth/logout` quando backend esta configurado.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): backend passou a validar o bearer token em `GET /api/mobile/jobs` contra `X-Tenant-Id` e `X-Actor-Id`, com teste de integracao Compass cobrindo login real + listagem de jobs e rejeicao de contexto divergente.
Observacao 2026-04-10 (PARCIAL - Compass Pacote B): backend tambem valida o bearer token quando informado em configuracao dinamica e sincronizacao de vistoria, bloqueando tenant/ator divergente antes do processamento operacional.

### BL-032
Criar onboarding de novos usuÃ¡rios para perfis CLT e PJ, com coleta de dados cadastrais completos e captura de foto pelo app.

Observacao 2026-03-30 (CONCLUIDO): onboarding em etapas com selecao CLT/PJ, dados pessoais e bloco bancario para PJ, integrado ao estado de autenticacao.

### BL-033
Adicionar tela de aguardando aprovaÃ§Ã£o de cadastro para usuÃ¡rios onboarded que dependem de liberaÃ§Ã£o do backoffice.

Observacao 2026-03-30 (CONCLUIDO): tela dedicada de aguardando aprovacao adicionada, com acao de verificacao de status e simulacao de aprovacao em ambiente de desenvolvimento.

### BL-057
Refatorar o fluxo de vistoria como alinhamento arquitetural ao V2 da plataforma, removendo a semÃ¢ntica inspection-centric do nÃºcleo do fluxo configurÃ¡vel sem reescrever a navegaÃ§Ã£o atual.

- Camada: domain-inspection
- Dominio: domain-inspection
- Area: fluxo configurÃ¡vel / semÃ¢ntica
- Objetivo: unificar a dimensÃ£o funcional hoje exibida como `Por onde deseja comeÃ§ar?`, `Onde estou?` e `Ãrea da foto` sob uma chave semÃ¢ntica canÃ´nica Ãºnica
- Arquivos provaveis: `lib/screens/checkin_screen.dart`, `lib/screens/overlay_camera_screen.dart`, `lib/screens/inspection_review_screen.dart`, `lib/services/inspection_semantic_field_service.dart`, `lib/config/inspection_menu_package.dart`
- Dependencias: BL-051, BL-052
- Testes obrigatorios:
  - regressÃ£o de label por etapa (check-in, cÃ¢mera, revisÃ£o)
  - regressÃ£o de aliases/payload legado
  - `flutter analyze --no-pub`
- Evidencia esperada: labels diferentes por surface apontando para a mesma semÃ¢ntica canÃ´nica sem duplicaÃ§Ã£o de regra na UI
- Docs que precisam ser atualizados: este backlog, backlog V2 prioritÃ¡rio se houver mudanÃ§a de fronteira, resumo executivo contÃ­nuo
- Criterio de pronto: widgets deixam de decidir semÃ¢ntica funcional por texto exibido; remoto e fallback usam o mesmo shape lÃ³gico

Observacao 2026-04-06 (FECHAMENTO OBRIGATORIO ONDA 3): rodada reaberta para eliminar a Ãºltima inconsistÃªncia pÃºblica entre `InspectionFlowCoordinator` e `OverlayCameraScreen`, removendo contrato fragmentado legado da cÃ¢mera e consolidando labels/surface aliases na mesma chave semÃ¢ntica canÃ´nica.
Observacao 2026-04-12 (ALINHAMENTO CANONICO): o fluxo passa a reconhecer duas estruturas distintas e complementares: `arvore de captura` (check-in etapa 1, cÃ¢mera, revisÃ£o de evidÃªncias) e `matriz normativa/operacional` (check-in etapa 2, pendÃªncias, bloqueio de entrega). `Etapa 1` permanece obrigatÃ³ria para abertura da cÃ¢mera; `Etapa 2` pode ser obrigatÃ³ria para entrega, mas nÃ£o deve bloquear a captura. Documento de referÃªncia: `docs/05-operations/runbooks/MODELO_CANONICO_FLUXO_CONFIGURAVEL_VISTORIA.md`.

Observacao 2026-04-12 (IMPLEMENTACAO PRATICA): revisao, matching operacional e atalhos de pendencia passaram a trafegar por `subjectContext`, `targetItem` e `targetQualifier`, fechando o milestone `M3` no runtime. Painel operacional: `docs/05-operations/runbooks/PAINEL_MILESTONES_FLUXO_CONFIGURAVEL_VISTORIA.md`.

### BL-058
Separar explicitamente o estado inicial sugerido, o estado atual da captura e o Ãºltimo estado utilizado para retomada, mantendo compatibilidade com o payload de recovery existente.

- Camada: domain-inspection
- Dominio: domain-inspection
- Area: estado / recovery
- Objetivo: impedir que o contexto inicial vindo do check-in continue funcionando como trava operacional da cÃ¢mera
- Arquivos provaveis: `lib/screens/overlay_camera_screen.dart`, `lib/screens/inspection_review_screen.dart`, `lib/services/inspection_flow_coordinator.dart`, `lib/state/app_state.dart`
- Dependencias: BL-057
- Testes obrigatorios:
  - abrir cÃ¢mera com sugestÃ£o inicial
  - trocar contexto atual
  - voltar da revisÃ£o reabrindo no Ãºltimo contexto real
  - compatibilidade de recovery antigo e novo
  - `flutter analyze --no-pub`
- Evidencia esperada: retomada priorizando o Ãºltimo contexto real, com bootstrap e recovery claramente separados
- Docs que precisam ser atualizados: este backlog e resumo executivo contÃ­nuo
- Criterio de pronto: bootstrap, operaÃ§Ã£o corrente e retomada passam a existir como estados distintos fora da UI; payload novo Ã© aditivo e o legado continua suportado

Observacao 2026-04-06 (FECHAMENTO OBRIGATORIO ONDA 3): revisÃ£o reaberta para retirar montagem manual de `resumeContext` e serializaÃ§Ã£o manual de `cameraContext`, centralizando leitura/escrita no adapter de recovery sem quebrar payload legado.

Observacao 2026-04-12 (IMPLEMENTACAO PRATICA): cobertura automatizada valida bootstrap do `step1`, abertura da camera com `step2` obrigatoria apenas para entrega e bloqueio de finalizacao na revisao enquanto a pendencia normativa continuar aberta. Runbook de fechamento: `docs/05-operations/runbooks/VALIDACAO_FINAL_FLUXO_CONFIGURAVEL_VISTORIA.md`.

### BL-059
Consolidar a duplicaÃ§Ã£o de ambiente repetido como aÃ§Ã£o contextual do nÃ­vel atual, fora da Ã¡rvore principal, preservando o comportamento operacional `Trocar` e `Novo <ambiente>`.

- Camada: domain-inspection
- Dominio: domain-inspection
- Area: UX operacional da cÃ¢mera
- Objetivo: suportar `Quarto 2`, `Sala 2` e equivalentes sem criar submenu e sem quebrar revisÃ£o/retomada
- Arquivos provaveis: `lib/screens/overlay_camera_screen.dart`, `lib/screens/inspection_review_screen.dart`, `lib/services/inspection_environment_instance_service.dart`
- Dependencias: BL-057, BL-058
- Testes obrigatorios:
  - `Novo Quarto` cria `Quarto 2`
  - revisÃ£o mantÃ©m a instÃ¢ncia operacional
  - obrigatoriedade configurada para `Quarto` continua satisfeita por `Quarto 2`
  - `flutter analyze --no-pub`
- Evidencia esperada: aÃ§Ã£o contextual fora da Ã¡rvore principal com estado operacional preservado ponta a ponta
- Docs que precisam ser atualizados: este backlog e resumo executivo contÃ­nuo
- Criterio de pronto: instÃ¢ncia operacional de ambiente fica estÃ¡vel no fluxo principal sem aumento de profundidade da navegaÃ§Ã£o

Observacao 2026-04-06 (FECHAMENTO OBRIGATORIO ONDA 3): a rodada de fechamento mantÃ©m `Novo Quarto`/`Quarto 2` como aÃ§Ã£o contextual fora da Ã¡rvore principal, com persistÃªncia e retomada validadas a partir do estado canÃ´nico.

### BL-060
Quebrar incrementalmente o service concentrador de configuraÃ§Ã£o/menus em fatias coesas e compatÃ­veis com a arquitetura V2, sem mudanÃ§a abrupta de contrato externo.

- Camada: shared-foundation
- Dominio: cross-domain
- Area: config runtime / fallback / histÃ³rico
- Objetivo: separar carregamento de documento, merge, fallback, histÃ³rico de uso e prediction em responsabilidades independentes
- Arquivos provaveis: `lib/services/inspection_menu_service.dart`, `lib/config/inspection_menu_package.dart`, novos services/adapters seguindo o padrÃ£o real do projeto
- Dependencias: BL-057
- Testes obrigatorios:
  - regressÃ£o de load do asset
  - regressÃ£o de merge de override/mock
  - regressÃ£o de fallback offline
  - regressÃ£o de prediction/sugestÃ£o
  - `flutter analyze --no-pub`
- Evidencia esperada: responsabilidades hoje concentradas em `inspection_menu_service.dart` migradas por fatias, mantendo uma faÃ§ade compatÃ­vel durante a transiÃ§Ã£o
- Docs que precisam ser atualizados: este backlog e liÃ§Ãµes aprendidas quando a primeira fatia entrar
- Criterio de pronto: o service atual deixa de ser dono simultÃ¢neo de loader + merge + fallback + history + prediction; a migraÃ§Ã£o permanece invisÃ­vel para a UI no primeiro estÃ¡gio

Observacao 2026-04-06 (FECHAMENTO OBRIGATORIO ONDA 3): esta rodada nÃ£o amplia escopo do service deus; apenas fecha a fronteira residual de recovery/semÃ¢ntica entre coordinator, cÃ¢mera e revisÃ£o para concluir a migraÃ§Ã£o canÃ´nica jÃ¡ iniciada.

### BL-061
Isolar a especializaÃ§Ã£o do domÃ­nio inspection sobre um core reutilizÃ¡vel de fluxo configurÃ¡vel, preservando taxonomia imobiliÃ¡ria no domÃ­nio sem contaminar a semÃ¢ntica global da plataforma.

- Camada: domain-inspection
- Dominio: domain-inspection
- Area: adapter de domÃ­nio / taxonomia
- Objetivo: manter `tipoImovel`, `subtipo`, `ambiente`, `elemento`, `material` e `estado` como especializaÃ§Ã£o do domÃ­nio inspection, desacoplados do core
- Arquivos provaveis: `lib/screens/checkin_screen.dart`, `lib/screens/overlay_camera_screen.dart`, `lib/screens/inspection_review_screen.dart`, `lib/config/inspection_menu_package.dart`, novos adapters/taxonomy services conforme padrÃ£o do projeto
- Dependencias: BL-057, BL-060
- Testes obrigatorios:
  - regressÃ£o de traduÃ§Ã£o semÃ¢ntica -> vocabulÃ¡rio inspection
  - regressÃ£o de labels por surface
  - regressÃ£o de taxonomia na revisÃ£o e na cÃ¢mera
  - `flutter analyze --no-pub`
- Evidencia esperada: inspection permanece funcional como domain pack, mas o core reutilizÃ¡vel deixa de depender do vocabulÃ¡rio imobiliÃ¡rio
- Docs que precisam ser atualizados: este backlog, backlog V2 prioritÃ¡rio se houver ajuste de fronteira, resumo executivo contÃ­nuo
- Criterio de pronto: vocabulÃ¡rio imobiliÃ¡rio permanece no domain layer e nÃ£o exige rename global para neutralizar o core

Observacao 2026-04-06 (FECHAMENTO OBRIGATORIO ONDA 3): o fechamento desta etapa exige que a cÃ¢mera continue aceitando labels por surface e aliases legados apenas via camada semÃ¢ntica/adapters, sem regra crÃ­tica hardcoded na UI.

### BL-034
Disponibilizar atualizaÃ§Ã£o cadastral no menu de configuraÃ§Ãµes, mantendo consistÃªncia com os campos definidos no onboarding.

Observacao 2026-03-30 (CONCLUIDO): configuracoes agora possuem entrada de atualizacao cadastral com persistencia de nome/documento e sincronizacao com dados exibidos no app.

### BL-035
Exibir foto do usuÃ¡rio na Home e permitir atualizaÃ§Ã£o por cÃ¢mera, sem upload da galeria, preparando base para validaÃ§Ã£o facial futura.

Observacao 2026-03-30 (CONCLUIDO): foto de usuario exibida no header da Home, com atualizacao por captura de camera nas configuracoes e persistencia local da referencia da imagem.

### BL-040
Corrigir divergÃªncia entre Checkin Etapa 2 e RevisÃ£o para o item obrigatÃ³rio "Entorno", eliminando falso verde no checkin e bloqueio ao usar "Ir para pendÃªncia".

Observacao 2026-03-30 (CONCLUIDO): campo obrigatÃ³rio "Entorno" adicionado ao Checkin Etapa 2 (urbano) e refletido na revisÃ£o/pÃªndencias. Atalhos "Ir para pendÃªncia" agora expandem a seÃ§Ã£o de destino antes do scroll para evitar travamento de fluxo.

### BL-041
Reorganizar o bloco de revisÃ£o de fotos para a Ã¡rea inferior com agrupamento "RevisÃ£o de Fotos ObrigatÃ³rias", contendo dois acordeÃµes independentes: "Fotos ObrigatÃ³rias" e "Fotos Capturadas".

Observacao 2026-03-30 (CONCLUIDO): bloco inferior foi remodelado com dois acordeÃµes independentes e status visual OK/NOK para cada grupo.

### BL-042
No card de Novas Propostas, exibir ID do JOB e implementar simulaÃ§Ã£o do aceite por deslize, movendo o item aceito para "Meus Jobs Agendados" no mock.

**Implementado:** `ProposalsSection` convertido para `StatefulWidget` gerenciando lista local. ID exibido como `_InfoTag`. Swipe usa `confirmDismiss â†’ true` + `onDismissed` para animaÃ§Ã£o limpa. Aceite converte `ProposalOffer` em `Job` e adiciona em `AppState.jobs` via Provider. SnackBar de confirmaÃ§Ã£o exibido. Testes: 2/2 âœ…

### BL-043
Remover o componente de comandos rÃ¡pidos por voz da cÃ¢mera por comprometer a Ã¡rea Ãºtil de captura e classificaÃ§Ã£o.

### BL-044
Adicionar controle lateral para ocultar/mostrar menus dinÃ¢micos na cÃ¢mera, com comportamento padrÃ£o inicial expandido.

### BL-045
Transferir a funcionalidade de exportaÃ§Ã£o da vistoria do menu ConfiguraÃ§Ãµes para o Hub Operacional.

**Implementado:** Bloco "ExportaÃ§Ã£o da vistoria" removido de `settings_screen.dart` (incluindo state fields `_exportFolderController`, `_exportMode`, `_loadingExportSettings`, `_usingExternalExportBase`, mÃ©todos `_loadExportSettings`, lÃ³gica de export em `_saveSettings` e UI do Divider ao botÃ£o). `_ExportSettingsCard` (StatefulWidget com estado prÃ³prio) adicionado ao `operational_hub_screen.dart`. 110/110 testes âœ…

### BL-046
Corrigir o fluxo de "Sair da conta" em ConfiguraÃ§Ãµes para funcionar em mock e retornar para a tela inicial de login.

Observacao 2026-03-30 (CONCLUIDO): logout em ConfiguraÃ§Ãµes limpa sessÃ£o mock completa (email/perfil/documentos), retorna para a raiz e exibe Login de forma consistente.

### BL-047
Simplificar onboarding do app para perfil PJ (sem seletor CLT/PJ) e aplicar validaÃ§Ãµes de CNPJ, AgÃªncia, Conta e Banco.

Observacao 2026-03-30 (CONCLUIDO): onboarding passou a iniciar direto no fluxo PJ (2 etapas), removendo seletor CLT/PJ e validando CNPJ (14 dÃ­gitos + DV), banco, agÃªncia e conta.

### BL-048
Adicionar no Hub Operacional uma aÃ§Ã£o de reset do mock de onboarding para permitir retestes completos do fluxo.

Observacao 2026-03-30 (CONCLUIDO): Hub Operacional recebeu aÃ§Ã£o "Resetar mock de onboarding", retornando o usuÃ¡rio ao estado de cadastro sem reinstalar o app.

### BL-049
Consolidar o GitHub Project como fonte principal do backlog, garantindo sincronizaÃ§Ã£o integral dos itens BL e status com rastreabilidade.

Observacao 2026-04-01 (Em andamento): criado o resumo executivo continuo de implantacao (`docs/05-operations/release-governance/RESUMO_EXECUTIVO_CONTINUO.md`) com snapshot de branches, versao, gates de promocao e estado homolog -> main para reduzir perda de contexto entre sessoes e suportar decisao de merge com rastreabilidade.

Observacao 2026-04-01 (Em andamento): formalizado procedimento de excecao para mantenedor unico na promocao homolog -> main (ajuste temporario de aprovacao minima da branch protegida para 0, merge da PR e restore imediato para 1), com registro obrigatorio de evidencias.

Observacao 2026-04-01 (Despriorizado): configuracao de notificacao por e-mail para aprovacao de PR no celular movida para segundo plano do backlog operacional, pois o fluxo atual usa aprovacao/merge por CLI quando necessario.

Observacao 2026-04-01 (Em acompanhamento): divergencia de notificacao por e-mail entre ambientes - homolog envia e-mail de distribuicao, enquanto distribuicoes originadas de `main`/producao nao confirmaram recebimento nesta sessao.

Observacao 2026-04-02 (CONCLUIDO): ciclo de promocao homolog -> main finalizado por PR com excecao controlada de aprovacao minima e restauracao imediata da protecao (1 aprovacao), workflows chave em verde e equalizacao de ambientes concluida com `origin/main` e `origin/homolog` em 0/0 de divergencia.

### BL-050
Corrigir a Ã¡rea de aÃ§Ã£o final do onboarding para evitar que o botÃ£o "Concluir" fique encoberto pela barra de navegaÃ§Ã£o do Android, garantindo conclusÃ£o do fluxo com usabilidade consistente.

Observacao 2026-03-30 (ConcluÃ­do): botÃ£o movido do `body` (Column) para `Scaffold.bottomNavigationBar` com `SafeArea(top: false, minimum: EdgeInsets.fromLTRB(20, 8, 20, 20))` e altura fixa de 54dp via `SizedBox`. O `Scaffold` gerencia corretamente o inset do rodapÃ© do Android independente de modo de gestos ou botÃµes de navegaÃ§Ã£o. 3 testes passando.

### BL-051
Unificar a persistÃªncia e o consumo das regras dinÃ¢micas de obrigatoriedade entre Checkin Etapa 1/2, CÃ¢mera, RevisÃ£o e Menu de Vistoria, preparando o app para receber parÃ¢metros normativos do mÃ³dulo web (incluindo mÃ­nimo/mÃ¡ximo de fotos).

Observacao 2026-03-30 (Em andamento): refatoraÃ§Ã£o big-bang aplicada no fluxo mobile para consumir `step2Config` dinÃ¢mica de forma consistente em RevisÃ£o, CÃ¢mera em lote e Menu de Vistoria; export final da revisÃ£o passou a usar a lista de capturas atualizada em memÃ³ria (incluindo capturas adicionadas na prÃ³pria revisÃ£o); contrato dinÃ¢mico da etapa 2 recebeu suporte a `minFotos` e `maxFotos`, com validaÃ§Ã£o de limite mÃ¡ximo na Etapa 2 e sinalizaÃ§Ã£o operacional na RevisÃ£o.

Observacao 2026-03-30 (Em andamento): corrigida a persistencia do snapshot dinamico da Etapa 2 no draft de recuperacao para evitar perda de `step2Config` ao avancar/retomar o fluxo. Menu de Vistoria, Revisao, Camera e auditoria de fallback passaram a resolver a mesma configuracao persistida por um unico caminho no servico dinamico, reduzindo divergencia de indicador e obrigatorios entre telas.

Observacao 2026-03-30 (Concluido): reforcado o caminho de persistencia do indicador em retomadas com payload parcial/corrompido da Etapa 2, substituindo parse direto por restauracao resiliente (`restoreStep2Model`) em Home/Revisao e adicionando regressao para manter sinalizacao de obrigatorios pendentes sem quebra de tela.

Observacao 2026-04-10 (PARCIAL - Compass Pacote C): smoke E2E de homolog valida que a politica dinamica de fotos Compass (`min=2`, `max=8`) publicada no pacote operacional e consumida pelo mobile antes da vistoria finalizada, reduzindo risco de divergencia entre configuracao, captura e payload enviado.

### BL-052
Unificar no Hub Operacional um pacote Ãºnico de parametrizaÃ§Ã£o para o modo desenvolvedor, deixando explÃ­cito o que pertence ao Check-in e o que pertence Ã  CÃ¢mera, com organizaÃ§Ã£o por nÃ­veis configurÃ¡veis.

Observacao 2026-03-30 (Em andamento): o documento JSON local do modo desenvolvedor passou a servir como fonte unificada para `step1`, `step2` e `camera`, eliminando a separaÃ§Ã£o entre contrato de check-in e pacote isolado da cÃ¢mera. A cÃ¢mera agora pode consumir tambÃ©m nÃ­veis dinÃ¢micos de `material` e `estado` por tipo de imÃ³vel no mesmo documento salvo pelo HUB operacional. PrÃ³ximo passo: evoluir o editor visual do HUB para manipular nÃ­veis sem ediÃ§Ã£o manual de JSON.

Observacao 2026-03-30 (Em andamento): o app passou a ter tambem unificacao no codigo de leitura do documento, com um pacote unico de configuracao compartilhado entre Check-in Etapa 1, Etapa 2 e Camera, reduzindo duplicacao de parser e abrindo caminho para evolucao por niveis e por subtipo sem contratos paralelos.

Observacao 2026-03-30 (Em andamento): o pacote unificado passou a suportar niveis explicitos com resolucao por subtipo em `step1` e `camera` (`levels` e `levelsBySubtipo`), incluindo dependencia entre niveis (`dependsOn`) e fallback para niveis base quando nao houver override do subtipo.

Observacao 2026-03-30 (Em andamento): Check-in Etapa 1 passou a renderizar niveis dinamicos em runtime a partir do pacote unificado (com selecao por chips, dependencia entre niveis e persistencia em `step1.niveis`), mantendo compatibilidade com `porOndeComecar` para o fluxo atual de abertura da camera.

Observacao 2026-03-30 (Em andamento): definido checklist de validacao go/no-go para implantacao do pacote dinamico, cobrindo estrutura de niveis, dominio da informacao, regra normativa da Etapa 2, integracao entre telas e mock unificado do Hub Operacional (`docs/qa/CHECKLIST_GO_NO_GO_PACOTE_DINAMICO.md`).

Observacao 2026-03-30 (Em andamento): cobertura de regressao da BL-052 foi ampliada no servico de menus para camera com cenarios de fallback por subtipo nao configurado, fallback padrao sem niveis e saneamento de IDs invalidos de niveis, reduzindo risco de divergencia de ordem/visibilidade em runtime.

Observacao 2026-03-30 (Em andamento): adicionados testes de widget da camera para validar ordem e visibilidade dinamica dos seletores por nivel/subtipo (`test/screens/overlay_camera_screen_test.dart`), com modo deterministico de dados de teste na tela para evitar dependencia de inicializacao de hardware/servicos no ambiente de teste.

Observacao 2026-04-10 (PARCIAL - Compass Pacote C): smoke E2E de homolog cobre o pacote unificado Compass saindo do backoffice e governando o fluxo mobile ate sync, valuation, report e control tower, mantendo a regra operacional por tenant como fonte unica do percurso.

Observacao 2026-04-12 (IMPLEMENTACAO PRATICA): o pacote unificado ja cobre `step1`, `step2` e `camera` no web guiado, com contrato dinamico persistido no backend e consumido pelo mobile. A regra funcional vigente fica assim: `step1` governa bootstrap da captura; `step2` governa exigencias normativas e bloqueio de entrega; `camera` segue arvore de captura. Artefatos de apoio: `docs/05-operations/runbooks/MODELO_CANONICO_FLUXO_CONFIGURAVEL_VISTORIA.md`, `docs/05-operations/runbooks/PAINEL_MILESTONES_FLUXO_CONFIGURAVEL_VISTORIA.md` e `docs/05-operations/runbooks/VALIDACAO_FINAL_FLUXO_CONFIGURAVEL_VISTORIA.md`.

---

## Lista de evoluÃ§Ã£o de testes (dÃ©bito tÃ©cnico)

1. BT-TEST-001 [Em progresso]: mapear cobertura atual por mÃ³dulo (state, services, screens) e identificar lacunas.
2. BT-TEST-002 [ConcluÃ­do]: criar testes de unidade para `checkin_dynamic_config_service.dart` (parse, fallback, cache).
3. BT-TEST-003 [ConcluÃ­do]: criar testes de unidade para `inspection_sync_service.dart` e `inspection_sync_queue_service.dart` (sucesso, falha, retry).
4. BT-TEST-004: criar testes da auditoria de fallback (`inspection_fallback_audit_service.dart`) para cenÃ¡rios saudÃ¡vel, alerta e falha.
5. BT-TEST-005: criar testes de widget para aba Vistorias e detalhe read-only (`completed_inspections_screen.dart` e `completed_inspection_detail_screen.dart`).
6. BT-TEST-006: adicionar regra de PR/CI para exigir alteraÃ§Ã£o de teste quando houver alteraÃ§Ã£o funcional.
7. BT-TEST-007: registrar baseline de cobertura e meta incremental por sprint.

---

## ðŸš€ Itens CrÃ­ticos para ComeÃ§ar Agora

### BL-012: Menus de Checkin DinÃ¢micos (Prioridade #1)
**Por que agora?** ValidaÃ§Ã£o NBR Ã© bloqueadora e estÃ¡ hardcoded. Sem dinÃ¢mica, cada ajuste de obrigatoriedade precisa deploy.

**DependÃªncias:** 
- Contrato de API definido

**Exemplo de impacto:** Se o cliente quiser remover "Micro Detalhes" como obrigatÃ³rio, hoje Ã© deploy. AmanhÃ£ serÃ¡ 1 API call.

---

### BL-001: IntegraÃ§Ã£o API Real (Prioridade #2)
**Por que apÃ³s BL-012?** Precisa saber qual Ã© a estrutura de "checkinSessions" (BL-012) que serÃ¡ enviada no JSON final.

**DependÃªncias:**
- BL-012 estar estÃ¡vel (estrutura de sessÃµes conhecida)
- Endpoint da API web definido

**Fluxo:** Job finalizado â†’ Valida BL-012 (obrigatÃ³rios) â†’ Envia JSON via BL-001

---

## Observacao sobre Flavors (BL-011)
No momento, a estrategia aprovada e manter build unico para reduzir complexidade enquanto o app ainda nao esta em producao.

Quando revisitar BL-011:
1. A ate 2 sprints do go-live.
2. Quando houver necessidade real de distribuicao paralela (cliente final x equipe interna).
3. Quando requisitos de seguranca/compliance exigirem separacao formal de pacote.

---

## Detalhamento BL-012: Menus de Checkin Dinamicos

### Contexto
Atualmente, os menus de checkin etapa 1 e 2 estÃ£o hardcoded em `lib/config/checkin_step2_config.dart`. Cada sessÃ£o de captura (ex: fachada, ambiente, elemento inicial) possui:
- TÃ­tulo
- Ãcone
- Requisitos de captura (Macro Local, Ambiente, Elemento)
- Flag `obrigatorio` (booleano)

Estes requisitos sÃ£o baseados em padrÃµes NBR e validados durante o checkout/revisÃ£o final de uma vistoria.

### Requisito
Permitir configuraÃ§Ã£o dinÃ¢mica via backend para:
1. Adicionar/remover sessÃµes de captura
2. Alterar obrigatoriedade (obrigatorio vs desejÃ¡vel) sem deploy
3. Adaptar para diferentes tipos de imÃ³vel ou contextos

### Estrutura Proposta
```json
{
  "checkinSessions": [
    {
      "id": "fachada",
      "titulo": "Fachada",
      "icon": "building",
      "obrigatorio": true,
      "cameraMacroLocal": true,
      "cameraAmbiente": true,
      "cameraElementoInicial": true,
      "descricao": "Captura obrigatÃ³ria NBR 16500"
    },
    {
      "id": "ambiente",
      "titulo": "Ambiente Interno",
      "icon": "door",
      "obrigatorio": false,
      "cameraMacroLocal": true,
      "cameraAmbiente": true,
      "cameraElementoInicial": false,
      "descricao": "SessÃ£o desejÃ¡vel para contexto"
    }
  ]
}
```

### ValidaÃ§Ã£o na RevisÃ£o
O campo `obrigatorio` Ã© crÃ­tico pois bloqueia finalizaÃ§Ã£o se nÃ£o atendido (CheckinReviewScreen valida).

---

## Dependencias Tecnicas
1. Definicao do contrato da API web para recebimento do JSON de vistoria.
2. Definicao de politica de autenticacao para integracao mobile -> web.
3. Decisao sobre destino dos arquivos locais (apenas cache local ou sincronizacao obrigatoria).
4. **Define contrato de API para checkin sessions configurÃ¡vel (BL-012)**.
5. **Cache local de sessÃµes com fallback para config hardcoded se offline (BL-012)**.
6. **Definir polÃ­tica de destino de exportacao JSON (BL-016) sem comprometer sync offline e limpeza (BL-005)**.
7. **Definir contrato de agenda de jobs por usuÃ¡rio (BL-029) com data/hora/status e paginaÃ§Ã£o**.
8. **Definir contrato de mensagens vinculadas a job/proposta e eventos de push (BL-030)**.
9. **Definir provedor de push notification e estratÃ©gia de token/device registration (BL-030)**.
10. **Definir polÃ­tica de autenticaÃ§Ã£o (login, refresh token, expiraÃ§Ã£o e logout) para mobile (BL-031)**.
11. **Definir fluxos e validaÃ§Ãµes de onboarding CLT/PJ no backend e no app (BL-032/BL-033/BL-034)**.
12. **Definir diretriz de captura de foto via cÃ¢mera e regras anti-galeria para onboarding/perfil (BL-032/BL-035)**.

---

## ðŸ“ Notas para Colaboradores

Ao pegar um item para implementar:
1. âœ… Verifique se as dependÃªncias jÃ¡ foram satisfeitas
2. âœ… Atualize o status de `Pendente` para `Em Progresso`
3. âœ… Crie branch com padrÃ£o: `feature/BL-XXX-descricao-curto`
4. âœ… Commit com prefixo: `feat/BL-XXX: descriÃ§Ã£o`
5. âœ… Aplicar TDD no ciclo: escrever/ajustar teste, implementar, validar `flutter analyze` e `flutter test`
6. âœ… Atualize este arquivo ao terminar (marque como `ConcluÃ­do`)

## ADENDO 2026-04-04 - Priorizacao Mobile

- Trilhas criticas mantidas: BL-012, BL-001, BL-051, BL-052 e BL-054.
- BL-031 segue em andamento com dependencia de consolidacao backend-first.
- BL-056 concluida no Pacote B Compass para roteamento pos-login e tela dedicada de permissoes.
- Backlog complementar front/web: `docs/05-operations/tactical-backlogs/BACKLOG_FRONT_WEB.md`.




## ADENDO 2026-04-05 - Checkpoints de esteira e versionamento
- Pacote tecnico de alinhamento CI/CD publicado na branch `release/v1.2.28+48` com versao `1.2.28+48`.
- Ajustes de esteira aplicados: `backend_ci.yml` (gate OpenAPI resiliente) e `internal_docs_ci.yml` (portal interno ativo em `docs/internal-portal`).
- Procedimento operacional reforcado no AGENT_OPERATING_SYSTEM: execucao serial de comandos pesados, timeout explicito e registro de evidencia quando validacao ocorrer em terminal nativo.
- Backlog relacionado: BL-036 (eficiencia de pipeline) e trilha INT-016/INT-025 (contracts and CI gates).

## ADENDO 2026-04-06 - Refatoracao V2 do fluxo configuravel de inspection

- Esta frente deixa de ser tratada como melhoria isolada de tela e passa a ser rastreada como refatoracao de alinhamento arquitetural ao V2 da plataforma.
- Restricao de desenho obrigatoria:
  - Platform Core agnostico a dominio;
  - Shared Foundations neutras e reutilizaveis;
  - inspection como domain pack, sem definir a semantica global da plataforma.
- Decisao de implantacao:
  - nao fazer rename cego no projeto inteiro;
  - nao reescrever toda a navegacao;
  - executar por fatias/PRs incrementais, preservando o fluxo atual;
  - tratar fallback como obrigatorio, mas no mesmo shape logico do remoto.
- Fatias recomendadas:
  1. semantica canonica + labels por surface + compatibilidade com payload/JSON atual;
  2. estado inicial/atual/retomada + recovery aditivo;
  3. acoes contextuais e instancias operacionais de ambiente;
  4. quebra incremental do service concentrador de configuracao;
  5. limpeza final de hardcodes na UI e consolidacao do adapter de dominio inspection.
- Gates minimos por fatia:
  - regressao da etapa afetada (check-in, camera, revisao ou retomada);
  - compatibilidade com payloads/JSON existentes;
  - `flutter analyze --no-pub`;
  - documentacao do checkpoint no resumo executivo continuo.
