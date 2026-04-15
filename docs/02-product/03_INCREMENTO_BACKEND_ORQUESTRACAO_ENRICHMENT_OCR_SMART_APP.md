# Incremento de Produto — Backend/Plataforma para Enrichment, OCR e Smart App Derivado

## Objetivo

Documentar a evolucao incremental da plataforma para que `backend/plataforma` passe a orquestrar:

- enrichment
- OCR documental
- reconciliacao de fatos
- avaliacao de confianca e suficiencia
- geracao de hints
- publicacao de configuracao operacional para canais
- recepcao do retorno operacional do App Mobile
- preparacao progressiva da base do report

Este documento nao substitui a documentacao existente. Ele a complementa.

## Leitura correta do incremento

O incremento atual nao cria um novo centro arquitetural no App Mobile.

A leitura correta e:
- a plataforma continua como centro de orquestracao
- o dominio `inspection` continua dono da semantica operacional
- o App Mobile passa a consumir um `Execution Plan` derivado
- o App Mobile tambem devolve evidencias estruturadas para a plataforma

## Resultado funcional esperado

Apos um case elegivel entrar no fluxo:

1. a plataforma consolida dados de multiplas fontes
2. tenta produzir configuracao operacional suficiente para o canal
3. publica o plano de execucao para o App Mobile
4. recebe o retorno de campo do app
5. reconcilia esse retorno com facts ja conhecidos
6. prepara progressivamente a base do report e a trilha analytics-ready

## Fontes do processo

O processo deve considerar pelo menos estas fontes:
- dados nativos do case
- enrichment via pesquisa/IA
- OCR documental
- decisao humana do backoffice
- retorno operacional do App Mobile

## Smart app como saida derivada

O `smart app` nao e capability central isolada.
Ele e uma derivacao operacional do backend/plataforma.

A plataforma deve ser capaz de publicar ao app:
- configuracao de `check-in step 1`
- configuracao de `check-in step 2`
- configuracao do menu da camera
- regras de revisao/finalizacao
- alertas de campo
- hints operacionais e tecnicos

## Requisito especifico do recorte atual

No recorte atual de real estate inspection, o plano publicado ao mobile precisa cobrir:
- taxonomia do imovel
- subtipo e contexto inicial
- macro local / ambiente / elemento / material / estado
- sequencia esperada de captura quando aplicavel
- obrigatoriedade e quantidade minima
- checklist visual por tipologia
- alertas e validacoes de campo
- regras normativas e operacionais associadas

## Papel do backoffice

O backoffice continua obrigatorio para os casos insuficientes ou ambiguos.

Responsabilidades:
- corrigir tipologia/classificacao quando necessario
- revisar facts extraidos
- resolver pendencias operacionais
- liberar ou ajustar o `Execution Plan`

## Impacto em analytics

O incremento deve nascer preparado para analytics futura.

Logo, toda fonte do processo deve alimentar trilha:
- `raw`
- `normalized`
- `curated`

Isso inclui o retorno operacional do App Mobile.

## Criterio de sucesso

O incremento sera considerado bem-sucedido quando a plataforma conseguir:
- consolidar facts de backend, OCR e campo sem recentralizar a logica no mobile
- publicar plano operacional suficiente para o App Mobile
- receber e armazenar o retorno do app como fonte primaria de evidencia
- preparar a base progressiva do report
- manter trilha pronta para analytics futura

## Comparables e qualidade de amostra

O enrichment do recorte atual deve considerar comparables como artefato de primeira classe do processo.

A plataforma deve ser capaz de:
- capturar comparables com rastreabilidade de origem
- manter link da pesquisa e link do anuncio quando houver
- registrar duplicidade potencial
- aplicar deduplicacao basica
- calcular score inicial de aderencia
- reaproveitar historico em ciclos futuros quando aplicavel

Regra operacional sugerida para o recorte atual:
- capturar entre 10 e 30 comparables quando possivel
- aceitar evolucao futura para 20 a 40 em configuracoes mais agressivas por tenant/contrato
- sempre registrar quantidade capturada, quantidade valida e quantidade descartada

## Suficiencia e decisao operacional

A plataforma deve avaliar se o enrichment esta suficiente para publicar o `Execution Plan` sem resolucao manual.

A decisao deve considerar pelo menos:
- tipologia do imovel definida ou ambigua
- disponibilidade de dados minimos para parametrizacao do job
- consistencia entre case, OCR, pesquisa e fatos humanos aprovados
- qualidade da amostra de comparables
- flags impeditivas de reconciliacao

Estados operacionais minimos esperados:
- `SUFFICIENT_FOR_PLAN`
- `SUFFICIENT_WITH_ALERTS`
- `MANUAL_RESOLUTION_REQUIRED`
- `FAILED`

## Views minimas de backoffice

O backoffice deve possuir ao menos duas visoes para este incremento.

### 1. Lista de enrichment runs
nCampos minimos:
- `caseId`
- status
- quantidade de comparables capturados
- quantidade de comparables validos
- nivel de confianca geral
- necessidade ou nao de revisao humana

### 2. Fila `Jobs a Resolver`
Campos minimos:
- `caseId`
- causa principal da pendencia
- facts reconciliados disponiveis
- dados de OCR disponiveis
- configuracao operacional sugerida
- acao para aprovar ou ajustar o `Execution Plan`

## Endpoints internos minimos

A evolucao incremental deve prever, no minimo:
- `POST /internal/cases/{caseId}/enrichment/trigger`
- `GET /internal/cases/{caseId}/enrichment`
- `GET /internal/cases/{caseId}/job-configuration`
- `POST /internal/cases/{caseId}/documents`
- `POST /internal/cases/{caseId}/documents/process`
- `GET /internal/cases/{caseId}/documents`
- `GET /internal/backoffice/pending-jobs`
- `POST /internal/backoffice/pending-jobs/{pendingId}/resolve`
