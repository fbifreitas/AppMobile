# Incremento de Analysis & Design — Use Cases de Orquestracao do Backend/Plataforma

## Objetivo

Organizar os casos de uso incrementais que suportam o programa atual de:
- enrichment
- OCR
- fact reconciliation
- execution hints
- smart app derivado
- mobile return ingestion
- report basis preparation

## Use cases sugeridos

### 1. TriggerCaseEnrichmentUseCase
Responsabilidade:
- iniciar a esteira quando um case elegivel entrar no fluxo

### 2. ProcessCaseDocumentsUseCase
Responsabilidade:
- identificar e preparar documentos recebidos para classificacao e OCR

### 3. ExecuteResearchUseCase
Responsabilidade:
- acionar provider de pesquisa/IA e persistir artefatos brutos

### 4. ReconcileFactsUseCase
Responsabilidade:
- reconciliar facts do case, OCR, pesquisa e aprovacoes humanas

### 5. EvaluateSufficiencyUseCase
Responsabilidade:
- decidir se a plataforma consegue gerar configuracao operacional suficiente sem resolucao manual

### 6. BuildExecutionHintsUseCase
Responsabilidade:
- gerar hints operacionais e de canal a partir dos fatos reconciliados

### 7. PublishExecutionPlanUseCase
Responsabilidade:
- publicar o `Execution Plan` versionado para o canal consumidor

### 8. ReceiveMobileExecutionReturnUseCase
Responsabilidade:
- receber o retorno operacional do App Mobile

### 9. NormalizeFieldEvidenceUseCase
Responsabilidade:
- transformar o retorno bruto do app em evidencias normalizadas e comparaveis com outras fontes

### 10. PrepareReportBasisUseCase
Responsabilidade:
- gerar base progressiva do report a partir dos facts reconciliados e da evidencia de campo

### 11. QueueManualResolutionUseCase
Responsabilidade:
- abrir pendencia operacional quando o plano nao puder ser publicado com seguranca suficiente

## Boundary de implementacao

- use cases de aplicacao nao devem depender de SDK especifico de OCR ou provider especifico de IA
- gateways e repositories ficam na infraestrutura
- regras de reconciliacao e suficiencia ficam em servicos/policies de dominio

## Observacao de TDD

Cada use case do incremento deve nascer com teste cobrindo pelo menos:
- caminho feliz
- caminho insuficiente/divergente
- persistencia/estado esperado
- publish/return contract quando aplicavel
