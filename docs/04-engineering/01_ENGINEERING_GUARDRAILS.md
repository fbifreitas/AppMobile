# ENGINEERING GUARDRAILS

## Repo direction

Este repositorio deve ser desenvolvido como plataforma multi-dominio.

## Mandatory decisions before coding

Toda mudanca deve responder:
1. Isto pertence ao Platform Core?
2. Isto pertence a Shared Foundations?
3. Isto pertence a qual Domain Pack?
4. Isto pertence a Experience Layer?
5. Isto e preocupacao de Data & Intelligence?

## Naming rules

- nomes de dominio nao devem vazar para artefatos compartilhados
- nomes canonicos corporativos devem ser neutros
- especializacoes de dominio devem ficar em modulos de dominio
- implementacao segue `English-first`
- documentacao corrente segue em portugues
- vocabulario especializado so deve aparecer quando estiver claramente delimitado na camada de dominio/especializacao

## Architecture rules

- toda nova capability deve respeitar Clean Architecture
- o core/plataforma nao deve depender de semantica especializada de um unico vertical
- capacidades horizontais devem ser desenhadas para reaproveitamento futuro entre dominios quando isso fizer sentido
- canais nao podem concentrar inteligencia que deveria estar na plataforma
- artefatos publicados para canais devem ser contratos claros, versionados e testaveis

## Code quality rules

- Clean Code e obrigatorio
- SOLID e obrigatorio
- TDD e obrigatorio para o incremento em evolucao
- o fluxo recomendado e: contrato/teste -> implementacao minima -> refino -> documentacao
- toda camada nova deve nascer com testes no nivel adequado: unit, contract, integration ou widget/e2e, conforme a responsabilidade

## Storage and analytics rule

Toda capacidade nova que persista dados deve responder explicitamente:
1. o que vai para `raw`
2. o que vai para `normalized`
3. o que vai para `curated`
4. qual retorno operacional do App Mobile precisa ser armazenado
5. como a trilha fica preparada para analytics futura

## Documentation rule

Mudancas de arquitetura, backlog, nomenclatura ou ownership exigem atualizacao documental no mesmo ciclo.
