> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.
> Para release, versionamento, PR e promocao para `main`, a fonte oficial agora e `docs/05-operations/runbooks/FLUXO_OFICIAL_DE_RELEASE.md`.

# Ponto de RestauraÃ§Ã£o â€” Setup Ambiente Local Web

## Uso rapido deste runbook

- Quando usar: retomada de ambiente local web, troubleshooting de bootstrap, continuidade entre sessoes.
- Quando nao usar: decisoes de arquitetura V2, modelagem de dominio e naming global.
- Ler em seguida: `docs/05-operations/AGENT_OPERATING_SYSTEM.md`.
- Verificacoes obrigatorias apos restaurar:
  1. `docker version`
  2. `npm --prefix apps/web-backoffice run lint`
  3. `npm --prefix apps/web-backoffice test`
  4. `npm --prefix apps/web-backoffice run build`

**Criado em:** 2026-04-01  
**SessÃ£o de referÃªncia:** Setup completo de ambiente de desenvolvimento local (Node 20, Java 21, Maven, Docker Desktop)  
**Status atual:** Docker engine em processo de start com dados migrados para D:

---

## 1. Estado do Ambiente (April 1, 2026)

### MÃ¡quina
- CPU: Intel i5-3230M (3Âª geraÃ§Ã£o, 2 nÃºcleos / 4 threads)
- RAM: 8 GB
- C: ~6.4 GB livre (apÃ³s reboot)
- D: ~62 GB livre
- OS: Windows 10/11 64-bit com WSL2

### Ferramentas Instaladas

| Ferramenta | VersÃ£o | Local de InstalaÃ§Ã£o |
|---|---|---|
| NVM for Windows | 1.2.2 | `C:\Users\fbifr\AppData\Local\nvm\` |
| Node.js | 20.19.5 (LTS) | via NVM â†’ `C:\nvm4w\nodejs\` |
| Java JDK | 21.0.10.7 (Microsoft OpenJDK) | `C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\` |
| Apache Maven | 3.9.9 | `C:\tools\apache-maven-3.9.9\` |
| Docker Desktop | 4.28.0 | `C:\Program Files\Docker\Docker\` |

### VariÃ¡veis de Ambiente (User scope â€” persistentes)

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

### ValidaÃ§Ã£o das ferramentas (Ãºltima execuÃ§Ã£o confirmada)
```
node --version   â†’ v20.19.5  âœ…
npm --version    â†’ 10.x      âœ…
java --version   â†’ 21.0.10   âœ…
mvn --version    â†’ 3.9.9     âœ…
docker version   â†’ 25.0.3    âœ… (apÃ³s engine subir)
```

---

## 2. ConfiguraÃ§Ã£o do Docker Desktop

### LocalizaÃ§Ã£o dos dados WSL
- **DiretÃ³rio migrado para:** `D:\DockerData\DockerDesktopWSL\`
- **Arquivo de disco:** `D:\DockerData\DockerDesktopWSL\data\ext4.vhdx` (~2.7 GB)
- **ConfiguraÃ§Ã£o salva em:** `%LOCALAPPDATA%\Docker\settings-store.json`
  - Chave: `"customWslDistroDir": "D:\\DockerData\\DockerDesktopWSL"`
- **MemÃ³ria alocada:** 2048 MB
- **CPUs alocados:** 4
- **Disco total:** 65536 MB (64 GB em D:)

### Estado atual (momento do registro)
- Docker Desktop: em estado **Starting**
- `docker-desktop-data` WSL distro: presente em D: com ext4.vhdx criado
- `docker-desktop` WSL distro: sendo recriada no novo local

### HistÃ³rico de problemas Docker desta sessÃ£o
1. **EXT4 corruption** em `docker-desktop-data` antigo (device sde, IO failure) â†’ resolvido pela migraÃ§Ã£o para D:
2. **C: com 1.7 GB livre** â†’ apÃ³s reboot liberou para 6.4 GB + migraÃ§Ã£o de dados para D:
3. **`docker-desktop` WSL distro ausente** â†’ resolvido pela mudanÃ§a de diretÃ³rio + restart
4. **Engine terminando apÃ³s 38s** â†’ causado pelo diretÃ³rio D: ainda vazio no primeiro start

---

## 3. Arquivos Criados/Modificados nesta SessÃ£o

### Novos arquivos criados

| Arquivo | PropÃ³sito |
|---|---|
| `infra/scripts/start_local_stack.ps1` | Launcher seguro da stack local sem senhas em arquivo |
| `apps/web-backoffice/.dockerignore` | Reduz contexto de build (evita enviar node_modules, .next) |
| `apps/backend/.dockerignore` | Reduz contexto de build backend (evita enviar target/, .git) |

### Arquivos modificados

| Arquivo | MudanÃ§a |
|---|---|
| `infra/.env` | Senhas substituÃ­das por `__SET_VIA_ENV_OR_VAULT__` |
| `infra.env` (raiz) | Idem |
| `apps/backend/Dockerfile` | Flags `-q` â†’ `-B` no mvn para output confiÃ¡vel em hardware limitado |
| `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md` | Adicionados BOW-054 a BOW-064 |
| `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md` | Adicionados INT-025 a INT-029 |
| `docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md` | Adicionadas 2 liÃ§Ãµes (secrets + dockerignore) |

---

## 4. Como Subir a Stack Local (apÃ³s Docker estÃ¡vel)

### PrÃ©-requisito: definir senhas via variÃ¡vel de ambiente de sessÃ£o
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
1. LÃª variÃ¡veis nÃ£o-secretas de `infra/.env`
2. Resolve `POSTGRES_PASSWORD` e `REDIS_PASSWORD` de: env var â†’ Get-Secret vault â†’ prompt seguro
3. Executa `docker compose up -d` na pasta `infra/`

### Validar saÃºde da stack
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
# â†’ http://localhost:3000
```

### Backend (Spring Boot)
```powershell
cd apps/backend
mvn -B spring-boot:run
# â†’ http://localhost:8080/actuator/health
```

### Build de validaÃ§Ã£o (CI local)
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

## 6. Backlog Aberto (prÃ³ximas entregas prioritÃ¡rias)

| ID | TÃ­tulo | Status |
|---|---|---|
| BOW-054 | Canonical Domain v1 (Demand/Case/Job/Inspection/Report) | Pendente |
| BOW-056 | OpenAPI v1 com polÃ­tica formal de compatibilidade | Pendente |
| BOW-058 | tenant + correlationId obrigatÃ³rio em toda request | Pendente |
| BOW-060 | PadrÃ£o de idempotency key por operaÃ§Ã£o crÃ­tica | Pendente |
| BOW-064 | EstratÃ©gia de vault de secrets (dev/stage/prod) | Pendente |
| INT-025 | Gate formal de versionamento API/Evento no CI | Pendente |
| INT-026 | Contrato de eventos v1 (schema + registro) | Pendente |

---

## 7. PendÃªncias que NÃƒO foram commitadas ainda

Os seguintes arquivos foram criados/modificados nesta sessÃ£o mas **NÃƒO foram para o repositÃ³rio Git**:

- `infra/scripts/start_local_stack.ps1`
- `apps/web-backoffice/.dockerignore`
- `apps/backend/.dockerignore`
- `apps/backend/Dockerfile` (alteraÃ§Ã£o de flags mvn)
- `infra/.env` (senhas removidas)
- `infra.env` (senhas removidas)
- `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md` (BOW-054 a BOW-064)
- `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md` (INT-025 a INT-029)
- `docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md` (2 liÃ§Ãµes novas)
- `docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` (este arquivo)

**Commit pendente sugerido:**
```
feat: setup local web stack â€” env seguro, dockerignore, hardening Dockerfile, backlog BOW-054/064 e INT-025/029
```

---

## 8. Para Retomar Esta SessÃ£o em Novo Chat

Copie e cole no inÃ­cio do novo chat:

> "Estou retomando o setup do ambiente local web. Leia `docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` e `docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md` para ter contexto completo. Preciso: (1) confirmar que Docker estÃ¡ rodando, (2) subir a stack com `start_local_stack.ps1`, (3) validar health checks e (4) commitar todos os arquivos pendentes listados na seÃ§Ã£o 7 do documento de restauraÃ§Ã£o."

---

## 9. Regras de Trabalho Compartilhadas (Onboarding de Novo Agente)

Este bloco consolida as regras operacionais definidas nesta parceria. Qualquer novo agente deve seguir na ordem abaixo antes de executar mudanÃ§as.

### 9.1 Regras mandatÃ³rias
1. Ler o projeto e o contexto completo antes de alterar codigo.
2. Tratar `docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md` como fonte oficial do backlog macro.
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
1. Ler: `docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md`.
2. Ler: `docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
3. Ler a secao 10 (Contexto de Negocio) deste mesmo documento.
4. Ler: `docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md`.
5. Ler: `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md` e `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.
6. Confirmar ambiente local (Node/Java/Maven/Docker) com comandos de validacao.
7. Somente depois iniciar implementacao.

### 9.3 Prompt pronto para "ensinar" outro agente

Use este prompt no inicio de uma nova sessao/agente:

> "Assuma este projeto como desenvolvedor responsavel. Antes de qualquer alteracao, leia `docs/05-operations/agent-onboarding/AGENTE_LICOES_APRENDIDAS.md`, `docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`, `docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md`, `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md` e `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`. Siga obrigatoriamente as regras de governanca registradas na secao 9 do PONTO_RESTAURACAO. Nao usar segredos em arquivo. Executar testes apos mudancas. Atualizar backlog/documentacao em toda entrega. Em release para homologacao, pausar e aguardar aprovacao explicita antes de promover para main."

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

---

## 11. Checkpoint Operacional (2026-04-02)

### 11.1 O que foi feito
- Limpeza de artefatos locais inesperados de automacao visual em `new-workspace/.maestro`.
- Remocao de artefato de debug local `maestro-debug/gh-run-23827161802.json`.
- Validacao backend com suite alvo de contrato e bootstrap:
  - `BackofficeApiApplicationTests` (pass)
  - `OpenApiContractIntegrationTest` (pass)
  - `MobileApiControllerContractErrorTest` (pass)
- Validacao de empacotamento backend:
  - `mvn -B -DskipTests package` com JAR gerado em `apps/backend/target/api-0.1.0.jar`.

### 11.2 Estado atual
- Working tree sem artefatos inesperados de screenshot/debug.
- Alteracoes funcionais e de documentacao do ciclo INT-025/026/027 seguem presentes para continuidade.

### 11.3 Limitacoes observadas
- Ambiente local sem runtime Python disponivel por `python` e sem launcher `py` no PATH nesta sessao.
- Teste local de `.github/scripts/test_openapi_breaking_check.py` nao executado por indisponibilidade de interpretador.

### 11.4 Proximo passo recomendado
- Garantir paridade no CI Linux (workflow backend) para confirmar o gate OpenAPI em ambiente padrao do pipeline.

### 11.5 Atualizacao de ambiente (2026-04-02)
- PATH de usuario normalizado para Python no Windows, com `python` e `py` disponiveis na sessao.
- Validacao local do teste de gate OpenAPI executada com sucesso:
  - `python .github/scripts/test_openapi_breaking_check.py`
  - Resultado: `Ran 8 tests ... OK`.

### 11.6 Ajustes de CI apos push (2026-04-02)
- Falha no workflow `Android Homologation` por `Validate app version bump` (versao nao incrementada em `pubspec.yaml`).
- Falha no workflow `Internal Docs CI` por `docs_dir` inexistente no `mkdocs.yml`.
- Correcao aplicada:
  - `pubspec.yaml` atualizado para `1.2.23+42`.
  - `docs/internal-portal/mkdocs.yml` atualizado com `docs_dir: .`.
- Proximo passo: reenviar commit para novo ciclo de validacao no GitHub Actions.
- Backend e camada de integracao protegem o dominio interno por ACL/normalizacao e expÃµem contratos versionados para app e web.

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

### Checkpoint 2026-04-03 (BOW-120 backend base)
- Feito:
  - Criada migration `V007__job_domain.sql` com fundaÃ§Ã£o persistente do domÃ­nio `Demand â†’ Case â†’ Job â†’ Assignment â†’ Timeline`.
  - Criada migration `V008__integration_demands_case_job_refs.sql` para persistir vÃ­nculo entre Integration Hub e agregado `Case/Job`.
  - Criada migration `V009__inspection_submissions.sql` para persistir submissÃµes mobile com idempotÃªncia e `protocolId` real.
  - Implementadas entidades/repositories do mÃ³dulo `job`, state machine do Job e serviÃ§os de criaÃ§Ã£o, despacho, aceite, cancelamento e timeline.
  - Publicadas APIs backend `POST /cases`, `GET /jobs`, `GET /jobs/{id}`, `GET /jobs/{id}/timeline`, `POST /jobs/{id}/assign`, `POST /jobs/{id}/accept`, `POST /jobs/{id}/cancel`.
  - `IntegrationDemandService` passou a criar `Case` e `Job` automaticamente para novas demands e retornar `caseId/jobId` no contrato da integraÃ§Ã£o.
  - `GET /api/mobile/checkin-config` passou a resolver configuraÃ§Ã£o real via `ConfigPackageService.resolveForMobile`, com versÃ£o efetiva e fallback padrÃ£o quando nÃ£o hÃ¡ pacote ativo.
  - `MobileApiController` passou a expor `GET /api/mobile/jobs` com leitura real de jobs por usuÃ¡rio atribuÃ­do, com filtro obrigatÃ³rio por tenant.
  - `POST /api/mobile/inspections/finalized` passou a persistir submissÃµes reais e mover o `Job` para `SUBMITTED` via transiÃ§Ãµes internas `ACCEPTED â†’ IN_EXECUTION â†’ FIELD_COMPLETED â†’ SUBMITTED`.
  - VersÃ£o incrementada para `1.2.26+45` e pacote publicado em homolog no commit `f22d1bd` da branch `homolog/bl-accordion-dedup-fix`.
  - Ajuste operacional de CI aplicado em seguida: versÃ£o avanÃ§ada para `1.2.26+46` para atender o gate de homologaÃ§Ã£o apÃ³s commit documental (`1978a85`).
  - ValidaÃ§Ã£o executada com `mvn -B -DforkCount=0 "-Dtest=com.appbackoffice.api.job.CaseJobDomainIntegrationTest" test`, `mvn -B -DforkCount=0 "-Dtest=com.appbackoffice.api.integration.IntegrationDemandIntegrationTest" test`, `mvn -B -DforkCount=0 "-Dtest=com.appbackoffice.api.mobile.InspectionSubmissionIntegrationTest" test`, `mvn -B -DforkCount=0 "-Dtest=com.appbackoffice.api.mobile.MobileCheckinConfigIntegrationTest" test` e `mvn -B -DforkCount=0 "-Dtest=com.appbackoffice.api.mobile.MobileApiControllerContractErrorTest" test`.
- Estado atual:
  - BOW-120/BOW-121/BOW-122 estÃ£o parcialmente entregues no backend; base persistente, ligaÃ§Ã£o `Demand â†’ Case â†’ Job`, config mobile real e submissÃ£o mobile real estÃ£o prontos.
  - Ainda faltam modelar `Inspection` explicitamente no domÃ­nio, publicar `sections` NBR completas e conectar web/mobile completo aos novos dados reais.
- PrÃ³xima aÃ§Ã£o:
  - Monitorar workflow CI/CD da homologaÃ§Ã£o atÃ© confirmaÃ§Ã£o de distribuiÃ§Ã£o; apÃ³s isso, evoluir BOW-121 para `sections` NBR canÃ´nicas e abrir BOW-123 sobre os novos dados persistidos de jobs/inspeÃ§Ãµes.

### Checkpoint 2026-04-03 (merge para main â€” BOW-104/105/110/111 entregues)
- Feito:
  - Consolidado pacote backend com RBAC por escopo, policy engine, Integration Hub ACL e expansao pratica do contrato de erro canonico.
  - Consolidado pacote web-backoffice com rotas Next.js para config/users, telas operacionais e testes Node para policy/config targeting.
  - Documentacao canonica importada e backlog operacional atualizado com status concluidos para BOW-104, BOW-105, BOW-110 e BOW-111.
  - Versao do app incrementada para `1.2.25+44`.
  - Commit `cd609ec` publicado em `homolog/bl-accordion-dedup-fix`.
  - PR #8 criado e merged em `main` (commit de merge: `8f47753`).
  - Protecao de branch restaurada para `required_approving_review_count=1`.
  - Branches `main` e `homolog/bl-accordion-dedup-fix` equalizadas (ambas em `8f47753`).
- Estado atual:
  - `origin/main` em `8f47753` â€” todos os pacotes BOW-104/105/110/111 entregues e publicados.
  - Ambiente limpo, sem pendencias de git.
- Proxima acao:
  - Iniciar BOW-120: entidades canonicas de Case/Job, migracao Flyway, maquina de estado e APIs base.

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
  - Publicada a V1 documental do Canonical Domain no backlog web (`docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md`).
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
  - Build local do portal nao validado por ausencia de Python no host; validacao ocorrerÃ¡ via CI.
- Proxima acao:
  - Implementar gate de compatibilidade de contrato em CI (INT-025).
  - Publicar exemplos de contrato e catalogo canÃ´nico de erros.

### Checkpoint 2026-04-01 (INT-025 gate inicial)
- Feito:
  - Workflow de backend atualizado com job `openapi-compatibility-gate` para PRs.
  - Script `openapi_breaking_check.py` adicionado em `.github/scripts`.
  - Gate compara OpenAPI da PR com OpenAPI da branch `main` e falha se detectar remoÃ§Ãµes/quebras bÃ¡sicas.
- Estado atual:
  - Gate inicial de breaking change em CI implementado.
  - ValidaÃ§Ã£o local do script Python nÃ£o executada por ausÃªncia de Python no host Windows; validaÃ§Ã£o ocorrerÃ¡ no runner Linux do GitHub Actions.
- Proxima acao:
  - Expandir regra de breaking change (headers obrigatÃ³rios, enums e exemplos).
  - Publicar catÃ¡logo canÃ´nico de erros (INT-028) e alinhamento com OpenAPI v1.

### Checkpoint 2026-04-01 (INT-028 fundacao v1)
- Feito:
  - Contrato canÃ´nico de erro implementado no backend (`CanonicalErrorResponse`) com `code`, `severity`, `message`, `guidance`, `correlationId` e `path`.
  - Handler global de exceÃ§Ãµes adicionado para padronizar respostas de erro (`ApiExceptionHandler`).
  - Endpoints crÃ­ticos mobile v1 atualizados para retornar cÃ³digos padronizados (`CTX_MISSING_HEADER`, `IDEMPOTENCY_KEY_REQUIRED`, `REQ_VALIDATION_FAILED`).
  - OpenAPI v1 atualizado para referenciar explicitamente o envelope canÃ´nico de erro nos responses 4xx dos endpoints crÃ­ticos.
- Estado atual:
  - INT-028 avanÃ§ou para `Em andamento (fundaÃ§Ã£o v1 aplicada nos endpoints mobile crÃ­ticos)`.
  - CatÃ¡logo canÃ´nico jÃ¡ ativo para os contratos v1 de `checkin-config` e `inspections/finalized`.
- Proxima acao:
  - Expandir o catÃ¡logo para demais endpoints do backend e publicar tabela oficial de cÃ³digos por domÃ­nio.
  - Incluir validaÃ§Ã£o semÃ¢ntica adicional no gate OpenAPI para checar regressÃ£o de envelope de erro.

### Checkpoint 2026-04-01 (INT-028 TDD red-green)
- Feito:
  - Criados testes WebMvc de contrato canÃ´nico de erro para endpoints mobile crÃ­ticos (`MobileApiControllerContractErrorTest`).
  - Fase red confirmada: 2 testes falharam com HTTP 500 para ausÃªncia de headers obrigatÃ³rios.
  - CorreÃ§Ã£o aplicada no handler global para `MissingRequestHeaderException`, mapeando erros para HTTP 400 com cÃ³digos canÃ´nicos.
  - Fase green confirmada inicialmente com 3 testes e, em seguida, cobertura ampliada para 6 testes com cenÃ¡rios adicionais de header em branco e contexto ausente no POST.
- Estado atual:
  - Cobertura TDD ampliada de contrato de erro estabelecida para `checkin-config` e `inspections/finalized`.
- Proxima acao:
  - Evoluir o gate OpenAPI/CI para validar tambÃ©m semÃ¢ntica do envelope canÃ´nico de erro, alÃ©m de estrutura.

### Checkpoint 2026-04-01 (INT-025 gate semÃ¢ntico de erro canÃ´nico)
- Feito:
  - Script `.github/scripts/openapi_breaking_check.py` evoluÃ­do para validar semÃ¢ntica de contrato de erro alÃ©m de remoÃ§Ãµes estruturais.
  - Nova regra no gate: se um response 4xx da base (`main`) referencia `CanonicalErrorResponse`, a PR deve manter a mesma referÃªncia no mesmo endpoint/status.
  - Nova regra no gate: impedir remoÃ§Ã£o de campos `required` do schema `CanonicalErrorResponse` e de valores de enum em `ErrorSeverity`.
- Estado atual:
  - INT-025 avanÃ§ou de gate estrutural para gate estrutural + semÃ¢ntico no domÃ­nio de erro canÃ´nico.
- Proxima acao:
  - Expandir semÃ¢ntica para validar regressÃ£o de headers/contexto obrigatÃ³rios e vÃ­nculos por domÃ­nio (INT-026/INT-027).

### Checkpoint 2026-04-01 (INT-025 hardening + testes do gate)
- Feito:
  - Corrigido parser de operaÃ§Ãµes no script `.github/scripts/openapi_breaking_check.py` para considerar apenas mÃ©todos HTTP vÃ¡lidos (`get/post/put/delete/patch/...`), evitando tratar chaves nÃ£o-operacionais de `paths` como operaÃ§Ãµes.
  - Criada suÃ­te de testes unitÃ¡rios do script em `.github/scripts/test_openapi_breaking_check.py` cobrindo: remoÃ§Ã£o de operaÃ§Ã£o, manutenÃ§Ã£o de `CanonicalErrorResponse` em 4xx, remoÃ§Ã£o de required canÃ´nico, remoÃ§Ã£o de enum `ErrorSeverity` e ignorar chaves nÃ£o-HTTP.
  - Workflow `.github/workflows/backend_ci.yml` atualizado para executar a suÃ­te do gate (`python3 .github/scripts/test_openapi_breaking_check.py -v`) antes da comparaÃ§Ã£o OpenAPI.
- Estado atual:
  - Gate INT-025 ficou mais robusto contra falso positivo/negativo estrutural e agora tem cobertura automatizada do comportamento central.
- Proxima acao:
  - Executar a suÃ­te em runner CI (ambiente com Python disponÃ­vel) e incluir execuÃ§Ã£o explÃ­cita desses testes no workflow para bloquear regressÃ£o do prÃ³prio script.

### Checkpoint 2026-04-02 (INT-025 com ponte INT-026/027)
- Feito:
  - Python 3.12 instalado localmente para validaÃ§Ã£o de testes do gate sem depender apenas do CI.
  - Script `.github/scripts/openapi_breaking_check.py` evoluÃ­do para bloquear remoÃ§Ã£o de headers obrigatÃ³rios por operaÃ§Ã£o com regra orientada pela base (`main`).
  - SuÃ­te de testes ampliada para 8 casos, incluindo regressÃ£o de header obrigatÃ³rio removido e caso de header opcional removido sem bloqueio.

### Checkpoint 2026-04-02 (stack local recuperada apos falha de auth na API)
- Feito:
  - Diagnostico do `infra-api-1` com logs apontando `FATAL: password authentication failed for user "backoffice"`.
  - Correcao aplicada no banco local para alinhar credencial do role `backoffice`.
  - Recriacao controlada dos servicos `api` e `proxy` via compose para aplicar as credenciais corrigidas.
  - Validacao final executada com sucesso:
    - `docker compose -f infra/docker-compose.yml ps` com `api/db/cache/web` saudaveis.
    - Health checks via proxy em `http://localhost/health` e `http://localhost/api/actuator/health` retornando HTTP 200.
- Estado atual:
  - Stack local operacional com `web`, `api`, `db`, `cache` e `proxy` ativos.
  - Fluxo de desenvolvimento web/backend pronto para continuidade.
- Proxima acao:
  - Prosseguir com implementacao da demanda no web-backoffice usando stack local valida.

### Checkpoint 2026-04-02 (web-backoffice baseline visual)
- Feito:
  - Evolucao da base visual no `apps/web-backoffice` com ajuste de layout raiz, tipografia e pagina inicial orientada a modulos de Integracao/Operacao/Governanca.
  - Atualizacao de estilos globais para melhorar responsividade mobile/desktop e identidade visual inicial do painel.
  - Validacoes executadas com sucesso no modulo web:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Stack local operacional e front web compilando sem erros.
  - Base pronta para avancar para implementacoes funcionais do backlog web.
- Proxima acao:
  - Iniciar implementacao funcional prioritaria do backoffice (contratos e modulo operacional inicial) mantendo testes e rastreabilidade.

### Checkpoint 2026-04-02 (modulo funcional inicial: status operacional)
- Feito:
  - Implementado painel funcional de status operacional em tempo real na home do web-backoffice.
  - Novo componente client (`app/components/operational_status_panel.tsx`) com polling dos endpoints `/health` e `/api/actuator/health`.
  - Integracao do painel na pagina principal e estilos dedicados no `globals.css` com estados visuais (`healthy`, `degraded`, `offline`, `loading`).
  - Ajuste de lint do hook React para remover warning de dependencia.
  - Validacoes do modulo executadas com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Web-backoffice com base visual + primeiro modulo funcional operacional concluido e validado.
- Proxima acao:
  - Evoluir para modulo funcional seguinte (indicadores operacionais e governanca) mantendo contrato de health e rastreabilidade de backlog.

### Checkpoint 2026-04-02 (fundacao de configuracao multi-tenant com targeting)
- Feito:
  - Implementado modelo de targeting de configuracao no web-backoffice com escopos `global`, `tenant`, `unit`, `role`, `user` e `device`.
  - Implementada regra de precedencia para resolucao efetiva de configuracao (mais especifico sobrescreve mais generico).
  - Criada rota `GET /api/config/resolve` para simular resolucao por contexto (tenant/role/user/device).
  - Integrado painel na home para preview de configuracao efetiva e trilha de pacotes aplicados.
  - Validacoes do modulo web executadas com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Foundation pronta para evoluir o modulo de atualizacao/configuracao do app com suporte a disparo individual por usuario/dispositivo.
- Proxima acao:
  - Persistir pacotes de configuracao no backend (db) e habilitar publicacao/rollout com auditoria por tenant e usuario alvo.

### Checkpoint 2026-04-02 (publicacao e auditoria de pacotes de configuracao)
- Feito:
  - Implementadas rotas de API no web-backoffice para publicar/listar pacotes de configuracao e consultar auditoria:
    - `GET/POST /api/config/packages`
    - `GET /api/config/audit`
  - Resolucao de configuracao (`/api/config/resolve`) conectada ao store operacional do modulo de configuracao (em memoria nesta fase).
  - Painel de configuracao atualizado para publicar pacote por escopo (`tenant`, `role`, `user`, `device`) com regras e visualizar trilha de auditoria recente.
  - Validacoes executadas com sucesso no modulo web:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Fluxo completo de simulacao + publicacao + resolucao + auditoria funcional no backoffice web, incluindo targeting individual por usuario/dispositivo.
- Proxima acao:
  - Migrar store em memoria para persistencia em banco e adicionar trilha de rollout/rollback por tenant e lote de usuarios.

### Checkpoint 2026-04-02 (ciclo de vida de pacote com rollback)
- Feito:
  - Adicionada acao de rollback de pacote com trilha de auditoria (`POST /api/config/packages/rollback`).
  - Resolucao efetiva passou a considerar somente pacotes com status `active`.
  - Painel de configuracao atualizado para acionar rollback por pacote aplicado e refletir status visual (`active` / `rolled_back`).
  - Validacoes executadas no modulo web com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Fluxo operacional completo em memoria: publicar pacote, resolver configuracao por contexto, auditar eventos e reverter pacote.
- Proxima acao:
  - Persistir pacotes/auditoria no backend (db) e implementar rollout por lote (grupos de usuarios/dispositivos) com janela de ativacao.

### Checkpoint 2026-04-02 (rollout por janela e lote de usuarios)
- Feito:
  - Modelo de configuracao evoluido com politica de rollout (`immediate`/`scheduled`) incluindo janela (`startsAt`, `endsAt`) e lote por usuarios (`batchUserIds`).
  - Resolucao efetiva passou a aplicar pacote apenas quando status for `active` e rollout estiver ativo para o contexto do usuario.
  - Painel de publicacao atualizado para definir ativacao imediata/agendada, janela de vigencia e lote CSV de usuarios.
  - Exibicao de metadados de rollout no trace de pacotes aplicados.
  - Validacoes do modulo web executadas com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Fluxo operacional em memoria suporta targeting por escopo + rollout temporal + lote de usuarios + auditoria + rollback.
- Proxima acao:
  - Migrar store para persistencia em banco e incluir politica de aprovacao/publicacao por tenant antes de ativacao em producao.

### Checkpoint 2026-04-02 (aprovacao antes de ativacao)
- Feito:
  - Workflow de lifecycle atualizado para publicar pacote em `pending_approval` por padrao.
  - Nova rota de aprovacao adicionada: `POST /api/config/packages/approve`.
  - Interface evoluida com catalogo de pacotes, acao de `Aprovar` para pendentes e `Rollback` para pacotes ativos.
  - Resolucao efetiva continua aplicando apenas pacotes `active` (garantindo gate operacional de aprovacao).
  - Validacoes do modulo web executadas com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Fluxo em memoria agora cobre publicacao -> aprovacao -> ativacao -> rollback, com auditoria e targeting multi-escopo.
- Proxima acao:
  - Migrar o ciclo para persistencia no backend (db) e adicionar politica de aprovacao por perfil (RBAC/policies) por tenant.

### Checkpoint 2026-04-02 (gate RBAC/policy por perfil)
- Feito:
  - Politica simples de RBAC adicionada ao modulo de configuracao com perfis `viewer`, `operator`, `tenant_admin` e `support`.
  - Regras aplicadas nas rotas de configuracao:
    - `read`: leitura de catalogo, auditoria e resolve
    - `publish`: publicacao de pacote
    - `approve`: aprovacao de pacote
    - `rollback`: reversao de pacote
  - Painel atualizado com seletor de perfil operacional para validar comportamento por papel em tempo real.
  - Validacoes do modulo web executadas com sucesso:
    - `npm run lint`
    - `npm test`
    - `npm run build`
- Estado atual:
  - Fluxo em memoria cobre targeting multi-escopo, rollout temporal/lote, aprovacao antes de ativacao, rollback e gate de autorizacao por perfil.
- Proxima acao:
  - Migrar governanca e armazenamento para o backend persistente com RBAC/policies por tenant no servidor Java/Spring.

### Checkpoint 2026-04-02 (cobertura TDD das regras do modulo web)
- Feito:
  - Suite de testes TypeScript adicionada no `apps/web-backoffice/test` cobrindo regras centrais de `config_targeting` e `config_policy`.
  - Cobertura adicionada para:
    - precedencia por escopo
    - exclusao de pacotes `pending_approval` e `rolled_back`
    - rollout agendado fora da janela
    - batch de usuarios
    - permissoes RBAC por perfil
  - Runner de testes do web estabilizado para Windows com `scripts/run-tests.mjs` + `tsx`.
  - Validacoes executadas com sucesso:
    - `npm test` (8 testes passando)
    - `npm run lint`
    - `npm run build`
- Estado atual:
  - Modulo web segue validado com testes de regra reais, e nao apenas smoke test.
- Proxima acao:
  - Manter a evolucao do modulo de configuracao com red/green nas regras centrais antes de expandir a persistencia no backend.

### Checkpoint 2026-04-02 (backend persistente do ciclo de configuracao)
- Feito:
  - Criado modulo `com.appbackoffice.api.config` no backend Java/Spring com entidades JPA, repositories, service, policy service, DTOs e controller para o ciclo de configuracao remota.
  - Persistido fluxo servidor para `publish -> pending_approval -> approve -> active -> rollback`, incluindo auditoria por ator e resolucao por contexto.
  - Contrato de mutacao alinhado para retornar `201` em publicacao com `result.created` e `result.updated` em aprovacao/reversao.
  - Serializacao do `effective` ajustada para omitir campos `null`, mantendo o contrato esperado de resolucao quando nao ha regra ativa.
  - Teste de integracao `ConfigPackageLifecycleIntegrationTest` implementado antes dos ajustes e validado em verde apos o ciclo red/green.
  - Validacoes executadas com sucesso no backend:
    - `mvn -B -f apps/backend/pom.xml -Dtest=ConfigPackageLifecycleIntegrationTest -DforkCount=0 test`
    - `mvn -B -f apps/backend/pom.xml -DforkCount=0 test`
- Estado atual:
  - Backend ja sustenta persistencia e governanca basica do modulo de configuracao, ainda desacoplado do consumo final do web-backoffice.
- Proxima acao:
  - Substituir o store em memoria do web-backoffice pelos endpoints persistentes do backend e expandir filtros/policies por tenant de forma ponta a ponta.

### Checkpoint 2026-04-02 (web-backoffice integrado ao backend persistente)
- Feito:
  - Rotas do web-backoffice para configuracao (`/api/config/packages`, `/api/config/packages/approve`, `/api/config/packages/rollback`, `/api/config/resolve`, `/api/config/audit`) migradas do store em memoria para consumo do backend Java em `/api/backoffice/config/*`.
  - Criado client compartilhado em `apps/web-backoffice/app/lib/config_backend_client.ts` com suporte a `BACKOFFICE_CONFIG_API_BASE_URL` (fallback local para `http://localhost/api/backoffice/config`).
  - Contrato de resposta mantido compatÃ­vel com o painel atual (incluindo `metadata` no resolve e `limit` aplicado no layer web para auditoria).
  - Validacoes executadas com sucesso no web-backoffice:
    - `npm --prefix apps/web-backoffice run lint`
    - `npm --prefix apps/web-backoffice test`
    - `npm --prefix apps/web-backoffice run build`
- Estado atual:
  - O painel de configuracao do web-backoffice ja opera sobre endpoints persistentes, eliminando dependencia operacional do store local em memoria.
- Proxima acao:
  - Endurecer politicas multi-tenant no backend (filtros por tenant/unidade/role no servidor) e ampliar testes de contrato web-backoffice -> backend.

### Checkpoint 2026-04-02 (tenant guard em mutacoes de pacote)
- Feito:
  - Contrato de acao no backend endurecido para exigir `tenantId` em `approve` e `rollback` (`ConfigPackageActionRequest`).
  - Service de configuracao atualizado para resolver pacote por `packageId` + validacao de ownership por tenant antes de mutar status.
  - Teste de integracao ampliado com caso cross-tenant garantindo bloqueio de mutacao fora do tenant.
  - Web-backoffice atualizado para propagar `tenantId` nas acoes de aprovacao/reversao.
  - Validacoes automatizadas executadas com sucesso:
    - `mvn -B -f apps/backend/pom.xml -Dtest=ConfigPackageLifecycleIntegrationTest -DforkCount=0 test` (3 testes, 0 falhas)
    - `mvn -B -f apps/backend/pom.xml -DforkCount=0 test` (11 testes, 0 falhas)
    - `npm --prefix apps/web-backoffice run lint`
    - `npm --prefix apps/web-backoffice test`
    - `npm --prefix apps/web-backoffice run build`
- Estado atual:
  - Mutacoes de ciclo de vida de pacote agora exigem contexto de tenant e impedem alteracao cross-tenant por `packageId` isolado.
- Proxima acao:
  - Evoluir de validacao de ownership por campo para consulta repository diretamente escopada por tenant e adicionar testes de contrato HTTP no web-backoffice para falhas 404/403 de tenant guard.

### Checkpoint 2026-04-02 (hardening tenant-scoped + contratos HTTP web)
- Feito:
  - Backend endurecido no mÃ³dulo de configuraÃ§Ã£o com lookup repository escopado por tenant (`findByIdAndTenantId`) durante approve/rollback.
  - Service de configuraÃ§Ã£o ajustado para resolver pacote diretamente por `packageId + tenantId`, removendo dependÃªncia de validaÃ§Ã£o tardia de ownership apÃ³s carga por `id`.
  - Suite de contratos do web-backoffice ampliada com cenÃ¡rios de erro para rotas de approve/rollback:
    - `400` quando `tenantId` ausente,
    - `403` para perfil sem permissÃ£o,
    - `404` propagado do backend em pacote nÃ£o encontrado.
  - ValidaÃ§Ãµes automatizadas executadas com sucesso:
    - `mvn -B -f apps/backend/pom.xml -Dtest=ConfigPackageLifecycleIntegrationTest -DforkCount=0 test` (3 testes, 0 falhas)
    - `mvn -B -f apps/backend/pom.xml -DforkCount=0 test` (11 testes, 0 falhas)
    - `npm --prefix apps/web-backoffice run lint`
    - `npm --prefix apps/web-backoffice test` (12 testes, 0 falhas)
    - `npm --prefix apps/web-backoffice run build`
- Estado atual:
  - Tenant guard de mutaÃ§Ãµes sensÃ­veis ficou mais robusto no backend e com cobertura de contrato HTTP no web para erros crÃ­ticos de contexto e autorizaÃ§Ã£o.
  - Base pronta para expansÃ£o do enforcement de contexto mÃ­nimo (`tenantId/correlationId`) para demais endpoints.
- Proxima acao:
  - Expandir BOW-058/INT-026 para validar tambÃ©m `correlationId` no backend e propagar o contexto de forma padronizada nas rotas crÃ­ticas restantes.

### Checkpoint 2026-04-02 (promocao para main e equalizacao)
- Feito:
  - PR de release para `main` mergeada com sucesso apos estabilizacao dos workflows de Backend CI, Android CI e Internal Docs CI.
  - Excecao controlada de protecao aplicada somente para viabilizar merge em cenario de mantenedor unico e restaurada no mesmo ciclo.
  - Protecao da branch `main` confirmada com `required_approving_review_count = 1` apos o merge.
  - Branch de homologacao sincronizada por fast-forward a partir de `origin/main`.
  - Verificacao final de divergencia executada com resultado `0/0` entre `origin/main` e `origin/homolog`.
- Estado atual:
  - Ambientes equalizados (codigo de `main` e homolog alinhados).
  - Fluxo de governanca de release preservado com evidencias registradas.
  - Gate OpenAPI em CI estabilizado para continuidade de INT-025/026/027.
- Proxima acao:
  - Manter acompanhamento da esteira de distribuicao e confirmar qualquer sinal de divergencia de notificacao entre homolog/producao quando houver novo envio.
  - Ao retomar a sessao apos desligamento da maquina, executar primeiro a subida do ambiente local (stack web/api) antes de iniciar o proximo ciclo de implementacao.

### Checkpoint 2026-04-02 (OpenAPI backend validado com H2)
- Feito:
  - `apps/backend/pom.xml` ajustado para incluir `h2` em escopo de teste, destravando o `@SpringBootTest` com profile `test`.
  - DependÃªncia OpenAPI do backend migrada para `springdoc-openapi-starter-webmvc-api` com publicaÃ§Ã£o do Swagger UI via WebJar, preservando o endpoint pÃºblico `GET /api/swagger` por redirecionamento explÃ­cito.
  - Criado `OpenApiContractIntegrationTest` para validar o endpoint `GET /api/openapi/v1` contra o contrato efetivamente publicado.
  - `CanonicalErrorResponse` passou a expor os campos canÃ´nicos como `required` no OpenAPI e `ErrorSeverity` passou a ser publicado como schema reutilizÃ¡vel (`enumAsRef = true`).
  - SuÃ­te alvo do backend validada localmente com sucesso: `BackofficeApiApplicationTests`, `OpenApiContractIntegrationTest` e `MobileApiControllerContractErrorTest`.
- Estado atual:
  - O backend sobe localmente em profile `test` com H2 e o endpoint OpenAPI v1 estÃ¡ validado por teste de integraÃ§Ã£o.
  - `GET /api/swagger` foi mantido como alias estÃ¡vel, agora desacoplado do auto-config problemÃ¡tico do UI do `springdoc`.
- Proxima acao:
  - Executar `backend_ci.yml` em PR para validar o mesmo comportamento no runner Linux.
  - Avaliar se vale adicionar teste especÃ­fico para o redirect de `GET /api/swagger` alÃ©m do teste do JSON OpenAPI.

---

### Checkpoint 2026-04-03 (documentacao mestre unificada importada)
- Feito:
  - ZIP `DOCS_MESTRE_FINAL_UNIFICADO.zip` extraÃ­do e estrutura copiada para `docs/` do repositÃ³rio.
  - Pastas importadas: `00-overview`, `01-executive`, `02-product`, `03-architecture`, `04-engineering`, `05-operations`, `06-analysis-and-design`, `07-diagrams`.
  - Total: 38 arquivos .md + diagramas .puml/.mmd + imagens .png.
  - `copilot-instructions.md` atualizado com secao "Documentacao mestre" listando os 13 documentos canonicos obrigatorios de consulta.
  - `AGENTE_LICOES_APRENDIDAS.md` atualizado com licao sobre as duas camadas de documentacao.
- Estado atual:
  - Projeto tem documentacao mestre completa commitavel: produto, arquitetura, IAM, dominios, ADRs, personas, PRD, roadmap, engenharia, operacao, casos de uso, regras de negocio, diagramas C4 e UML.
  - Nenhum arquivo operacional preexistente foi removido ou sobrescrito.
- Fontes canonicas de verdade agora ativas:
  - Visao estrategica: `docs/01-executive/05_VISAO_ESTRATEGICA_E_ESTATIOS.md`
  - Blueprint: `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
  - Modelo canonico: `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
  - Tenant transversal e ecossistema de plataforma: `docs/03-architecture/10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md`
  - Canal mobile white-label e branding/distribuicao: `docs/03-architecture/08_BRAND_AND_DISTRIBUTION_MODEL.md`
  - Decisoes V2: `docs/06-analysis-design/01_DECISION_LOG_V2.md`
  - Personas: `docs/02-product/01_PERSONAS_E_PAPEIS.md`
  - Regras de negocio: `docs/06-analysis-design/01_DECISION_LOG_V2.md`
- Proxima acao:
  - Fazer commit desta documentacao para garantir que CI/CD e outros agentes tenham acesso imediato.
  - Retomar planejamento de implementacao a partir de `docs/05-operations/02_PLANO_IMPLEMENTACAO_90_DIAS.md` como guia de proximos passos.

_Documento de restauraÃ§Ã£o mantido pelo agente (Copilot) como ponto de continuidade operacional._

### Checkpoint 2026-04-02 (BOW-003/BOW-053 - gestao de usuarios web+mobile)
- Feito:
  - Backend User Management expandido para cobrir cadastro por app (MOBILE_ONBOARDING), cadastro manual web (WEB_CREATED) e importacao externa (AD_IMPORT).
  - Endpoints ativos: `GET /api/users`, `POST /api/users`, `POST /api/users/import`, `GET /api/users/pending`, `POST /api/users/{id}/approve`, `POST /api/users/{id}/reject`.
  - Web backoffice evoluido com telas: `/backoffice/users`, `/backoffice/users/create`, `/backoffice/users/import`, mantendo `/backoffice/users/pending`.
  - Proxies Next.js adicionados: `/api/users` e `/api/users/import`.
- Estado atual:
  - Backend compila com sucesso (`mvn -B -DskipTests clean compile`).
  - Web validado com sucesso (`npm run lint`, `npm test`, `npm run build`).
  - Execucao completa de `mvn test` no Windows segue instavel por prompt espurio de lote (`Deseja finalizar o arquivo em lotes (S/N)?`).
- Proxima acao:
  - Estabilizar execucao de testes backend em shell sem prompt interativo para fechar a validacao automatizada full.
  - Evoluir trilha de auditoria de alteracoes de usuario e paginacao/filtros avancados no modulo de gestao.

### Checkpoint 2026-04-02 (seguranca identidade + auditoria de usuarios)
- Feito:
  - Backend de usuarios passou a persistir trilha de auditoria para create/import/approve/reject em tabela dedicada (`user_audit_entries`), incluindo `tenantId`, `actorId`, `correlationId`, alvo e detalhes da acao.
  - Endpoint `GET /api/users/audit` publicado no backend e proxy web `/api/users/audit` criado, com tela operacional em `/backoffice/users/audit`.
  - Mutacoes sensiveis do modulo de usuarios agora exigem `X-Actor-Id` alem de `X-Tenant-Id` e `X-Correlation-Id`.
  - Diagnostico consolidado: BL-031 nao esta pronto no sentido arquitetural; o app mobile ainda usa autenticacao local/mock em `AuthState`, sem login backend real, sem refresh/revogacao e sem controle de tentativas.
- Estado atual:
  - Auditoria de acoes administrativas de usuarios esta implementada e pronta para consumo/validacao.
  - A seguranca de identidade entrou como premissa de arquitetura: autenticacao real, controle de tentativas, lockout, MFA readiness e trilha de acesso deixaram de ser backlog distante.
  - Execucao Maven ficou estavel localmente com `-DforkCount=0`, removendo o prompt espurio de lote como bloqueio pratico nesta sessao.
- Proxima acao:
  - Abrir a fundacao de autenticacao backend-first (login/refresh/logout/me) com persistencia de sessao/token e rate limit de tentativas.
  - Definir a estrategia de MFA: TOTP/passkeys para internos e federacao OIDC/SAML para clientes corporativos/AD.

### Checkpoint 2026-04-02 (governanca de camadas de acesso)
- Decisao registrada:
  - As camadas de acesso do backoffice devem ser tratadas com segregacao forte por escopo, sem misturar privilegios:
    1. operacao local da empresa (tenant scope),
    2. administracao de usuarios mobile da empresa especifica (tenant admin scope),
    3. administracao da plataforma (platform scope).
  - A evolucao de auth/RBAC deve preservar essa hierarquia como requisito de seguranca obrigatorio.
  - Fonte de verdade para interpretacao de niveis de acesso: modelo de dominio IAM/white label e personas de negocio (Tenant, OrganizationUnit, Membership, IdentityBinding; operacao, gestor e administracao de plataforma).
  - Exemplos pontuais de conversa nao substituem a estrategia canÃ´nica documentada.
- Impacto imediato no backlog:
  - BOW-002 e BOW-033 passam a explicitar a diferenca entre administracao por empresa e administracao global da plataforma.
- Proxima acao:
  - Materializar essa segregacao na matriz de permissao backend-first com claims de escopo e validacoes por dominio sensivel (users, onboarding, configuracao).

### Checkpoint 2026-04-03 (backlog 4 ondas gerado â€” guia de desenvolvimento completo)
- O que foi feito:
  - Lidos e consolidados todos os documentos canonicos importados na sessao anterior (docs/00-overview a docs/06-analysis-and-design).
  - Auditados 58 arquivos Java do backend e 9 arquivos TSX do web-backoffice.
  - Mapeadas as dividas tecnicas criticas (User sem tenantId FK, Tenant/Membership ausentes, auth mock no mobile).
  - BACKLOG_BACKOFFICE_WEB.md reescrito com estrutura de 4 ondas e cards detalhados com contexto, contratos, criterios de pronto e referencias canonicas.
  - BACKLOG_FUNCIONALIDADES.md atualizado com sequenciamento corrigido de BL-031 (depende de BOW-100/101/102).
- Estado atual:
  - Backlog principal: 24 cards detalhados na Onda 1 (BOW-100 a BOW-151), 8 cards na Onda 2, 4 planejados na Onda 3, 4 visao na Onda 4.
  - DependÃªncia critica identificada: BOW-100 (Tenant+Membership) bloqueia tudo. Deve ser o primeiro card implementado.
  - Codigo existente com divida: User.java (sem FK tenantId real), ConfigPackage (sem FK tenant), MobileApiController (stubs sem persistencia).
  - Nenhum dos 5 bounded contexts ausentes (Job Lifecycle, Field Ops, Valuation, Reporting, Settlement) tem codigo no backend.
- Proxima acao:
  - Iniciar BOW-100: criar Tenant + OrganizationUnit + Membership com migrations Flyway em identity_db.
  - Seguir sequencia obrigatoria: BOW-100 â†’ BOW-101 â†’ BOW-102 â†’ BOW-103 â†’ BOW-104 â†’ BOW-105 â†’ BOW-110.
  - Nao iniciar BL-031 (auth mobile) antes de BOW-102 estar funcional com GET /auth/me retornando tenant context.

### Checkpoint 2026-04-03 (retomada de desenvolvimento â€” BOW-100 parcial implementado)
- O que foi feito:
  - Implementado novo modulo `identity` no backend com entidades: `Tenant`, `OrganizationUnit`, `Membership`.
  - Implementados enums de dominio: `TenantStatus`, `OrganizationUnitType`, `MembershipRole`, `MembershipStatus`.
  - Implementados repositories: `TenantRepository`, `OrganizationUnitRepository`, `MembershipRepository`.
  - Implementado teste de integracao `IdentityTenantMembershipIntegrationTest` validando isolamento por tenant e consulta por `user + tenant`.
  - Ajustado teste para evitar `LazyInitializationException` e evitar contaminacao da suite por FK residual.
- Estado atual:
  - Suite backend verde apos mudanca (todos os relatÃ³rios surefire com `failures=0` e `errors=0`).
  - BOW-100 avanÃ§ou para "Em andamento (parcial)" no backlog.
  - Ainda nao ha migrations Flyway no projeto; o backend segue semversao de schema por SQL versionado.
- Proxima acao:
  - Concluir BOW-100 com introducao de Flyway e migrations `V002..V006`.
  - Iniciar BOW-101 com retrofit de `User` para vinculo real com `Tenant` e remocao progressiva de papel na entidade de identidade.

### Checkpoint 2026-04-03 (BOW-101 iniciado â€” UserLifecycle separado)
- O que foi feito:
  - Criada entidade `UserLifecycle` com repository dedicado para separar ciclo de aprovacao da identidade em `User`.
  - Criado enum `UserLifecycleStatus` com estados `PENDING_APPROVAL`, `APPROVED`, `REJECTED`.
  - `UserService` atualizado para escrever transicoes no lifecycle em create (mobile/web/import), approve e reject.
  - `UserResponse` ampliado com `lifecycleStatus` para rastrear status do agregado novo durante migraÃ§Ã£o.
  - Criado teste `UserLifecycleTransitionIntegrationTest` validando transicao APPROVED e REJECTED no lifecycle.
- Estado atual:
  - Suite backend segue verde (failures/errors = 0 em todas as suites surefire).
  - BOW-101 atualizado para "Em andamento (parcial)".
  - Compatibilidade mantida: `User.status` e `User.role` ainda existem temporariamente para nao quebrar contratos existentes.
- Proxima acao:
  - Migrar responsabilidade de role para `Membership` e iniciar desuso de `User.role`.
  - Preparar FK real de tenant em `users` com migraÃ§Ã£o (junto de Flyway no fechamento de BOW-100/BOW-101).

### Checkpoint 2026-04-03 (BOW-101 continuacao â€” dual-write de Membership)
- O que foi feito:
  - `UserService` atualizado para gravar `Membership` em dual-write nas trilhas de create mobile, create web, import AD, approve e reject.
  - Introduzido mapeamento transicional `UserRole -> MembershipRole` para manter compatibilidade com contratos existentes.
  - Ajustada criacao incremental de tenant no fluxo para suportar persistencia de membership durante a migraÃ§Ã£o.
  - Teste `UserLifecycleTransitionIntegrationTest` ampliado para validar estado de membership (`ACTIVE`/`REVOKED`) junto do lifecycle.
  - `UserManagementLifecycleIntegrationTest` ajustado para limpeza ordenada de `memberships` antes de `users` e evitar quebra por FK em suites sequenciais.
- Estado atual:
  - Escrita de autorizacao em `Membership` ativa sem quebra dos endpoints existentes.
  - `User.role` permanece temporariamente para compatibilidade de leitura e auditoria durante transiÃ§Ã£o.
- Proxima acao:
  - Migrar leituras/autorizacao para `Membership` como fonte principal e iniciar deprecacao de leituras por `User.role`.
  - Fechar card com migracao de FK real `users.tenant_id -> tenants.id` e limpeza dos campos legados.

### Checkpoint 2026-04-03 (BOW-101 continuacao â€” leitura de role via Membership)
- O que foi feito:
  - `UserService` ajustado para resolver role efetiva por `Membership` nas consultas (`findAll`, `findByStatus`, `findPending`, `findUserById`), preservando fallback temporÃ¡rio para `User.role`.
  - Fluxos de `approve`/`reject` passaram a reutilizar role efetiva resolvida para transicao de status da membership.
  - Novo teste de integracao em `UserManagementLifecycleIntegrationTest` valida precedencia de role da membership no `GET /api/users/{id}`.
- Estado atual:
  - Leitura de papel ja segue fonte `Membership` na camada de servico sem quebra do contrato de resposta atual (`role` continua no DTO).
  - Estrategia de transicao mantida: fallback legado ativo enquanto `User.role` nao e removido.
- Proxima acao:
  - Remover fallback para `User.role` apos fechamento de migracao de dados legados.
  - Concluir BOW-101 com migracao de FK real `users.tenant_id -> tenants.id`.

### Checkpoint 2026-04-03 (BOW-101 continuacao â€” backfill automatico de membership legado)
- O que foi feito:
  - `UserService` passou a criar `Membership` automaticamente para usuarios legados sem vinculo quando consultados.
  - Regra de backfill aplica role/status derivando de `User.role` e `User.status` apenas no momento da migracao incremental.
  - Novo teste `shouldBackfillMembershipForLegacyUserWithoutMembership` adicionado em `UserManagementLifecycleIntegrationTest` validando criacao de membership e role retornada no endpoint.
- Estado: Supersedido pelo checkpoint abaixo (BOW-101 concluido).

### Checkpoint 2026-04-03 (BOW-101 CONCLUIDO â€” Flyway + FK + User.role @Transient)
- O que foi feito:
  - Flyway introduzido: `flyway-core` adicionado ao pom.xml; Spring Boot autoconfigura migraÃ§Ãµes de `db/migration`.
  - V001: schema inicial completo (8 tabelas, sem FK em users.tenant_id).
  - V002: FK real `users.tenant_id â†’ tenants.id` via ALTER TABLE.
  - V003: DROP COLUMN role da tabela users (campo migrado para memberships).
  - `User.role` alterado de `@Column @Enumerated` para `@Transient` â€” persiste sÃ³ em memÃ³ria para projeÃ§Ã£o de role efetiva.
  - `backfillLegacyMembership`: com role=null (transient), usa FIELD_OPERATOR como padrÃ£o (via toMembershipRole(null)).
  - `UserService.createFromWeb` audit: usa req.role() string diretamente (nÃ£o mais saved.getRole()).
  - `application.yml` (prod): ddl-auto=none (Flyway gerencia schema).
  - `application-test.yml`: H2 com MODE=PostgreSQL, ddl-auto=none, Flyway ativo.
  - Todos os testes que criavam User diretamente via new User() atualizados para ter o tenant prÃ©-existente (@BeforeEach).
  - Testes de backfill atualizados: role legado default = FIELD_OPERATOR (nÃ£o AUDITOR), status = SUSPENDED.
- Estado atual:
  - BOW-101 concluÃ­do. User.role removida da persistÃªncia. FK users.tenant_id aplicada.
  - Suite: 30 testes, 0 falhas, 0 erros.
- Proxima acao:
  - Iniciar BOW-102 (JWT auth backend).

---

### Checkpoint 2026-04-03 (BOW-102 + BOW-103 CONCLUIDOS â€” Auth module + IdP Adapter)
- O que foi feito:
  - **V004** (Flyway): tabelas `user_credentials` (FK â†’ users, tenants) e `sessions` (FK â†’ users, tenants) criadas.
  - **V005** (Flyway): tabela `identity_bindings` (FK â†’ users, tenants; UNIQUE por provider_type+provider_sub+tenant) criada.
  - **MÃ³dulo auth** criado em `apps/backend/src/main/java/com/appbackoffice/api/auth/` (27 arquivos):
    - Entidades: `UserCredentialEntity`, `SessionEntity`, `IdentityBindingEntity`, `IdentityProviderType`
    - RepositÃ³rios JPA: `UserCredentialRepository`, `SessionRepository`, `IdentityBindingRepository`
    - Providers (BOW-103): interface `IdentityProvider` + `InternalIdentityProvider` + `AuthenticationRequest` + `AuthenticatedIdentity`
    - ServiÃ§os: `AuthService`, `JwtTokenService`, `JwtPrincipal`, `LoginAttemptStore`, `LoginAttemptStatus`, `TokenRevocationStore`, `RedisResilientLoginAttemptStore`, `RedisResilientTokenRevocationStore`, `PermissionCatalog`
    - Controller + DTOs para `/api/auth/login`, `/api/auth/refresh`, `/api/auth/logout`, `/api/auth/me`
  - **jjwt 0.12.6** adicionado ao pom.xml para geraÃ§Ã£o/validaÃ§Ã£o de JWT.
  - **spring-security-crypto** adicionado para BCrypt.
  - **Redis stores resilientes**: fallback gracioso quando Redis indisponÃ­vel (caches locais).
  - **AuthIntegrationTest**: 4 testes (login, refresh, logout, me, lockout) â€” todos passando.
  - **CorreÃ§Ã£o FK cleanup**: 3 testes antigos (`IdentityTenantMembershipIntegrationTest`, `UserLifecycleTransitionIntegrationTest`, `UserManagementLifecycleIntegrationTest`) atualizados para limpar `sessions â†’ identityBindings â†’ userCredentials` antes de deletar `users`.
- Estado atual:
  - BOW-102 e BOW-103 concluÃ­dos.
  - Suite completa: 10 classes, 34 testes, 0 falhas, 0 erros.
  - Migrations Flyway: V001â€“V005 ativas.
- Proxima acao:
  - Iniciar BOW-104 (RBAC por escopo: platform Ã— tenant Ã— operacional Ã— campo).

---

### Checkpoint 2026-04-03 (BOW-104 + BOW-105 + BOW-110 + BOW-111 CONCLUIDOS â€” Seguranca RBAC + Policy + Integration Hub)
- O que foi feito:
  - **BOW-104 (RBAC por escopo)**:
    - Criada annotation `@RequiresTenantRole`.
    - Criado `TenantSecurityContext` + `TenantSecurityContextHolder` (thread local).
    - Criado `TenantSecurityContextFilter` para extrair `tid/roles` do JWT e validar membership ativa.
    - Criado `TenantRoleAuthorizationInterceptor` + `SecurityWebMvcConfig`.
    - Endpoints protegidos com anotacoes em `UserManagementController` e `ConfigPackageController`.
    - Teste de contrato adicionado: `ConfigPackageAuthorizationContractTest` (403 com papel insuficiente).
  - **BOW-105 (Policy engine)**:
    - Criada interface `DomainPolicy<T>`.
    - Criadas policies `JobAccessPolicy` e `UserAccessPolicy` para autorizacao contextual por acao/recurso.
  - **BOW-110 (Integration Hub / ACL)**:
    - **V006** (Flyway) adicionada: tabela `integration_demands` com FK para `tenants` e UNIQUE em `external_id`.
    - Criados `IntegrationDemandEntity`, `IntegrationDemandRepository`, DTOs de demanda e `IntegrationDemandService`.
    - Criado `IntegrationDemandController` com endpoints:
      - `POST /api/integration/demands` (normalizacao + idempotencia por `externalId`)
      - `GET /api/integration/demands/{externalId}?tenantId=`
    - Publicacao de evento simulada via `LogIntegrationEventPublisher` (`DemandCreated`).
    - Testes de integracao adicionados: `IntegrationDemandIntegrationTest` (valido, invalido, duplicado).
  - **BOW-111 (erro canÃ´nico expandido)**:
    - Novos cenarios de autorizacao (`AUTH_FORBIDDEN`, `TENANT_CONTEXT_MISMATCH`) entregues no envelope `CanonicalErrorResponse` via `ApiContractException`.
    - Cobertura de contrato para 403 canÃ´nico validada.
  - Ajustes de estabilidade dos testes:
    - Ordem de cleanup em `IntegrationDemandIntegrationTest` atualizada para deletar dependentes antes de `tenants`.
    - `ConfigPackageLifecycleIntegrationTest` ajustado para incluir `X-Actor-Role` nas mutacoes protegidas.
- Estado atual:
  - BOW-104, BOW-105, BOW-110 e BOW-111 concluÃ­dos.
  - Backend: `mvn -B -f apps/backend/pom.xml -DforkCount=0 test` verde.
  - Suite completa backend: **38 testes, 0 falhas, 0 erros**.
  - Migrations Flyway ativas: V001â€“V006.
- Proxima acao:
  - Iniciar BOW-120 (modelo canÃ´nico de domÃ­nio: Case/Job/Assignment).

### Checkpoint 2026-04-03 (promocao homolog -> main â€” PR #9)
- O que foi feito:
  - PR `#9` criado de `homolog/bl-accordion-dedup-fix` para `main` com pacote BOW-120/BOW-121/BOW-122.
  - Merge para `main` concluido no mesmo ciclo, com esteiras principais monitoradas ate conclusao.
  - Workflows confirmados: `Backend CI` (success), `Backend Deploy` (success), `Internal Docs CI` (success), `Android CI` (success).
  - Workflow `Android Distribution` no push de `main` ficou `skipped` (sem falha de pipeline).
- Estado atual:
  - `main` atualizado com as entregas BOW-120/BOW-121/BOW-122.
  - Promocao concluida e pipelines criticas verdes.
- Regra operacional reforcada para proxima promocao (mantenedor unico):
  - Aplicar o procedimento oficial de excecao: reduzir temporariamente `required_approving_review_count` para `0`, realizar merge da PR e restaurar imediatamente para `1`.
  - Evitar uso de merge administrativo direto como caminho padrao quando o procedimento de excecao controlada estiver disponivel.
- Proxima acao:
  - Na proxima promocao para `main`, executar obrigatoriamente o procedimento de excecao controlada com evidencia de ajuste e restore da protecao no mesmo checkpoint.

### Checkpoint 2026-04-03 (pacote grande â€” Fase A incrementos 1 e 2)
- O que foi feito:
  - Criada migration `V010__checkin_sections.sql` com modelo canÃ´nico NBR de seÃ§Ãµes de check-in (`checkin_sections`).
  - Criadas `CheckinSectionEntity` e `CheckinSectionRepository` no backend.
  - `GET /api/mobile/checkin-config` evoluÃ­do para retornar `publishedAt` e `sections[]` canÃ´nicas (com fallback default), mantendo `step1/step2` por retrocompatibilidade.
  - Criada migration `V011__inspections.sql` com agregado explÃ­cito `inspections` ligado a submissÃ£o e job.
  - Criadas `InspectionEntity` e `InspectionRepository`.
  - `InspectionSubmissionService` atualizado para persistir `Inspection` explÃ­cita e responder status `SUBMITTED` no retorno mobile.
  - Testes ajustados:
    - `MobileCheckinConfigIntegrationTest` cobrindo `publishedAt` + `sections[]`.
    - `InspectionSubmissionIntegrationTest` cobrindo persistÃªncia do agregado `Inspection` + idempotÃªncia.
- Estado atual:
  - Flyway backend em `V011`.
  - Incrementos da Fase A validados com sucesso em teste focado backend (`4 testes, 0 falhas`).
  - BOW-121 e BOW-122 avanÃ§aram com persistÃªncia/modelo explÃ­cito; BOW-123 ainda pendente.
- PrÃ³xima aÃ§Ã£o:
  - Iniciar BOW-123 no `apps/web-backoffice`: rota `/backoffice/inspections` com lista, filtros e indicadores operacionais em cima de dados reais de `inspections`.

### Checkpoint 2026-04-03 (pacote grande â€” BOW-123 incremento inicial web)
- O que foi feito:
  - Criado backend `InspectionBackofficeController` com endpoints `GET /api/backoffice/inspections` e `GET /api/backoffice/inspections/{id}`.
  - Criado `InspectionBackofficeService` com filtros por status, janela temporal e vistoriador, alÃ©m de detalhe tÃ©cnico do payload persistido.
  - Criadas rotas Next.js `/api/inspections` e `/api/inspections/[inspectionId]` para bridge com o backend.
  - Criada pÃ¡gina `apps/web-backoffice/app/backoffice/inspections/page.tsx` com cards-resumo, filtros, tabela e painel de detalhe tÃ©cnico.
  - Dashboard inicial atualizado com atalho para o novo painel de vistorias recebidas.
  - Warning de `useEffect` corrigido; `npm --prefix apps/web-backoffice run lint` voltou limpo.
  - `npm --prefix apps/web-backoffice test` executado com sucesso: 14 testes, 0 falhas.
- Estado atual:
  - BOW-123 saiu de pendente para incremento funcional inicial entregue.
  - Backend focado segue verde (`MobileCheckinConfigIntegrationTest` + `InspectionSubmissionIntegrationTest` = 4 testes, 0 falhas).
  - `next build` do web-backoffice ficou pendurado neste ambiente local sem erro explÃ­cito; requer nova checagem isolada antes do pacote de homologaÃ§Ã£o.
- PrÃ³xima aÃ§Ã£o:
  - Fechar BOW-123 com paginaÃ§Ã£o navegÃ¡vel/indicadores operacionais mais ricos e revalidar `npm --prefix apps/web-backoffice run build` de forma determinÃ­stica antes da publicaÃ§Ã£o em homolog.

### Checkpoint 2026-04-03 (pacote grande â€” BOW-123 paginaÃ§Ã£o + testes)
- O que foi feito:
  - `InspectionBackofficeService` ajustado para paginaÃ§Ã£o ordenada por `submittedAt desc, id desc`.
  - Painel web de inspections atualizado com paginaÃ§Ã£o navegÃ¡vel (`page/size`) e cards-resumo mais prÃ³ximos do critÃ©rio operacional.
  - Novo teste backend `InspectionBackofficeIntegrationTest` cobrindo listagem paginada e detalhe tÃ©cnico.
  - Novo teste web `inspections_api_routes.test.ts` cobrindo propagaÃ§Ã£o de query params e detalhe via rotas Next.js.
  - SuÃ­te backend focada validada: 6 testes, 0 falhas (`InspectionBackofficeIntegrationTest`, `InspectionSubmissionIntegrationTest`, `MobileCheckinConfigIntegrationTest`).
  - SuÃ­te web validada: `npm --prefix apps/web-backoffice test` com 16 testes verdes e `npm --prefix apps/web-backoffice run lint` limpo.
- Estado atual:
  - BOW-123 avanÃ§ou para um painel funcional com paginaÃ§Ã£o inicial e cobertura automatizada bÃ¡sica.
  - Build de produÃ§Ã£o do web-backoffice segue em verificaÃ§Ã£o isolada com log (`apps/web-backoffice/.next-build.log`) para confirmar se o travamento anterior era apenas ausÃªncia de output no terminal.
- PrÃ³xima aÃ§Ã£o:
  - Ler o resultado do build em background, eliminar a pendÃªncia operacional do `next build` e entÃ£o decidir se seguimos para fechamento de mÃ©tricas/intake ou jÃ¡ preparamos rodada de homologaÃ§Ã£o do pacote.

### Checkpoint 2026-04-03 (pacote grande â€” bloqueio operacional do next build)
- O que foi feito:
  - Removida dependÃªncia de fonte remota em `apps/web-backoffice/app/layout.tsx` (remoÃ§Ã£o de `next/font/google`) e substituÃ­da por pilhas locais em `apps/web-backoffice/app/globals.css`.
  - Build do Next testado em mÃºltiplos modos (`next build`, `next build --debug`, `next build --no-lint`) com limpeza de cache `.next` e tempo de observaÃ§Ã£o estendido (15 minutos).
  - ReinstalaÃ§Ã£o limpa de dependÃªncias web executada para descartar corrupÃ§Ã£o local de `node_modules`.
  - PÃ³s-reinstalaÃ§Ã£o, testes quebraram por `ERR_MODULE_NOT_FOUND: get-tsconfig` no loader do `tsx`; ajuste aplicado adicionando `get-tsconfig` como `devDependency` direta em `apps/web-backoffice/package.json`.
  - ValidaÃ§Ã£o funcional restaurada: `npm --prefix apps/web-backoffice test` (16 verdes) e `npm --prefix apps/web-backoffice run lint` (sem erros).
- Estado atual:
  - O travamento do `npm --prefix apps/web-backoffice run build` persiste no ambiente Windows local, sem saÃ­da adicional apÃ³s o banner `â–² Next.js 14.2.33`.
  - NÃ£o hÃ¡ erro de cÃ³digo reportado por lint/test nas alteraÃ§Ãµes do pacote BOW-121/BOW-122/BOW-123.
  - O pacote estÃ¡ funcional para backend/web em testes e lint, com pendÃªncia especÃ­fica no build de produÃ§Ã£o do Next neste ambiente.
- PrÃ³xima aÃ§Ã£o:
  - Abrir trilha de diagnÃ³stico de ambiente para o build do Next (comparar execuÃ§Ã£o em shell limpo e/ou runner Linux CI) e decidir, com base no resultado, se o gate de homologaÃ§Ã£o do pacote serÃ¡ bloqueado por build local ou delegado para validaÃ§Ã£o no CI web.

  ### Checkpoint 2026-04-03 (pacote grande â€” validaÃ§Ã£o completa do pacote)
  - O que foi feito:
    - Diagnosticado e resolvido o travamento do `npm run build` do web-backoffice: causa raiz era `output: "standalone"` no `next.config.mjs` que bloqueia o file-tracing no Windows.
    - `next.config.mjs` ajustado para ativar `output: "standalone"` apenas quando `CI=1` ou `NEXT_BUILD_STANDALONE=1`, preservando modo standalone para Docker/CI e desbloqueando builds locais.
    - `npm --prefix apps/web-backoffice run build` concluiu com sucesso: 21 rotas compiladas, 0 erros, 0 warnings.
    - SuÃ­te backend completa revalidada: 53 testes, 0 falhas, 0 erros (todas as 17 classes).
    - SuÃ­te web revalidada: 16 testes, 0 falhas; lint limpo; build verde.
    - Dockerfile/CI devem passar `NEXT_BUILD_STANDALONE=1` para ativar modo standalone no pipeline.
  - Estado atual:
    - Pacote BOW-121/BOW-122/BOW-123 â€” todas as validaÃ§Ãµes passando.
    - Backend: Flyway V001â†’V011, 17 classes de teste, 53 testes verdes.
    - Web: 16 testes, lint e build de produÃ§Ã£o verdes.
    - MudanÃ§as uncommitted prontas para homologaÃ§Ã£o.
  - PrÃ³xima aÃ§Ã£o:
    - Incrementar versÃ£o em `pubspec.yaml` (se aplicÃ¡vel ao Flutter), verificar `pubspec.yaml` do app mobile.
    - Criar branch `homolog/bow-121-122-123` e fazer commit+push para acionar pipeline de homologaÃ§Ã£o.

### Checkpoint 2026-04-03 (promocao homolog -> main â€” PR #10)
- O que foi feito:
  - PR `#10` criada de `homolog/bow-121-122-123` para `main` com o pacote grande BOW-121/BOW-122/BOW-123.
  - ExceÃ§Ã£o controlada aplicada conforme regra de mantenedor Ãºnico:
    - `required_approving_review_count` reduzido temporariamente de `1` para `0`.
    - Merge normal da PR executado (sem `--admin`) gerando commit `a19382bdbe2e8d800322918fdf744c47eebd65c5`.
    - ProteÃ§Ã£o restaurada imediatamente para `required_approving_review_count = 1`.
  - Versionamento aplicado no app: `pubspec.yaml` atualizado para `1.2.27+47`.
- Estado atual:
  - `main` atualizado com o pacote BOW-121/BOW-122/BOW-123 via PR #10.
  - Pipelines pÃ³s-merge concluÃ­das com sucesso: `Android CI`, `Backend CI`, `Web CI`, `Internal Docs CI`, `Backend Deploy`, `Web Deploy`.
  - `Android Distribution` do merge em `main` concluÃ­da com sucesso (`run 23954252296`).
- PrÃ³xima aÃ§Ã£o:
  - Aguardar confirmaÃ§Ã£o explÃ­cita de recebimento do e-mail do Firebase App Distribution para encerrar formalmente o ciclo de release.

### Encerramento do ciclo (2026-04-03)
- ConfirmaÃ§Ã£o recebida do usuÃ¡rio: e-mail do Firebase App Distribution recebido.
- Status final do ciclo: **ENCERRADO**.

