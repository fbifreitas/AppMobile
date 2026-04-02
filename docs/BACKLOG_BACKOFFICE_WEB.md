# Backlog de Desenvolvimento — Backoffice Web (Integração com App Mobile)

Atualizado em: 2026-04-01

## Objetivo
Organizar o backlog do aplicativo web de backoffice necessário para suportar o AppMobile em produção, cobrindo:
- integrações já esperadas pelo código mobile,
- configurações remotas necessárias para o fluxo de vistoria,
- funcionalidades futuras já previstas no backlog mobile que exigem backend/backoffice.

## Stack oficial aprovada

### Plataforma principal
1. Backend: Java 21 + Spring Boot 3.
2. Frontend Web: TypeScript + React/Next.js.
3. Banco relacional: PostgreSQL.
4. Cache e sessões técnicas: Redis.
5. Mensageria/eventos: RabbitMQ (fase inicial) com evolução para Kafka se volume exigir.
6. API contracts: OpenAPI 3 com geração de client SDK quando aplicável.

### Segurança e identidade
1. Protocolo de identidade: OIDC/SAML.
2. Camada IAM: Keycloak (self-managed) ou Entra ID/Auth0 por tenant conforme estratégia comercial.
3. Federação corporativa futura: Active Directory (Azure AD/ADFS) via adapter de identidade.
4. Autorização: RBAC + políticas contextuais de domínio (policy engine).

### Observabilidade e operação
1. Tracing/metrics: OpenTelemetry.
2. Métricas e dashboards: Prometheus + Grafana.
3. Logs centralizados: ELK/OpenSearch (ou stack equivalente no provedor cloud).
4. Alertas: regras por SLO/SLA da esteira de integração e geração de laudos.

### Documentos e assinatura digital
1. Geração de documento: serviço de composição de laudo (HTML/PDF) orientado a template por tenant.
2. Assinatura digital: integração com provedores privados e públicos via gateway de assinatura.
3. Armazenamento de artefatos assinados: storage imutável + trilha de auditoria.

### Motivos da escolha
1. Aderência alta ao mercado enterprise e facilidade de contratação.
2. Ecossistema robusto para segurança corporativa, AD e governança regulatória.
3. Maturidade para arquitetura modular DDD em domínios complexos.
4. Escalabilidade para cálculos técnicos, integrações externas e mensageria.
5. Boa separação entre time backend corporativo e time frontend de produto.

## Backlog complementar de integracao
Para seguranca, protocolo e operacao da comunicacao bidirecional entre Web e Mobile, consultar `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

## Diretriz estratégica obrigatória
O backoffice deve nascer como plataforma white label orientada a domínio (DDD), com arquitetura de identidade preparada para federação corporativa futura (Active Directory via OIDC/SAML), sem refatoração estrutural quando essa integração for habilitada.

## Princípios arquiteturais (DDD + IAM + White Label)
1. Modelar por bounded contexts:
  - Identity and Access
  - Tenant and Branding
  - User Lifecycle (Onboarding, Approval, Profile)
  - Scheduling
  - Field Inspection Operations
  - Messaging and Notification
2. Evitar regras de autorização espalhadas na camada de interface; centralizar em políticas de domínio.
3. Separar autenticação (quem é o usuário) de autorização (o que pode fazer) e de tenant context (em qual marca/empresa atua).
4. Garantir multi-tenant lógico desde o início para suportar white label real no web e no mobile.
5. Tratar integração com IdP externo como porta de infraestrutura (adapter), não como regra do domínio.

## Modularização obrigatória para ciclo do laudo (NBR 14653)
O sistema deve ser modular para automatizar ao máximo o trabalho técnico, mantendo assinatura e responsabilidade técnica humana.

### Bounded contexts adicionais (núcleo de avaliação)
1. Inspection Intake: recepção e validação técnica da vistoria vinda do app mobile.
2. Valuation Data Hub: coleta, normalização e governança de dados externos.
3. NBR 14653 Valuation Engine: execução dos métodos e cálculos técnicos.
4. Technical Report Composer: composição automática do laudo e anexos.
5. Technical Review and Sign-Off: revisão por engenheiro/arquiteto e assinatura digital.
6. Process Orchestration: esteira com estados, SLA, fila e reprocessamento.
7. Management Intelligence: painéis de operação, qualidade e produtividade.

### Meta operacional
1. Objetivo: aproximar o sistema de 100% de automação do trabalho operacional/técnico repetitivo.
2. Guarda-corpo: assinatura final e responsabilidade técnica continuam com profissional habilitado.
3. Estratégia: automação de coleta, pré-cálculo, consistência normativa, redação técnica e montagem documental.

## Diagnóstico técnico do app mobile
Pontos já integrados no mobile que dependem de backend/backoffice:
- Configuração dinâmica de check-in:
  - `APP_API_BASE_URL`
  - `APP_API_TOKEN`
  - `APP_CHECKIN_CONFIG_ENDPOINT` (default: `/api/mobile/checkin-config`)
- Envio da vistoria final:
  - `APP_API_BASE_URL`
  - `APP_API_TOKEN`
  - `APP_INSPECTION_SYNC_ENDPOINT` (default: `/api/mobile/inspections/finalized`)
- Sincronização offline com fila local (retry ao reabrir Home): exige endpoint idempotente e observável.
- Funcionalidades com placeholder no mobile e dependência direta de backoffice:
  - Agenda (aba dedicada em evolução)
  - Notificações/mensagens (tela placeholder)
  - Login/autenticação
  - Onboarding CLT/PJ + aprovação
  - Atualização cadastral e foto de perfil
  - Exibição de protocolo/ID externo no job

## Contexto novo: integração de payload da financeira
1. O backoffice deve receber payload de criação de processo vindo da financeira (upstream) e normalizar para o modelo canônico de jobs/processos.
2. A resposta para a financeira deve manter contrato estável (ex.: `success`, `message`, `process_id`, `process_number`, `data`) e rastreabilidade completa.
3. O app mobile não deve consumir o payload bruto da financeira; deve consumir somente APIs internas do backoffice já saneadas e com controle de visibilidade de campos.
4. Campos com dados pessoais/sensiveis exigem política de mascaramento e controle de acesso por perfil/tenant.

## Mapeamento com backlog mobile
Itens mobile que geram demanda de backend/backoffice:
- BL-001, BL-002, BL-004, BL-009, BL-012, BL-017, BL-021, BL-022, BL-023
- BL-029, BL-030, BL-031, BL-032, BL-033, BL-034, BL-035, BL-056

---

## Roadmap recomendado (Web Backoffice)

### Fase 1 — Fundação de plataforma (crítica)
1. BOW-001 a BOW-006
2. BOW-029 a BOW-033

### Fase 2 — Integrações core do mobile (crítica)
1. BOW-007 a BOW-013

### Fase 3 — Operação e governança (alta)
1. BOW-014 a BOW-019

### Fase 4 — Funcionalidades de ciclo seguinte (alta)
1. BOW-020 a BOW-028
2. BOW-034

### Fase 5 — Núcleo de laudo técnico e assinatura (crítica)
1. BOW-035 a BOW-048

---

## Backlog priorizado (Backoffice Web)

| Seq | ID | Módulo | Relaciona com BL mobile | Status | Prioridade | Critério de pronto |
|---|---|---|---|---|---|---|
| 1 | BOW-001 | Identidade e acesso (Auth) | BL-031 | Pendente | Crítica | Login com JWT (access + refresh), expiração, renovação, logout, revogação de sessão |
| 2 | BOW-002 | RBAC backoffice | BL-031, BL-033 | Pendente | Crítica | Perfis mínimos: Admin, Operação, Suporte, Auditoria; controle por rota e ação |
| 3 | BOW-003 | Gestão de usuários | BL-032, BL-033, BL-034, BL-035 | Pendente | Crítica | CRUD de usuário, status de aprovação, trilha de auditoria de alterações |
| 4 | BOW-004 | Contrato de erros e observabilidade | BL-021, BL-022 | Pendente | Crítica | Envelope padrão de erro, correlation id por request, logs estruturados |
| 5 | BOW-005 | Segurança e secrets | BL-023 | Pendente | Crítica | Segredos fora de código, rotação, mascaramento e checklist de segurança |
| 6 | BOW-006 | Catálogo de integrações mobile | BL-017 | Pendente | Crítica | Catálogo versionado de contratos (OpenAPI) para endpoints mobile |
| 7 | BOW-007 | API de jobs do vistoriador | BL-029, BL-004 | Pendente | Crítica | Endpoint paginado de jobs com protocolo externo, status e geolocalização |
| 8 | BOW-008 | API de configuração dinâmica check-in | BL-012 | Pendente | Crítica | Endpoint `/api/mobile/checkin-config` com versionamento, filtro por tipoImovel e validação |
| 9 | BOW-009 | Painel backoffice de sessões NBR | BL-012 | Pendente | Crítica | UI para editar sessões (obrigatório/desejável, ícone, contexto), publicar versão e rollback |
| 10 | BOW-010 | API de recebimento da vistoria final | BL-001, BL-002 | Pendente | Crítica | Endpoint idempotente para JSON final, persistência completa, retorno de protocolo |
| 11 | BOW-011 | Motor de idempotência e deduplicação | BL-001, BL-002 | Pendente | Crítica | Reenvios da fila offline não geram duplicidade de vistoria |
| 12 | BOW-012 | API de status de sincronização | BL-002, BL-009 | Pendente | Alta | Consulta de status por job/protocolo para suporte e reconciliação |
| 13 | BOW-013 | Backoffice de vistorias recebidas | BL-001, BL-003, BL-004 | Pendente | Alta | Lista, filtro e detalhe técnico da vistoria recebida com protocolo |
| 14 | BOW-014 | Telemetria de fluxo mobile | BL-009, BL-022 | Pendente | Alta | Ingestão de eventos (início, retomada, conclusão, falha), dashboard operacional |
| 15 | BOW-015 | Auditoria de fallback e retomada | BL-008 | Pendente | Alta | Painel para inspeção de integridade de payload e diagnóstico de retomada |
| 16 | BOW-016 | Catálogo de mensagens operacionais | BL-030 | Pendente | Alta | Gestão de templates e mensagens vinculadas a job/proposta |
| 17 | BOW-017 | Serviço de push notifications | BL-030 | Pendente | Alta | Registro de device token, envio push por evento, rastreio de entrega |
| 18 | BOW-018 | Centro de mensagens (web) | BL-030 | Pendente | Alta | Conversas por job/proposta, histórico, anexos, status lida/não lida |
| 19 | BOW-019 | Contract tests mobile-backend | BL-017 | Pendente | Alta | Pact/contract tests em CI bloqueando quebra de contrato |
| 20 | BOW-020 | Agenda operacional (web) | BL-029 | Pendente | Alta | Calendário por vistoriador, regras de conflito, status do agendamento |
| 21 | BOW-021 | API de agenda para mobile | BL-029 | Pendente | Alta | Endpoint de agenda mensal/semanal com paginação e timezone consistente |
| 22 | BOW-022 | Onboarding CLT/PJ (web) | BL-032 | Pendente | Crítica | Fluxos de cadastro com validação documental, dados bancários PJ e trilha de análise |
| 23 | BOW-023 | Aprovação de cadastro | BL-033 | Pendente | Crítica | Workflow pendente/aprovado/reprovado com motivo e data |
| 24 | BOW-024 | API de perfil do usuário | BL-034, BL-035 | Pendente | Alta | Leitura/escrita de perfil, versionamento e validação de campos |
| 25 | BOW-025 | Upload de foto de perfil | BL-035 | Pendente | Alta | Endpoint seguro para foto de perfil com política de conteúdo e armazenamento |
| 26 | BOW-026 | Política de retenção de dados | BL-005, BL-016 | Pendente | Média | Regras de retenção para payloads, anexos e logs com rotinas automáticas |
| 27 | BOW-027 | Administração de parâmetros remotos | BL-006, BL-010 | Pendente | Média | Painel para toggles/config remota com auditoria e segregação por ambiente |
| 28 | BOW-028 | Governança de release e ambiente | BL-011, BL-023 | Pendente | Média | Separação de ambientes (dev/internal/prod), chaves e políticas por ambiente |
| 29 | BOW-029 | Modelo multi-tenant do domínio | BL-031, BL-033 | Pendente | Crítica | Entidades Tenant, Organization, Membership e isolamento lógico por tenant aplicados em todas as operações |
| 30 | BOW-030 | White label de marca e comportamento | BL-029, BL-030, BL-031 | Pendente | Alta | Branding por tenant (nome, logo, cores, textos, domínios, políticas) refletido em web e contratos mobile |
| 31 | BOW-031 | Abstração de identidade (IdP agnóstico) | BL-031 | Pendente | Crítica | Login suportando provider interno e provider externo por adapter, sem acoplamento ao AD |
| 32 | BOW-032 | Federação com Active Directory | BL-031 | Pendente | Alta | Suporte OIDC/SAML para Azure AD/ADFS com mapeamento de grupos para papéis de domínio |
| 33 | BOW-033 | Autorização por políticas de domínio | BL-031, BL-033, BL-034 | Pendente | Crítica | RBAC + regras contextuais (tenant, unidade, papel, status) centralizadas em policy engine |
| 34 | BOW-034 | Provisionamento e ciclo de identidade | BL-032, BL-033, BL-034 | Pendente | Alta | Provisionamento manual/automatizado (SCIM-ready), ativação, bloqueio, desligamento e trilha de auditoria |
| 35 | BOW-035 | Pipeline de intake de vistoria | BL-001, BL-002, BL-012 | Pendente | Crítica | Payload da vistoria validado, versionado e transformado para domínio técnico sem perda de rastreabilidade |
| 36 | BOW-036 | Modelo canônico de avaliação | BL-001, BL-017 | Pendente | Crítica | Entidades de domínio para avaliação, imóvel, amostras, premissas e resultado técnico com versionamento |
| 37 | BOW-037 | Conectores de dados externos | BL-009, BL-022 | Pendente | Crítica | Integrações com fontes externas (mercado, geoespacial, socioeconômica e documental) com cache e auditoria |
| 38 | BOW-038 | Qualidade e confiabilidade dos dados | BL-021, BL-022 | Pendente | Alta | Score de qualidade por fonte, tratamento de lacunas e trilha de origem por dado utilizado |
| 39 | BOW-039 | Engine NBR 14653 (métodos) | BL-017, BL-021 | Pendente | Crítica | Implementação modular de métodos aplicáveis da NBR 14653 com premissas explícitas e logs de cálculo |
| 40 | BOW-040 | Serviço de memória de cálculo | BL-017, BL-022 | Pendente | Crítica | Cada resultado técnico reproduzível (input, versão da regra, output) com hash e trilha auditável |
| 41 | BOW-041 | Validação normativa automática | BL-012, BL-021 | Pendente | Alta | Checklist automático de conformidade técnica com alertas bloqueantes e não bloqueantes |
| 42 | BOW-042 | Composer de laudo técnico | BL-003, BL-004 | Pendente | Crítica | Geração automática de laudo completo (texto, tabelas, anexos e evidências) por template de tenant |
| 43 | BOW-043 | Workspace de revisão técnica | BL-033, BL-034 | Pendente | Alta | Engenheiro/arquiteto revisa, comenta, ajusta premissas e aprova/reprova antes da assinatura |
| 44 | BOW-044 | Assinatura digital (provedores pagos) | BL-031, BL-033 | Pendente | Alta | Integração com provedores privados de assinatura eletrônica com trilha de evidências e carimbo temporal |
| 45 | BOW-045 | Assinatura digital (provedores públicos) | BL-031, BL-033 | Pendente | Alta | Suporte a assinatura pública quando aplicável ao contexto jurídico e ao tenant |
| 46 | BOW-046 | Cofre de documentos assinados | BL-023, BL-026 | Pendente | Alta | Armazenamento imutável de laudos assinados, versão, cadeia de custódia e verificação de integridade |
| 47 | BOW-047 | Portal de gestão ponta a ponta | BL-029, BL-030, BL-033 | Pendente | Alta | Gestores acompanham throughput, SLA, qualidade técnica, pendências e gargalos por etapa |
| 48 | BOW-048 | MLOps/RuleOps do motor técnico | BL-019, BL-024 | Pendente | Média | Governança de versões de regras/modelos com aprovação, rollback e monitoramento de deriva |
| 49 | BOW-049 | API de ingestão da financeira (criação de processo) | BL-001, BL-004, BL-029 | Pendente | Crítica | Endpoint autenticado para receber payload externo com validação, idempotência e persistência canônica |
| 50 | BOW-050 | Serviço de normalização de payload externo | BL-001, BL-012 | Pendente | Crítica | Normaliza `inspectionType`, `resType`, endereço, cliente e datas para modelo interno consistente |
| 51 | BOW-051 | Painel de conciliação financeira x processo | BL-001, BL-009 | Pendente | Alta | Backoffice consulta/filtra divergências entre entrada externa, processo criado e status operacional |
| 52 | BOW-052 | Callback/status de retorno para financeira | BL-001, BL-009 | Pendente | Alta | Retorno padronizado e auditável com status do processo, protocolo e timestamps de processamento |
| 53 | BOW-053 | Orquestração web de estado de onboarding de permissões mobile | BL-056, BL-032, BL-031 | Em andamento | Crítica | Backoffice expõe/atualiza status de onboarding-permissões por usuário e força reentrada no app para tela de permissões quando cadastro é criado/ativado sem onboarding concluído |
| 54 | BOW-054 | Canonical Domain v1 (Demand/Case/Job/Inspection/Report) | BL-001, BL-012, BL-017 | Em andamento | Crítica | Modelo canônico publicado com glossário, regras de transição e mapeamento explícito de ACL para payload externo |
| 55 | BOW-055 | Governança de arquitetura por ADR | BL-020, BL-026 | Pendente | Alta | ADRs obrigatórios para decisões críticas (identidade, tenancy, contratos, storage, integração) com template e revisão em PR |
| 56 | BOW-056 | OpenAPI v1 com política formal de compatibilidade | BL-017, BL-021 | Pendente | Crítica | Contratos REST v1 publicados com regra de versionamento, depreciação e bloqueio de breaking change em CI |
| 57 | BOW-057 | Contratos de eventos v1 (fatos de negócio) | BL-017, BL-022 | Pendente | Crítica | Eventos versionados com tenant/correlationId e consumers idempotentes validados por testes de contrato |
| 58 | BOW-058 | Enforcement obrigatório de tenant + correlationId | BL-022, BL-031 | Pendente | Crítica | Toda request rejeitada sem contexto mínimo (tenantId/correlationId) e propagação ponta a ponta no backend |
| 59 | BOW-059 | Matriz de autorização backend-first (RBAC + policies) | BL-031, BL-033, BL-034 | Pendente | Crítica | Permissões por domínio consolidadas no backend com testes de autorização e proibição de regra sensível na UI |
| 60 | BOW-060 | Padrão de idempotência por operação crítica | BL-001, BL-002, BL-021 | Pendente | Crítica | Chaves idempotentes por caso de uso (ingestão, sync final, callback) com deduplicação observável e SLA definido |
| 61 | BOW-061 | Baseline de observabilidade e SLO técnico | BL-009, BL-022 | Pendente | Alta | Logs estruturados, traces distribuídos, métricas essenciais e alertas de SLA por contexto de negócio |
| 62 | BOW-062 | Estratégia de migração de dados e evolução de schema | BL-013, BL-020 | Pendente | Alta | Plano versionado de migrações e rollback sem lock-in de parceiro para os estágios de evolução da plataforma |
| 63 | BOW-063 | Hardening de build local (Docker context, cache e resiliência) | BL-023, BL-036 | Em andamento | Alta | Contextos reduzidos com `.dockerignore`, builds reproduzíveis e procedimento anti-EOF/SIGBUS documentado para ambiente limitado |
| 64 | BOW-064 | Estratégia de segredos com cofre (dev/stage/prod) | BL-023, BL-028 | Em andamento | Crítica | Segredos fora de arquivos versionados, injeção por cofre/variável de ambiente e trilha de rotação por ambiente |

---

## Matriz de APIs (contratos mínimos)

### APIs de identidade e tenancy (fundação)
1. `POST /api/mobile/auth/login`
2. `POST /api/mobile/auth/refresh`
3. `POST /api/mobile/auth/logout`
4. `GET /api/mobile/auth/me`
5. `GET /api/mobile/tenants`
6. `POST /api/mobile/auth/sso/start`
7. `GET /api/mobile/auth/sso/callback`

### APIs já esperadas pelo mobile (prioridade imediata)
1. `GET /api/mobile/checkin-config`
- Query: `tipoImovel` (opcional)
- Auth: Bearer token
- Retorno: estrutura de `step1` e `step2` com `camposFotos`/`gruposOpcoes`

2. `POST /api/mobile/inspections/finalized`
- Auth: Bearer token
- Payload: `exportedAt`, `job`, `step1`, `step2`, `step2Config`, `review`
- Requisito: idempotência por combinação de chave funcional (ex.: job + exportedAt + hash)
- Resposta: `protocolId`, `receivedAt`, `status`

### APIs de integração com origem financeira (upstream)
1. `POST /api/integrations/financial/processes`
- Auth: credencial de integração (service account + assinatura)
- Payload: dados de processo (tipo de vistoria, cliente, imóvel, agenda e metadados)
- Requisito: idempotência por chave de negócio (ex.: `number` + origem)
- Resposta: `success`, `message`, `process_id`, `process_number`, `data`

2. `GET /api/integrations/financial/processes/{processNumber}/status`
- Auth: credencial de integração
- Retorno: status atual, protocolo interno, timestamps e motivo em caso de falha

### APIs necessárias para retirar mocks e placeholders do mobile
1. `GET /api/mobile/jobs`
2. `GET /api/mobile/jobs/{id}`
3. `GET /api/mobile/agenda`
4. `GET /api/mobile/notifications`
5. `POST /api/mobile/notifications/device-token`
6. `GET /api/mobile/profile`
7. `PUT /api/mobile/profile`
8. `POST /api/mobile/profile/photo`
9. `POST /api/mobile/onboarding`
10. `GET /api/mobile/onboarding/status`

### APIs para ciclo técnico do laudo (web/backoffice)
1. `POST /api/backoffice/valuations/intake`
2. `GET /api/backoffice/valuations/{id}`
3. `POST /api/backoffice/valuations/{id}/external-data/refresh`
4. `POST /api/backoffice/valuations/{id}/calculate`
5. `GET /api/backoffice/valuations/{id}/calculation-memory`
6. `POST /api/backoffice/reports/{id}/compose`
7. `POST /api/backoffice/reports/{id}/review/approve`
8. `POST /api/backoffice/reports/{id}/review/reject`
9. `POST /api/backoffice/reports/{id}/sign/private-provider`
10. `POST /api/backoffice/reports/{id}/sign/public-provider`
11. `GET /api/backoffice/reports/{id}/signed-artifacts`
12. `GET /api/backoffice/management/pipeline-metrics`

---

## Configurações obrigatórias para operação mobile

### Variáveis de ambiente do app mobile
1. `APP_API_BASE_URL`
2. `APP_API_TOKEN` (enquanto não migrar para auth por usuário)
3. `APP_CHECKIN_CONFIG_ENDPOINT`
4. `APP_INSPECTION_SYNC_ENDPOINT`

### Configurações no backoffice/web
1. Gestão de token/chave de integração mobile
2. Versionamento de configuração de check-in com rollback
3. Política de idempotência para recebimento da vistoria
4. Catálogo de códigos de erro para UX consistente no app
5. Correlation id propagado API → logs → painel de suporte
6. Política de retenção e mascaramento de dados sensíveis
7. Configuração por tenant para white label (branding e políticas)
8. Escolha do provedor de identidade por tenant (interno/externo)
9. Mapeamento de grupos externos (AD) para papéis de domínio
10. Catálogo de provedores de dados externos por tenant (credenciais, SLA, custo)
11. Catálogo de provedores de assinatura digital por tenant (privado/público)
12. Política de retenção probatória para documentos assinados e memória de cálculo

---

## Estratégia de implementação do ciclo NBR 14653

### Etapa A — Fundamentos de domínio técnico
1. Definir modelo canônico de avaliação e taxonomia de dados técnicos.
2. Definir método(s) NBR 14653 alvo da primeira versão e fronteiras do motor de cálculo.
3. Definir critérios de qualidade de dados para cálculo automático confiável.

### Etapa B — Automação de dados e cálculo
1. Implementar conectores de dados externos com fila, cache e observabilidade.
2. Implementar engine de cálculo com memória reproduzível e versionamento de regra.
3. Implementar validação normativa automática antes da composição do laudo.

### Etapa C — Produção de laudo e assinatura
1. Implementar composer de laudo com templates white label por tenant.
2. Implementar workspace de revisão para engenheiro/arquiteto.
3. Implementar assinatura digital com múltiplos provedores (privados e públicos).

### Etapa D — Operação e governança executiva
1. Implementar portal de gestão ponta a ponta com SLA, fila e qualidade.
2. Implementar governança de regras/modelos (RuleOps/MLOps) com aprovação e rollback.

---

## Perfis de acesso e responsabilidades
1. Operação de Backoffice:
  - acompanha intake, pendências de dados, reprocessamento e publicação de documentos.
2. Engenheiro/Arquiteto Responsável Técnico:
  - revisa premissas, valida cálculos, aprova e assina o laudo.
3. Gestor Operacional/Executivo:
  - acompanha SLA, produtividade, qualidade técnica e risco operacional.
4. Administração de Plataforma:
  - gerencia tenants, branding, integrações externas e políticas de segurança.

---

## Modelo de login evolutivo (sem retrabalho)
1. Etapa atual: login interno com access token + refresh token e sessões revogáveis.
2. Etapa de transição: introduzir camada de Identity Provider Adapter (provider interno + provider externo).
3. Etapa corporativa: habilitar federação AD por OIDC/SAML por tenant sem alterar domínio de usuário e permissão.
4. Etapa enterprise: provisionamento automático e governança de ciclo de vida (entrada, mudança, desligamento).

---

## Modelo de domínio mínimo para IAM e white label
1. Tenant: representa a marca/cliente white label.
2. OrganizationUnit: estrutura interna da empresa/cliente.
3. User: identidade canônica da plataforma.
4. IdentityBinding: vínculo entre User e provedor de identidade (interno, Azure AD, ADFS, outros).
5. Membership: vínculo User x Tenant x OrganizationUnit.
6. Role: papel funcional de domínio.
7. Permission: capacidade granular.
8. Policy: regra contextual de autorização.
9. Session: sessão autenticada, revogável e auditável.

---

## Dependências e ordem de execução
1. Entregar BOW-001..BOW-006 e BOW-029..BOW-033 antes de abrir integrações críticas em produção.
2. Entregar BOW-008, BOW-009 e BOW-010 em conjunto para evitar contrato parcial.
3. Entregar BOW-011 junto com BOW-010 para garantir robustez da fila offline do mobile.
4. Entregar BOW-016..BOW-018 junto com BOW-017 para concluir ciclo de mensagens com push.
5. Entregar BOW-022..BOW-025 junto de BOW-034 para evitar onboarding sem governança de identidade.
6. Entregar BOW-035..BOW-042 antes da esteira de assinatura digital em produção.
7. Entregar BOW-043..BOW-046 para fechar o ciclo técnico-comprobatório do laudo.
8. Entregar BOW-047..BOW-048 para escala e governança contínua.

---

## Critérios de aceite transversais
1. Todo endpoint mobile-backend deve ter contrato OpenAPI versionado e teste de contrato em CI.
2. Toda operação crítica deve registrar correlation id e trilha de auditoria.
3. Todo dado sensível deve ter política de retenção, criptografia em trânsito e mascaramento em log.
4. Todo fluxo novo do backoffice deve ter feature flag por ambiente.
5. Toda entrega de integração deve validar cenário offline/retry do app mobile.

---

## Plano de execução sugerido (90 dias)

### Onda 1 (Semanas 1-3) — Base técnica e contratos
1. BOW-001, BOW-002, BOW-004, BOW-006.
2. Entregável: autenticação ativa, RBAC mínimo, padrão de erro, OpenAPI inicial publicada.

### Onda 2 (Semanas 4-6) — Integração mobile crítica
1. BOW-008, BOW-009, BOW-010, BOW-011.
2. Entregável: configuração dinâmica NBR no ar e ingestão idempotente de vistoria final.

### Onda 3 (Semanas 7-9) — Operação assistida
1. BOW-012, BOW-013, BOW-014, BOW-015, BOW-019.
2. Entregável: reconciliação de sync, painel de vistorias e observabilidade com contrato validado em CI.

### Onda 4 (Semanas 10-13) — Jornada de usuário e comunicação
1. BOW-016, BOW-017, BOW-018, BOW-020, BOW-021, BOW-022, BOW-023, BOW-024, BOW-025.
2. Entregável: agenda, mensagens com push, onboarding/aprovação e perfil completos.

---

## Definition of Ready por item
Antes de iniciar qualquer item BOW, validar:
1. Contrato OpenAPI do módulo existe e foi revisado.
2. Critérios de autenticação e autorização definidos.
3. Estratégia de observabilidade (eventos, métricas, correlation id) definida.
4. Casos de erro e códigos HTTP mapeados.
5. Cenário de compatibilidade com app mobile atual documentado.

---

## Sprint zero (próximas ações imediatas)
1. Definir bounded contexts e contratos de integração entre domínios (DDD).
2. Definir modelo multi-tenant com chave obrigatória de tenant em todos os agregados críticos.
3. Definir arquitetura de Identity Provider Adapter (interno + externo).
4. Publicar OpenAPI v1 com os dois endpoints críticos já consumidos pelo mobile:
  - `GET /api/mobile/checkin-config`
  - `POST /api/mobile/inspections/finalized`
5. Definir chave de idempotência da vistoria final (`job.id + exportedAt + checksum`).
6. Definir tabela de versionamento de configuração de check-in com rollback.
7. Definir política de token mobile temporário (transição para login por usuário).
8. Definir roadmap técnico de federação AD (OIDC/SAML) por tenant.
9. Definir dashboard mínimo de suporte:
  - fila de sync pendente,
  - erros por endpoint,
  - latência p95/p99,
  - total de vistorias recebidas por dia.
10. Definir escopo técnico da primeira entrega de laudo NBR 14653 (método, premissas e limites).
11. Definir matriz de provedores externos de dados (prioridade, fallback e custo).
12. Definir matriz de provedores de assinatura digital (privado/público) e estratégia de fallback.
13. Definir política de revisão obrigatória por profissional habilitado antes da assinatura final.

---

## Riscos principais e mitigação
1. Risco: quebrar contrato com app em produção ao alterar payload.
  - Mitigação: versionamento de contrato + contract test obrigatório em PR.
2. Risco: duplicidade de vistoria por retry offline.
  - Mitigação: idempotência por chave funcional + lock transacional.
3. Risco: falha de push por token inválido/desatualizado.
  - Mitigação: endpoint de refresh de token + invalidação automática por erro de provedor.
4. Risco: atraso por dependência cruzada mobile/backoffice.
  - Mitigação: congelar contrato por onda e liberar mudanças em feature flags.
5. Risco: acoplamento precoce ao AD inviabilizar cenários de outros clientes white label.
  - Mitigação: adotar provider agnóstico por adapter e federação configurável por tenant.
6. Risco: vazamento de dados entre tenants.
  - Mitigação: isolamento lógico obrigatório por tenant, testes automatizados de segregação e auditoria contínua.
7. Risco: inconsistência técnica por baixa qualidade de dados externos.
  - Mitigação: score de qualidade, imputação controlada, bloqueio automático para dados críticos ausentes.
8. Risco: questionamento jurídico/técnico do laudo gerado automaticamente.
  - Mitigação: memória de cálculo reproduzível, trilha de auditoria e revisão/assinatura humana obrigatória.
9. Risco: indisponibilidade de provedor de assinatura digital.
  - Mitigação: estratégia multi-provedor com fallback por tenant e fila de retentativa.
