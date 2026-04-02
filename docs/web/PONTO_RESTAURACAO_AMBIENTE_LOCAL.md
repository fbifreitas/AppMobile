# Ponto de Restauração — Setup Ambiente Local Web

**Criado em:** 2026-04-01  
**Sessão de referência:** Setup completo de ambiente de desenvolvimento local (Node 20, Java 21, Maven, Docker Desktop)  
**Status atual:** Docker engine em processo de start com dados migrados para D:

---

## 1. Estado do Ambiente (April 1, 2026)

### Máquina
- CPU: Intel i5-3230M (3ª geração, 2 núcleos / 4 threads)
- RAM: 8 GB
- C: ~6.4 GB livre (após reboot)
- D: ~62 GB livre
- OS: Windows 10/11 64-bit com WSL2

### Ferramentas Instaladas

| Ferramenta | Versão | Local de Instalação |
|---|---|---|
| NVM for Windows | 1.2.2 | `C:\Users\fbifr\AppData\Local\nvm\` |
| Node.js | 20.19.5 (LTS) | via NVM → `C:\nvm4w\nodejs\` |
| Java JDK | 21.0.10.7 (Microsoft OpenJDK) | `C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\` |
| Apache Maven | 3.9.9 | `C:\tools\apache-maven-3.9.9\` |
| Docker Desktop | 4.28.0 | `C:\Program Files\Docker\Docker\` |

### Variáveis de Ambiente (User scope — persistentes)

```powershell
JAVA_HOME     = C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot
MAVEN_HOME    = C:\tools\apache-maven-3.9.9
NVM_HOME      = C:\Users\fbifr\AppData\Local\nvm
NVM_SYMLINK   = C:\nvm4w\nodejs
```

### PATH additions (User scope)
```
C:\tools\apache-maven-3.9.9\bin
C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin
C:\Program Files\Docker\Docker\resources\bin
C:\nvm4w\nodejs  (gerenciado pelo NVM)
```

### Validação das ferramentas (última execução confirmada)
```
node --version   → v20.19.5  ✅
npm --version    → 10.x      ✅
java --version   → 21.0.10   ✅
mvn --version    → 3.9.9     ✅
docker version   → 25.0.3    ✅ (após engine subir)
```

---

## 2. Configuração do Docker Desktop

### Localização dos dados WSL
- **Diretório migrado para:** `D:\DockerData\DockerDesktopWSL\`
- **Arquivo de disco:** `D:\DockerData\DockerDesktopWSL\data\ext4.vhdx` (~2.7 GB)
- **Configuração salva em:** `%LOCALAPPDATA%\Docker\settings-store.json`
  - Chave: `"customWslDistroDir": "D:\\DockerData\\DockerDesktopWSL"`
- **Memória alocada:** 2048 MB
- **CPUs alocados:** 4
- **Disco total:** 65536 MB (64 GB em D:)

### Estado atual (momento do registro)
- Docker Desktop: em estado **Starting**
- `docker-desktop-data` WSL distro: presente em D: com ext4.vhdx criado
- `docker-desktop` WSL distro: sendo recriada no novo local

### Histórico de problemas Docker desta sessão
1. **EXT4 corruption** em `docker-desktop-data` antigo (device sde, IO failure) → resolvido pela migração para D:
2. **C: com 1.7 GB livre** → após reboot liberou para 6.4 GB + migração de dados para D:
3. **`docker-desktop` WSL distro ausente** → resolvido pela mudança de diretório + restart
4. **Engine terminando após 38s** → causado pelo diretório D: ainda vazio no primeiro start

---

## 3. Arquivos Criados/Modificados nesta Sessão

### Novos arquivos criados

| Arquivo | Propósito |
|---|---|
| `infra/scripts/start_local_stack.ps1` | Launcher seguro da stack local sem senhas em arquivo |
| `apps/web-backoffice/.dockerignore` | Reduz contexto de build (evita enviar node_modules, .next) |
| `apps/backend/.dockerignore` | Reduz contexto de build backend (evita enviar target/, .git) |

### Arquivos modificados

| Arquivo | Mudança |
|---|---|
| `infra/.env` | Senhas substituídas por `__SET_VIA_ENV_OR_VAULT__` |
| `infra.env` (raiz) | Idem |
| `apps/backend/Dockerfile` | Flags `-q` → `-B` no mvn para output confiável em hardware limitado |
| `docs/BACKLOG_BACKOFFICE_WEB.md` | Adicionados BOW-054 a BOW-064 |
| `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md` | Adicionados INT-025 a INT-029 |
| `docs/AGENTE_LICOES_APRENDIDAS.md` | Adicionadas 2 lições (secrets + dockerignore) |

---

## 4. Como Subir a Stack Local (após Docker estável)

### Pré-requisito: definir senhas via variável de ambiente de sessão
```powershell
$env:POSTGRES_PASSWORD = 'sua_senha_postgres'
$env:REDIS_PASSWORD    = 'sua_senha_redis'
```

### Subir a stack
```powershell
cd C:\src\AppMobile
powershell -ExecutionPolicy Bypass -File .\infra\scripts\start_local_stack.ps1 -Detach $true
```

O script:
1. Lê variáveis não-secretas de `infra/.env`
2. Resolve `POSTGRES_PASSWORD` e `REDIS_PASSWORD` de: env var → Get-Secret vault → prompt seguro
3. Executa `docker compose up -d` na pasta `infra/`

### Validar saúde da stack
```powershell
docker compose -f infra/docker-compose.yml ps
```

URLs de health check:
- Web (via proxy nginx):   http://localhost/health  
- API (via proxy nginx):   http://localhost/api/actuator/health  
- DB (Postgres):   porta 5432 (acesso interno)
- Cache (Redis):   porta 6379 (acesso interno)

Observacao: no compose atual, apenas o proxy expoe portas no host (80/443).

---

## 5. Desenvolvimento Local (sem Docker)

### Frontend (Next.js)
```powershell
cd apps/web-backoffice
npm install
npm run dev
# → http://localhost:3000
```

### Backend (Spring Boot)
```powershell
cd apps/backend
mvn -B spring-boot:run
# → http://localhost:8080/actuator/health
```

### Build de validação (CI local)
```powershell
# Frontend
cd apps/web-backoffice
npm run lint
npm test
npm run build

# Backend
cd apps/backend
mvn -B -DskipTests package
```

---

## 6. Backlog Aberto (próximas entregas prioritárias)

| ID | Título | Status |
|---|---|---|
| BOW-054 | Canonical Domain v1 (Demand/Case/Job/Inspection/Report) | Pendente |
| BOW-056 | OpenAPI v1 com política formal de compatibilidade | Pendente |
| BOW-058 | tenant + correlationId obrigatório em toda request | Pendente |
| BOW-060 | Padrão de idempotency key por operação crítica | Pendente |
| BOW-064 | Estratégia de vault de secrets (dev/stage/prod) | Pendente |
| INT-025 | Gate formal de versionamento API/Evento no CI | Pendente |
| INT-026 | Contrato de eventos v1 (schema + registro) | Pendente |

---

## 7. Pendências que NÃO foram commitadas ainda

Os seguintes arquivos foram criados/modificados nesta sessão mas **NÃO foram para o repositório Git**:

- `infra/scripts/start_local_stack.ps1`
- `apps/web-backoffice/.dockerignore`
- `apps/backend/.dockerignore`
- `apps/backend/Dockerfile` (alteração de flags mvn)
- `infra/.env` (senhas removidas)
- `infra.env` (senhas removidas)
- `docs/BACKLOG_BACKOFFICE_WEB.md` (BOW-054 a BOW-064)
- `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md` (INT-025 a INT-029)
- `docs/AGENTE_LICOES_APRENDIDAS.md` (2 lições novas)
- `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` (este arquivo)

**Commit pendente sugerido:**
```
feat: setup local web stack — env seguro, dockerignore, hardening Dockerfile, backlog BOW-054/064 e INT-025/029
```

---

## 8. Para Retomar Esta Sessão em Novo Chat

Copie e cole no início do novo chat:

> "Estou retomando o setup do ambiente local web. Leia `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` e `docs/AGENTE_LICOES_APRENDIDAS.md` para ter contexto completo. Preciso: (1) confirmar que Docker está rodando, (2) subir a stack com `start_local_stack.ps1`, (3) validar health checks e (4) commitar todos os arquivos pendentes listados na seção 7 do documento de restauração."

---

## 9. Regras de Trabalho Compartilhadas (Onboarding de Novo Agente)

Este bloco consolida as regras operacionais definidas nesta parceria. Qualquer novo agente deve seguir na ordem abaixo antes de executar mudanças.

### 9.1 Regras mandatórias
1. Ler o projeto e o contexto completo antes de alterar codigo.
2. Tratar `docs/BACKLOG_FUNCIONALIDADES.md` como fonte oficial do backlog macro.
3. Atualizar backlog/documentacao de rastreabilidade em toda demanda.
4. Nao remover codigo/arquivo fora do escopo explicitamente solicitado.
5. Antes de commit/push/publicacao, validar versao no `pubspec.yaml` (quando aplicavel).
6. Rodar testes e validacoes possiveis apos mudancas (`flutter analyze`, `flutter test`, `npm run lint/test/build`, `mvn -B -DskipTests package` conforme escopo).
7. Se algum teste nao puder ser executado, registrar justificativa explicita.
8. Usar padrao de commit/publicacao: `[versao] - [tipo]: [resumo curto em portugues]`.
9. Nao persistir segredos em arquivo (`infra/.env`, `infra.env`, codigo). Usar env/vault/prompt seguro.
10. Apos distribuicao para homologacao, aguardar de acordo explicito do usuario na mesma sessao antes de promover para `main`.
11. Monitorar workflow CI/CD e confirmar recebimento de e-mail do Firebase App Distribution antes de considerar o ciclo encerrado.

### 9.2 Sequencia de bootstrap para novo agente
1. Ler: `docs/AGENTE_LICOES_APRENDIDAS.md`.
2. Ler: `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
3. Ler a secao 10 (Contexto de Negocio) deste mesmo documento.
4. Ler: `docs/BACKLOG_FUNCIONALIDADES.md`.
5. Ler: `docs/BACKLOG_BACKOFFICE_WEB.md` e `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.
6. Confirmar ambiente local (Node/Java/Maven/Docker) com comandos de validacao.
7. Somente depois iniciar implementacao.

### 9.3 Prompt pronto para "ensinar" outro agente

Use este prompt no inicio de uma nova sessao/agente:

> "Assuma este projeto como desenvolvedor responsavel. Antes de qualquer alteracao, leia `docs/AGENTE_LICOES_APRENDIDAS.md`, `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`, `docs/BACKLOG_FUNCIONALIDADES.md`, `docs/BACKLOG_BACKOFFICE_WEB.md` e `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`. Siga obrigatoriamente as regras de governanca registradas na secao 9 do PONTO_RESTAURACAO. Nao usar segredos em arquivo. Executar testes apos mudancas. Atualizar backlog/documentacao em toda entrega. Em release para homologacao, pausar e aguardar aprovacao explicita antes de promover para main."

---

## 10. Contexto de Negocio (Resumo Executivo para Continuidade)

### 10.1 Proposito do produto
- Entregar uma plataforma integrada mobile + web para operacao de vistorias com padrao NBR, rastreabilidade ponta a ponta e capacidade de evolucao sem novo deploy para ajustes operacionais frequentes.
- Reduzir retrabalho de campo e inconsistencias entre coleta (mobile) e governanca (backoffice).

### 10.2 Problema que estamos resolvendo
- Regras de captura e checklist mudam com frequencia e nao podem depender de release mobile para cada ajuste.
- Operacao precisa funcionar offline com sincronizacao confiavel e auditavel.
- Integracoes externas possuem contratos heterogeneos; o dominio interno precisa permanecer estavel.

### 10.3 Modelo operacional alvo
- Mobile executa captura guiada de vistoria, inclusive com continuidade offline.
- Backoffice web define configuracoes dinamicas (menus, obrigatoriedades, politicas de foto), aprova cadastros e monitora operacao.
- Backend e camada de integracao protegem o dominio interno por ACL/normalizacao e expõem contratos versionados para app e web.

### 10.4 Dominio canonico (linguagem comum)
- Entidades centrais: Demand, Case, Job, Inspection, Report.
- Diretriz: sistemas externos se adaptam ao dominio interno (anti-corruption layer), e nao o contrario.

### 10.5 Personas e objetivos
- Operador de campo: concluir vistoria com clareza de pendencias e baixo atrito.
- Gestor operacional: acompanhar execucao, qualidade e gargalos por tenant/equipe.
- Administrador de configuracao: ajustar regras operacionais sem depender de nova versao do app.
- Time de integracao/TI: manter contratos estaveis, observaveis e seguros.

### 10.6 Capabilidades de negocio prioritarias
- Configuracao dinamica de checklists e obrigatoriedade de fotos.
- Sincronizacao resiliente (offline-first + retentativa + idempotencia).
- Versionamento de API/eventos com compatibilidade controlada.
- Segregacao multi-tenant com governanca por identidade (OIDC/SAML, RBAC e politicas de dominio).

### 10.7 KPIs sugeridos para orientar backlog tecnico
- Tempo medio de conclusao de vistoria.
- Taxa de retrabalho por pendencia NBR.
- Taxa de sucesso de sincronizacao na primeira tentativa.
- Latencia de propagacao de alteracao de configuracao para operacao.
- Incidentes por quebra de contrato API/evento.

### 10.8 Riscos de negocio que guiam decisoes tecnicas
- Acoplamento ao contrato externo bruto (mitigar com dominio canonico + ACL).
- Divergencia de regra entre Check-in, Camera e Revisao (mitigar com fonte unica de regra dinamica).
- Evolucao sem observabilidade (mitigar com correlationId e telemetria de fluxo).

### 10.9 Como isso conversa com o backlog atual
- BOW-054/BOW-056/BOW-058/BOW-060/BOW-064 e INT-025/INT-026 sao os pilares tecnicos mais diretamente ligados a risco/valor de negocio no curto prazo.
- Prioridade de implementacao deve preservar primeiro: integridade operacional da vistoria, estabilidade de contrato e seguranca de dados.

---

## 11. Checklist Final de Onboarding para Novo Agente

Use este checklist no inicio de qualquer nova sessao para confirmar que nada critico ficou de fora.

### 11.1 Acesso e permissao minima
- Repositorio Git com permissao de leitura e escrita.
- Permissao para acompanhar pipelines no GitHub Actions.
- Acesso ao ambiente de distribuicao homologacao/producao (quando aplicavel).
- Confirmacao de como obter segredos sem arquivo: variavel de sessao, cofre local ou mecanismo equivalente aprovado.

### 11.2 Verificacao tecnica rapida (smoke de ambiente)
- Node, npm, Java, Maven e Docker respondendo em terminal.
- Docker Desktop em estado Running.
- `docker compose -f infra/docker-compose.yml config` sem erro.
- Health checks principais acessiveis apos subida da stack.

### 11.3 Contratos operacionais obrigatorios
- Nao gravar segredos em arquivo versionado.
- Atualizar backlog e rastreabilidade em toda entrega.
- Executar checkpoint de continuidade em cada marco: registrar "feito", "estado atual" e "proxima acao" neste documento.
- Executar testes pertinentes ao escopo e registrar resultado.
- Se teste nao executado, registrar motivo de forma explicita.
- Respeitar gate de release: homologacao primeiro e promocao para main somente com aprovacao explicita na mesma sessao.

### 11.4 Estado atual a ser retomado
- Docker passou por migracao de dados para D e pode levar alguns minutos no primeiro start.
- Ha alteracoes locais ainda nao commitadas (ver secao 7).
- Proxima validacao operacional: confirmar Docker Running, subir stack local, validar health checks e so depois preparar commit.

### 11.5 Criterio de sessao concluida
- Ambiente local validado (ou bloqueio documentado com causa e tentativa feita).
- Backlog e documentacao atualizados com o que foi executado.
- Evidencias de teste registradas.
- Se houve distribuicao, CI/CD monitorado ate confirmacao de entrega.

---

## 12. Checkpoint Operacional Continuo

### Checkpoint 2026-04-01 (status de runtime Docker)
- Feito:
  - Commit de onboarding e continuidade criado (`666ba11`).
  - Docker Desktop reiniciado e processos confirmados em execucao.
  - Validacao WSL executada repetidamente.
  - Confirmado em log do Docker o reset (`POST /app/reset`).
  - Diagnosticado bloqueio de permissao para inicializar `LxssManager` em terminal sem elevacao.
- Estado atual:
  - Tela do Docker Desktop permanece em `Starting the Docker Engine...`.
  - `wsl -l -v` lista apenas `Ubuntu` e `docker-desktop-data` (distro `docker-desktop` ausente).
  - Engine ainda nao responde para `docker version`/`docker ps`.
- Proxima acao:
  - Executar em PowerShell Administrador: `wsl --shutdown`, `wsl --update`, `Start-Service LxssManager` e abrir Docker Desktop.
  - Revalidar com `wsl -l -v`, `docker version`, `docker ps`.
  - Com engine pronto, subir stack local via `infra/scripts/start_local_stack.ps1` e registrar novo checkpoint.

### Checkpoint 2026-04-01 (recuperacao concluida)
- Feito:
  - Distros Docker recriadas no WSL (`docker-desktop` e `docker-desktop-data`).
  - Validado `wsl -l -v` com as distros Docker em `Running`.
  - Validado `docker version` com bloco `Server: Docker Desktop 4.28.0`.
  - Validado `docker ps` respondendo normalmente.
- Estado atual:
  - Docker Engine operacional no host local.
- Proxima acao:
  - Subir stack local usando `infra/scripts/start_local_stack.ps1` com segredos via variavel de ambiente/cofre/prompt seguro.
  - Validar `docker compose ps`, `http://localhost:3000/health` e `http://localhost:8080/actuator/health`.

### Checkpoint 2026-04-01 (ajuste de robustez no script)
- Feito:
  - Corrigida a leitura do parametro `Detach` no `infra/scripts/start_local_stack.ps1`.
  - O script agora aceita valores booleanos, `true/false` em texto e `1/0`.
- Estado atual:
  - Erro de transformacao de argumento para `Detach` mitigado.
- Proxima acao:
  - Reexecutar subida da stack com `-Detach 1` (ou sem `-Detach`, pois o default continua em modo destacado).

### Checkpoint 2026-04-01 (validacao compose)
- Feito:
  - `docker compose ps` executado com retorno vazio (sem servicos em execucao).
  - `docker compose config` validado com sucesso.
- Estado atual:
  - Docker Engine operacional.
  - Stack local ainda nao iniciada.
  - Variaveis sensiveis permanecem com placeholder e devem ser resolvidas por env/vault/prompt.
- Proxima acao:
  - Subir stack com `start_local_stack.ps1`.
  - Validar `docker compose ps` e health checks web/api.

### Checkpoint 2026-04-01 (stack operacional)
- Feito:
  - Corrigido bind do web para healthcheck (`HOSTNAME=0.0.0.0`) em `infra/docker-compose.yml`.
  - `docker compose up -d --build` concluido com `web/api/db/cache/proxy` em status healthy/up.
  - Validacao de endpoints no host executada.
- Estado atual:
  - Endpoints diretos `localhost:3000` e `localhost:8080` nao estao expostos no host no compose atual.
  - Endpoints via proxy estao respondendo com HTTP 200.
- Proxima acao:
  - Usar `http://localhost/health` e `http://localhost/api/actuator/health` para smoke local.
  - Opcional: se desejar acesso direto em 3000/8080, adicionar mapeamento de portas em `web` e `api`.

### Checkpoint 2026-04-01 (BOW-054 v1 documental)
- Feito:
  - Publicada a V1 documental do Canonical Domain no backlog web (`docs/BACKLOG_BACKOFFICE_WEB.md`).
  - Incluidos: glossario oficial, transicoes de estado, envelope minimo obrigatorio, mapeamento ACL e invariantes de dominio.
- Estado atual:
  - BOW-054 com status `Em andamento (v1 documental publicado)`.
  - Dependencias de enforcement em runtime permanecem para BOW-056/BOW-058/BOW-060 e INT-025/026/027.
- Proxima acao:
  - Traduzir o modelo v1 para contratos OpenAPI e validacoes de runtime.

### Checkpoint 2026-04-01 (BOW-056 fundacao + portal interno)
- Feito:
  - Fundacao OpenAPI v1 implementada no backend com `springdoc`.
  - Endpoints de docs publicados: `/api/openapi/v1` e `/api/swagger`.
  - Endpoints criticos mobile v1 adicionados: `GET /api/mobile/checkin-config` e `POST /api/mobile/inspections/finalized`.
  - Envelope minimo (`tenantId`, `correlationId`, `actorId`) e idempotency-key aplicados nos contratos criticos.
  - Portal interno implantado em `docs/internal-portal` com pipeline `.github/workflows/internal_docs_ci.yml`.
- Estado atual:
  - Backend compila com artefato gerado (`api-0.1.0.jar`).
  - Build local do portal nao validado por ausencia de Python no host; validacao ocorrerá via CI.
- Proxima acao:
  - Implementar gate de compatibilidade de contrato em CI (INT-025).
  - Publicar exemplos de contrato e catalogo canônico de erros.

---

_Documento de restauração mantido pelo agente (Copilot) como ponto de continuidade operacional._
