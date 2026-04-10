# MANUAL OPERACIONAL BACKOFFICE

> [MANUAL ATIVO]
> Este documento explica como navegar no backoffice e operar os fluxos principais do sistema.

## Objetivo

Permitir que um operador ou gestor entenda:
- quais telas existem
- para que serve cada uma
- em que ordem usar
- como o fluxo sai do mobile e chega ao web

Para um roteiro completo de QA ponta a ponta, do embarque do usuario ate o laudo final, usar tambem:
- [GUIA_QA_CAMINHO_FELIZ_END_TO_END.md](C:\src\AppMobile\docs\05-operations\manuals\GUIA_QA_CAMINHO_FELIZ_END_TO_END.md)

## Visao Geral Do Fluxo

Fluxo principal atual:
1. o operador finaliza a vistoria no mobile
2. o mobile envia a vistoria ao backend
3. o backend cria ou recupera o processo de valuation
4. o backoffice recebe e opera:
   - inspections
   - jobs
   - valuation
   - reports
   - operations

## Regra Importante De Identidade

Hoje existem dois modelos distintos de entrada de usuario:

1. `MOBILE_ONBOARDING`
- o usuario se cadastra pelo app para pedir acesso
- normalmente nasce pendente de aprovacao
- a aprovacao e operada pelo backoffice

2. `WEB_CREATED` ou `AD_IMPORT`
- o usuario e criado administrativamente pelo backoffice
- pode representar usuario da empresa cliente ou usuario interno da Kaptu
- nao deve depender do mesmo fluxo de auto-cadastro comercial do app

Leitura pratica:
- `users/pending` governa principalmente o funil de aprovacao do `MOBILE_ONBOARDING`
- `users/create` e `users/import` governam o provisionamento administrativo

## Tela Inicial

Rota:
- `/`

Funcao:
- dashboard principal do backoffice
- ponto de entrada para os modulos operacionais

Links principais:
- `/backoffice/users`
- `/backoffice/users/audit`
- `/backoffice/users/pending`
- `/backoffice/inspections`
- `/backoffice/config`
- `/backoffice/jobs`
- `/backoffice/cases`
- `/backoffice/valuation`
- `/backoffice/reports`
- `/backoffice/operations`

## Fluxo 1 - Configuracao Operacional

Rota:
- `/backoffice/config`

Uso basico:
1. abrir a central de configuracao
2. revisar pacote
3. publicar ou aprovar
4. validar a resolucao efetiva
5. se necessario, executar rollback

## Fluxo 2 - Criacao De Cases

Rota:
- `/backoffice/cases`

Uso basico:
1. preencher os dados do case
2. clicar em `Criar case`
3. verificar o retorno com:
   - `caseNumber`
   - `caseId`
   - `jobId`
   - `jobStatus`
4. seguir para `/backoffice/jobs`

## Fluxo 3 - Operacao De Jobs

Rota:
- `/backoffice/jobs`

Uso basico:
1. aplicar filtros
2. abrir um job em `Detalhe`
3. revisar:
   - status
   - case
   - prazo
   - assignments
   - timeline
4. atribuir um usuario em `Assign`
5. se necessario, cancelar o job

## Fluxo 4 - Vistorias Recebidas

Rota:
- `/backoffice/inspections`

Uso basico:
1. aplicar filtros
2. revisar a tabela de inspections
3. abrir `Detalhe`
4. verificar:
   - `jobId`
   - `protocolId`
   - `status`
   - `idempotencyKey`
   - payload completo

## Fluxo 5 - Valuation Intake

Rota:
- `/backoffice/valuation`

Uso basico:
1. informar `Inspection ID`
2. opcionalmente informar `Assigned analyst ID`
3. clicar em `Create or recover`
4. abrir o processo
5. preencher validacao de intake
6. enviar validacao

## Fluxo 6 - Reports

Rota:
- `/backoffice/reports`

Uso basico:
1. informar `Valuation process ID`
2. clicar em `Generate draft`
3. abrir o report
4. revisar conteudo
5. escolher:
   - `APPROVE`
   - `RETURN_FOR_CHANGES`
6. enviar revisao

## Fluxo 7 - Control Tower Operacional

Rota:
- `/backoffice/operations`

Uso basico:
1. abrir a control tower
2. revisar cards de saude
3. revisar alertas ativos
4. localizar endpoint com erro
5. revisar eventos recentes com:
   - `protocolId`
   - `jobId`
   - `processId`
   - `reportId`
6. rodar retention cleanup quando aplicavel

## Ordem Recomendada De Navegacao Por Cenario

### Cenario A - Configurar o app antes do uso

1. `/backoffice/config`
2. validar rollout
3. publicar ou aprovar

### Cenario B - Criar atendimento manualmente

1. `/backoffice/cases`
2. `/backoffice/jobs`

### Cenario C - Confirmar que uma vistoria enviada chegou

1. `/backoffice/inspections`
2. `/backoffice/valuation`

### Cenario D - Avancar o ciclo tecnico

1. `/backoffice/valuation`
2. `/backoffice/reports`

### Cenario E - Investigar problema operacional

1. `/backoffice/operations`
2. `/backoffice/inspections`
3. `/backoffice/jobs`
4. `/backoffice/valuation`
5. `/backoffice/reports`

## Regra De Atualizacao Deste Manual

Este manual deve ser revisado sempre que houver mudanca em:
- rotas do backoffice
- fluxo principal entre telas
- nomenclatura de acao ou status
- campos obrigatorios para operacao
