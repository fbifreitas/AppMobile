# SOURCE OF TRUTH MATRIX

## Objetivo

Definir tema -> documento oficial para reduzir ambiguidade de execucao.

## Matriz

- Direcao corporativa multi-brand: README.md
- Guardrails do agente: GEMINI.md e .github/copilot-instructions.md
- Visao geral e ordem de leitura: docs/00-overview/00_INDEX_GERAL.md
- Arquitetura corporativa: docs/03-architecture/01_CORPORATE_BLUEPRINT.md
- Core e foundations: docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md
- Canonic model corporativo: docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md
- Ecossistema de plataforma e tenant transversal: docs/03-architecture/10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md
- Fronteiras entre plataforma, canais e capabilities: docs/03-architecture/11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md
- Maturidade real da V3: docs/03-architecture/12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md
- Canal mobile white-label, branding e distribuicao: docs/03-architecture/08_BRAND_AND_DISTRIBUTION_MODEL.md
- Onboarding white-label mobile: docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md
- Domain inspection: docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md
- Domain wellness: docs/03-architecture/04_DOMAIN_PACK_WELLNESS.md
- Domain church: docs/03-architecture/05_DOMAIN_PACK_CHURCH.md
- Guardrails de engenharia: docs/04-engineering/01_ENGINEERING_GUARDRAILS.md
- Backlog estrategico: docs/BACKLOG_V2_PRIORIDADES.md
- Operacao ativa (entrada): docs/05-operations/01_OPERATING_MODEL.md
- Setup local web: docs/05-operations/local-setup/SETUP_LOCAL_WEB.md
- Troubleshooting/restauracao: docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md
- Backlog tatico web: docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md
- Backlog tatico mobile/operacao: docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md
- Backlog tatico integracao: docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md
- Backlog tatico front/web: docs/05-operations/tactical-backlogs/BACKLOG_FRONT_WEB.md
- Release/promocao: docs/05-operations/release-governance/RESUMO_EXECUTIVO_CONTINUO.md
- Onboarding do agente: docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md
- Mapa de legado: docs/99-legacy/LEGACY_MIGRATION_MAP.md
- Snapshot historico: docs/legacy/legacy-import/

## Regra De Precedencia

Se houver conflito:
1. `01_CORPORATE_BLUEPRINT.md` e `07_CORPORATE_CANONICAL_MODEL.md` mandam sobre a visao de plataforma.
2. `10`, `11` e `12` mandam sobre tenant transversal, fronteiras e maturidade da V3.
3. `08` manda apenas sobre o canal mobile white-label.
4. `09` manda sobre onboarding white-label mobile.

## Regra De Legado

O antigo `06_TENANT_AND_WHITE_LABEL_MODEL.md` nao deve mais ser usado como fonte ativa.
Quando aparecer em material historico, deve ser tratado como referencia de transicao/legado.
