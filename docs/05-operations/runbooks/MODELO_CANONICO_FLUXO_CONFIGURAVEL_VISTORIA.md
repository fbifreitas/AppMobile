# Modelo Canonico do Fluxo Configuravel de Vistoria

## Objetivo

Consolidar a regra funcional e tecnica do fluxo configuravel de vistoria para que:

- `check-in etapa 1`
- `check-in etapa 2`
- `camera`
- `revisao`
- `pendencias`

consumam a mesma base semantica sem misturar arvore de captura com exigencias normativas.

## Principios

1. O app nao e dono da taxonomia.
2. O backoffice monta a configuracao de forma guiada.
3. O backend resolve o payload efetivo por escopo.
4. O app consome esse payload como caminho principal.
5. `check-in etapa 1` e obrigatorio para iniciar a captura.
6. `check-in etapa 2` pode ser obrigatorio para entrega, mas nao bloqueia a camera.
7. O fluxo de vistoria continua sendo especializacao do dominio `inspection` sobre capacidades mais horizontais da plataforma.
8. O plano operacional consumido pelo app deve nascer do backend/plataforma como `Execution Plan` derivado.

## Modelo canonico

O fluxo possui dois blocos complementares, mas distintos.

### 1. Arvore de captura

Usada por:

- `check-in etapa 1`
- `camera`
- `revisao das evidencias`
- `menu operacional`

Dimensoes canonicas:

1. `contextoDeCaptura`
2. `itemAlvo`
3. `atributoOuTipo`
4. `condicaoOuEstado`

Exemplo no dominio de imoveis:

- `contextoDeCaptura` -> `Rua`, `Area externa`, `Area interna`
- `itemAlvo` -> `Fachada`, `Quarto`, `Cozinha`, `Portao`
- `atributoOuTipo` -> `Alvenaria`, `Madeira`, `Metal`
- `condicaoOuEstado` -> `Bom`, `Regular`, `Ruim`

Exemplo de labels por surface:

- `check-in etapa 1`: `Por onde deseja comecar?`
- `camera`: `Area da foto`
- `surface futura`: `Onde estou?`

Os labels podem variar por tela. A chave semantica por tras deve ser a mesma.

### 2. Matriz normativa e operacional

Usada por:

- `check-in etapa 2`
- `revisao`
- `pendencias para encerrar`
- `bloqueio de entrega`

Essa matriz contem:

- campos obrigatorios
- minimos de foto
- grupos de opcoes
- itens da norma
- regras da empresa contratante
- requisitos que podem apontar para evidencias da camera

Esses itens nao precisam fazer parte da arvore de captura.

## Papel de cada etapa

### Check-in etapa 1

Seleciona duas coisas:

- `ramo estrutural do dominio`
  - exemplo: `Urbano -> Apartamento`
- `contexto inicial de captura`
  - exemplo: `Rua`

Regra:

- obrigatorio para abrir a camera
- deve ser rapido e de baixo atrito
- serve como bootstrap da arvore seguinte

### Camera

Consome a arvore de captura correspondente ao ramo escolhido no `check-in etapa 1`.

Regra:

- abre no `contexto inicial de captura`
- nao fica travada nesse contexto
- deve permitir deslocamento livre do vistoriador
- deve preservar contexto atual e contexto de retomada

### Check-in etapa 2

Consome a matriz normativa e operacional.

Regra:

- visibilidade configuravel
- obrigatoriedade configuravel
- obrigatoriedade de `etapa 2` significa bloqueio de entrega, nao bloqueio de camera
- pode apontar para evidencias da camera sem entrar na arvore de captura

Flags canonicas recomendadas para o contrato:

- `visivelNoFluxo`
- `obrigatoriaParaEntrega`
- `bloqueiaCaptura`

Compatibilidade atual:

- `obrigatoriaNoFluxo` deve ser interpretado como `obrigatoriaParaEntrega`
- `bloqueiaCaptura` deve ser explicito e default `false`

## Vinculo com o incremento atual de plataforma

O programa atual adiciona uma camada acima do fluxo configuravel de vistoria.

Essa camada deve:
- consolidar facts de case, OCR, pesquisa e campo
- gerar `Execution Plan` para o app
- publicar configuracao operacional pronta para consumo
- receber o retorno do App Mobile como evidencia estruturada
- preparar a base progressiva do report e da trilha analytics-ready

Importante:
- isso nao muda o modelo canonico do fluxo configuravel
- isso melhora a qualidade da configuracao publicada para o app

## Artefatos operacionais vinculados

- `docs/05-operations/runbooks/PAINEL_MILESTONES_FLUXO_CONFIGURAVEL_VISTORIA.md`
- `docs/05-operations/runbooks/VALIDACAO_FINAL_FLUXO_CONFIGURAVEL_VISTORIA.md`
- `docs/05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md`

### Revisao

Consolida:

- composicao/evidencias vindas da arvore de captura
- pendencias normativas e operacionais da `etapa 2`

Regra:

- pode bloquear a entrega quando faltarem itens obrigatorios
- nao deve recriar regra paralela fora da configuracao efetiva

## Cadastro web

O backoffice deve operar com tres camadas:

1. `catalogo base por vertical`
   - `imoveis`
   - `veiculos`
   - outras verticais futuras

2. `customizacao por tenant`
   - ativar/desativar itens sugeridos
   - renomear labels
   - incluir novos itens por nivel
   - incluir novos niveis

3. `matriz de uso por etapa`
   - onde aparece
   - se e obrigatorio
   - se bloqueia captura ou entrega
   - min/max de fotos
   - vinculos com revisao e pendencias

## Invariantes de implementacao

1. Adicionar novo dominio nao pode quebrar a arvore.
2. Novo item deve declarar:
   - em qual nivel entra
   - quem e o pai
   - se participa da camera
   - se participa da revisao
   - se e operacional ou analitico
3. `check-in etapa 2` nao deve ser modelado como ramo artificial da camera.
4. `check-in etapa 1` deve continuar sendo a entrada obrigatoria do fluxo de captura.
5. Recovery deve distinguir:
   - estado inicial sugerido
   - estado atual
   - estado de retomada

## Reflexo imediato no codigo

### Regra funcional adotada agora

- `check-in etapa 1` continua obrigatorio para abrir a camera
- `check-in etapa 2` deixa de bloquear `Confirmar e abrir a camera`
- `check-in etapa 2` continua elegivel para bloqueio na revisao e entrega

### Backlog relacionado

- `BL-052`: pacote unificado de parametrizacao do check-in e camera
- `BL-057`: semantica canonica unica entre check-in, camera, revisao e menu
- `BL-058`: separar estado inicial, estado atual e retomada
- `BOW-130`: consumo mobile da configuracao real como caminho principal
- `BL-080`: programa incremental de backend/plataforma para enrichment, OCR, reconciliacao, smart app derivado e analytics-ready trail
