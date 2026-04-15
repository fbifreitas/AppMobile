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

## Relacao com o app atual

No recorte de `inspection`, os artefatos acima precisam continuar dialogando com:
- `check-in step 1`
- `check-in step 2`
- `camera`
- `review`
- `finalization`

Sem criar outro contrato paralelo de semantica de captura.
