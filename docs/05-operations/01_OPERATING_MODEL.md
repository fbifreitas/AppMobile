# OPERATING MODEL

## O que e operacao ativa

Operacao ativa e a camada documental usada no trabalho diario de execucao.
Ela organiza setup, runbooks, backlog tatico, governanca operacional e autonomia do agente.

## Operational documentation index

Esta pasta concentra documentacao operacional corrente ativa.

1. Runbooks: `docs/05-operations/runbooks/`
2. Setup local: `docs/05-operations/local-setup/`
3. Backlogs taticos: `docs/05-operations/tactical-backlogs/`
4. Governanca backlog/board: `docs/05-operations/backlog-governance/`
5. Onboarding de agentes: `docs/05-operations/agent-onboarding/`
6. Governanca de release: `docs/05-operations/release-governance/`
7. Sistema operacional do agente:
    - `docs/05-operations/AGENT_OPERATING_SYSTEM.md`
    - `docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md`
    - `docs/05-operations/TASK_BRIEF_TEMPLATE.md`
    - `docs/05-operations/DONE_CHECKLIST_BY_WORK_TYPE.md`
    - `docs/05-operations/WHEN_TO_STOP_AND_ASK.md`

## Quando usar cada documento

- Iniciar tarefa: `TASK_BRIEF_TEMPLATE.md`
- Decidir leitura e execucao: `AGENT_OPERATING_SYSTEM.md`
- Resolver duvida de fonte oficial: `SOURCE_OF_TRUTH_MATRIX.md`
- Fechar entrega: `DONE_CHECKLIST_BY_WORK_TYPE.md`
- Delimitar autonomia/risco: `WHEN_TO_STOP_AND_ASK.md`
- Retomar ambiente local: `runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`
- Setup web: `local-setup/SETUP_LOCAL_WEB.md`

## Scope boundary

Os documentos desta pasta sao operacionais e nao substituem a direcao arquitetural multi-brand.
Para decisoes estrategicas, usar sempre `README.md`, `GEMINI.md`, `.github/copilot-instructions.md` e os docs ativos de arquitetura/engenharia.

## Corporate operation

A operacao corporativa governa:
- tenants
- white-label
- modulos habilitados
- integracoes
- qualidade operacional
- metricas corporativas
- orquestracao de enrichment e OCR
- storage bruto/normalizado/curado
- readiness para analytics

## Domain operation

Cada dominio governa:
- seu fluxo operacional
- sua semantica
- seus SLAs
- seus KPIs
- suas integracoes especificas

## Marketplace / network note

Quando houver operacao intermediada ou modelo de rede, isso deve ser modelado como capacidade do dominio ou do canal, e nao como identidade unica da plataforma.

## Regra operacional do incremento atual

O programa atual deve ser tratado como incremento de backend/plataforma com primeira entrega forte em `inspection`.

Logo, a operacao ativa precisa contemplar:
- publicacao de configuracao operacional para canais
- recepcao do retorno do App Mobile como fonte de evidencia
- reconciliacao entre backend, OCR, pesquisa e campo
- fila de manual resolution para casos insuficientes ou divergentes
- preparacao progressiva da base do report e da trilha analytics-ready
