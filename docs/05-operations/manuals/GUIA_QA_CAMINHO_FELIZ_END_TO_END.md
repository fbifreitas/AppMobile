# GUIA QA CAMINHO FELIZ END TO END

> [MANUAL ATIVO]
> Este documento ensina como executar o caminho feliz ponta a ponta do AppMobile.
> O objetivo e permitir que um analista de qualidade, operador ou agente consiga sair do embarque do usuario ate o laudo final sem depender de conhecimento de codigo.

## Objetivo

Validar, em um unico roteiro:
- embarque da empresa operadora no backoffice
- inclusao de usuarios administrativos e operacionais
- embarque de usuarios no backoffice
- operacao web minima necessaria
- fluxo mobile de vistoria
- integracao mobile -> backend -> web
- criacao do processo tecnico
- geracao e aprovacao do laudo

## Quando Usar Este Documento

Use este manual quando o objetivo for:
- homologar um pacote funcional ponta a ponta
- validar ambiente de QA ou caixa preta
- executar demonstracao completa do produto
- provar que o fluxo operacional esta fechando do onboarding ao laudo

Nao use este manual como fonte primaria para:
- subir infraestrutura
- release para `main`
- hardening de producao

Nesses casos, use tambem:
- [AMBIENTE_FUNCIONAL_CAIXA_PRETA.md](C:\src\AppMobile\docs\05-operations\runbooks\AMBIENTE_FUNCIONAL_CAIXA_PRETA.md)
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [SEGURANCA_E_HARDENING_PRODUCAO.md](C:\src\AppMobile\docs\05-operations\runbooks\SEGURANCA_E_HARDENING_PRODUCAO.md)

## Resultado Esperado

Ao final deste roteiro, o analista deve sair com:
- operacao backoffice preparada para a empresa
- usuario backoffice operacional valido
- usuario de campo valido e aprovado
- case criado
- job atribuido ao usuario correto
- vistoria enviada pelo mobile
- inspection visivel no backoffice
- valuation process criado e validado
- report gerado
- report aprovado em `READY_FOR_SIGN`

## Escopo Real Atual Do Sistema

Hoje, o caminho feliz operacional esta distribuido assim:

### Web / backoffice

- onboarding e aprovacao de usuarios
- provisionamento administrativo de usuarios
- criacao de case
- atribuicao de job
- acompanhamento de inspection
- validacao de intake
- geracao e revisao de report
- observabilidade operacional

### Mobile

- login do usuario de campo
- recebimento do job atribuido
- execucao da vistoria
- envio final da vistoria para o backend

### Integracao

- backend recebe a vistoria final
- atualiza o job
- persiste a inspection
- cria ou recupera o valuation process
- expoe o fluxo no backoffice

## Variantes Operacionais Da Vistoria

Hoje o fluxo ponta a ponta admite duas variantes validas:

1. `modo guiado`
- a camera segue a arvore/classificacao operacional publicada pelo backend
- obrigatoriedades podem ser cobradas ainda no mobile, conforme a policy do fluxo

2. `modo de captura livre`
- o `check-in etapa 1` continua obrigatorio
- a ativacao real acontece em `Configuracoes`
- no `check-in`, o vistoriador recebe mensagem informativa e registra ciencia
- a camera captura fotos sem classifica-las no app
- a classificacao, as obrigatoriedades e a `etapa 2` passam a ser cobradas na web

## Pre-Requisitos Obrigatorios

Antes de executar o roteiro, valide:

1. ambiente funcional ativo conforme [AMBIENTE_FUNCIONAL_CAIXA_PRETA.md](C:\src\AppMobile\docs\05-operations\runbooks\AMBIENTE_FUNCIONAL_CAIXA_PRETA.md)
2. backoffice acessivel por navegador
3. backend respondendo health
4. app mobile instalado ou build homologado disponivel
5. tenant de teste ativo
6. segredos obrigatorios provisionados
7. dados minimos de QA disponiveis ou capacidade de criacao manual via backoffice

## Perfis Minimos Necessarios

Para este roteiro, o ideal e ter estes atores:

1. usuario backoffice com poder de administracao ou operacao
   - cria usuario
   - importa usuario quando necessario
   - cria case
   - atribui job
   - valida intake
   - gera e revisa report

2. usuario de campo
   - role recomendada: `FIELD_AGENT`
   - status obrigatorio: `APPROVED`
   - tenant igual ao tenant do job

## Regra De Identidade Para Este Guia

Este guia precisa separar dois fluxos diferentes:

1. auto-cadastro no app
- origem esperada: `MOBILE_ONBOARDING`
- usa fila de aprovacao do backoffice

2. cadastro administrativo no backoffice
- origem esperada: `WEB_CREATED` ou `AD_IMPORT`
- usado para usuarios da empresa cliente ou da propria Kaptu
- nao representa o mesmo fluxo de auto-cadastro comercial do app

## Rotas Envolvidas

### Backoffice

- `/`
- `/backoffice/users`
- `/backoffice/users/create`
- `/backoffice/users/import`
- `/backoffice/users/pending`
- `/backoffice/users/audit`
- `/backoffice/config`
- `/backoffice/cases`
- `/backoffice/jobs`
- `/backoffice/inspections`
- `/backoffice/valuation`
- `/backoffice/reports`
- `/backoffice/operations`

### Mobile / backend

- `GET /api/mobile/jobs`
- `POST /api/mobile/inspections/finalized`

## Cenario 0 - Embarcar A Empresa Operadora No Backoffice

Este cenario existe para preparar a operacao antes de qualquer teste de campo.

### Objetivo

Garantir que a empresa que vai operar o sistema tenha:
- usuarios backoffice validos
- usuario de campo aprovado
- trilha de auditoria visivel
- configuracao operacional publicada

### Passo 1. Validar o tenant de operacao

Antes de criar usuarios ou jobs, confirmar:
- qual tenant sera usado no teste
- qual identificador do tenant sera usado nas telas
- qual actor sera usado nas acoes do backoffice

Se o teste usar o tenant padrao do ambiente:
- usar `tenant-default`

### Passo 2. Criar o primeiro usuario backoffice

Passos:
1. abrir `/backoffice/users/create`
2. preencher:
   - `Nome`
   - `E-mail`
   - `Tipo`
   - `Role = ADMIN` ou `OPERATOR`
   - `CPF` ou `CNPJ` quando aplicavel
   - `External ID` opcional
3. clicar em `Criar usuario`
4. abrir `/backoffice/users`
5. confirmar que o usuario aparece com:
   - role correta
   - origem `Web`
   - status `APPROVED`

Resultado esperado:
- a operacao da empresa passa a ter ao menos um usuario backoffice valido

### Passo 3. Criar usuarios adicionais de operacao

Se o cenario exigir mais de um operador:

Opcao A:
- repetir o cadastro em `/backoffice/users/create`

Opcao B:
- abrir `/backoffice/users/import`
- usar payload JSON para importar usuarios em lote
- confirmar o resultado de importacao
- abrir `/backoffice/users`
- validar se os usuarios aparecem com status esperado

Resultado esperado:
- empresa com equipe minima operacional registrada

### Passo 4. Validar a trilha de auditoria de usuarios

Passos:
1. abrir `/backoffice/users/audit`
2. localizar os eventos recentes de criacao, aprovacao ou importacao
3. confirmar:
   - usuario alvo
   - ator
   - correlation id
   - horario

Resultado esperado:
- a trilha administrativa da empresa esta rastreavel

### Passo 5. Publicar a configuracao operacional do app

Antes de mandar o usuario a campo, validar a configuracao:

Passos:
1. abrir `/backoffice/config`
2. revisar o pacote operacional
3. publicar ou aprovar o pacote necessario
4. validar a resolucao efetiva
5. confirmar que o tenant do teste esta coberto

Resultado esperado:
- o app nao depende de configuracao improvisada
- o tenant de teste tem pacote operacional valido

### Passo 6. Escolher qual usuario vai para campo

Ao final do embarque da empresa, o QA precisa ter anotado:
- `tenant`
- usuario backoffice principal
- `userId` do usuario de campo
- role do usuario de campo
- status do usuario de campo

Sem isso, o restante do roteiro fica fraco ou ambíguo.

## Cenario 1 - Preparar O Usuario De Campo

Existem dois caminhos validos.

### Caminho A - Criacao direta no backoffice

Use quando quiser o caminho mais controlado para QA.

Passos:
1. abrir `/backoffice/users/create`
2. preencher:
   - `Nome`
   - `E-mail`
   - `Tipo`
   - `Role = FIELD_AGENT`
   - `CPF` ou `CNPJ` quando aplicavel
   - `External ID` opcional
3. clicar em `Criar usuario`
4. confirmar a mensagem de sucesso
5. abrir `/backoffice/users`
6. confirmar que o usuario aparece com:
   - origem `Web`
   - status `APPROVED`

Resultado esperado:
- usuario criado e aprovado imediatamente

### Caminho B - Onboarding vindo do mobile

Use quando o teste precisa validar tambem a aprovacao do cadastro.

Passos:
1. executar o onboarding no mobile
2. abrir `/backoffice/users/pending`
3. localizar o usuario aguardando aprovacao
4. clicar em `Aprovar`
5. voltar para `/backoffice/users`
6. confirmar que o usuario passou para `APPROVED`

Resultado esperado:
- usuario aparece com origem `Mobile`
- fila de pendencia diminui
- usuario fica apto para atribuicao de job

### Caminho C - Usuario provisionado pelo backoffice para usar o app

Use quando o usuario de campo nao deve se auto-cadastrar no mobile.

Passos:
1. criar o usuario via `/backoffice/users/create`
   - ou `/backoffice/users/import`
2. garantir que ele ficou `APPROVED`
3. autenticar no mobile com esse usuario
4. validar se o app nao exige repetir o auto-cadastro comercial
5. validar apenas as etapas residuais de primeiro acesso que forem obrigatorias

Resultado esperado:
- usuario provisionado entra no app por fluxo de ativacao ou primeiro acesso
- nao refaz o cadastro comercial do `MOBILE_ONBOARDING`
- segue para uso operacional apos concluir etapas residuais exigidas

### Validacao final antes de seguir

Antes de ir para criacao de case, confirmar em `/backoffice/users`:
- usuario de campo existe
- status e `APPROVED`
- role e `FIELD_AGENT`
- tenant e o mesmo tenant do teste

### Problemas comuns nesta etapa

#### Usuario nao aparece para atribuicao depois de criado

Verificar:
- role correta
- status `APPROVED`
- tenant correto

#### Job falha ao atribuir ao usuario

Causa mais provavel:
- usuario nao esta `APPROVED`
- usuario pertence a outro tenant

#### A operacao ainda nao tem usuario backoffice suficiente

Voltar para:
- `/backoffice/users/create`
- ou `/backoffice/users/import`

E concluir o embarque da empresa antes de seguir

## Cenario 2 - Criar O Atendimento No Backoffice

Passos:
1. abrir `/backoffice/cases`
2. preencher:
   - `Tenant`
   - `Actor`
   - `Numero do case`
   - `Endereco do imovel`
   - `Tipo de vistoria`
   - `Deadline` opcional
   - `Titulo do job inicial`
3. clicar em `Criar case`
4. registrar o retorno:
   - `caseNumber`
   - `caseId`
   - `jobId`
   - `jobStatus`
5. clicar em `Ir para fila de jobs`

Resultado esperado:
- case criado
- job inicial criado
- job aparece com status inicial de despacho

## Cenario 3 - Atribuir O Job Ao Usuario De Campo

Passos:
1. abrir `/backoffice/jobs`
2. filtrar pelo tenant correto
3. localizar o `jobId` criado
4. clicar em `Detalhe`
5. confirmar que o job esta apto para atribuicao
6. preencher o campo de atribuicao com o `userId` do usuario de campo aprovado
7. executar a acao de `Assign`
8. revisar o detalhe do job e a timeline

Resultado esperado:
- `assignedTo` passa a apontar para o usuario correto
- status do job avanca para `OFFERED`
- timeline registra a atribuicao

### Evidencia que o QA deve guardar

- `jobId`
- `caseId`
- `assignedTo`
- status do job apos atribuicao

### Problemas comuns nesta etapa

#### Erro de atribuicao

Verificar:
- `userId` numerico correto
- usuario no mesmo tenant
- usuario `APPROVED`

#### Job nao aparece na lista

Verificar:
- filtro de tenant
- paginacao

## Cenario Adicional - Validar Captura Livre Ponta A Ponta

Use este cenario quando o objetivo for provar que o app pode coletar imagens sem classifica-las no campo e transferir a consolidacao para a web.

### Preparacao

1. no app, abrir `Configuracoes`
2. habilitar `Modo de captura livre`
3. garantir que o tenant usado no teste possui acesso ao backoffice web

### Execucao no mobile

1. iniciar a vistoria normalmente
2. preencher o `check-in etapa 1`
3. confirmar a mensagem informativa de que o modo livre esta ativo
4. abrir a camera
5. capturar imagens sem classifica-las
6. finalizar a vistoria

Resultado esperado:
- a camera nao exige selecao de arvore/classificacao
- a revisao/finalizacao no app nao bloqueiam por obrigatoriedade
- o envio conclui e a inspection chega ao backoffice

### Validacao no backoffice

1. abrir `/backoffice/inspections`
2. localizar a inspection recem-enviada
3. abrir `Detalhe`
4. confirmar que a vistoria foi recebida como pendente de classificacao manual
5. classificar as imagens manualmente
6. validar a matriz de obrigatoriedade
7. preencher a `etapa 2` quando o fluxo exigir

Resultado esperado:
- a web passa a ser o local de consolidacao da vistoria
- a classificacao manual e obrigatoria
- obrigatoriedades continuam sendo respeitadas
- `etapa 2` continua sendo respeitada quando habilitada

### Evidencias Minimas Adicionais Para O Modo Livre

Registrar:
- screenshot do aviso de `modo de captura livre` no check-in
- screenshot da camera aberta sem arvore de classificacao
- screenshot da inspection na web aguardando classificacao manual
- screenshot da tela web de classificacao manual com a matriz de obrigatoriedade visivel
- status selecionado

## Cenario 4 - Aceite E Execucao No Mobile

Esta etapa acontece no app.

Passos:
1. logar no mobile com o usuario de campo aprovado
2. abrir a lista de jobs disponiveis para o usuario
3. localizar o job atribuido
4. aceitar o job no app
5. executar a vistoria completa
6. preencher o conteudo obrigatorio do fluxo
7. finalizar a vistoria
8. enviar a vistoria

Resultado esperado:
- o app conclui o envio sem erro estrutural
- a resposta final do backend retorna:
  - `protocolId`
  - `processId`
  - `jobId`
  - `status`
  - `receivedAt`
- o job e avancado no backend ate `SUBMITTED`

### O que e obrigatorio aqui

O actor do mobile precisa ser:
- o mesmo usuario atribuido ao job
- um usuario aprovado
- um usuario do mesmo tenant

### Problemas comuns nesta etapa

#### O app nao consegue aceitar ou enviar o job

Verificar:
- job realmente atribuido ao mesmo usuario
- usuario `APPROVED`
- tenant coerente
- build do app apontando para o backend correto

#### Reenvio gera conflito

Verificar:
- reuso indevido de `X-Idempotency-Key`
- payload alterado com a mesma chave

## Cenario 5 - Confirmar A Inspecao No Backoffice

Passos:
1. abrir `/backoffice/inspections`
2. localizar a vistoria recem enviada
3. abrir `Detalhe`
4. revisar:
   - `jobId`
   - `protocolId`
   - `status`
   - `idempotencyKey`
   - payload final

Resultado esperado:
- a inspection aparece na tabela
- o payload esta persistido
- `protocolId` e `jobId` batem com o retorno do mobile

### Problemas comuns nesta etapa

#### A vistoria nao apareceu

Verificar:
- app realmente recebeu sucesso no envio
- ambiente mobile apontando para a API correta
- rota `POST /api/mobile/inspections/finalized` sem erro
- tenant/filtros da tela

## Cenario 6 - Criar Ou Recuperar O Processo Tecnico

Passos:
1. abrir `/backoffice/valuation`
2. informar `Inspection ID`
3. opcionalmente informar `Assigned analyst ID`
4. clicar em `Create or recover`
5. abrir o processo

Resultado esperado:
- process criado ou recuperado
- status inicial disponivel para intake
- `inspectionId` corretamente vinculado

Observacao importante:
- em muitos cenarios o backend ja cria esse processo automaticamente ao receber a inspection
- esta tela tambem existe para recuperar ou consolidar o processo no fluxo operacional

## Cenario 7 - Validar O Intake

Passos:
1. ainda em `/backoffice/valuation`, abrir o processo
2. revisar:
   - `Process ID`
   - `Inspection ID`
   - `Status`
   - `Assigned analyst`
3. na caixa `Validate intake`, preencher:
   - `Result = VALIDATED`
   - `Notes`
   - `Issues JSON`
4. clicar em `Submit intake validation`

Resultado esperado:
- mensagem de sucesso
- `latestIntakeValidation` preenchido
- status do processo avanca para o proximo ponto do fluxo tecnico

### Problemas comuns nesta etapa

#### Validacao falha

Verificar:
- `Inspection ID` correto
- processo realmente aberto
- `Issues JSON` em formato JSON valido

## Cenario 8 - Gerar O Laudo

Passos:
1. abrir `/backoffice/reports`
2. informar `Valuation process ID`
3. clicar em `Generate draft`
4. abrir o report gerado
5. revisar:
   - `Report ID`
   - `Process ID`
   - `Status`
   - `Generated by`
   - conteudo do report

Resultado esperado:
- report criado com status `GENERATED`
- conteudo carregado no painel de detalhe

## Cenario 9 - Revisar E Aprovar O Laudo

Passos:
1. ainda em `/backoffice/reports`, abrir o report gerado
2. em `Review report`, preencher:
   - `Action = APPROVE`
   - `Notes`
3. clicar em `Submit review`
4. recarregar a lista
5. confirmar o novo status

Resultado esperado:
- report aprovado
- processo tecnico avanca para `READY_FOR_SIGN`

### Alternativa controlada

Se quiser validar retorno para correcao:
- usar `RETURN_FOR_CHANGES`

Mas isso nao faz parte do caminho feliz principal.

## Cenario 10 - Validar Observabilidade E Fechamento

Passos:
1. abrir `/backoffice/operations`
2. revisar cards de saude
3. localizar eventos relacionados usando:
   - `protocolId`
   - `jobId`
   - `processId`
   - `reportId`
4. confirmar que o fluxo deixou rastros operacionais

Resultado esperado:
- eventos e metricas carregam
- a operacao consegue rastrear o caminho do envio ao laudo

## Checklist Do Caminho Feliz

Considere o teste aprovado somente se todos os itens abaixo ficarem `ok`:

1. usuario de campo criado ou aprovado
2. usuario aparece como `APPROVED`
3. case criado com sucesso
4. job criado com `jobId` rastreavel
5. job atribuido ao usuario correto
6. mobile localiza o job
7. mobile aceita e envia a vistoria
8. inspection aparece no backoffice
9. valuation process existe
10. intake foi validado
11. report foi gerado
12. report foi aprovado
13. status final ficou em `READY_FOR_SIGN`
14. control tower mostra o rastro operacional

## Evidencia Minima Que O QA Deve Registrar

Ao final da execucao, registrar:
- ambiente usado
- tenant usado
- usuario de campo usado
- `userId`
- `caseId`
- `jobId`
- `protocolId`
- `inspectionId`
- `valuationProcessId`
- `reportId`
- status final do report/process
- prints ou evidencias das telas principais
- qualquer anomalia encontrada

## O Que Fazer Se O Fluxo Travar

Use esta ordem de diagnostico:

1. `/backoffice/users`
2. `/backoffice/jobs`
3. `/backoffice/inspections`
4. `/backoffice/valuation`
5. `/backoffice/reports`
6. `/backoffice/operations`

Perguntas objetivas:

1. o usuario esta aprovado?
2. o job foi atribuido ao usuario certo?
3. o mobile estava apontando para o ambiente correto?
4. a inspection foi persistida?
5. o valuation process foi criado?
6. o report foi gerado?
7. a control tower registrou o evento?

## Limitacoes Atuais

Hoje este roteiro ainda depende de alguns cuidados manuais:
- nao ha seed unico de QA para gerar todo o cenario por comando unico
- o aceite do job acontece no mobile, nao no backoffice
- parte da navegacao mobile depende do build e do ambiente configurado corretamente
- o fluxo de assinatura final do laudo ainda nao esta fechado neste manual

## Regra De Atualizacao Deste Manual

Este manual deve ser revisado sempre que houver mudanca em:
- onboarding de usuarios
- regras de aprovacao
- criacao de case/job
- fluxo mobile de aceite ou envio
- campos obrigatorios de intake
- geracao ou revisao de report
- rotas de observabilidade operacional
