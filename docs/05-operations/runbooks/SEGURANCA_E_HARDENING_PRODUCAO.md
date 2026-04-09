# SEGURANCA E HARDENING DE PRODUCAO

> [RUNBOOK ATIVO]
> Este documento define o minimo de seguranca para publicar e operar a plataforma em ambiente real.

## Objetivo

Garantir que a publicacao em VPS e nas lojas nao aconteca com lacunas basicas de seguranca.

## Escopo

Este runbook cobre:
- dominio e DNS
- VPS Linux
- Docker e servicos
- banco, cache e storage
- segredos
- publicacao Android e iOS
- operacao minima de continuidade

## Regra Central

Nao existe producao segura deste projeto sem:
1. dominio sob controle do responsavel operacional
2. HTTPS ativo
3. segredos fortes e fora do Git
4. backup testado
5. acesso administrativo restrito
6. assinatura correta dos apps mobile

Runbook complementar obrigatorio:
- [GESTAO_DE_SEGREDOS_E_COFRE.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_SEGREDOS_E_COFRE.md)

## Parte 1 - Dominio E DNS

### Regras obrigatorias

1. O dominio deve ficar em conta corporativa, nao pessoal.
2. O DNS deve permitir acesso administrativo apenas a responsaveis autorizados.
3. Deve existir registro de quem controla:
   - registrador
   - DNS
   - renovacao
   - e-mail de contato

### Recomendacoes

1. Ativar MFA no registrador do dominio.
2. Ativar MFA no provedor de DNS.
3. Usar Cloudflare ou equivalente para:
   - DNS
   - protecao basica
   - gestao simplificada de certificados e proxy, se adotado

## Parte 2 - VPS E Sistema Operacional

### Regras obrigatorias

1. Usar Ubuntu LTS suportado.
2. Atualizar o sistema antes da primeira subida.
3. Nao operar a aplicacao no mesmo usuario usado para administracao manual quando isso puder ser evitado.
4. Abrir apenas as portas necessarias:
   - 22
   - 80
   - 443
5. Desabilitar autenticacao por senha quando o acesso por chave SSH estiver pronto.

### Recomendacoes

1. Restringir SSH por IP de origem se o time tiver IP fixo.
2. Habilitar `fail2ban` ou equivalente.
3. Ativar reinicio automatico dos servicos criticos.

## Parte 3 - Containers E Rede

### Regras obrigatorias

1. O banco nao deve ficar exposto publicamente.
2. O Redis nao deve ficar exposto publicamente.
3. O acesso externo deve entrar pelo proxy reverso.
4. O backend deve responder atras do nginx, nao diretamente exposto.

## Parte 4 - Segredos E Configuracao

### Regras obrigatorias

Nunca publicar com valores default para:
- `AUTH_JWT_SECRET`
- `INTEGRATION_CONFIG_SIGNING_HMAC_KEY`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`

Tambem e obrigatorio:
1. `INTEGRATION_CONFIG_SIGNING_REQUIRE_SECRET=true` em ambiente real
2. `.env` fora do Git
3. segredos compartilhados apenas por cofre seguro ou gestor de senhas

## Parte 5 - Banco, Cache E Storage

### PostgreSQL

Obrigatorio:
1. senha forte
2. backup diario
3. teste de restauracao periodico

### Redis

Obrigatorio:
1. senha forte
2. sem exposicao publica

### Storage

Se usar `local`:
1. monitorar disco
2. incluir uploads no backup

Se usar `r2`:
1. proteger access key e secret key
2. controlar bucket e politica de acesso

## Parte 6 - HTTPS E Certificados

### Regras obrigatorias

1. Nao operar em producao definitiva sem HTTPS.
2. Certificado deve estar valido e renovavel.
3. O nginx deve encaminhar:
   - `Host`
   - `X-Forwarded-For`
   - `X-Forwarded-Proto`

## Parte 7 - Publicacao Android

### Regras obrigatorias

1. `applicationId` definitivo e corporativo.
2. assinatura release com keystore real.
3. keystore guardado em local seguro.
4. senhas da assinatura fora do codigo e fora do Git.
5. politica de privacidade coerente com:
   - camera
   - localizacao
   - microfone
   - speech recognition

### Proibido

1. Publicar com chave de debug.
2. Publicar com `com.example.*`.

## Parte 8 - Publicacao iOS

### Regras obrigatorias

1. bundle identifier definitivo.
2. conta Apple Developer corporativa quando o app for da empresa.
3. assinatura valida com certificado e provisioning profile corretos.
4. revisao de App Privacy coerente com as permissoes declaradas no app.

### Proibido

1. Publicar com `com.example.*`.
2. Publicar sem revisar os textos de permissoes no `Info.plist`.

## Parte 9 - Operacao E Continuidade

### Obrigatorio

1. Health check de web e api apos cada deploy.
2. Verificacao de logs apos cada deploy.
3. Backup diario.
4. Registro de incidente relevante.
5. Registro de rollback quando houver.

## Checklist Minimo Antes De Produzir

- dominio sob controle corporativo
- DNS com MFA
- VPS atualizada
- firewall ativo
- HTTPS ativo
- banco sem exposicao publica
- Redis sem exposicao publica
- secrets fortes e fora do Git
- backup testado
- `AUTH_JWT_SECRET` real
- `INTEGRATION_CONFIG_SIGNING_HMAC_KEY` real
- Android com keystore release real
- iOS com assinatura real
- politica de privacidade publicada
