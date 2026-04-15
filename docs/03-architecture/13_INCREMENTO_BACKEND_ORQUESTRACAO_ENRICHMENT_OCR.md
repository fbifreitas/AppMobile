# Incremento de Arquitetura — Backend/Plataforma para Enrichment, OCR e Reconciliacao

## Objetivo

Descrever a arquitetura incremental que adiciona ao backend/plataforma as capacidades de:
- enrichment
- document OCR
- fact reconciliation
- quality/confidence evaluation
- hint generation
- channel publication
- mobile return ingestion

Tudo isso sem quebrar:
- a centralidade do case existente
- a separacao por camadas
- os boundaries entre core, dominio e canal

## Principios

- Clean Architecture
- SOLID
- Clean Code
- TDD obrigatorio na implementacao
- nomes tecnicos em ingles na implementacao
- documentacao em portugues
- vocabulario especializado restrito a camada de dominio/especializacao

## Posicionamento nas camadas

### Platform Core / Shared Foundations

Capacidades reaproveitaveis:
- `DocumentIngestion`
- `DocumentOcr`
- `FactExtraction`
- `FactReconciliation`
- `ConfidenceEvaluation`
- `ManualResolution`
- `ArtifactStorage`
- `AnalyticsReadyTrail`
- `ExecutionPlanPublication`
- `ChannelReturnIngestion`

### Domain Pack Inspection

Capacidades do dominio:
- semantica de job e execution plan de vistoria
- regras operacionais do fluxo
- regras de revisao e finalizacao
- semantic mapping entre check-in, camera e review

### Real-estate specialization inside inspection

Especializacoes do recorte atual:
- regras NBR
- tipologia e subtipo de imovel
- configuracao de camera orientada por imovel
- regras de check-in step 1 e step 2
- preparacao da base do report/laudo imobiliario

## Use cases incrementais sugeridos

- `TriggerCaseEnrichmentUseCase`
- `ProcessCaseDocumentsUseCase`
- `ExecuteResearchUseCase`
- `PersistResearchArtifactsUseCase`
- `PersistDocumentArtifactsUseCase`
- `ReconcileFactsUseCase`
- `EvaluateSufficiencyUseCase`
- `BuildExecutionHintsUseCase`
- `PublishExecutionPlanUseCase`
- `ReceiveMobileExecutionReturnUseCase`
- `NormalizeFieldEvidenceUseCase`
- `PrepareReportBasisUseCase`
- `QueueManualResolutionUseCase`

## Estados sugeridos

### Processing
- `PENDING`
- `PROCESSING`
- `COMPLETED`
- `REVIEW_REQUIRED`
- `FAILED`

### Execution plan
- `NOT_GENERATED`
- `GENERATED`
- `MANUAL_RESOLUTION_REQUIRED`
- `READY_FOR_EXECUTION`
- `SUPERSEDED`

## Artefatos satelite sugeridos

- `case_research_run`
- `case_document_artifact`
- `case_document_extraction`
- `case_reconciled_fact`
- `case_execution_plan_snapshot`
- `case_mobile_return_artifact`
- `case_field_evidence`
- `case_report_basis_snapshot`
- `case_operational_pending`
- `case_data_quality_flag`

## Boundary rule

Nenhum desses artefatos deve substituir o case canonicamente existente.
Eles sao satelites do processo.

## Canais

### Publicado para mobile
- configuracao operacional pronta para consumo
- hints e alertas
- versao do plano publicado
- metadados de correlacao e rastreabilidade

### Retornado pelo mobile
- selecoes operacionais
- evidencias capturadas
- classificacao semantica
- metadados de geolocalizacao/dispositivo/app
- review/finalization outputs
- justificativas tecnicas quando aplicavel

## Relacao com analytics

A arquitetura deve produzir trilha preparada para:
- analise operacional
- qualidade de dados
- reaproveitamento cross-domain futuro
- promocao futura para bronze/silver/gold

## Regra de implementacao

Nenhuma entrega do incremento deve mover a semantica principal para o App Mobile.
O canal consome e devolve dados; a plataforma orquestra.

## Contracto do provider de research/IA

O provider de research/IA deve ser consumido via gateway de infraestrutura e responder preferencialmente com JSON estruturado.

Campos minimos esperados:
- `propertyIdentification`
- `propertyHypothesis`
- `condominiumData`
- `locationData`
- `marketData`
- `comparables`
- `researchLinks`
- `inspectionHints`
- `jobConfigurationHints`
- `dataQualityFlags`

Regras obrigatorias do contrato:
- nao inferir unidade a partir do condominio sem flag explicita
- separar unidade, condominio, endereco/localizacao e entorno/mercado
- classificar cada fato com nivel minimo equivalente a `CONFIRMED`, `INDICATIVE`, `DIVERGENT`, `NOT_FOUND`
- registrar link de retorno da pesquisa e link do anuncio quando houver
- registrar sinalizacao de duplicidade potencial

## Policies recomendadas

Policies de dominio sugeridas:
- `ResearchSufficiencyPolicy`
- `FactReconciliationPolicy`
- `DocumentExtractionConfidencePolicy`
- `ComparableDeduplicationPolicy`
- `ComparableFitScoringPolicy`
- `ExecutionPlanPolicy`

## Faseamento tecnico incremental

### Fase 1 — POC local
- orchestracao basica
- gateway de research
- gateway de OCR
- storage local historico
- fatos normalizados basicos
- hints basicos e fila manual minima

### Fase 2 — Operacao assistida
- deduplicacao de comparables
- score de aderencia
- matriz mais objetiva de suficiencia
- backoffice de resolucao manual mais rico
- ingestion do retorno do App Mobile

### Fase 3 — Promocao analitica
- trilha pronta para bronze/silver/gold
- relatorios de qualidade e reconciliacao
- reaproveitamento progressivo cross-domain
