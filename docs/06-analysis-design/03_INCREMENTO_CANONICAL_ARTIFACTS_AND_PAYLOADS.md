# Incremento de Analysis & Design — Artefatos Canonicos e Payloads

## Objetivo

Definir os artefatos canonicos minimos do incremento para evitar contratos paralelos e garantir rastreabilidade entre backend, backoffice, mobile e analytics futura.

## Artefatos canonicos

### 1. Reconciled Property Profile
Representa o conjunto reconciliado de fatos do case.

Campos de referencia:
- `caseId`
- `propertyType`
- `propertySubtype`
- `facts`
- `qualityFlags`
- `sourcePrecedence`
- `confidenceSummary`

### 2. Execution Plan Snapshot
Representa a configuracao operacional publicada para um canal.

Campos de referencia:
- `caseId`
- `planVersion`
- `channel`
- `step1Config`
- `step2Config`
- `cameraConfig`
- `reviewConfig`
- `alerts`
- `inspectionHints`
- `publishedAt`

### 3. Mobile Return Artifact
Representa o retorno bruto do App Mobile.

Campos de referencia:
- `caseId`
- `planVersionConsumed`
- `step1Selection`
- `step2Return`
- `captureReturn`
- `reviewReturn`
- `finalizationReturn`
- `receivedAt`
- `appMetadata`

Campos incrementais relevantes:
- `freeCaptureMode`
- `manualClassificationRequired`

### 4. Field Evidence
Representa evidencia estruturada do campo.

Campos de referencia:
- `caseId`
- `evidenceId`
- `captureContext`
- `targetItem`
- `targetQualifier`
- `material`
- `state`
- `geo`
- `timestamps`
- `source`
- `fileReferences`
- `classificationLevels`

Observacao:
- em `modo de captura livre`, a evidencia pode chegar inicialmente sem todos os niveis de classificacao preenchidos
- nesse caso, a classificacao posterior acontece na web e complementa o artefato

### 5. Report Basis Snapshot
Representa a base progressiva do report.

Campos de referencia:
- `caseId`
- `snapshotVersion`
- `approvedFacts`
- `approvedFieldEvidence`
- `pendingFlags`
- `generatedAt`

## Regras de contrato

- nomes tecnicos em ingles
- versionamento obrigatorio de snapshots e payloads publicados
- rastreabilidade minima por `caseId`, `correlationId` e `source`
- retorno do app sempre precisa referenciar a versao do plano consumido
- nenhum payload do canal substitui o modelo reconciliado do backend
- o `modo de captura livre` nao invalida o contrato; ele muda apenas o momento da classificacao
- o backend deve aceitar `field evidence` com classificacao parcial ou nula quando `freeCaptureMode = true`

## Relacao com o app atual

No recorte de `inspection`, os artefatos acima precisam continuar dialogando com:
- `check-in step 1`
- `check-in step 2`
- `camera`
- `review`
- `finalization`

Sem criar outro contrato paralelo de semantica de captura.

## Adendo 2026-04-20 - Captura livre e classificacao posterior

### Regra incremental

O ecossistema agora suporta duas formas de retorno do mobile:

1. `guided capture return`
- a classificacao ja sai preenchida do app

2. `free capture return`
- o app envia apenas a coleta bruta
- a web complementa a classificacao depois

### Campos canonicos adicionais no payload final do mobile

- `freeCaptureMode: boolean`
- `manualClassificationRequired: boolean`

Quando `freeCaptureMode = true`, cada captura pode sair com:
- `classificationStatus = pending_manual_classification`
- `macroLocation` nulo
- `environmentName` nulo ou placeholder operacional
- `element/material/state` nulos

### Regra de responsabilidade por canal

- mobile:
  - coleta
  - sincroniza
  - nao bloqueia por classificacao em modo livre

- web:
  - classifica manualmente
  - aplica obrigatoriedades
  - exige `step2` quando configurado

### Implicacao canonica

O contrato externo deixa de pressupor que toda `Field Evidence` chega completa na primeira escrita.
O backend passa a tratar o artefato como progressivo, preservando:
- retorno bruto do campo
- reconciliacao posterior
- rastreabilidade de quem classificou depois
