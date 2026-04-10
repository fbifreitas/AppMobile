# OPERATING MODEL

## O que e operacao ativa

Operacao ativa e a camada documental usada no trabalho diario de execucao.
Ela organiza setup, runbooks, backlog tatico, governanca operacional e autonomia do agente.

## Operational documentation index

Esta pasta concentra documentação operacional corrente ativa.

1. Runbooks: `docs/05-operations/runbooks/`
2. Setup local: `docs/05-operations/local-setup/`
3. Backlogs táticos: `docs/05-operations/tactical-backlogs/`
4. Governança backlog/board: `docs/05-operations/backlog-governance/`
5. Onboarding de agentes: `docs/05-operations/agent-onboarding/`
6. Governança de release: `docs/05-operations/release-governance/`
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

Os documentos desta pasta são operacionais e não substituem a direção arquitetural multi-brand.
Para decisões estratégicas, usar sempre `README.md`, `GEMINI.md`, `.github/copilot-instructions.md` e os docs ativos de arquitetura/engenharia.

## Corporate operation

A operação corporativa governa:
- tenants
- white-label
- módulos habilitados
- integrações
- qualidade operacional
- métricas corporativas

## Domain operation

Cada domínio governa:
- seu fluxo operacional
- sua semântica
- seus SLAs
- seus KPIs
- suas integrações específicas

## Marketplace / network note

Quando houver operação intermediada ou modelo de rede, isso deve ser modelado como capacidade do domínio ou do canal, e não como identidade única da plataforma.
