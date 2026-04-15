# Incremento de Arquitetura — Storage, Reconciliation e Analytics Trail

## Objetivo

Documentar a estrategia incremental de storage para suportar:
- enrichment
- OCR documental
- facts reconciliados
- publication de execution plan
- retorno operacional do App Mobile
- preparacao progressiva da base do report
- readiness para analytics futura

## Regra central

O storage nao deve ser preparado apenas para backend research e OCR.
Ele tambem deve receber e organizar o retorno do App Mobile como fonte primaria de evidencia do processo.

## Fontes que precisam ser armazenadas

- input inicial do case
- research/enrichment
- documentos e OCR
- comparables
- execution plan publicado
- retorno operacional do App Mobile
- field evidence
- facts reconciliados
- report basis snapshots
- decisions e approvals do backoffice

## Estrutura sugerida

```text
/storage
  /raw
    /cases/{caseId}/input/
    /cases/{caseId}/research/
    /cases/{caseId}/documents/
    /cases/{caseId}/comparables/
    /cases/{caseId}/job-config/
    /cases/{caseId}/inspection-return/
    /cases/{caseId}/field-evidence/
  /normalized
    /cases/{caseId}/property-profile/
    /cases/{caseId}/documents/
    /cases/{caseId}/comparables/
    /cases/{caseId}/job-config/
    /cases/{caseId}/inspection/
    /cases/{caseId}/report-prep/
  /curated
    /cases/{caseId}/approved-profile/
    /cases/{caseId}/approved-document-facts/
    /cases/{caseId}/approved-inspection-facts/
    /cases/{caseId}/approved-report-basis/
```

## Regras por camada de storage

### Raw

Objetivo:
- preservar artefato bruto
- nunca sobrescrever historico
- manter rastreabilidade por `runId`, `timestamp`, `source` e `correlationId`

Exemplos:
- resposta bruta do provider de pesquisa
- output bruto de OCR
- payload publicado para o app
- payload retornado pelo app
- evidencias recebidas sem reconciliacao

### Normalized

Objetivo:
- estruturar fatos em modelo consistente
- permitir reconciliacao entre fontes
- padronizar campos e taxonomias tecnicas

Exemplos:
- property profile normalizado
- facts documentais normalizados
- field evidence normalizada
- execution plan normalizado
- report prep base normalizada

### Curated

Objetivo:
- representar fatos aprovados ou reconciliados como base confiavel de operacao/reporting
- separar o que e historico bruto do que ja passou por validacao humana ou politica de suficiencia

Exemplos:
- facts aprovados do documento
- facts aprovados do campo
- report basis aprovada
- execution plan aprovado/supercedido

## Mobile return como requisito obrigatorio

A plataforma deve armazenar explicitamente o retorno do App Mobile, inclusive quando o payload nao resultar em reconciliacao imediata.

Isso inclui:
- step 1 selections
- step 2 payload
- camera captures metadata
- semantic classification
- review outputs
- technical justification
- sync metadata
- app/build/device metadata quando aplicavel

## Entidades satelite sugeridas

- `case_execution_plan_snapshot`
- `case_mobile_return_artifact`
- `case_field_evidence`
- `case_fact_reconciliation`
- `case_report_basis_snapshot`

## Relacao com analytics

Este storage deve nascer pronto para futura promocao analitica.

Expectativas:
- `raw` preserva a observacao original
- `normalized` sustenta consolidacao operacional
- `curated` sustenta consumo confiavel por operacao, report e analytics

## Regra de evolucao

A implementacao inicial pode usar filesystem local como landing zone historica.
A troca futura por object storage nao deve exigir mudanca nos use cases da aplicacao.

## Regras adicionais de versionamento e persistencia

- nunca sobrescrever artefatos em `raw`
- versionar por `runId` e `timestamp` sempre que houver nova execucao relevante
- manter relacao entre artefato bruto, normalizado e curado por `caseId` e `correlationId`
- preservar referencia a versao do `Execution Plan` publicada e consumida

## Artefatos minimos sugeridos por caso

Persistir no minimo, quando aplicavel:
- `case_input_snapshot.json`
- `research_request.json`
- `research_response_raw.json`
- `research_response_normalized.json`
- `comparables_raw.json`
- `comparables_normalized.json`
- `document_ocr_raw.json`
- `document_extractions_normalized.json`
- `job_configuration_snapshot.json`
- `mobile_execution_return.json`
- `field_evidence_normalized.json`
- `report_basis_snapshot.json`
- `review_decision.json`

## Estrategia de transicao futura

A implementacao inicial pode usar filesystem local como landing zone historica.
A migracao futura para object storage deve preservar:
- contratos dos use cases
- estrutura semantica de `raw`, `normalized` e `curated`
- versionamento dos artefatos
- rastreabilidade por `caseId`, `runId` e `correlationId`
