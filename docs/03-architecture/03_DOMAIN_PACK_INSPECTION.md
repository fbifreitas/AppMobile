# DOMAIN PACK INSPECTION

## Role

Inspection e o primeiro domain pack da plataforma e continua sendo um ativo estrategico.

## Scope

- demanda de vistoria
- case de inspecao
- job operacional
- execucao em campo
- checklist NBR
- evidencias e revisao
- valuation support
- laudo/reporting
- settlement especifico do dominio
- distribuicao operacional e marketplace de vistoria

## Important note

Os conceitos acima nao devem definir a semantica do Platform Core.
Eles sao especializacoes do dominio inspection.

## Domain-specific canonical flow

```text
Demand -> Case -> Job -> Inspection -> Valuation -> Report -> Settlement
```

## Strategic evolution

As 4 ondas do dominio inspection continuam validas como roadmap do proprio dominio, e nao mais como roteiro corporativo unico.

## Incremento ativo — backend/plataforma como orquestrador

O incremento atual do domain pack `inspection` deve ser lido como evolucao da plataforma, e nao como recentralizacao do mobile.

A capacidade em evolucao e:

- `backend/plataforma` orquestra `enrichment`, `document OCR`, `fact reconciliation`, `hint generation`, `manual resolution` e publicacao para canais

No recorte atual, a primeira especializacao operacional dessa capacidade acontece em `inspection` com foco em jornadas de imoveis, incluindo:

- pre-configuracao inteligente de `check-in step 1`
- pre-configuracao inteligente de `check-in step 2`
- pre-configuracao inteligente do menu da camera
- preparacao progressiva da base do laudo/report

### Boundary importante

Os elementos abaixo pertencem ao dominio e nao devem subir para o core corporativo:

- taxonomia de imovel
- subtipo de imovel
- regras NBR
- matriz normativa de obrigatoriedade
- configuracao operacional de captura imobiliaria

### Shared/horizontal capabilities aproveitaveis por outros dominios

As capacidades abaixo devem ser modeladas de forma reaproveitavel para outros negocios previstos da plataforma, como `wellness` e `church`, quando fizer sentido:

- document ingestion
- OCR pipeline
- fact extraction
- fact reconciliation
- confidence and sufficiency evaluation
- artifact storage
- manual resolution queue
- publication of execution hints for channels
- analytics-ready raw/normalized/curated trail

### Papel do mobile

O App Mobile continua importante, mas como canal operacional do dominio:

- consome `Execution Plan` e `job configuration hints`
- executa coleta de campo
- devolve evidencias estruturadas para a plataforma

Logo, `inspection` continua dono da semantica do fluxo, enquanto a inteligencia operacional passa a ser preparada primariamente pelo backend/plataforma.

## Adendo 2026-04-20 - Dual capture mode

O dominio `inspection` passa a admitir duas variantes operacionais de captura:

1. `guided capture`
- a camera segue a arvore operacional publicada pela plataforma
- a classificacao acontece no campo

2. `free capture`
- a camera coleta imagens sem classificacao no mobile
- a consolidacao classificatoria acontece depois na web

Regras:
- `check-in etapa 1` continua obrigatorio nos dois modos
- `free capture` nao elimina obrigatoriedades do dominio
- ele apenas desloca a cobranca operacional do mobile para o backoffice web
