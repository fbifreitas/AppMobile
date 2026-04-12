# AMBIENTE FUNCIONAL DE CAIXA PRETA

> [RUNBOOK ATIVO]
> Este documento ensina a subir um ambiente funcional para teste de caixa preta do AppMobile.
> O foco e permitir que qualquer pessoa ou agente consiga colocar o sistema no ar, validar o fluxo ponta a ponta e saber o que revisar antes de iniciar os testes.

## Objetivo

Sair de:
- codigo no repositorio
- servicos isolados
- validacao so por teste tecnico

Para:
- ambiente funcional completo
- backend, web, banco e cache ativos
- segredos provisionados corretamente
- smoke funcional executavel
- fluxo pronto para validacao humana ou automatizada

## Quando Usar Este Documento

Use este runbook quando o objetivo for:
- validar o sistema ponta a ponta como usuario final ou operador
- preparar ambiente de homologacao funcional
- executar teste de caixa preta local ou em VPS
- entregar um ambiente de demonstracao interna
- preparar uma sessao de QA, negocio ou validacao operacional

Nao use este documento como fonte primaria para:
- release e promocao para `main`
- publicacao em loja
- hardening completo de producao

Nesses casos, use tambem:
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md](C:\src\AppMobile\docs\05-operations\runbooks\IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md)
- [SEGURANCA_E_HARDENING_PRODUCAO.md](C:\src\AppMobile\docs\05-operations\runbooks\SEGURANCA_E_HARDENING_PRODUCAO.md)
- [GESTAO_DE_SEGREDOS_E_COFRE.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_SEGREDOS_E_COFRE.md)

## O Que E Um Ambiente Funcional De Caixa Preta

Neste projeto, um ambiente funcional de caixa preta e um ambiente onde a pessoa nao precisa conhecer o codigo para validar o fluxo.

Ele precisa ter, no minimo:
- web/backoffice acessivel por navegador
- backend acessivel pela web
- banco PostgreSQL funcional
- Redis funcional
- segredos obrigatorios provisionados
- dados minimos para navegar no sistema
- forma de instalar ou acessar o app candidato quando o teste envolver mobile

## Topologia Minima Do Ambiente

### Servicos obrigatorios

- `proxy`: nginx
- `web`: Next.js
- `api`: Spring Boot
- `db`: PostgreSQL
- `cache`: Redis

### Arquivos base usados

- Compose: [docker-compose.yml](C:\src\AppMobile\infra\docker-compose.yml)
- Variaveis: [\.env.example](C:\src\AppMobile\infra\.env.example)
- Script local: [start_local_stack.ps1](C:\src\AppMobile\infra\scripts\start_local_stack.ps1)
- Setup VPS: [vps-setup.sh](C:\src\AppMobile\infra\scripts\vps-setup.sh)

## Pre-Requisitos Obrigatorios

### Para ambiente local

- Docker Desktop instalado e funcionando
- PowerShell
- portas `80`, `443`, `3000`, `8080`, `5432` e `6379` sem conflito relevante
- cofre local operacional via `Get-Secret`; para teste funcional de caixa preta este e o caminho padrao de segredos

### Para ambiente em VPS

- VPS Linux funcional
- Docker e Docker Compose plugin
- dominio ou subdominio apontado para a VPS
- acesso SSH
- segredos provisionados fora do codigo

### Segredos minimos

Sem estes segredos o ambiente nao deve ser tratado como valido:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `AUTH_JWT_SECRET`
- `INTEGRATION_CONFIG_SIGNING_HMAC_KEY`

Fonte primaria:
- [GESTAO_DE_SEGREDOS_E_COFRE.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_SEGREDOS_E_COFRE.md)

## Caminho Recomendado

O caminho mais seguro para validar o ambiente e este:

1. subir primeiro o ambiente local funcional
2. validar smoke de navegador e backend
3. ajustar segredos, DNS e urls
4. subir o ambiente homolog em VPS
5. repetir o smoke funcional
6. so depois abrir sessao de QA, negocio ou validacao de caixa preta

## Parte 1 - Subida Local Para Caixa Preta

### Passo 1. Preparar o arquivo de ambiente

Se o arquivo ainda nao existir:

```powershell
Copy-Item infra\.env.example infra\.env
```

Revise pelo menos estes campos em `infra/.env`:
- `POSTGRES_DB`
- `POSTGRES_USER`
- `APP_BASE_URL`
- `API_BASE_URL`
- `WEB_BACKOFFICE_API_BASE_URL`
- `STORAGE_ADAPTER`

Observacao:
- nao grave segredos reais no arquivo versionado
- para teste funcional de caixa preta, trate o cofre local como obrigatorio; variavel de sessao ou prompt seguro ficam como fallback tecnico, nao como caminho principal

### Passo 2. Provisionar segredos locais

Opcao obrigatoria para este teste funcional no Windows:
- PowerShell SecretManagement + SecretStore

Segredos minimos esperados pelo script local:
- `AppMobile/PostgresPassword`
- `AppMobile/RedisPassword`
- `AppMobile/JwtSecret`
- `AppMobile/IntegrationConfigSigningHmacKey`
- `AppMobile/PlatformBootstrapAdminPassword` quando `PLATFORM_BOOTSTRAP_ENABLED=true`

### Passo 3. Subir a stack local

```powershell
powershell -ExecutionPolicy Bypass -File infra\scripts\start_local_stack.ps1
```

Esse script:
- carrega `infra/.env`
- resolve segredos
- sobe `proxy`, `web`, `api`, `db` e `cache`
- injeta as variaveis `COMPOSE_PLATFORM_BOOTSTRAP_*` so na sessao do script quando o bootstrap da plataforma estiver completo
- habilita `AUTH_FIRST_ACCESS_EXPOSE_DEBUG_OTP=true` apenas na sessao local usada para o ambiente funcional de caixa preta
- usa `docker compose up --force-recreate` para garantir que mudancas de flags/segredos de ambiente entrem de fato nos containers ja existentes
- nao forca rebuild das imagens; depois de alterar codigo do `web`, `api` ou `proxy`, execute `docker compose -f infra\docker-compose.yml build <servico>` antes de subir a stack

Compatibilidade da stack local:
- o banco oficial do ambiente funcional local deve permanecer em `postgres:15-alpine` no [`infra/docker-compose.yml`](C:\src\AppMobile\infra\docker-compose.yml)
- o backend precisa manter `org.flywaydb:flyway-database-postgresql` no classpath para bootstrap com PostgreSQL real
- migrations SQL usadas no bootstrap PostgreSQL local devem usar tipos compatíveis com Postgres, como `TEXT` no lugar de `CLOB`

- o proxy local em [`infra/nginx/nginx.conf`](C:\src\AppMobile\infra\nginx\nginx.conf) deve encaminhar `/api/actuator/*` para o backend Java e o restante de `/api/*` para o Next.js, preservando as rotas `app/api/*` do backoffice web
- o proxy local em [`infra/nginx/nginx.conf`](C:\src\AppMobile\infra\nginx\nginx.conf) tambem deve encaminhar `/auth/*` e `/api/mobile/*` para o backend Java, porque esses contratos sao usados diretamente pelo app mobile Compass quando `APP_API_BASE_URL` aponta para `http://localhost`
- o bootstrap correto do caminho de plataforma usa `PLATFORM_BOOTSTRAP_ENABLED=true` no `.env`, tenant inicial `tenant-platform` e credencial do `PLATFORM_ADMIN` resolvida por segredo em `PLATFORM_BOOTSTRAP_ADMIN_PASSWORD`
- o container `api` so deve receber bootstrap de plataforma pelas variaveis `COMPOSE_PLATFORM_BOOTSTRAP_*` injetadas pelo [`start_local_stack.ps1`](C:\src\AppMobile\infra\scripts\start_local_stack.ps1); rodar `docker compose up` direto pode subir a stack, mas nao deve ser usado para inicializar o `PLATFORM_ADMIN`
- no container `web`, o backend interno deve apontar para `http://api:8080` e `http://api:8080/api`, nunca para `localhost:8080`

Registro operacional local em 2026-04-11:
- `BUG-E2E-COMPASS-003`: bootstrap local quebrava por incompatibilidade Flyway/PostgreSQL; corrigido com suporte PostgreSQL no Flyway e baseline local em `postgres:15-alpine`
- `BUG-E2E-COMPASS-006`: migrations usavam `CLOB`, incompatível com PostgreSQL real; corrigido para `TEXT`
- `BUG-E2E-COMPASS-008`: proxy local encaminhava todo `/api/*` para o backend Java e bloqueava as rotas `app/api/*` do backoffice web; corrigido separando `/api/actuator/*` para backend e mantendo o restante de `/api/*` no Next.js
- `BUG-E2E-COMPASS-009`: a primeira correcao do proxy local quebrou `GET /api/actuator/health` por reescrita incorreta de caminho; corrigido encaminhando `/api/actuator/*` para `/actuator/*` no backend Java
- `BUG-E2E-COMPASS-010`: ambiente limpo nao tinha `PLATFORM_ADMIN` nem credenciais para iniciar o login correto da plataforma; corrigido com bootstrap configuravel de `PLATFORM_ADMIN`
- `BUG-E2E-COMPASS-011`: superficie de plataforma nao permitia criar tenant do zero; corrigido com criacao de tenant pela propria trilha de plataforma
- `BUG-E2E-COMPASS-012`: container `web` tentava acessar backend em `localhost:8080`, quebrando login e proxies `app/api/*`; corrigido para usar `api:8080` dentro da rede Docker
- `BUG-E2E-COMPASS-013`: `docker compose up` direto podia recriar a `api` com `PLATFORM_BOOTSTRAP_ENABLED=true` e sem a senha secreta do bootstrap, derrubando o container; corrigido isolando o bootstrap nas variaveis `COMPOSE_PLATFORM_BOOTSTRAP_*` e validando o segredo antes de subir a stack
- `BUG-E2E-COMPASS-024`: o proxy local nao expunha `/auth/*` nem `/api/mobile/*` para o backend, fazendo o app mobile receber HTML da web no lugar de JSON do contrato de autenticacao; corrigido no `nginx`
- `BUG-E2E-COMPASS-025`: o cliente mobile de autenticacao explodia com `FormatException` quando recebia HTML/resposta invalida; corrigido com mensagem operacional clara para URL/proxy errado
- `BUG-E2E-COMPASS-023`: o campo `Data de nascimento` no Android exigia `dd/mm/aaaa`, mas o teclado numerico nao oferecia `/`; corrigido com mascara automatica por digitos no app mobile
- `BUG-E2E-COMPASS-027`: ambiente funcional local nao oferecia forma operacional de recuperar o codigo de primeiro acesso; corrigido expondo `debugOtp` apenas na stack local iniciada pelo `start_local_stack.ps1`
- `BUG-E2E-COMPASS-028`: etapa de codigo no mobile usava jargao `OTP` e nao orientava usuario leigo; corrigido com linguagem simples, CTA de reenvio e ajuda contextual
- `BUG-E2E-COMPASS-038`: o `start_local_stack.ps1` nao recriava containers existentes, entao flags locais como bootstrap da plataforma e `debugOtp` podiam nao entrar na `api`; corrigido com `docker compose up --force-recreate`

### Passo 4. Verificar containers

```powershell
docker compose -f infra\docker-compose.yml ps
```

Estado esperado:
- todos os containers `Up`
- `web` e `api` com healthcheck `healthy`

### Passo 5. Validar endpoints basicos

No navegador:
- `http://localhost/`

No terminal:

```powershell
Invoke-WebRequest http://localhost:8080/actuator/health
Invoke-WebRequest http://localhost:3000/health
```

Resultado esperado:
- backend responde `UP`
- web responde `200`

### Passo 6. Validar navegacao minima do backoffice

Abrir no navegador:
- `http://localhost/`
- `http://localhost/backoffice/config`
- `http://localhost/backoffice/valuation`
- `http://localhost/backoffice/reports`
- `http://localhost/backoffice/operations`

Use o manual:
- [MANUAL_OPERACIONAL_BACKOFFICE.md](C:\src\AppMobile\docs\05-operations\manuals\MANUAL_OPERACIONAL_BACKOFFICE.md)

### Passo 7. Declarar o ambiente como funcional

So declare o ambiente local como pronto quando:
- os 5 servicos estiverem de pe
- web e backend responderem health
- o backoffice abrir sem erro estrutural
- houver dado minimo para navegacao funcional

## Parte 2 - Subida Em VPS Para Homologacao Funcional

### Passo 1. Preparar a VPS

Na VPS Linux:

```bash
sudo bash infra/scripts/vps-setup.sh URL_DO_REPOSITORIO_GIT
```

Fonte detalhada:
- [IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md](C:\src\AppMobile\docs\05-operations\runbooks\IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md)

### Passo 2. Publicar o codigo na VPS

Na VPS:

```bash
cd /opt/backoffice
git pull
cp infra/.env.example infra/.env
nano infra/.env
```

### Passo 3. Preencher urls do ambiente homolog

Campos tipicos:
- `APP_BASE_URL=https://seu-dominio`
- `API_BASE_URL=https://seu-dominio/api`
- `WEB_BACKOFFICE_API_BASE_URL=https://seu-dominio/api`

### Passo 4. Provisionar segredos do ambiente

Preencha fora do codigo:
- senha de banco
- senha de redis
- segredo JWT
- segredo HMAC de integracao

Se o ambiente for `homolog` ou `prod`, trate isso como obrigatorio.

### Passo 5. Subir a stack

```bash
cd /opt/backoffice/infra
docker compose up -d --build
```

### Passo 6. Validar o estado da stack

```bash
docker compose ps
docker compose logs api --tail 100
docker compose logs web --tail 100
```

### Passo 7. Validar DNS e HTTPS

No navegador:
- `https://seu-dominio/`
- `https://seu-dominio/backoffice/operations`

No terminal:

```bash
curl -I https://seu-dominio/
curl -I https://seu-dominio/api/actuator/health
```

### Passo 8. Declarar o ambiente homolog funcional

So declare pronto quando:
- DNS estiver propagado
- HTTPS estiver valido
- stack estiver `healthy`
- telas principais abrirem
- health do backend estiver `UP`

## Parte 3 - Dados Minimos Para Teste Funcional

Sem dados minimos, o ambiente sobe mas nao e testavel de forma util.

Hoje, para teste funcional, voce precisa garantir ao menos:
- tenant ativo
- usuario operacional valido
- job/case/inspection coerentes para navegacao
- valuation process e report quando o objetivo for validar o fluxo tecnico completo

Se o ambiente estiver vazio:
- a navegacao tecnica pode abrir
- mas o teste de caixa preta funcional fica fraco

## Parte 4 - Smoke Funcional Obrigatorio

Depois de subir o ambiente, execute este smoke minimo.

### Smoke de infraestrutura

1. abrir home web
2. abrir `/backoffice/config`
3. abrir `/backoffice/valuation`
4. abrir `/backoffice/reports`
5. abrir `/backoffice/operations`
6. validar `api/actuator/health`

### Smoke de operacao

1. listar processos em valuation
2. abrir um processo
3. validar ou rejeitar intake
4. abrir reports
5. localizar um report gerado
6. revisar status e navegacao

### Smoke de observabilidade

1. abrir `/backoffice/operations`
2. validar se o painel responde
3. validar se metricas e eventos carregam sem erro estrutural

## Parte 5 - Quando O Teste Envolver Mobile

Para teste funcional com mobile, o ambiente de caixa preta nao termina na VPS.
Tambem e necessario:
- build Android homologado ou instalado localmente
- apontamento correto para a API homolog
- credenciais e dados compativeis com o ambiente

Regras praticas:
- para validacao de fluxo candidato, usar o build vindo de `Android Homologation`
- para validacao local tecnica, usar build local apenas se a URL da API estiver coerente com o ambiente
- no ambiente local de caixa preta, a etapa `Primeiro acesso` do Compass exibe um bloco `Codigo de teste do ambiente local` quando o backend devolver `debugOtp`; isso existe apenas para destravar o E2E local e nao representa o comportamento esperado em producao

## Parte 6 - Troubleshooting Rapido

### Web nao sobe

Verificar:
- `docker compose logs web`
- `APP_BASE_URL`
- `WEB_BACKOFFICE_API_BASE_URL`

### Backend nao sobe

Verificar:
- `docker compose logs api`
- segredos obrigatorios
- conectividade com `db` e `cache`
- health do PostgreSQL

### Banco sobe, mas app nao funciona

Verificar:
- migrations do Flyway
- dados minimos de teste
- usuario/tenant ativo

### Nginx sobe, mas a aplicacao nao responde

Verificar:
- `nginx.conf`
- upstreams de `web` e `api`
- DNS
- certificados

### Ambiente "subiu", mas o teste funcional nao anda

Quase sempre a causa real e uma destas:
- sem dados minimos
- sem usuario operacional
- segredos inconsistentes
- urls erradas entre web e api
- ambiente mobile apontando para outro backend

## Criterio De Pronto

O ambiente funcional de caixa preta esta pronto quando:

1. stack completa sobe sem erro estrutural
2. segredos obrigatorios estao provisionados
3. web e api respondem health
4. telas principais abrem
5. existe dado minimo para o cenario de teste
6. smoke funcional foi executado
7. qualquer humano ou agente consegue repetir a subida usando este documento

## Evidencia Minima

Antes de declarar o ambiente pronto, registre:
- qual ambiente foi subido
- data e hora
- branch ou versao usada
- urls do web e api
- status da stack
- resultado do smoke funcional
- pendencias conhecidas

## Limitacoes Atuais Do Projeto

Hoje o projeto ainda nao tem:
- seed unificado de QA por um comando unico
- provisionamento automatico completo de dados de caixa preta
- deploy automatizado completo por SSH na esteira
- manual unificado de operacao mobile + web no mesmo documento

Leitura pratica:
- o runbook resolve a subida do ambiente
- mas ainda exige disciplina operacional para dados, segredos e validacao final
