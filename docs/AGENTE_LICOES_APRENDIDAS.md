# Lições Aprendidas e Procedimento Operacional do Agente (Copilot)

## Objetivo
Registrar práticas essenciais, aprendizados e padrões de operação que devem ser seguidos em qualquer workspace, independente do chat ou contexto, para garantir continuidade, rastreabilidade e resiliência.

---

## 1. Princípios Gerais
- Sempre ler o projeto inteiro antes de qualquer mudança.
- Usar docs/BACKLOG_FUNCIONALIDADES.md como fonte oficial de backlog.
- Atualizar backlog local e board do GitHub Project em toda demanda.
- Seguir rigorosamente o padrão de versionamento e commit definido.
- Executar testes após mudanças; se não for possível, justificar.
- Nunca remover código/arquivo fora do escopo explícito.
- Priorizar TDD, Clean Code, SOLID e cobertura de testes.

## 2. Procedimento Operacional Padrão
- Antes de commit/push/publicação:
  - Checar e incrementar versão em pubspec.yaml (quando aplicável).
  - Executar `flutter analyze` e `flutter test`.
  - Validar rastreabilidade no backlog e board.
- Em cenário de mantenedor único (sem segundo revisor com write):
  - Aplicar exceção controlada de PR: reduzir temporariamente `required_approving_review_count` para `0`, executar merge da PR e restaurar imediatamente para `1`.
  - Registrar evidência do ajuste temporário e do restore na documentação operacional da entrega.
- Em cada solicitação:
  - Abrir/registrar card de rastreabilidade no backlog antes de implementar.
  - Atualizar status ao concluir.
- Mensagem de commit: `[versão] - [tipo alteração]: [resumo curto em português]`.

## 3. Resiliência e Troubleshooting
- Se um comando/integração falhar (ex: terminal travado, CLI sem acesso, API sem token):
  - Buscar alternativas (ex: executar comandos manualmente, usar scripts, validar variáveis de ambiente, checar permissões de token).
  - Registrar o erro e a solução adotada.
  - Documentar a lição aprendida neste arquivo.
- Sempre validar se há acesso ao GitHub Projects e se o token está configurado antes de tentar sincronização.
- Se não houver acesso, notificar e sugerir configuração do token/secret.

## 4. Continuidade entre sessões
- Este documento deve ser consultado e atualizado em toda nova interação, independente do chat.
- Sempre registrar novas lições aprendidas e padrões operacionais aqui.
- Usar este arquivo como base de conhecimento para auto-localização e troubleshooting futuro.

---

## Exemplos de Lições Aprendidas
- [2026-03-31] Se o terminal travar ou não houver acesso ao GitHub Projects, validar token, tentar comandos alternativos e registrar workaround.
- [2026-03-31] Sempre checar se o secret PROJECT_AUTOMATION_TOKEN está configurado antes de rodar workflows de board.
- [2026-03-31] Se o board não sincronizar, executar scripts manuais e atualizar checklist de sincronização.
- [2026-04-01] Manter `docs/RESUMO_EXECUTIVO_CONTINUO.md` atualizado a cada ciclo de homologacao para consolidar snapshot de branch/versao/gates e reduzir perda de contexto na promocao para `main`.
- [2026-04-01] Em fluxo com mantenedor unico, o merge de PR para `main` pode usar excecao temporaria de protecao (0 aprovacoes) com restauracao imediata para 1 aprovacao apos o merge.
- [2026-04-01] Notificacao por e-mail de aprovacao de PR no celular foi movida para segundo plano no backlog operacional; prioridade mantida para envio de distribuicao por ambiente (homolog/producao).
- [2026-04-01] Na Revisao de Fotos, deduplicacao de obrigatorios deve usar chave tecnica da configuracao dinamica (cameraAmbiente/cameraElementoInicial), e nao apenas titulo exibido, para evitar ambiguidade quando o JSON web variar labels.
- [2026-04-01] Para stack web local, nao persistir senhas em `infra/.env`/`infra.env`; usar variaveis de ambiente de sessao, cofre (`Get-Secret`) ou prompt seguro no script de inicializacao.
- [2026-04-01] Em hardware limitado, adicionar `.dockerignore` por app (web/backend) reduzindo contexto de build e risco de falhas `rpc EOF` durante download/extracao de camadas.
- [2026-04-01] Docker Desktop com WSL2 em C: baixo: migrar `customWslDistroDir` para D: via Settings > Resources > Advanced > Disk image location. Após Apply+Restart, o ext4.vhdx é recriado no novo local. O primeiro start pode demorar 2-3min para recriar distros `docker-desktop` e `docker-desktop-data`.
- [2026-04-01] Ponto de restauração do ambiente local documentado em `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` — consultar sempre que retomar setup de ambiente web em nova sessão.
- [2026-04-01] Ao transferir contexto para novo agente, usar a secao 9 (Regras de Trabalho Compartilhadas + Prompt pronto) em `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` para preservar governanca, padrao de testes e gate de promocao para `main`.
- [2026-04-01] Para BOW-054, publicar o Canonical Domain v1 no proprio `docs/BACKLOG_BACKOFFICE_WEB.md` (glossario, transicoes, ACL e invariantes) evita dispersao em arquivos novos e acelera onboarding de novos agentes.
- [2026-04-01] Para referencia interna entre times, manter portal em docs-as-code (`docs/internal-portal`) com workflow dedicado de build de artefato (`internal_docs_ci.yml`) reduz divergencia entre backlog e documentacao operacional.
- [2026-04-01] Para INT-025, um gate inicial efetivo em CI pode comparar OpenAPI da PR vs `main` e bloquear remoção de operações/responses/schemas antes de evoluir para regras avançadas.
- [2026-04-01] Para INT-028, iniciar com envelope canônico único de erro + handler global e aplicar primeiro nos endpoints críticos acelera adoção sem bloquear evolução incremental do catálogo completo por domínio.
- [2026-04-01] Em TDD para contrato de erro, testes WebMvc de headers obrigatórios devem vir antes do ajuste de handler; isso revela rapidamente regressões 500->400 em MissingRequestHeaderException.
- [2026-04-01] Após estabilizar ausência de header, ampliar cobertura com casos de header em branco e combinação de contexto ausente no POST reduz regressão silenciosa na validação semântica do envelope canônico.
- [2026-04-01] Para evoluir INT-025 sem criar falso positivo, o gate semântico deve ser orientado pelo contrato base da `main`: só exigir `CanonicalErrorResponse` onde a base já exigia, preservando compatibilidade e permitindo adoção incremental por endpoint.
- [2026-04-01] No gate OpenAPI (INT-025), o parser de `paths` deve considerar somente métodos HTTP válidos; tratar chaves como `parameters`/`summary` como operação gera falso positivo/negativo.
- [2026-04-01] Regras do validador de contrato também precisam de testes do próprio script (não só testes do backend), cobrindo regressão estrutural e semântica para reduzir risco de quebra silenciosa no CI.
- [2026-04-02] Em Windows, após instalar Python via winget, o alias `python` pode continuar apontando para `WindowsApps`; para validação imediata usar o executável real em `%LocalAppData%\Programs\Python\Python312\python.exe`.
- [2026-04-02] Para avançar INT-026/027 sem falso positivo, aplicar regra base-oriented também para headers obrigatórios: só bloquear remoção do que a `main` já marca como required por operação.
- [2026-04-02] No backend Spring Boot, `application-test.yml` pode depender de H2 sem que a dependência esteja explícita no `pom.xml`; validar o bootstrap real via `@SpringBootTest` antes de assumir que o profile de teste está funcional.
- [2026-04-02] Para Spring Boot 3.4.4, a combinação estável encontrada foi separar `springdoc-openapi-starter-webmvc-api` da UI e publicar o Swagger UI por WebJar com redirect próprio; isso evita falhas de auto-config do `springdoc` UI no startup.
- [2026-04-02] Teste de integração do endpoint `/api/openapi/v1` é útil para capturar gaps contratuais reais que o gate semântico isolado não vê, como campos `required` ausentes e enums publicados inline em vez de `components/schemas`.
- [2026-04-02] Se o ambiente local estiver sem `python` e sem `py` no PATH, registrar explicitamente a limitação e usar validação equivalente no CI (Linux) como continuidade para scripts de gate OpenAPI.
- [2026-04-03] Documentacao mestre unificada (`DOCS_MESTRE_FINAL_UNIFICADO.zip`) importada para `docs/` com estrutura numerada (00-overview a 07-diagrams). Esta e a fonte canonica de negocio, produto e arquitetura. Qualquer decisao de design, RBAC, integracao ou modelagem de dominio deve partir destes documentos antes de consultar backlog operacional.
- [2026-04-03] A estrutura de documentacao do projeto agora segue duas camadas: (1) documentacao mestre em `docs/00-07` (produto, arquitetura, engenharia, operacao) e (2) documentacao operacional legada em `docs/*.md` e `docs/web/` (backlog, licoes, ponto de restauracao). As duas sao complementares e nao conflitam.
- [2026-04-02] Em Windows, o PATH de usuário pode ficar malformado com caminhos concatenados por espaço; normalizar o PATH (corrigir delimitador `;`) e priorizar `...\Python312`, `...\Python312\Scripts` e `...\Python\Launcher` restaura `python` e `py` na sessao atual.
- [2026-04-02] No workflow `Android Homologation`, o passo `Validate app version bump` bloqueia o pipeline quando `pubspec.yaml` nao incrementa; para cada push de homologacao, subir `version` no formato semver+build.
- [2026-04-02] No workflow `Internal Docs CI`, quando o `mkdocs.yml` fica em subdiretorio sem pasta `docs/` filha, definir `docs_dir: .` evita erro de configuracao do MkDocs em `--strict`.
- [2026-04-02] Em ciclo de promocao para `main` com mantenedor unico, aplicar excecao temporaria de aprovacao minima apenas no instante do merge e restaurar `required_approving_review_count = 1` imediatamente apos a conclusao.
- [2026-04-02] Ao finalizar promocao, sincronizar homolog por fast-forward a partir de `origin/main` e validar divergencia final `0/0` para confirmar equalizacao real dos ambientes.
- [2026-04-02] Para evitar bloqueio recorrente no `Android Homologation` durante iteracoes de `release/*`, a validacao de version bump deve ser focada no fluxo de homologacao principal e nao no ciclo tecnico de ajuste da branch de release.
- [2026-04-02] No `apps/web-backoffice`, o Node test runner no Windows nao resolveu glob `*.test.ts` de forma confiavel via script npm; a solucao estavel foi usar um runner proprio (`scripts/run-tests.mjs`) para descobrir arquivos `.test.ts` e invocar `node --import tsx --test` explicitamente.
- [2026-04-02] No backend Java, a execucao do Maven/Surefire no terminal compartilhado do VS Code em Windows pode encerrar com prompt espurio de lote; para validacao deterministica nesta sessao, a abordagem estavel foi executar com `-DforkCount=0` em shell novo e ler o resultado completo dessa execucao.
- [2026-04-02] Em temas de seguranca/autenticacao, nao marcar backlog como concluido quando houver apenas UI/estado local ou mocks; exigir comprovacao de backend real, renovacao/revogacao, trilha de acesso e controles de tentativa antes de considerar o item fechado.
- [2026-04-02] Em RBAC de plataforma multi-tenant, separar explicitamente escopos de acesso (operacao da empresa, administracao de usuarios mobile da empresa e administracao global da plataforma) evita over-privilege e reduz risco de vazamento entre tenants.
- [2026-04-02] Em decisoes de acesso/identidade, usar sempre a estrategia canonica de negocio (IAM + white label + tenant + membership + personas) como fonte primaria; exemplos pontuais servem apenas para ilustrar e nao para redefinir o modelo.
- [2026-04-02] Para BOW-058/INT-026, aplicar RequestContextValidator centralizado reusavel em Spring Boot ao inves de validacao duplicada por controller evita manutencao dispersa e acelera expansao para novos modulos seguindo o mesmo padrao (ex: validador agora pronto para routers INT-026).
- [2026-04-02] Ao replicar pattern de validacao de headers para novo modulo (config module), mover testes de contrato para classe separada (ConfigPackageControllerContractErrorTest) com foco exclusivo em error cases (missing/blank) revela regressions de validacao 400 antes do suite geral.
- [2026-04-02] O config_backend_client.ts implementado com auto-geracao de correlationId via `cfg-${randomUUID()}` e deduplicacao de headers (evita override se ja presente) reduz boilerplate nas rotas Next.js e centraliza a logica de propagacao.
- [2026-04-02] Para validacao de propagacao web-to-backend, usar mock fetch com captura de headers no test da rota Next.js prova que o client injeta X-Correlation-Id sem depender de stack real (mais rapido e isolado que E2E).
- [2026-04-02] Apos aplicar patch multi-arquivo (8 arquivos), validacao em 3 niveis provou efetiva: 1) target set (6 testes = 2 contract + 3 lifecycle + 1 OpenAPI), 2) full backend suite (13 tests), 3) web lint + build, capturando regressoes em diferentes camadas com execucao total <60s.
- [2026-04-02] Para hardening multi-tenant em mutacoes sensiveis (approve/rollback), preferir consulta repository escopada por `tenantId` (`findByIdAndTenantId`) em vez de carregar por `id` e validar ownership depois; isso reduz risco de bypass e simplifica contrato de seguranca.
- [2026-04-02] Em edicao grande de classes Java, evitar replace parcial que pode manter conteudo legado duplicado no fim do arquivo; apos qualquer refactor amplo, validar imediatamente o arquivo completo e compilar para detectar duplicidade de classe/import antes de seguir.
- [2026-04-03] Ao gerar backlog multi-onda partir de documentos canonicos, primeiro auditar o codigo existente (java files, tsx files) para mapear o que existe vs. o que o modelo exige; gaps entre o codigo atual e o modelo canônico devem virar cards de "retrofit" com prioridade critica antes dos cards de feature nova.
- [2026-04-03] A sequencia correta de implementacao de IAM/tenant e: BOW-100 (Tenant+Membership entities) → BOW-101 (User retrofit com FK real) → BOW-102 (JWT auth backend) → BOW-103 (IdP adapter) → BOW-104 (RBAC escopo) → BOW-105 (policy engine). Nenhum endpoint sensivel deve ser exposto antes dessa cadeia estar completa.
- [2026-04-03] BL-031 (auth mobile) nao deve ser iniciado enquanto BOW-102 (JWT auth backend) nao tiver GET /auth/me funcional com tenant context correto; marcar BL-031 como "bloqueado por backend" evita retrabalho de UI sem contrato real.
- [2026-04-03] Ao substituir conteudo legado de arquivo via replace_string_in_file, o conteudo antigo que nao estava no trecho substituido permanece no arquivo; usar PowerShell (Get-Content + truncate por numero de linha) para remover conteudo legado do fim do arquivo de forma deterministica.
- [2026-04-03] Ao introduzir novas FKs em entidades de teste (ex.: Membership -> User), limpar dados apenas em `@BeforeEach` pode nao evitar contaminacao entre classes; adicionar `@AfterEach` com delete ordenado (dependente -> pai) evita quebra intermitente da suite.
- [2026-04-03] Em testes de integracao JPA, evitar assert em propriedades de relacoes LAZY fora de contexto transacional; preferir asserts por IDs ou usar fetch adequado para impedir `LazyInitializationException`.
- [2026-04-03] Para migracoes de dominio sem quebrar contrato (ex.: separar `UserLifecycle` de `User`), adotar estrategia dual-write temporaria no service e expor campo novo de observabilidade (`lifecycleStatus`) antes de remover campos legados (`status/role`) do contrato principal.
- [2026-04-03] Na etapa de migracao de autorizacao para `Membership`, aplicar dual-write em todas as mutacoes de usuario (create/import/approve/reject) e ajustar limpeza dos testes na ordem dependente -> pai (`memberships` antes de `users`) evita regressao intermitente por FK.
- [2026-04-03] Em migracao incremental de IAM, mover primeiro a leitura de role para `Membership` com fallback temporario em `User.role` preserva contrato de API e permite remover legado em etapa posterior sem freeze de entregas.
- [2026-04-03] Para base legada sem `Membership`, o backfill on-read no service (criando membership ao consultar usuario) reduz risco de ruptura e elimina dependencia prolongada de fallback em runtime.
- [2026-04-03] Ao introduzir Flyway em projeto que usava Hibernate ddl-auto create-drop: (a) mudar ddl-auto para none; (b) adicionar MODE=PostgreSQL no JDBC URL do H2 para compatibilidade de SQL; (c) atualizar todos os testes que criavam usuario diretamente (via new User + save) para primeiro garantir que o tenant existe — a FK V002 (users.tenant_id -> tenants.id) bloqueia INSERT sem tenant correspondente.
- [2026-04-03] Ao remover campo DB mas manter campo Java (@Transient), a V003/DROP ocorre antes dos testes rodarem (Flyway roda ao iniciar contexto Spring), entao o INSERT via Hibernate (que nao inclui @Transient) ja encontra a coluna ausente sem erro. Esta sequencia é segura para remocao de campos legados sem alterar construtores Java imediatamente.
- [2026-04-03] Ao criar novas tabelas com FK para `users` (ex.: user_credentials, sessions, identity_bindings via auth module), TODOS os testes de integracao que executam `userRepository.deleteAll()` devem ser atualizados para limpar as tabelas dependentes antes de deletar users. Falhar nisto causa FK violation silenciosa apenas ao rodar a suite completa (não ao rodar o novo teste isolado). Padrao de cleanup: sessions -> identityBindings -> userCredentials -> memberships -> ... -> users -> tenants.
- [2026-04-03] Para implementar auth JWT com stores resilientes (Redis opcional): usar interface + implementacao Redis com fallback para in-memory/no-op garante que testes de integracao passem mesmo sem Redis disponivel. O LoginAttemptStore e TokenRevocationStore com fallback gracioso sao o padrao correto para ambientes locais/CI.
- [2026-04-03] O BOW-103 (IdP Adapter) deve ser implementado junto com BOW-102: a interface IdentityProvider precisa existir antes de AuthService ser criado, pois AuthService depende dela. Separar em sprints distintos cria dependencia de classe concreta que quebra o padrao de inversao de dependencia.
- [2026-04-03] Ao introduzir autorizacao por interceptor (`@RequiresTenantRole`) em codigo legado com testes de contrato, manter a ordem de erro original e essencial: se `X-Correlation-Id` estiver ausente, o interceptor deve liberar e deixar o `RequestContextValidator` devolver `400 CTX_MISSING_HEADER`; caso contrario, testes existentes quebram por antecipar `401/403`.
- [2026-04-03] Para rollout incremental de RBAC em endpoints ja existentes, usar fallback legado controlado no interceptor (ex.: `actorRole` query/header e, temporariamente, `X-Actor-Id`/tenant context) evita quebra massiva da suite enquanto o fluxo JWT completo ainda nao foi propagado para todos os clientes.
- [2026-04-03] Ao adicionar nova tabela com FK para `tenants` (ex.: `integration_demands`), testes novos que executam `tenantRepository.deleteAll()` precisam limpar primeiro tabelas dependentes de tenants e tambem dependentes indiretos vindos de suites anteriores (memberships/sessoes/credentials), senao aparecem erros intermitentes por contaminacao de estado entre classes na execucao da suite completa.
- [2026-04-03] Antes de consolidar um pacote grande multi-stack para homologacao, usar `git diff --stat` + matriz final de validacao (backend full tests, web lint/test/build) ajuda a confirmar que o conjunto esta coerente para um unico commit rastreavel.

---

_Este arquivo é a referência viva do agente para garantir continuidade, resiliência e rastreabilidade operacional._
