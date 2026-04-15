# Plano de Implantacao — Incremento de Enrichment, OCR, Smart App Derivado e Analytics Trail

Atualizado em: 2026-04-15

## Objetivo

Guiar a implantacao incremental do programa atual em ciclos longos de desenvolvimento, com foco em continuidade de entrega e baixo custo de replanejamento.

## Premissas

- documentacao em portugues
- implementacao `English-first`
- Clean Architecture, SOLID e Clean Code obrigatorios
- TDD obrigatorio para o incremento
- App Mobile nao e centro da arquitetura
- backend/plataforma e o orquestrador do processo

## Milestones do programa

| Milestone | Nome | Objetivo | Ciclo sugerido |
|---|---|---|---|
| `M1` | Orchestrated Foundations | posicionar o incremento na plataforma e preparar foundations horizontais | ciclo longo 1 |
| `M2` | Reconciliation and Storage Trail | consolidar storage, facts e retorno do mobile | ciclo longo 2 |
| `M3` | Smart Inspection Execution Plan | publicar plano operacional derivado para o mobile | ciclo longo 3 |
| `M4` | Manual Resolution and Report Basis | fechar backoffice, reconciliacao final e base progressiva do report | ciclo longo 4 |
| `Mx` | Analytics Readiness and Hardening | deixar a trilha pronta para analytics e endurecer a governanca tecnica | ciclo longo 5 |

## Detalhamento dos ciclos

### `M1` Orchestrated Foundations

Escopo:
- eventos de disparo do enrichment
- document ingestion inicial
- OCR gateway baseline
- research/enrichment gateway baseline
- artefatos satelite iniciais
- contractos base de execution hints

Foco de desenvolvimento:
- backend/plataforma
- foundations compartilhadas
- contracts e testes

### `M2` Reconciliation and Storage Trail

Escopo:
- storage `raw/normalized/curated`
- persistencia de research e OCR
- persistencia de execution plan publicado
- recepcao do retorno do App Mobile
- normalizacao de field evidence
- reconciliacao inicial entre case, OCR, research e mobile

Foco de desenvolvimento:
- backend/plataforma
- data trail
- analytics readiness baseline

### `M3` Smart Inspection Execution Plan

Escopo:
- `step1Config`
- `step2Config`
- `cameraConfig`
- `reviewConfig`
- `finalizationRules`
- versionamento do plano publicado
- consumo pelo mobile como caminho principal

Foco de desenvolvimento:
- backend/plataforma
- mobile
- contracts web/mobile/backend

### `M4` Manual Resolution and Report Basis

Escopo:
- manual resolution queue
- aprovacao/correcao de facts
- republicacao de execution plan
- base progressiva do report
- reconciliacao consolidada pos-campo

Foco de desenvolvimento:
- backend/plataforma
- backoffice
- governanca operacional

### `Mx` Analytics Readiness and Hardening

Escopo:
- enriquecimento da trilha analitica
- regras de promocao futura
- quality gates
- contract tests
- observabilidade por correlation id
- revisao arquitetural e endurecimento tecnico

Foco de desenvolvimento:
- plataforma
- engenharia
- analytics readiness

## Regra de execucao recomendada

O programa deve ser conduzido em ciclos longos e coesos, com poucas interrupcoes entre backend, backoffice e mobile.

Cada milestone deve fechar um bloco arquitetural inteiro antes de abrir o seguinte.

## Definition of Done por milestone

Cada milestone so pode ser encerrado quando houver:
- documentacao atualizada
- testes criados/atualizados
- contratos versionados
- evidencia de runtime ou validacao tecnica correspondente
- backlog sincronizado
