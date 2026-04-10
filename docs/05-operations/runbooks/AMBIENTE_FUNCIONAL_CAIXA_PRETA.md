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
- segredos locais provisionados por variavel de ambiente, `Get-Secret` ou prompt seguro

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
- o script local resolve segredos por env, cofre ou prompt

### Passo 2. Provisionar segredos locais

Opcao recomendada no Windows:
- PowerShell SecretManagement + SecretStore

Segredos minimos esperados pelo script local:
- `AppMobile/PostgresPassword`
- `AppMobile/RedisPassword`
- `AppMobile/JwtSecret`
- `AppMobile/IntegrationConfigSigningHmacKey`

### Passo 3. Subir a stack local

```powershell
powershell -ExecutionPolicy Bypass -File infra\scripts\start_local_stack.ps1
```

Esse script:
- carrega `infra/.env`
- resolve segredos
- sobe `proxy`, `web`, `api`, `db` e `cache`

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
