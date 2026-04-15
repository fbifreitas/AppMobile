# Matriz de Rastreabilidade — Incremento v4 para Documentacao Ativa

Atualizado em: 2026-04-15

## Objetivo

Registrar a cobertura dos requisitos presentes no pacote `docs_incremento_full_v4` dentro da documentacao ativa do projeto.

Status possiveis:
- `Considerado`
- `Considerado parcialmente`
- `Nao considerado`

Todo item parcial ou ausente deve trazer justificativa.

## Matriz

| ID | Requisito de origem | Origem | Status | Destino na documentacao ativa | Justificativa |
|---|---|---|---|---|---|
| `R-01` | Incremento, nao reconstruir do zero | README + 03 + 04 | Considerado | `02-product/03`, `03-architecture/13`, `06-analysis-design/01_DECISION_LOG_V2` | |
| `R-02` | Case existente continua canonico | 01 + 03 + 04 | Considerado | `03-architecture/13`, `06-analysis-design/02` | |
| `R-03` | Mobile e consumidor da configuracao, nao centro da inteligencia | 01 + 02 + 03 + 04 | Considerado | `03-architecture/11`, `03-architecture/15`, `05-operations/01_OPERATING_MODEL` | |
| `R-04` | Backend/plataforma orquestra enrichment, OCR, reconciliacao e hints | 01 + 03 + 05 | Considerado | `02-product/03`, `03-architecture/13` | |
| `R-05` | Backoffice precisa de fila `Jobs a Resolver` | 01 + 02 + 03 + 04 + 05 | Considerado | `02-product/03`, `03-architecture/13`, `05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md` | |
| `R-06` | Backoffice deve visualizar dados pesquisados e resolver manualmente template/telas/campos/checklist | 02 + 04 | Considerado | `02-product/03` | |
| `R-07` | OCR documental como fonte complementar estruturante | README + 01 + 03 + 05 | Considerado | `02-product/03`, `03-architecture/13`, `03-architecture/16` | |
| `R-08` | Tipos documentais elegiveis: IPTU, matricula, certidoes | 05 | Considerado | `03-architecture/16` | |
| `R-09` | Campos relevantes por tipo documental | 02 + 05 | Considerado | `03-architecture/16` | |
| `R-10` | Precedencia sugerida entre OCR, case, pesquisa, hipotese e decisao manual | 01 + 03 + 05 | Considerado | `03-architecture/16`, `06-analysis-design/03` | |
| `R-11` | Precedencia deve ser configuravel no futuro por tenant/contrato | 01 + 05 | Considerado parcialmente | `03-architecture/16` | A documentacao registra a necessidade futura de configurabilidade, mas ainda nao detalha um modelo tecnico de parametrizacao por tenant/contrato. |
| `R-12` | Persistir bruto e normalizado | 02 + 03 + 04 | Considerado | `03-architecture/14` | |
| `R-13` | Usar filesystem local nesta fase | README + 03 + 04 | Considerado | `03-architecture/14` | |
| `R-14` | Preparar migracao futura para object storage | 03 + 04 | Considerado | `03-architecture/14` | |
| `R-15` | Estrutura raw/normalized/curated | 03 + 05 | Considerado | `03-architecture/14` | |
| `R-16` | Storage deve receber retorno do App Mobile | discussao do chat + ajuste de escopo | Considerado | `03-architecture/14`, `03-architecture/15` | Requisito ampliado em relacao ao pacote original para refletir o desenho consolidado do programa. |
| `R-17` | Persistir artefatos minimos como request/response/comparables/job snapshot/review decision | 04 | Considerado | `03-architecture/14` | |
| `R-18` | Entidades satelite de research, comparables, job snapshot, pending e quality flag | 03 + 04 | Considerado | `03-architecture/13` | |
| `R-19` | Adicionar artefatos satelite para retorno mobile e report basis | discussao do chat | Considerado | `03-architecture/13`, `03-architecture/14`, `06-analysis-design/03` | Requisito adicional consolidado a partir do entendimento macro do processo. |
| `R-20` | Contrato do provider de IA com campos minimos estruturados | 03 + 04 | Considerado | `03-architecture/13` | |
| `R-21` | Regras do provider: nao inferir unidade sem flag, separar unidade/condominio/localizacao/mercado, classificar facts | 03 + 04 | Considerado | `03-architecture/13` | |
| `R-22` | Capturar comparables com links rastreaveis | 01 + 02 + 03 + 04 | Considerado | `02-product/03`, `03-architecture/13` | |
| `R-23` | Capturar 10 a 30 comparables quando possivel | 03 | Considerado | `02-product/03` | |
| `R-24` | Capturar 20 a 40 comparables quando possivel | 04 | Considerado parcialmente | `03-architecture/13` | Mantive o intervalo 10 a 30 como regra operacional do pacote principal e registrei 20 a 40 como configuracao mais agressiva futura. Ha variacao entre os anexos, entao a documentacao preserva ambos sem fixar um unico numero universal. |
| `R-25` | Deduplicacao basica de comparables | 03 + 04 | Considerado | `03-architecture/13`, `06-analysis-design/02` | |
| `R-26` | Score de aderencia de comparables | 03 | Considerado | `03-architecture/13` | |
| `R-27` | Reaproveitamento historico de comparables | 01 | Considerado parcialmente | `02-product/03`, `03-architecture/13` | O reaproveitamento historico foi registrado como direcao e capacidade desejada, mas ainda nao foi detalhado em politica operacional propria. |
| `R-28` | Avaliacao de suficiencia para gerar plano automaticamente ou exigir revisao | 01 + 02 + 03 + 04 + 05 | Considerado | `02-product/03`, `03-architecture/13`, `06-analysis-design/02` | |
| `R-29` | Matriz de decisao mais objetiva de suficiencia | 03 + 04 | Considerado parcialmente | `02-product/03`, `03-architecture/13` | O estado e os criterios minimos foram documentados, mas a matriz completa de thresholds ainda nao foi especificada requisito a requisito. |
| `R-30` | Publicar `jobConfigurationHints` para o app | 01 + 02 + 03 + 04 | Considerado | `03-architecture/15`, `06-analysis-design/03` | |
| `R-31` | Payload minimo esperado para mobile: jobType, propertyType, requiredScreens, requiredFields, optionalFields, requiredPhotos, alerts, inspectionHints | 02 + 04 | Considerado | `03-architecture/15` | |
| `R-32` | Smart app deve cobrir configuracao de check-in e camera no recorte atual | discussao do chat | Considerado | `02-product/03`, `03-architecture/15` | Requisito consolidado a partir do entendimento do codigo atual e da conversa. |
| `R-33` | Smart app nao substitui vistoria humana nem laudo final | 01 + 02 + 04 | Considerado | `02-product/03` | |
| `R-34` | Base progressiva para report/laudo | discussao do chat + 03 + 05 | Considerado | `02-product/03`, `03-architecture/13`, `03-architecture/14`, `06-analysis-design/03` | |
| `R-35` | Preparacao para analytics bronze/silver/gold | 01 + 03 + 05 | Considerado | `03-architecture/14`, `05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md` | |
| `R-36` | Endpoints internos minimos para enrichment, documents e pending jobs | 03 + 04 | Considerado | `02-product/03` | |
| `R-37` | Observabilidade por caseId, tenantId, correlationId | 03 + 04 | Considerado | `03-architecture/13`, `05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md` | |
| `R-38` | Faseamento tecnico POC local -> operacao assistida -> promocao analitica | 03 | Considerado | `03-architecture/13` | |
| `R-39` | Nao criar novo case master ou fluxo paralelo de case | 03 + 04 | Considerado | `03-architecture/13`, `06-analysis-design/01_DECISION_LOG_V2` | |
| `R-40` | Nao implementar avaliacao automatica final de valor de mercado nesta fase | 01 + 04 | Considerado parcialmente | `02-product/03` | O documento atual registra que a base do report e progressiva e que o incremento nao recentraliza o valuation no app, mas ainda nao explicita em um item isolado a exclusao formal da avaliacao automatica final de valor de mercado. |
| `R-41` | Clean Architecture, SOLID, Clean Code e TDD como diretrizes obrigatorias | README + 03 + 04 | Considerado | `04-engineering/01_ENGINEERING_GUARDRAILS.md`, `03-architecture/13`, `05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md` | |
| `R-42` | Documentacao em portugues e implementacao English-first | diretriz consolidada do chat | Considerado | `04-engineering/01_ENGINEERING_GUARDRAILS.md`, `05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md` | |

## Itens nao considerados

No fechamento atual, nao restou item totalmente fora do pacote.

Os itens marcados como `Considerado parcialmente` exigem detalhamento adicional em futura passada documental ou diretamente durante a especificacao tecnica de implementacao.
