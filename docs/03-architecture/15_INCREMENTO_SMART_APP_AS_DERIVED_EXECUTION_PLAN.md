# Incremento de Arquitetura — Smart App como Execution Plan Derivado

## Objetivo

Documentar o `smart app` como saida derivada da orquestracao de backend/plataforma.

Este documento existe para evitar dois erros:
- recentralizar a inteligencia no App Mobile
- reduzir o incremento a configuracao superficial de telas

## Regra central

O App Mobile nao e o centro do desenho.
O App Mobile consome um `Execution Plan` publicado pela plataforma e devolve evidencias estruturadas.

## O que a plataforma deve publicar ao app

### Camada comum
- `jobType`
- `domainContext`
- `executionPlanVersion`
- `correlationId`
- `alerts`
- `inspectionHints`

### Configuracao operacional
- `step1Config`
- `step2Config`
- `cameraConfig`
- `reviewConfig`
- `finalizationRules`

## Recorte atual de real estate inspection

No vertical atual, `cameraConfig` e `stepConfig` precisam cobrir:
- `propertyType`
- `propertySubtype`
- `captureContext`
- `macroLocal`
- `ambiente`
- `elemento`
- `material`
- `estado`
- `expectedSequence`
- `required`
- `minimumPhotos`
- `visualChecklist`
- `fieldAlerts`
- `normativeRequirements`

## Regra de compatibilidade com o fluxo atual

A publicacao precisa respeitar o modelo canonico ja em uso no app:
- `check-in step 1`
- `check-in step 2`
- `camera`
- `review`
- `pending items`

Logo, o incremento nao deve criar uma segunda semantica paralela.
Deve preencher melhor a semantica operacional ja existente.

## O que o app deve retornar

- `step1Selection`
- `step2Return`
- `captureReturn`
- `reviewReturn`
- `finalizationReturn`
- `fieldEvidence`
- `technicalJustification`
- `syncMetadata`

## Beneficio arquitetural

Esse desenho permite:
- evoluir a inteligencia na plataforma sem inflar o cliente
- manter o mobile leve e governado por contrato
- reaproveitar o mesmo backend para outros canais no futuro
- manter o retorno do campo como input estruturado para report e analytics

## Compatibilidade com payload minimo legado

Para preservar evolucao incremental, o `Execution Plan` deve conseguir ser projetado para payloads mais simples consumidos pelo app atual.

Payload minimo de compatibilidade esperado:
- `jobType`
- `propertyType`
- `requiredScreens`
- `requiredFields`
- `optionalFields`
- `requiredPhotos`
- `alerts`
- `inspectionHints`

## Regra de transformacao

A plataforma pode manter artefatos ricos internamente, mas deve conseguir projetar uma visao simplificada para canais que ainda nao consumam o contrato completo.

## Adendo 2026-04-20 - Excecao controlada para captura livre

A regra central continua valida: o app deve ser governado por contrato e nao virar centro de inteligencia.

Porem, existe agora uma excecao operacional controlada:

- quando `freeCaptureMode = true`
- o app deixa de usar o `Execution Plan` para dirigir a classificacao da camera
- e passa a usa-lo apenas como contexto de rastreabilidade e consolidacao posterior

Leitura correta:
- `guided capture` -> o plano governa a coleta
- `free capture` -> o plano continua existindo, mas a classificacao migra para a web

Isso nao cria uma segunda semantica paralela.
Cria apenas uma segunda estrategia operacional dentro do mesmo contrato de retorno.
