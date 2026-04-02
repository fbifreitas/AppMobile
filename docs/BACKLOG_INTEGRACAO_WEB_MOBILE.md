# Backlog de Integracao Web-Mobile (Seguranca e Comunicacao Bidirecional)

Atualizado em: 2026-04-01

## Objetivo
Planejar e executar a camada de integracao entre backoffice web e AppMobile com:
1. seguranca forte,
2. comunicacao bidirecional confiavel,
3. rastreabilidade ponta a ponta,
4. capacidade de rollout/rollback de atualizacoes operacionais (ex.: menus dinamicos).

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
| 1 | INT-001 | API Gateway de Integracao | Critica | Pendente | Gateway dedicado para canais mobile com politicas de auth, rate limit, idempotencia e auditoria |
| 2 | INT-002 | Contratos versionados Web-Mobile | Critica | Pendente | OpenAPI versionada + politica de compatibilidade retroativa + deprecation policy |
| 3 | INT-003 | Canal seguro de configuracao remota | Critica | Pendente | Pacotes assinados, versionados e auditaveis para menus dinamicos/config operacional |
| 4 | INT-004 | Rollout e rollback de pacotes | Critica | Pendente | Publicacao por tenant, por grupo de apps e rollback em 1 clique com trilha |
| 5 | INT-005 | ACK/NACK de pacote no mobile | Alta | Pendente | Backoffice enxerga status de aplicacao por dispositivo/app version |
| 6 | INT-006 | Uplink de vistoria com idempotencia | Critica | Pendente | Recebimento resiliente de vistoria final sem duplicidade por retry offline |
| 7 | INT-007 | Protocolo de entrega e reconciliacao | Alta | Pendente | Protocolo unico por vistoria com consulta de status fim a fim |
| 8 | INT-008 | Fila de reprocessamento no backoffice | Alta | Pendente | Mensagens/payloads com erro podem ser reprocessados com controle e auditoria |
| 9 | INT-009 | Telemetria de integracao | Alta | Pendente | p95/p99, taxa de falha, timeout, retries, throughput por endpoint e tenant |
| 10 | INT-010 | Alertas operacionais de integracao | Alta | Pendente | Alertas por erro anomalo, backlog de fila, quebra de contrato e falha de pacote |
| 11 | INT-011 | Seguranca de pacote (assinatura) | Critica | Pendente | Assinatura e verificacao de pacote com rotacao de chave e validade temporal |
| 12 | INT-012 | Anti-replay e anti-tamper | Critica | Pendente | Nonce + timestamp + hash com bloqueio de repeticao e adulteracao |
| 13 | INT-013 | Gestao de credenciais por tenant | Critica | Pendente | Segredos/chaves segregados por tenant e ambiente com rotacao assistida |
| 14 | INT-014 | Matriz de compatibilidade app x pacote | Alta | Pendente | Pacote define versao minima/maxima de app suportada |
| 15 | INT-015 | Feature flags de integracao | Media | Pendente | Habilitacao gradual de canais e recursos por tenant/ambiente |
| 16 | INT-016 | Testes de contrato automatizados | Critica | Pendente | CI bloqueia merge em caso de quebra de contrato mobile-web |
| 17 | INT-017 | Testes E2E de resiliencia | Alta | Pendente | Cenarios de offline, retry, timeout, rollback e recuperacao automatizada |
| 18 | INT-018 | Painel de operacao de integracao | Alta | Pendente | Backoffice visualiza saude bidirecional em tempo real |
| 19 | INT-019 | Politica de retention de eventos | Media | Pendente | Eventos de integracao com retention, mascaramento e trilha probatoria |
| 20 | INT-020 | DR e continuidade da integracao | Media | Pendente | Plano de recuperacao para indisponibilidade parcial/total do canal |
| 21 | INT-021 | Contrato financeira->backoffice (ingestao de job) | Critica | Pendente | Contrato versionado para payload de entrada da financeira com validacao de schema, autenticidade e idempotencia |
| 22 | INT-022 | Normalizacao canonica de processo/job | Critica | Pendente | Payload externo convertido para modelo canonico (processo, cliente, endereco, agenda, status) sem perda de rastreabilidade |
| 23 | INT-023 | Callback/status para origem financeira | Alta | Pendente | Resposta padronizada com `success`, `message`, `process_id`, `process_number`, estado e trilha de auditoria |
| 24 | INT-024 | Matriz de visibilidade de dados (LGPD) | Alta | Pendente | Definicao de quais campos da origem externa sao expostos no web e no mobile, com mascaramento por perfil |
| 25 | INT-025 | Política de versionamento de APIs e eventos | Critica | Em andamento | Regras formais de compatibilidade retroativa e depreciação com gate em CI para breaking changes |
| 26 | INT-026 | Context envelope obrigatório (tenant + correlation + actor) | Critica | Pendente | Toda chamada síncrona e evento assíncrono deve carregar contexto mínimo validado no gateway |
| 27 | INT-027 | Padrão de idempotency-key por operação | Critica | Pendente | Chaves idempotentes normalizadas por domínio, TTL definido e reprocessamento seguro sem duplicidade |
| 28 | INT-028 | Contrato de erro canônico entre canais | Alta | Pendente | Catálogo único de erros com códigos, severidade e orientação operacional consistente para web/mobile |
| 29 | INT-029 | Isolamento criptográfico por tenant/parceiro | Alta | Pendente | Credenciais e segredos segregados por tenant/parceiro com rotação auditável e política de menor privilégio |

---

## Mapeamento com backlog de backoffice
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
