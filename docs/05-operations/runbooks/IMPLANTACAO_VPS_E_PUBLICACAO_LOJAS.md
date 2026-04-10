# IMPLANTACAO VPS E PUBLICACAO LOJAS

> [RUNBOOK ATIVO]
> Este documento ensina a colocar a plataforma em operacao em uma VPS Linux e a publicar o app nas lojas oficiais da Apple e do Google. O foco e pratico e orientado para um leitor leigo.

## Objetivo

Sair de:
- codigo no repositorio
- app rodando so em ambiente local

Para:
- backend e web publicados em uma VPS Linux
- dominio com HTTPS
- operacao minima com backup e monitoramento basico
- app Android publicado na Google Play
- app iOS publicado na App Store

## Resumo Executivo

Hoje o projeto tem esta topologia:
- Mobile: Flutter, na raiz do repositorio
- Backend: Spring Boot 3.4, PostgreSQL, Redis, Flyway, Dockerfile pronto em `apps/backend`
- Web/backoffice: Next.js 14, Dockerfile pronto em `apps/web-backoffice`
- Infra pronta para compose + nginx em `infra/`

O caminho mais simples para uma primeira implantacao e:
1. contratar uma VPS Linux HostGator
2. apontar um dominio
3. instalar Docker e Docker Compose
4. subir `proxy`, `web`, `api`, `db` e `cache` via `infra/docker-compose.yml`
5. ativar HTTPS
6. preparar assinatura e publicacao do Android e iOS

## Leitura Importante Antes De Comecar

- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [PONTO_RESTAURACAO_AMBIENTE_LOCAL.md](C:\src\AppMobile\docs\05-operations\runbooks\PONTO_RESTAURACAO_AMBIENTE_LOCAL.md)
- [AMBIENTE_FUNCIONAL_CAIXA_PRETA.md](C:\src\AppMobile\docs\05-operations\runbooks\AMBIENTE_FUNCIONAL_CAIXA_PRETA.md)
- [CONTROL_TOWER_CONTINUITY_RUNBOOK.md](C:\src\AppMobile\docs\05-operations\runbooks\CONTROL_TOWER_CONTINUITY_RUNBOOK.md)
- [SEGURANCA_E_HARDENING_PRODUCAO.md](C:\src\AppMobile\docs\05-operations\runbooks\SEGURANCA_E_HARDENING_PRODUCAO.md)
- [GESTAO_DE_SEGREDOS_E_COFRE.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_SEGREDOS_E_COFRE.md)

## O Que Contratar

### 1. Infra web/backend

Minimo para piloto ou producao pequena:
- 1 VPS Linux HostGator no nivel `KVM 2` ou equivalente
- 1 dominio proprio
- 1 conta de DNS

Recomendacao mais segura para producao:
- subir um plano acima do `KVM 2` se o uso real incluir:
  - backend Java
  - PostgreSQL
  - Redis
  - Next.js
  - nginx
  - upload de fotos

Leitura pratica:
- `KVM 2` serve como piso operacional
- para producao mais confortavel, eu trataria `KVM 2` como inicio, nao como teto

### 2. Servicos de publicacao mobile

Obrigatorios:
- conta Google para Google Play Console
- conta Apple Developer Program

Quase obrigatorios:
- e-mail corporativo
- telefone corporativo
- politica de privacidade publicada em URL publica

Para iOS:
- 1 Mac fisico ou um servico CI com macOS para gerar e enviar o app

### 3. Servicos opcionais mas recomendados

- Cloudflare para DNS e protecao basica
- Cloudflare R2 para storage de fotos se o volume crescer
- provedor de e-mail transacional se depois houver notificacoes

## O Que Ja Existe No Projeto

### Infra pronta

- Compose: [docker-compose.yml](C:\src\AppMobile\infra\docker-compose.yml)
- Variaveis: [\.env.example](C:\src\AppMobile\infra\.env.example)
- Proxy: [nginx.conf](C:\src\AppMobile\infra\nginx\nginx.conf)
- Setup inicial de VPS: [vps-setup.sh](C:\src\AppMobile\infra\scripts\vps-setup.sh)

### Containers previstos

- `proxy`: nginx
- `web`: Next.js
- `api`: Spring Boot
- `db`: PostgreSQL
- `cache`: Redis

### Configuracoes ja previstas no backend

O backend ja aceita configuracao por variavel de ambiente para:
- PostgreSQL
- Redis
- storage local ou R2
- JWT secret
- HMAC da integracao
- retention do control tower

Arquivo base:
- [application.yml](C:\src\AppMobile\apps\backend\src\main\resources\application.yml)

## Lacunas Atuais Antes De Publicar Em Loja

Estas lacunas precisam ser fechadas antes de loja oficial:

1. Android ainda usa identificador placeholder:
- `applicationId = "com.example.myapp"`
- arquivo: [build.gradle.kts](C:\src\AppMobile\android\app\build.gradle.kts)

2. iOS ainda usa bundle identifier placeholder:
- `PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp`
- arquivo: [project.pbxproj](C:\src\AppMobile\ios\Runner.xcodeproj\project.pbxproj)

3. Android release ainda esta assinado com chave de debug:
- arquivo: [build.gradle.kts](C:\src\AppMobile\android\app\build.gradle.kts)

4. Arquivos de integracao Firebase nao estao presentes:
- `android/app/google-services.json` ausente
- `ios/Runner/GoogleService-Info.plist` ausente

5. HTTPS no nginx ainda esta comentado:
- arquivo: [nginx.conf](C:\src\AppMobile\infra\nginx\nginx.conf)

6. Workflows de deploy ainda validam secrets, mas nao executam deploy completo por SSH:
- [backend_deploy.yml](C:\src\AppMobile\.github\workflows\backend_deploy.yml)
- [web_deploy.yml](C:\src\AppMobile\.github\workflows\web_deploy.yml)

## Parte 1 - Contratacao Da VPS E Dominio

### Passo 1. Contrate a VPS

Ao contratar na HostGator:
1. escolha VPS Linux
2. escolha `KVM 2` ou superior
3. prefira Ubuntu 24.04 LTS se a opcao existir
4. habilite acesso root ou um usuario administrador
5. guarde:
   - IP publico
   - usuario
   - senha inicial ou chave SSH

### Passo 2. Contrate ou separe o dominio

Exemplo de dominios:
- `app.seudominio.com` para o web/backoffice
- `api.seudominio.com` para o backend

Se quiser simplificar no inicio:
- use apenas `seudominio.com` para web
- use `seudominio.com/api` para backend via nginx

Esse repositorio ja esta preparado para o segundo modelo.

### Passo 3. Configure o DNS

No provedor do dominio:
1. crie um registro `A`
2. aponte o dominio para o IP da VPS
3. aguarde a propagacao

## Parte 2 - Preparacao Da VPS

### Passo 4. Acesse a VPS via SSH

No Windows PowerShell:

```powershell
ssh root@IP_DA_VPS
```

Se a HostGator entregar um usuario diferente de `root`, use o usuario informado.

### Passo 5. Rode o setup inicial

O projeto ja tem um script de setup:

- [vps-setup.sh](C:\src\AppMobile\infra\scripts\vps-setup.sh)

Esse script:
- atualiza o sistema
- instala `curl`, `git`, `ufw`, `certbot`
- instala Docker
- instala Docker Compose plugin
- abre portas `22`, `80` e `443`
- cria estrutura base em `/opt/backoffice`

Execucao:

```bash
sudo bash infra/scripts/vps-setup.sh URL_DO_REPOSITORIO_GIT
```

Exemplo:

```bash
sudo bash infra/scripts/vps-setup.sh https://github.com/SEU_ORG/AppMobile.git
```

### Passo 6. Copie o arquivo de ambiente

Na VPS:

```bash
cd /opt/backoffice
cp infra/.env.example infra/.env
nano infra/.env
```

Preencha pelo menos:
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `NEXT_PUBLIC_API_BASE_URL`
- `STORAGE_ADAPTER`

## Parte 3 - Configuracao Obrigatoria De Producao

### Passo 7. Ajuste secrets do backend

No estado atual, o compose ainda nao injeta todas as secrets criticas do backend.
Antes de producao, ajuste o `infra/docker-compose.yml` ou use um override para passar:

- `AUTH_JWT_SECRET`
- `INTEGRATION_CONFIG_SIGNING_HMAC_KEY`
- `INTEGRATION_CONFIG_SIGNING_REQUIRE_SECRET=true`
- opcionalmente:
  - `R2_ENDPOINT`
  - `R2_ACCESS_KEY`
  - `R2_SECRET_KEY`
  - `R2_BUCKET`
  - `R2_PUBLIC_BASE`

Recomendacao objetiva:
- nao use o valor default de JWT em producao
- nao publique sem segredo HMAC real para integracao

### Passo 8. Escolha storage local ou R2

Opcao simples:
- `STORAGE_ADAPTER=local`
- usa disco da VPS para uploads

Opcao melhor para escala:
- `STORAGE_ADAPTER=r2`
- fotos e anexos vao para bucket compativel com S3

Recomendacao:
- comece com `local` em piloto pequeno
- migre para `r2` se o volume de fotos crescer ou se backup de disco virar gargalo

## Parte 4 - Subida Da Aplicacao

### Passo 9. Suba a stack

Na VPS:

```bash
cd /opt/backoffice
docker compose -f infra/docker-compose.yml up -d --build
```

### Passo 10. Verifique se os containers ficaram saudaveis

```bash
docker compose -f infra/docker-compose.yml ps
docker compose -f infra/docker-compose.yml logs -f
```

Voce quer ver:
- `proxy` up
- `web` healthy
- `api` healthy
- `db` healthy
- `cache` healthy

### Passo 11. Teste os endpoints

Sem HTTPS ainda:

- `http://SEU_DOMINIO/health`
- `http://SEU_DOMINIO/api/actuator/health`
- `http://SEU_DOMINIO/api/openapi/v1`

## Parte 5 - HTTPS E Dominio

### Passo 12. Gere o certificado SSL

Na VPS:

```bash
certbot certonly --standalone -d seudominio.com
```

Depois copie os arquivos:

```bash
cp /etc/letsencrypt/live/seudominio.com/fullchain.pem /opt/backoffice/infra/nginx/certs/
cp /etc/letsencrypt/live/seudominio.com/privkey.pem /opt/backoffice/infra/nginx/certs/
```

### Passo 13. Ative o bloco HTTPS do nginx

Edite:
- [nginx.conf](C:\src\AppMobile\infra\nginx\nginx.conf)

Voce precisa:
1. descomentar o bloco `server` de `443`
2. trocar `seudominio.com` pelo seu dominio real
3. opcionalmente redirecionar HTTP para HTTPS

Depois recrie o proxy:

```bash
cd /opt/backoffice
docker compose -f infra/docker-compose.yml up -d --build proxy
```

## Parte 6 - Operacao Minima Do Servidor

### Passo 14. Defina rotina minima de backup

Voce precisa proteger:
- banco PostgreSQL
- volume de uploads
- arquivo `infra/.env`

Rotina minima recomendada:
1. backup diario do PostgreSQL
2. backup diario da pasta de uploads
3. copia segura do `.env` fora da VPS

Exemplo de dump PostgreSQL:

```bash
docker exec -t $(docker ps --filter name=db --format "{{.ID}}") \
  pg_dump -U backoffice backoffice > /opt/backoffice/backup-backoffice.sql
```

### Passo 15. Monitore a saude minima

Cheque diariamente ou a cada deploy:
- `docker compose ps`
- logs do backend
- logs do proxy
- espaco em disco
- memoria da VPS
- health check web/api

### Passo 16. Atualize sem quebrar

Fluxo recomendado:
1. merge em `main`
2. release conforme o runbook oficial
3. pull na VPS
4. rebuild da stack
5. validar healths

Exemplo:

```bash
cd /opt/backoffice
git pull origin main
docker compose -f infra/docker-compose.yml up -d --build
```

## Parte 7 - Publicacao Android Na Google Play

### Passo 17. Crie a conta de desenvolvedor Google Play

Voce vai precisar de:
- conta Google
- cadastro no Google Play Console
- verificacoes de identidade quando exigidas

### Passo 18. Corrija o identificador do app

No Android:
- troque `com.example.myapp` por um identificador definitivo

Exemplo:
- `br.seucliente.appmobile`

Arquivo:
- [build.gradle.kts](C:\src\AppMobile\android\app\build.gradle.kts)

Regra importante:
- esse identificador nao deve mudar depois que o app for publicado

### Passo 19. Configure a assinatura release do Android

Hoje o projeto usa chave de debug em release.
Isso precisa ser substituido por:
1. um keystore real
2. configuracao de signing release
3. armazenamento seguro das senhas

Sem isso, nao publique.

### Passo 20. Gere o app bundle

No terminal:

```bash
flutter build appbundle --release
```

Saida esperada:
- `build/app/outputs/bundle/release/app-release.aab`

### Passo 21. Prepare a pagina da loja

Voce vai precisar:
- nome do app
- descricao curta
- descricao completa
- icone 512x512
- screenshots
- categoria
- e-mail de suporte
- URL de politica de privacidade

### Passo 22. Preencha declaracoes obrigatorias

Normalmente a Google Play exige:
- classificacao de conteudo
- seguranca de dados
- uso de permissoes sensiveis
- publico-alvo
- politica de privacidade

No estado atual do app, voce deve revisar com cuidado:
- camera
- localizacao
- microfone
- reconhecimento de fala

### Passo 23. Faca um teste interno antes da producao

Fluxo recomendado:
1. crie `Internal testing`
2. suba o `.aab`
3. convide testers
4. valide login, envio de vistoria e uso de camera/localizacao
5. so depois avance para `Closed testing` ou `Production`

## Parte 8 - Publicacao iOS Na App Store

### Passo 24. Crie a conta Apple Developer

Voce vai precisar de:
- Apple ID
- adesao ao Apple Developer Program
- dados da empresa se a conta for corporativa

### Passo 25. Garanta um ambiente macOS

Para publicar iOS, voce precisa de:
- um Mac
ou
- um servico CI com macOS

Sem isso, nao ha publicacao iOS real.

### Passo 26. Corrija o bundle identifier

Troque:
- `com.example.myapp`

Por um bundle real, por exemplo:
- `br.seucliente.appmobile`

Arquivos impactados:
- [project.pbxproj](C:\src\AppMobile\ios\Runner.xcodeproj\project.pbxproj)

### Passo 27. Configure assinatura Apple

Voce precisa configurar:
- Team Apple Developer
- certificados
- provisioning profiles
- capacidades do app, se houver

### Passo 28. Gere o build iOS

Em um Mac:

```bash
flutter build ipa --release
```

Ou gere via Xcode/Archive.

### Passo 29. Crie o app no App Store Connect

Voce vai precisar preencher:
- nome do app
- bundle identifier
- SKU
- categoria
- politica de privacidade
- screenshots
- descricao

### Passo 30. Envie primeiro para TestFlight

Fluxo recomendado:
1. subir build
2. testar internamente
3. testar externamente, se necessario
4. so depois enviar para review da App Store

### Passo 31. Revise permissoes e privacidade

O iOS do projeto ja declara:
- camera
- localizacao
- microfone
- speech recognition

Arquivo:
- [Info.plist](C:\src\AppMobile\ios\Runner\Info.plist)

Voce ainda precisa alinhar:
- texto final dessas permissoes
- politica de privacidade
- respostas de App Privacy no App Store Connect

## Parte 9 - Checklist Final Para Um Leigo

### Infra

- VPS contratada
- dominio apontado
- acesso SSH funcionando
- Docker instalado
- `.env` preenchido
- stack subida
- health check web ok
- health check api ok
- HTTPS ativo
- backup testado

### Android

- `applicationId` definitivo
- keystore release criado
- build `.aab` gerado
- pagina da loja preenchida
- politica de privacidade publicada
- teste interno executado

### iOS

- conta Apple Developer ativa
- Mac ou CI macOS disponivel
- bundle identifier definitivo
- assinatura configurada
- `ipa` ou archive gerado
- TestFlight validado
- App Store Connect preenchido

## Recomendacao Objetiva

Se voce quer colocar isso no ar com menor risco:
1. publique primeiro web + backend na VPS
2. valide o fluxo real com usuarios internos
3. publique Android primeiro
4. publique iOS depois que assinatura e TestFlight estiverem estaveis

Isso reduz risco operacional porque:
- o backend e o web passam a existir em ambiente real
- o Android costuma ser mais simples operacionalmente
- iOS traz a parte mais sensivel de assinatura e ambiente macOS

## Referencias Oficiais Externas

- HostGator Brasil: https://www.hostgator.com.br/
- Apple Developer Program: https://developer.apple.com/programs/
- Apple App Store Connect Help: https://developer.apple.com/help/app-store-connect/
- Google Play Console Help: https://support.google.com/googleplay/android-developer/
- Android release overview: https://developer.android.com/studio/publish
