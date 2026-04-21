# Validacao Final do Fluxo Configuravel de Vistoria

Atualizado em: 2026-04-12

## Objetivo

Executar a validacao ponta a ponta do fluxo configuravel de vistoria no ambiente real local, cobrindo:

- `web`
- `backend`
- `mobile`

## Regra funcional esperada

1. `check-in etapa 1` e obrigatorio para abrir a camera
2. `check-in etapa 2` pode ser obrigatorio para entrega
3. `check-in etapa 2` nao pode bloquear a camera quando `bloqueiaCaptura = false`
4. a revisao deve bloquear `Finalizar vistoria` enquanto a pendencia obrigatoria de `step2` estiver aberta

## Variante A - Modo guiado

O comportamento original continua valido:
- a camera segue o fluxo configuravel
- a arvore operacional vem do backend
- a revisao bloqueia a entrega quando houver pendencia obrigatoria prevista pela policy

## Pre-condicoes

1. stack docker local saudavel
2. `api` healthy
3. `web` healthy
4. app mobile carregando pacote dinamico atualizado

Comando util:

```powershell
docker compose -f infra\docker-compose.yml ps
```

## Configuracao alvo no web

Abrir:

- `http://localhost/backoffice/config`

Publicar pacote no escopo `tenant` com os seguintes pontos:

### `Step 1`

- tipo: `Urbano`
- subtipo: `Apartamento`
- contexto inicial: `Rua`

### `Step 2`

- `visivelNoFluxo = true`
- `obrigatoriaParaEntrega = true`
- `bloqueiaCaptura = false`
- ao menos um campo obrigatorio de foto

Exemplo minimo:

- `id = fachada`
- `titulo = Fachada`
- `cameraMacroLocal = Rua`
- `cameraAmbiente = Fachada`
- `obrigatorio = true`

Depois:

1. `Publicar para aprovacao`
2. `Aprovar`

## Validacao no app

### Parte A - Camera nao bloqueada

1. voltar para a Home
2. executar refresh
3. iniciar uma vistoria
4. preencher `Step 1`
5. sem cumprir integralmente a `Etapa 2`, tocar em `Confirmar e abrir a camera`

Resultado esperado:

- a camera abre
- nao aparece bloqueio modal exigindo conclusao previa da `Etapa 2`

### Parte B - Entrega bloqueada

1. sair da camera e seguir para revisao
2. manter ao menos uma pendencia obrigatoria de `Step 2` em aberto
3. abrir a revisao final

Resultado esperado:

- aparece bloco `Pendências para encerrar`
- aparece CTA `Ir para captura`
- aparece mensagem `Conclua os itens pendentes para finalizar.`
- botao `Finalizar vistoria` fica desabilitado

## Evidencias minimas

Registrar:

1. screenshot da tela web com o pacote aprovado
2. screenshot do app abrindo a camera com `step2` pendente
3. screenshot da revisao com botao de finalizacao bloqueado
4. resultado dos testes automatizados abaixo

## Testes automatizados de apoio

```powershell
C:\src\flutter\bin\flutter.bat test --no-pub test\screens\checkin_flow_navigation_test.dart
```

```powershell
C:\src\flutter\bin\flutter.bat test --no-pub test\screens\inspection_review_screen_test.dart
```

```powershell
C:\src\flutter\bin\flutter.bat test --no-pub test\services\checkin_dynamic_config_service_test.dart
```

## Criterio de encerramento

O fluxo so pode ser considerado validado quando as duas afirmacoes forem verdadeiras ao mesmo tempo:

1. a camera abre com `step2` ainda incompleta
2. a entrega continua bloqueada na revisao enquanto a pendencia obrigatoria nao for resolvida

## Variante B - Modo de captura livre

### Regra funcional esperada

1. `check-in etapa 1` continua obrigatorio
2. o `modo de captura livre` e ativado em `Configuracoes`
3. no `check-in`, o app mostra aviso informativo e registra ciencia do vistoriador
4. a camera abre sem exigir classificacao no mobile
5. obrigatoriedades deixam de bloquear a finalizacao no mobile
6. a cobranca migra para a web em `/backoffice/inspections`

### Validacao no app

1. habilitar `Modo de captura livre` em `Configuracoes`
2. iniciar uma vistoria
3. preencher o `check-in etapa 1`
4. confirmar a mensagem de ciencia do modo livre
5. abrir a camera
6. capturar imagens sem usar menu/arvore
7. finalizar e enviar a vistoria

Resultado esperado:
- a camera abre em modo livre
- o app nao exige classificacao das fotos
- a revisao/finalizacao nao bloqueiam por obrigatoriedade

### Validacao na web

1. abrir `/backoffice/inspections`
2. localizar a inspection recebida
3. abrir `Detalhe`
4. confirmar que a classificacao manual esta pendente
5. classificar as imagens
6. revisar a matriz de obrigatoriedade
7. preencher `etapa 2` quando exigida

Resultado esperado:
- a web exige a classificacao manual posterior
- as obrigatoriedades continuam valendo
- `etapa 2` continua sendo exigida quando habilitada no fluxo

### Criterio de encerramento da variante livre

O fluxo so pode ser considerado validado quando as tres afirmacoes forem verdadeiras ao mesmo tempo:

1. o mobile permite capturar e enviar sem classificar
2. a inspection aparece na web aguardando classificacao manual
3. a web exige obrigatoriedades e `etapa 2` quando a policy determinar

## Risco residual conhecido

No ambiente local atual existe um comportamento conhecido no web:

- apos `rollback`, uma nova publicacao pode falhar ate refazer login

Esse ponto nao invalida a regra funcional do fluxo, mas deve ser tratado separadamente como follow-up operacional.
