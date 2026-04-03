# OPERATING MODEL

## Operational documentation index

Esta pasta concentra documentação operacional corrente ativa.

1. Runbooks: `docs/05-operations/runbooks/`
2. Setup local: `docs/05-operations/local-setup/`
3. Backlogs táticos: `docs/05-operations/tactical-backlogs/`
4. Governança backlog/board: `docs/05-operations/backlog-governance/`
5. Onboarding de agentes: `docs/05-operations/agent-onboarding/`
6. Governança de release: `docs/05-operations/release-governance/`

## Scope boundary

Os documentos desta pasta são operacionais e não substituem a direção arquitetural V2.
Para decisões estratégicas, usar sempre `README.md`, `GEMINI.md`, `.github/copilot-instructions.md` e os docs ativos de arquitetura/engenharia V2.

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
