> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Backlog de Integracao Web-Mobile (Seguranca e Comunicacao Bidirecional)

Atualizado em: 2026-04-08

## Objetivo
Planejar e executar a camada de integracao entre backoffice web e AppMobile com:
1. seguranca forte,
2. comunicacao bidirecional confiavel,
3. rastreabilidade ponta a ponta,
4. capacidade de rollout/rollback de atualizacoes operacionais (ex.: menus dinamicos).

## Cabecalho executavel (padrao)

Usar este cabecalho nos itens priorizados:
- Camada
- Dominio
- Area
- Objetivo
- Arquivos provaveis
- Dependencias
- Testes obrigatorios
- Evidencia esperada
- Docs que precisam ser atualizados
- Criterio de pronto

## Stack de integracao alinhada
1. API Gateway e servicos de integracao: Java 21 + Spring Boot 3.
2. Mensageria de integracao: RabbitMQ (fase inicial) com trilha de evolucao para Kafka.
3. Persistencia de eventos e protocolos: PostgreSQL.
4. Cache operacional e controle anti-replay: Redis.
5. Contratos e compatibilidade: OpenAPI 3 + testes de contrato em CI.
6. Observabilidade: OpenTelemetry + Prometheus/Grafana + logs centralizados.

## Decisoes de seguranca de referencia
1. Autenticacao por OIDC/JWT com access token curto e refresh controlado.
2. Assinatura de pacote de configuracao (JWS ou equivalente) com rotacao de chave.
3. Validacao de integridade de payload por hash/checksum nos dois sentidos.
4. Anti-replay por nonce, timestamp e janela de validade.
5. Segregacao de segredos e chaves por tenant e ambiente.

## Escopo
1. Downlink (Web -> Mobile): configuracoes, pacotes, comandos operacionais, notificacoes.
2. Uplink (Mobile -> Web): finalizacao de vistoria, eventos, status de sync, telemetria.
3. Governanca de contrato: versionamento, compatibilidade e rollout progressivo.

## Contexto novo: integracao Financeira -> Web -> Mobile
1. A entrada de jobs via payload de financeira deve ser tratada como contrato de integracao de origem externa (upstream), com normalizacao no backoffice antes de exposicao ao mobile.
2. Nem todos os campos da financeira devem chegar ao app; o mobile deve consumir apenas o recorte operacional necessario via APIs de jobs/config/sync.
3. O contrato de resposta do backoffice para a financeira deve preservar rastreabilidade por `process_id`, `process_number`, status e timestamps.
4. Campos sensiveis (ex.: documento de cliente) devem seguir mascaramento e politicas de privacidade por tenant/ambiente.

### Exemplo de mapeamento funcional (origem financeira -> dominio web/mobile)
1. `number` -> `process_number` -> job/protocolo exibivel no app (BL-004).
2. `inspectionType` -> tipo de vistoria para roteamento de fluxo e regras.
3. `resType` + endereco -> tipo de imovel e contexto de check-in dinamico (BL-012).
4. `inspectionDate[]` -> agenda operacional (BL-029) e status de alocacao.
5. `internalPropose` -> referencia cruzada para conciliacao operacional e suporte.
6. `client.doc`, `client.phoneNumber` -> dados restritos com acesso controlado por perfil.

---

## Decisao arquitetural
Manter backlog de integracao separado e vinculado aos demais backlogs.

Motivo:
1. Integracao e um produto em si (seguranca, protocolo, observabilidade, rollout).
2. Evita esconder riscos criticos dentro de backlog funcional geral.
3. Permite priorizacao e ownership claro (plataforma/integracao).

---

## Modelo de comunicacao bidirecional

### Fluxo A - Web para Mobile (downlink)
1. Backoffice publica pacote (ex.: configuracao de check-in).
2. Gateway de integracao valida assinatura/versionamento.
3. Mobile consulta/recebe pacote e valida integridade.
4. Mobile aplica pacote, registra ACK/NACK para web.

### Fluxo B - Mobile para Web (uplink)
1. Mobile finaliza vistoria e envia payload tecnico.
2. Gateway valida autenticacao, idempotencia e schema.
3. Backoffice persiste, gera protocolo e retorna status.
4. Mobile confirma recebimento, limpa fila local quando aplicavel.

---

## Requisitos de seguranca obrigatorios
1. Autenticacao forte por token de curta duracao + refresh controlado.
2. Assinatura de pacotes de configuracao (JWS/assinatura digital equivalente).
3. Validacao de integridade de payload (hash/checksum) nos dois sentidos.
4. Protecao contra replay (nonce, timestamp, janela de validade).
5. Idempotencia obrigatoria para operacoes de escrita criticas.
6. Rotacao de chaves e credenciais com versionamento.
7. Segregacao por tenant (white label) em todos os canais.
8. Correlation id em todas as chamadas para auditoria.
9. Criptografia em transito (TLS) e hardening de endpoints.
10. Trilha de auditoria imutavel para eventos sensiveis.

---

## Backlog priorizado de integracao (INT)

| Seq | ID | Modulo | Prioridade | Status | Criterio de pronto |
|---|---|---|---|---|---|
| 1 | INT-001 | API Gateway de Integracao | Critica | Em andamento (filtro de gateway mobile com validaï¿½ï¿½o de versï¿½o e rate-limit base em 2026-04-04) | Gateway dedicado para canais mobile com politicas de auth, rate limit, idempotencia e auditoria |
| 2 | INT-002 | Contratos versionados Web-Mobile | Critica | Em andamento (header obrigatï¿½rio X-Api-Version v1 aplicado em 2026-04-04) | OpenAPI versionada + politica de compatibilidade retroativa + deprecation policy |
| 3 | INT-003 | Canal seguro de configuracao remota | Critica | Em andamento (baseline funcional entregue em 2026-04-08 com assinatura HMAC emitida/validada e consumo mobile real) | Pacotes assinados, versionados e auditaveis para menus dinamicos/config operacional |
| 4 | INT-004 | Rollout e rollback de pacotes | Critica | Em andamento (baseline operacional entregue em 2026-04-08 com versionamento de pacote e rollback refletindo no mobile) | Publicacao por tenant, por grupo de apps e rollback em 1 clique com trilha |
| 5 | INT-005 | ACK/NACK de pacote no mobile | Alta | Pendente | Backoffice enxerga status de aplicacao por dispositivo/app version |
| 6 | INT-006 | Uplink de vistoria com idempotencia | Critica | Em andamento (baseline operacional entregue em 2026-04-08 com API idempotente, dedupe local e sync real) | Recebimento resiliente de vistoria final sem duplicidade por retry offline |
| 7 | INT-007 | Protocolo de entrega e reconciliacao | Alta | Em andamento (metadata de processo/protocolo devolvida no sync ate 2026-04-08) | Protocolo unico por vistoria com consulta de status fim a fim |
| 8 | INT-008 | Fila de reprocessamento no backoffice | Alta | Pendente | Mensagens/payloads com erro podem ser reprocessados com controle e auditoria |
| 9 | INT-009 | Telemetria de integracao | Alta | Em andamento (control tower operacional entregue em 2026-04-08) | p95/p99, taxa de falha, timeout, retries, throughput por endpoint e tenant |
| 10 | INT-010 | Alertas operacionais de integracao | Alta | Em andamento (baseline de alertas entregue em 2026-04-08) | Alertas por erro anomalo, backlog de fila, quebra de contrato e falha de pacote |
| 11 | INT-011 | Seguranca de pacote (assinatura) | Critica | Em andamento (assinatura e verificacao ativas no baseline entregue em 2026-04-08) | Assinatura e verificacao de pacote com rotacao de chave e validade temporal |
| 12 | INT-012 | Anti-replay e anti-tamper | Critica | Em andamento (nonce/timestamp obrigatorios no uplink critico ate 2026-04-08) | Nonce + timestamp + hash com bloqueio de repeticao e adulteracao |
| 13 | INT-013 | Gestao de credenciais por tenant | Critica | Pendente | Segredos/chaves segregados por tenant e ambiente com rotacao assistida |
| 14 | INT-014 | Matriz de compatibilidade app x pacote | Alta | Pendente | Pacote define versao minima/maxima de app suportada |
| 15 | INT-015 | Feature flags de integracao | Media | Pendente | Habilitacao gradual de canais e recursos por tenant/ambiente |
| 16 | INT-016 | Testes de contrato automatizados | Critica | Em andamento (suite de contrato mobile ajustada para v1 e headers obrigatï¿½rios em 2026-04-04) | CI bloqueia merge em caso de quebra de contrato mobile-web |
| 17 | INT-017 | Testes E2E de resiliencia | Alta | Pendente | Cenarios de offline, retry, timeout, rollback e recuperacao automatizada |
| 18 | INT-018 | Painel de operacao de integracao | Alta | Em andamento (control tower operacional entregue em 2026-04-08) | Backoffice visualiza saude bidirecional em tempo real |
| 19 | INT-019 | Politica de retention de eventos | Media | Em andamento (retention baseline entregue em 2026-04-08) | Eventos de integracao com retention, mascaramento e trilha probatoria |
| 20 | INT-020 | DR e continuidade da integracao | Media | Em andamento (checklist operacional entregue em 2026-04-08) | Plano de recuperacao para indisponibilidade parcial/total do canal |
| 21 | INT-021 | Contrato financeira->backoffice (ingestao de job) | Critica | Pendente | Contrato versionado para payload de entrada da financeira com validacao de schema, autenticidade e idempotencia |
| 22 | INT-022 | Normalizacao canonica de processo/job | Critica | Pendente | Payload externo convertido para modelo canonico (processo, cliente, endereco, agenda, status) sem perda de rastreabilidade |
| 23 | INT-023 | Callback/status para origem financeira | Alta | Pendente | Resposta padronizada com `success`, `message`, `process_id`, `process_number`, estado e trilha de auditoria |
| 24 | INT-024 | Matriz de visibilidade de dados (LGPD) | Alta | Pendente | Definicao de quais campos da origem externa sao expostos no web e no mobile, com mascaramento por perfil |
| 25 | INT-025 | PolÃ­tica de versionamento de APIs e eventos | Critica | Concluido (gate estrutural + semantico no CI, suite de 8 testes do validador, hardening de readiness/fallback de endpoint OpenAPI e tolerancia a baseline ausente no ciclo de promocao para main em 2026-04-02) | Regras formais de compatibilidade retroativa e depreciaÃ§Ã£o com gate em CI para breaking changes |
| 26 | INT-026 | Context envelope obrigatÃ³rio (tenant + correlation + actor) | Critica | Em andamento (config module enforcement + web client auto-propagation complete; RequestContextValidator utility reusable; pendente: expansion to INT-026 integration routers para inbound calls from external apis following same pattern) | Toda chamada sÃ­ncrona e evento assÃ­ncrono deve carregar contexto mÃ­nimo validado no gateway |
| 27 | INT-027 | PadrÃ£o de idempotency-key por operaÃ§Ã£o | Critica | Pendente | Chaves idempotentes normalizadas por domÃ­nio, TTL definido e reprocessamento seguro sem duplicidade |
| 28 | INT-028 | Contrato de erro canÃ´nico entre canais | Alta | Em andamento (fundaÃ§Ã£o v1 + cobertura TDD ampliada nos endpoints mobile crÃ­ticos) | CatÃ¡logo Ãºnico de erros com cÃ³digos, severidade e orientaÃ§Ã£o operacional consistente para web/mobile |

| 30 | INT-030 | Configuracao de segredo de assinatura por ambiente (homolog/producao) | Critica | Em andamento (validator e gate operacional entregues em 2026-04-08; pendente provisionamento definitivo por ambiente) | integration.config-signing.hmac-key provisionado por ambiente via secret manager/Actions secrets, com checklist de release e evidencias de validacao |

---

## Mapeamento com backlog de backoffice

### Bloco executavel prioritario (inicio)

#### INT-001
- Camada: platform-core
- Dominio: cross-domain
- Area: integration gateway
- Objetivo: gateway dedicado para canais mobile com auth/rate-limit/idempotencia
- Arquivos provaveis: `apps/backend/**/gateway*`, filtros/interceptors, config
- Dependencias: BOW-100, BOW-102
- Testes obrigatorios: contrato + seguranca de contexto minimo
- Evidencia esperada: endpoint protegido com trilha auditavel
- Docs a atualizar: backlog integracao e backlog web impactado
- Criterio de pronto: chamadas mobile com politicas minimas aplicadas

#### INT-002
- Camada: shared-foundation
- Dominio: cross-domain
- Area: contracts/versioning
- Objetivo: contratos versionados com politica de compatibilidade
- Arquivos provaveis: OpenAPI, validadores de contrato CI, docs de contrato
- Dependencias: INT-001
- Testes obrigatorios: contract tests em CI
- Evidencia esperada: gate de quebra contratual ativo
- Docs a atualizar: backlog integracao e docs operacionais de governanca
- Criterio de pronto: PR bloqueada automaticamente em breaking change

1. BOW-008, BOW-009 <-> INT-003, INT-004, INT-011, INT-014
2. BOW-010, BOW-011, BOW-012 <-> INT-006, INT-007, INT-008, INT-012
3. BOW-014, BOW-019, BOW-047 <-> INT-009, INT-010, INT-016, INT-018
4. BOW-005, BOW-029, BOW-030, BOW-031, BOW-032 <-> INT-001, INT-013, INT-015
5. BOW-049, BOW-050, BOW-051, BOW-052 <-> INT-021, INT-022, INT-023, INT-024

---

## Entregas imediatas (Sprint de Integracao)
1. INT-001 + INT-002: gateway e contratos versionados.
2. INT-003 + INT-004: canal de pacotes de configuracao com rollout/rollback.
3. INT-006 + INT-007: uplink de vistoria com protocolo e reconciliacao.
4. INT-011 + INT-012: assinatura de pacote e anti-replay.
5. INT-009 + INT-018: observabilidade operacional minima.

---

## Criterios de aceite transversais
1. Nenhuma operacao critica sem idempotencia e correlation id.
2. Nenhum pacote operacional sem assinatura e verificacao de integridade.
3. Nenhuma mudanca de contrato sem teste automatizado de compatibilidade.
4. Nenhum tenant compartilha chave, segredos ou trilha de eventos com outro.
5. Todo incidente de integracao deve ser diagnosticavel por painel e logs.

## ADENDO 2026-04-04 - Reconciliacao de Integracao

- INT-025 continua concluido como base de governanca de versao.
- INT-026 e INT-028 continuam em andamento.
- Existe avanco tecnico parcial de integracao no codigo ativo (context envelope, rotas web-backoffice para config/inspections e trilha de publish/approve/rollback), devendo ser usado para priorizar fechamento de INT-001, INT-002, INT-003, INT-004 e INT-006.




## Adendo 2026-04-04 (execucao pacote)
- INT-001: filtro MobileGatewayPolicyFilter adicionado no backend para rotas /api/mobile/* com validaï¿½ï¿½o de versï¿½o e rate-limit base por tenant/actor.
- INT-002: contratos mobile passaram a exigir X-Api-Version (1) em endpoint e validaï¿½ï¿½o de contexto.
- INT-016: testes de contrato/integraï¿½ï¿½o mobile atualizados para novo header obrigatï¿½rio e polï¿½tica de versï¿½o.

## Adendo 2026-04-05 (governanca da esteira automatica)
- INT-025: pacote `v1.2.28+48` incluiu ajuste de resiliencia no `openapi-compatibility-gate` da `backend_ci.yml`, evitando quebra hard quando o OpenAPI current nao sobe no run de PR.
- INT-016: estabilizacao do backend CI com alinhamento de asserts canonicos em `ConfigPackageControllerContractErrorTest` para mensagem de contrato vigente.
- Checkpoint de processo: pacote promovido para branch `release/v1.2.28+48` (sem PR direto para `main`), respeitando fluxo de homologacao documentado.

## Adendo 2026-04-10 - Compass Mobile Auth/Jobs
- INT-001: `GET /api/mobile/jobs` exige `Authorization: Bearer <token>` e valida a sessao contra `X-Tenant-Id` e `X-Actor-Id`, bloqueando spoof de contexto por header.
- INT-001: `GET /api/mobile/checkin-config` e `POST /api/mobile/inspections/finalized` validam o bearer token quando informado, bloqueando contexto divergente antes de resolver configuracao ou aceitar payload finalizado.
- INT-016: `MobileAuthJobsIntegrationTest` cobre o smoke Compass com login backend real, job aceito atribuido ao operador e rejeicao `AUTH_CONTEXT_MISMATCH` para ator divergente.
- Evidencia local: `C:\tools\apache-maven-3.9.14\bin\mvn.cmd "-Dtest=MobileAuthJobsIntegrationTest,MobileApiControllerContractErrorTest,AuthIntegrationTest" test` passou com 17 testes; suite focada `MobileAuthJobsIntegrationTest,MobileApiControllerContractErrorTest,MobileCheckinConfigIntegrationTest,InspectionSubmissionIntegrationTest` passou com 26 testes apos hardening de config/sync.

## Adendo 2026-04-10 - Compass Operacao E2E Homolog
- INT-001: smoke E2E valida o percurso autenticado Compass de login, jobs mobile, config mobile e sync de vistoria finalizada usando bearer e contexto tenant/ator.
- INT-004: smoke E2E valida publicacao e aprovacao de pacote operacional Compass por tenant antes do consumo mobile.
- INT-009: smoke E2E valida persistencia de eventos operacionais durante config, sync, inspection, valuation e report.
- INT-018: smoke E2E valida control tower com requests nas ultimas 24h, endpoint mobile rastreado e report pronto para assinatura.
- Evidencia local: `C:\tools\apache-maven-3.9.14\bin\mvn.cmd "-Dtest=CompassOperationEndToEndIntegrationTest" test` passou com 1 teste; regressao focada `CompassOperationEndToEndIntegrationTest,ValuationReportBackofficeIntegrationTest,OperationsControlTowerIntegrationTest` passou com 3 testes.

## Adendo 2026-04-08 - Agrupamento operacional em 2 macro-pacotes

### Macro-pacote A - Go-Live Core Web-Mobile
Itens de integracao incluidos nesta rodada:
1. INT-001
2. INT-002
3. INT-003
4. INT-004
5. INT-006
6. INT-007
7. INT-011
8. INT-012
9. INT-016
10. INT-026
11. INT-027
12. INT-028
13. INT-030

Objetivo do conjunto:
1. fechar configuracao remota com seguranca real;
2. fechar uplink de vistoria com idempotencia, protocolo e reconciliacao;
3. proteger contrato, contexto e assinatura em CI e em ambiente.

Gate de saida do pacote:
1. nenhuma operacao critica sem idempotency-key, correlation id e contexto minimo;
2. nenhum pacote operacional sem assinatura e verificacao ativa onde exigido;
3. nenhum merge permitido com quebra contratual mobile-web;
4. segredo de assinatura por ambiente provisionado e evidenciado.

### Macro-pacote B - Backoffice Operational Closure
- Nao ha item de integracao entrando como prioridade principal nesta rodada.
- Itens como INT-008, INT-009, INT-010, INT-018, INT-019 e INT-020 ficam explicitamente fora do caminho critico imediato e so devem subir apos fechamento do Macro-pacote A.
## Adendo 2026-04-08 - Pos-release v1.2.40+60

- INT-001/002/003/004/006/007/011/012/016/026/027/028/030 avancaram de forma real no codigo promovido para `main`, com esteira verde na PR #25.
- O backlog de integracao deixa de tratar rollout, assinatura, uplink idempotente e anti-replay como apenas aspiracionais; o estado correto agora e baseline operacional entregue com hardening residual pendente.
- A lacuna mais visivel apos o release deixou de ser contrato basico e passou a ser operacao/observabilidade de integracao (`INT-009`, `INT-010`, `INT-018`).

## Adendo 2026-04-08 - Control tower operacional entregue

- INT-009, INT-010 e INT-018 passaram a ter baseline real com eventos persistidos, agregados por endpoint/tenant e painel unico no backoffice.
- INT-019 e INT-020 tambem deixaram de ser apenas intencao: existe cleanup manual de retention no backend e checklist operacional de continuidade exposto na control tower.
- O backlog de integracao agora sai de observabilidade zero para observabilidade basica entregue, ficando o restante como evolucao de profundidade e refinamento de alertas.
