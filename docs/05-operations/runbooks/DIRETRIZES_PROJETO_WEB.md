> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Diretrizes do Projeto Web - Resumo Executavel

Atualizado em: 2026-04-01

## 1) Objetivo macro
Construir o backoffice web integrado ao AppMobile com foco em:
1. Integracao bidirecional segura (Web <-> Mobile).
2. Operacao de check-in/configuracao remota e sync de vistoria.
3. Arquitetura enterprise pronta para evolucao (DDD, IAM, multi-tenant, white label, AD futuro).
4. Automacao progressiva do ciclo tecnico (NBR 14653) com assinatura humana final.

## 2) Decisoes arquiteturais e de stack ja definidas
1. Backend oficial: Java 21 + Spring Boot 3.
2. Frontend web oficial: TypeScript + Next.js/React.
3. Banco relacional: PostgreSQL.
4. Cache: Redis.
5. Mensageria inicial: RabbitMQ (com possibilidade de evoluir para Kafka).
6. Contratos: OpenAPI 3 + contract tests em CI.
7. Observabilidade: OpenTelemetry + Prometheus/Grafana + logs centralizados.
8. Identidade: OIDC/SAML, com estrategia AD futura via federacao (Azure AD/ADFS).
9. Autorizacao: RBAC + politicas de dominio.
10. Storage de fotos: comecar simples/local e migrar para R2/S3 com adapter, sem refatoracao grande.

## 3) Estrategia de hospedagem discutida
1. Opcao de custo previsivel aprovada para inicio: VPS simples (ex.: Hostinger) para web+api+db+cache.
2. Storage pode iniciar local e migrar depois para Cloudflare R2 (S3-compatible) ou AWS S3.
3. Recomendacao operacional: manter abstracao de storage desde o dia 1 (ja criada no backend).

### Alternativas avaliadas (e motivo)
1. Vercel: muito simples para Next.js, mas nao resolve stack completa com backend Java + DB + cache no mesmo lugar.
2. AWS full stack: excelente para escala e S3, mas com maior risco de custo/complexidade para fase inicial solo.
3. Railway: boa experiencia de deploy e custo inicial razoavel, mas sem storage equivalente a S3 nativo para fotos.
4. Decisao pratica de curto prazo: VPS com custo fixo (previsibilidade financeira) e estrategia de migracao gradual de storage.

## 4) Backlogs e planejamento formal ja produzidos
1. Backoffice web: docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md
2. Integracao web-mobile: docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md
3. Backlog mobile principal com links de governanca: docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md
4. Plano de execucao 30 dias (ownership, marcos, aceite, riscos): docs/05-operations/runbooks/PLANO_EXECUCAO_30_DIAS_WEB_MOBILE.md

## 5) Entregas tecnicas ja implementadas no repositorio
1. App web inicial em apps/web-backoffice (Next.js, health route, lint/test/build, Dockerfile).
2. API backend inicial em apps/backend (Spring Boot, health, Dockerfile, pom, testes basicos).
3. Camada de storage no backend:
- StorageService (interface)
- LocalStorageAdapter
- R2StorageAdapter (S3-compatible)
4. Infra local/VPS em infra:
- docker-compose.yml (proxy, web, api, postgres, redis)
- nginx/nginx.conf
- scripts/vps-setup.sh
- .env.example
5. Workflows CI/CD criados:
- .github/workflows/web_ci.yml
- .github/workflows/web_deploy.yml
- .github/workflows/backend_ci.yml
- .github/workflows/backend_deploy.yml

### Observacao de evolucao dos workflows
1. Web deploy iniciou com webhook opcional e foi evoluido para deploy por SSH em VPS.
2. Backend deploy usa SSH para atualizar e reconstruir servico no host alvo.

## 6) Estado atual real (onde paramos)
1. Estrutura de codigo e pipelines base estao no repositorio.
2. Docker/WSL no Windows apresentou instabilidade grave durante bootstrap local.
3. Erros recorrentes observados:
- daemon.json is invalid (SIGBUS)
- Wsl/Service/CreateInstance/E_FAIL
- Wsl/Service/E_UNEXPECTED
4. Diagnostico pratico: ambiente local com CPU antiga pode ter incompatibilidade com Docker Desktop mais novo.
5. Acao recomendada para estabilizar ambiente:
- usar Docker Desktop 4.28.0 (engine mais conservador para hardware antigo)
- validar docker ps e so depois subir compose

### Linha do tempo operacional relevante
1. Docker chegou a responder com sucesso (docker ps listando vazio).
2. Compose exigiu ajuste de env file por diferenca entre infra.env (raiz) e infra/.env (referencia interna do compose).
3. Ocorreram travamentos por uso em diretorio errado (system32) e comandos com aspas no comando inteiro no PowerShell.
4. Mesmo apos recuperacoes parciais, voltou erro grave de daemon (SIGBUS), mantendo bloqueio de subida da stack.

## 7) Riscos e cuidados operacionais
1. Nao executar comandos de reparo de servico sem PowerShell administrador.
2. Separar arquivo de variaveis: usar infra/.env para compose e evitar ambiguidades de caminho.
3. Em caso de reset pesado de Docker, pode haver perda de imagens/containers locais.
4. Em Windows com recursos limitados, iniciar com alocacao conservadora e uma stack por vez.
5. Evitar executar compose fora da raiz do projeto para nao perder referencia de paths.
6. No PowerShell, nao encapsular o comando inteiro entre aspas; usar aspas somente em caminhos com espaco.

## 8) Proximos passos objetivos
1. Estabilizar Docker local (versao compativel + validacao docker ps).
2. Subir stack local com compose (web/api/db/cache/proxy).
3. Validar endpoints minimos:
- Web home
- Web health
- API actuator health
4. Iniciar sprint de integracao:
- INT-001/INT-002/INT-003/INT-006/INT-011/INT-012
- BOW-008/BOW-010/BOW-011
5. Fechar contrato OpenAPI v1 e gates de CI para quebrar build em incompatibilidade.

### Checklist de retomada imediata (ambiente)
1. Confirmar versao do Docker Desktop instalada e reduzir para 4.28.0 se persistir SIGBUS.
2. Confirmar WSL Ubuntu abre sem erro (wsl -d Ubuntu) antes de qualquer compose.
3. Garantir arquivo de ambiente consistente em ambos caminhos quando necessario:
- C:/src/AppMobile/infra.env
- C:/src/AppMobile/infra/.env
4. Subir compose com caminho absoluto e validar health por servico.

## 9) Prompt pronto para continuidade (copiar e usar)
Contexto do projeto:
- Repositorio monorepo em C:/src/AppMobile.
- Mobile Flutter existente e funcional.
- Backoffice web inicial ja criado em apps/web-backoffice (Next.js).
- Backend inicial ja criado em apps/backend (Spring Boot Java 21).
- Infra local/VPS ja criada em infra (compose + nginx + setup script).
- CI/CD base ja criada para web e backend em .github/workflows.
- Backlogs oficiais estao em docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md e docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md.
- Plano de 30 dias em docs/05-operations/runbooks/PLANO_EXECUCAO_30_DIAS_WEB_MOBILE.md.

Decisoes obrigatorias:
- Manter stack Java/Spring + TS/Next.
- Manter arquitetura DDD, multi-tenant, white label e IAM AD-ready.
- Manter seguranca de integracao (idempotencia, assinatura, anti-replay, correlation id).
- Manter StorageService com adapter (local agora, R2/S3 depois).

Estado atual de bloqueio:
- Ambiente Docker Desktop no Windows apresentou erros SIGBUS/WSL E_UNEXPECTED.
- Prioridade imediata: estabilizar ambiente local Docker e validar compose.
- Ja houve recuperacao parcial (docker ps respondendo), mas compose voltou a falhar com daemon invalid SIGBUS.

Sua missao agora:
1. Validar o estado atual do ambiente Docker/WSL e recuperar de forma segura.
2. Subir stack local via infra/docker-compose.yml com env consistente.
3. Confirmar health checks de web e api.
4. Abrir proxima entrega tecnica: API de check-in config + recebimento de vistoria final com idempotencia.
5. Atualizar backlog/status conforme entregas.

Criterio de sucesso:
- docker compose stack em pe, endpoints de health ok, e primeira entrega de integracao em desenvolvimento ativo.
