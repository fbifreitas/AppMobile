# DOCUMENTATION INDEX

## Purpose

Esta documentação descreve a V2 do repositório, agora orientado a uma plataforma multi-domínio, multi-tenant e white-label.

## Reading order

1. `00-overview/02_DIRECTION_CHANGE_NOTICE.md`
2. `01-executive/01_CORPORATE_POSITIONING.md`
3. `01-executive/03_EXEC_SUMMARY_WAVES_MVP.md`
4. `03-architecture/01_CORPORATE_BLUEPRINT.md`
5. `03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
6. `03-architecture/03_DOMAIN_PACK_INSPECTION.md`
7. `03-architecture/04_DOMAIN_PACK_WELLNESS.md`
8. `03-architecture/05_DOMAIN_PACK_CHURCH.md`
9. `03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
10. `03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
11. `04-engineering/03_SHORT_PATH_TRANSITION_PLAN.md`
12. `05-operations/01_OPERATING_MODEL.md`
13. `05-operations/AGENT_OPERATING_SYSTEM.md`
14. `05-operations/SOURCE_OF_TRUTH_MATRIX.md`
15. `05-operations/TASK_BRIEF_TEMPLATE.md`
16. `05-operations/DONE_CHECKLIST_BY_WORK_TYPE.md`
17. `05-operations/WHEN_TO_STOP_AND_ASK.md`
18. `99-legacy/LEGACY_MIGRATION_MAP.md`

## Core ideas

- o repositório não representa mais apenas um produto vertical de vistoria
- inspection continua como domínio estratégico e primeiro domain pack
- wellness e church passam a ser domínios de primeira classe
- o Platform Core deve permanecer agnóstico a domínio
- Shared Foundations concentram capacidades compartilháveis de negócio
- white-label e tenant são capacidades estruturais, não detalhes de interface

## Active sections

- `00-overview`: visão geral e mudança de direção
- `01-executive`: posicionamento corporativo
- `02-product`: portfólio e roadmap
- `03-architecture`: blueprint corporativo e domínios
- `04-engineering`: guardrails, estrutura-alvo, plano de transição e brand setup
  - `BRAND_SETUP_AND_RELEASE_FLOW.md` — arquitetura multi-brand, flavors, scripts, limites de override
  - `iOS_FLAVOR_SETUP_GUIDE.md` — setup iOS por marca
- `05-operations`: operação corrente ativa (runbooks, setup, onboarding, governança de backlog e backlogs táticos)
- `06-analysis-design`: decisões arquiteturais (log ativo em `01_DECISION_LOG.md`)
- `07-diagrams`: índice de diagramas e imagens
- `99-legacy`: mapa de documentos legados e arquivos históricos

## Daily usage shortcut

- Comecar por `05-operations/AGENT_OPERATING_SYSTEM.md` para decidir fluxo de execucao.
- Usar `05-operations/SOURCE_OF_TRUTH_MATRIX.md` para resolver fonte oficial por tema.
- Fechar tarefa com `05-operations/DONE_CHECKLIST_BY_WORK_TYPE.md`.
