> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Backlog de Desenvolvimento — Plataforma (Backend + Web Backoffice + Integração Mobile)

Atualizado em: 2026-04-03

> **Fonte canônica obrigatória antes de implementar qualquer item:**
> - Arquitetura corporativa: `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
> - Foundations e core: `docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
> - Modelo canônico corporativo: `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
> - Domain pack inspection: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`
> - Tenant e white-label: `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
> - Guardrails de engenharia: `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`
> - Decisões V2: `docs/06-analysis-design/01_DECISION_LOG_V2.md`
> - Portfólio e roadmap corporativo: `docs/02-product/01_PORTFOLIO_VIEW.md` e `docs/02-product/02_ROADMAP_CORPORATE_AND_DOMAINS.md`

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

---

## Estado atual do código (auditoria 2026-04-03)

### O que existe hoje

| Módulo | Arquivos | Alinhamento com modelo canônico |
|---|---|---|
| `api.config` | ConfigPackage*, ConfigAudit*, ConfigPolicy*, ConfigScope* | Parcial — tenant guard implementado, mas sem Tenant entity real |
| `api.contract` | CanonicalErrorResponse, ApiExceptionHandler, RequestContextValidator | OK — envelope canônico funcional |
| `api.mobile` | MobileApiController, CheckinConfigResponse, InspectionFinalizedRequest | OK — contratos v1 publicados |
| `api.user` | User, UserRole, UserSource, UserStatus, UserAuditEntry* | Incompleto — sem Tenant entity, sem Membership, sem IdentityBinding |
| `api.openapi` | OpenApiConfiguration, OpenApiUiRedirectController | OK |
| `api.storage` | StorageService, LocalStorageAdapter, R2StorageAdapter | OK |
| Web: backoffice/users | list, create, import, pending, audit pages | Parcial — sem tenant context real |
| Web: components | config_targeting_panel, operational_status_panel | OK |

### Dívidas críticas a endereçar antes de evoluir

1. **`User` entity sem `tenantId` como coluna de isolamento real** — toda query de usuário vaza entre tenants
2. **Ausência de `Tenant`, `OrganizationUnit`, `Membership`** — fundação do modelo IAM não existe no banco
3. **Auth via mock no mobile** — `AuthState` em `lib/state/auth_state.dart` sem backend real
4. **`ConfigPackage` sem vínculo com `Tenant` entity** — tenant guard por campo, não por FK

---

## Ondas de implementação

Derivadas de `docs/02-product/04_ROADMAP_EPICOS.md` e `docs/05-operations/02_PLANO_IMPLEMENTACAO_90_DIAS.md`.

### Onda 1 — Go live controlado com empresa âncora (0–90 dias)
Objetivo: plataforma funcionando em produção para 1 empresa de avaliação + 1 financeira.

### Onda 2 — Robustez operacional + observabilidade (90–180 dias)
Objetivo: orchestration, notifications, E2E observability, múltiplas financeiras.

### Onda 3 — White label multi-tenant (180–270 dias)
Objetivo: múltiplas empresas de avaliação operando de forma isolada.

### Onda 4 — Marketplace (270–365+ dias)
Objetivo: plataforma encontra empresa de avaliação e vistoriador por demanda.

---

## Onda 1 — Backlog detalhado

### Grupo A: Fundação de Identidade e Tenant (pré-requisito de tudo)

---

#### BOW-100 — Modelo de domínio IAM: Tenant, OrganizationUnit, Membership
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Em andamento (parcial backend entregue em 2026-04-03)  
**Bloqueia:** BOW-101, BOW-102, BOW-103, BOW-110, BOW-120, toda integração mobile real

**Bloco executavel (prioritario):**
- Camada: platform-core
- Dominio: cross-domain
- Area: identity/tenant foundation
- Objetivo: criar fundacao IAM multi-tenant com integridade referencial
- Arquivos provaveis: `apps/backend/src/main/java/**/tenant*`, `**/membership*`, migrations
- Dependencias: nenhuma anterior; base para BOW-101 e BOW-102
- Testes obrigatorios: integracao de isolamento por tenant + repositorios
- Evidencia esperada: entidades/migrations ativas e testes verdes
- Docs a atualizar: backlog web e backlog integracao se houver contrato impactado
- Criterio de pronto: tenant/membership com FK real e isolamento comprovado

**Andamento 2026-04-03:**
- Entregue no backend: entidades `Tenant`, `OrganizationUnit`, `Membership` + enums de status/role + repositories.
- Entregue: teste de integração `IdentityTenantMembershipIntegrationTest` validando isolamento por tenant.
- Pendente para concluir card: migrations Flyway (`V002` a `V006`) e FK real em `users`/`config_packages`.

**Contexto:**  
Todos os dados do sistema precisam estar isolados por tenant desde o início (ADR-002, ADR-005). Hoje o backend tem `tenantId` como campo string solto nas entidades. Isso não garante integridade referencial nem permite evoluir para white label real.

**O que construir:**  
Backend (`identity_db`) — entidades JPA com migrations Flyway:

```java
// Tenant: representa a empresa cliente da plataforma (Onda 3: múltiplos tenants)
@Entity @Table(name = "tenants")
class Tenant {
  UUID id;
  String slug;          // ex: "empresa-ancora"
  String displayName;
  String status;        // ACTIVE, SUSPENDED, ARCHIVED
  Instant createdAt;
}

// OrganizationUnit: unidade interna da empresa (regional, departamento)
@Entity @Table(name = "organization_units")
class OrganizationUnit {
  UUID id;
  UUID tenantId;        // FK → tenants.id
  UUID parentId;        // nullable, self-referential para hierarquia
  String name;
  String type;          // REGIONAL, DEPARTMENT, TEAM
}

// Membership: vínculo entre User × Tenant × OrganizationUnit × Role
@Entity @Table(name = "memberships")
class Membership {
  UUID id;
  UUID userId;          // FK → users.id
  UUID tenantId;        // FK → tenants.id
  UUID organizationUnitId; // nullable, FK → organization_units.id
  String role;          // PLATFORM_ADMIN, TENANT_ADMIN, COORDINATOR, OPERATOR, AUDITOR
  String status;        // ACTIVE, SUSPENDED, REVOKED
  Instant grantedAt;
  Instant revokedAt;    // nullable
}
```

**Migrations Flyway obrigatórias:**
- `V002__create_tenants.sql`
- `V003__create_organization_units.sql`
- `V004__create_memberships.sql`
- `V005__add_tenantid_fk_to_users.sql` (adicionar FK real na tabela `users`)
- `V006__add_tenantid_fk_to_config_packages.sql`

**Regras de negócio (referência V2: docs/06-analysis-design/01_DECISION_LOG_V2.md):**
- Todo job deve ter contexto de tenant e organização (Regra 2)
- Toda mudança crítica deve gerar trilha de auditoria (Regra 8)

**Critério de pronto:**
- Migrations aplicadas sem erro no schema `identity_db`
- `TenantRepository` com `findBySlug`, `findById`
- `MembershipRepository` com `findByUserIdAndTenantId`, `findByTenantId`
- Seed de tenant âncora para testes de integração
- Testes de integração cobrindo criação e isolamento básico

---

#### BOW-101 — Alinhamento de User entity ao modelo canônico
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** BOW-100 | **Bloqueia:** BOW-102, BOW-110, BL-031

**Bloco executavel (prioritario):**
- Camada: platform-core
- Dominio: cross-domain
- Area: user lifecycle e authorization context
- Objetivo: desacoplar identidade de autorizacao e garantir escopo tenant
- Arquivos provaveis: `apps/backend/src/main/java/**/user*`, `**/membership*`, migrations
- Dependencias: BOW-100
- Testes obrigatorios: regressao de endpoints user + isolamento tenant
- Evidencia esperada: leitura de role por membership e compatibilidade de contrato
- Docs a atualizar: backlog web e decisoes operacionais quando houver mudanca de fluxo
- Criterio de pronto: sem regressao de API e autoridade por membership estabilizada

**Andamento 2026-04-03 (completo):**
- ✅ Entregue: novo agregado `UserLifecycle` separado da entidade `User` para fluxo de onboarding/aprovação.
- ✅ Entregue: `UserService` atualizado para transicionar lifecycle em create/approve/reject sem quebrar endpoints atuais.
- ✅ Entregue: `UserResponse` com `lifecycleStatus` para observabilidade da transição durante migração.
- ✅ Entregue: teste de integração `UserLifecycleTransitionIntegrationTest` validando APPROVED/REJECTED no lifecycle.
- ✅ Entregue: `UserService` com dual-write em todas as mutações (create/import/approve/reject) com mapeamento `UserRole ↔ MembershipRole`.
- ✅ Entregue: leituras de usuário resolvendo role por `Membership` como fonte primária de autoridade.
- ✅ Entregue: backfill automático de `Membership` para usuários legados sem vínculo (role padrão: FIELD_OPERATOR).
- ✅ Entregue: campo `role` removido da persistência (`@Transient`); domínio de autorização delegado integralmente ao `Membership`.
- ✅ Entregue: Flyway introduzido como fonte única de verdade do schema — V001 (schema completo), V002 (FK `users.tenant_id → tenants.id`), V003 (DROP COLUMN role).
- ✅ Testes: 30 testes, 0 falhas, 0 erros após todas as entregas.

**Contexto:**  
`User.java` atual tem `tenantId` como `String` solto, sem FK real para `Tenant`. A entidade mistura responsabilidades de identidade (`email`, `password`) com vínculo organizacional (`role`, `status`). Segundo o modelo V2 (tenant/white-label + domain boundaries): identidade e contexto de acesso devem ficar desacoplados e com escopo de tenant explícito.

**O que revisar/refatorar em `User.java`:**
```java
// ANTES (problema): role e status de acesso dentro da entidade de identidade
// DEPOIS: User guarda apenas identidade; Membership guarda acesso/contexto
@Entity @Table(name = "users")
class User {
  UUID id;
  UUID tenantId;        // FK → tenants.id (adicionar via BOW-100/V005)
  String email;
  String externalId;    // null para provider interno, IdP sub claim para OIDC
  String source;        // WEB_CREATED, MOBILE_ONBOARDING, AD_IMPORT
  String identityStatus; // PENDING_VERIFICATION, ACTIVE, SUSPENDED, ARCHIVED
  Instant createdAt;
  Instant updatedAt;
  // REMOVER: role (migrar para Membership)
  // REMOVER: approvalStatus da User entity → usar UserLifecycle separado
}
```

**O que adicionar:**
- `UserLifecycle` entity: fluxo de onboarding/aprovação separado da identidade
- Migração dos dados existentes de `role`/`status` para `Membership`

**Testes a manter verde:**
- `UserManagementControllerTest` — validar que nenhum endpoint quebra
- Novo: `UserTenantIsolationTest` — queries de usuário scopadas por tenant

**Critério de pronto:**
- `User` sem campo `role` (migrado para `Membership`)
- FK `tenantId → tenants.id` aplicada no banco
- Todos os endpoints de usuário filtram por `X-Tenant-Id` via FK, não apenas por campo string
- Testes de regressão e isolamento passando

---

#### BOW-102 — Autenticação backend-first: JWT + sessão persistida
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído  
**Depende de:** BOW-100, BOW-101 | **Bloqueia:** BL-031, BOW-103, toda API mobile autenticada

**Contexto:**  
Hoje o app mobile usa `AuthState` mockado (`lib/state/auth_state.dart`). Qualquer uso real em campo requer autenticação real. Este item implementa o provider interno de identidade — a Etapa 1 do modelo evolutivo de login (ver seção "Modelo de login evolutivo" neste próprio documento).

**O que construir — Backend:**

```
POST /auth/login        → valida email+senha, emite access_token (15min) + refresh_token (7d)
POST /auth/refresh      → troca refresh_token por novo access_token
POST /auth/logout       → revoga refresh_token (persiste revogação em Redis)
GET  /auth/me           → retorna User + Membership ativa + permissions do tenant context
```

**Modelo de token:**
```json
// access_token JWT payload
{
  "sub": "user-uuid",
  "tid": "tenant-uuid",     // tenant context
  "oid": "org-unit-uuid",   // org unit context (nullable)
  "roles": ["OPERATOR"],
  "exp": 1234567890
}
```

**Persistência de sessão:**
- Tabela `sessions` (ou Redis): `id`, `userId`, `tenantId`, `refreshTokenHash`, `expiresAt`, `revokedAt`, `deviceInfo`
- Revogação armazenada em Redis com TTL = tempo restante do token

**Rate limiting / lockout:**
- Max 5 tentativas em 10min por email+IP → Redis counter com TTL
- Após 5 falhas: `423 Locked` com `retryAfterSeconds`
- Log de tentativa bloqueada como evento de auditoria

**O que construir — Mobile (`lib/state/auth_state.dart`):**
- Substituir mock por chamadas reais ao backend
- Persistir `access_token` + `refresh_token` em `flutter_secure_storage`
- Interceptor HTTP que renova token automaticamente antes do call principal

**Referências:**
- `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md` — governança de identidade e escopo por tenant
- `docs/06-analysis-design/01_DECISION_LOG_V2.md` — decisões de transição e governança arquitetural

**Critério de pronto:**
- Endpoints testados com `AuthIntegrationTest` (login, refresh, logout, me)
- Lockout testado: 6ª tentativa retorna 423
- Mobile autentica contra backend real em ambiente de dev
- `GET /auth/me` retorna tenant context correto

---

#### BOW-103 — IdP Adapter: abstração de provedor de identidade
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído  
**Depende de:** BOW-102 | **Bloqueia:** BOW-132 (AD/OIDC), BOW-133

**Contexto:**  
ADR-005 exige que a arquitetura seja ready para estágio 4 desde o stágio 1. Para IAM, isso significa que o provider de identidade deve ser plugável — hoje provider interno, amanhã Keycloak/OIDC/SAML, depois AD por tenant. O código de autenticação não pode estar acoplado ao mecanismo de verificação de senha.

**O que construir:**

```java
// Interface que isola o domínio do protocolo de autenticação
interface IdentityProvider {
  AuthenticationResult authenticate(AuthenticationRequest request);
  UserIdentity resolveIdentity(String providerToken, String tenantId);
  void revokeSession(String sessionId);
}

// Implementação interna (Onda 1)
class InternalIdentityProvider implements IdentityProvider { ... }

// Futuro — registrado por tenant no TenantIdentityConfig
// class OidcIdentityProvider implements IdentityProvider { ... }
// class SamlIdentityProvider implements IdentityProvider { ... }
```

**Tabela `identity_bindings`:**
```sql
-- vínculo entre User canônico e provedor de identidade
CREATE TABLE identity_bindings (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  provider_type VARCHAR(50) NOT NULL,  -- INTERNAL, OIDC, SAML, AD
  provider_sub  VARCHAR(255) NOT NULL, -- claim "sub" do IdP
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  created_at    TIMESTAMP NOT NULL,
  UNIQUE(provider_type, provider_sub, tenant_id)
);
```

**Critério de pronto:**
- Interface `IdentityProvider` documentada com contrato explícito
- `InternalIdentityProvider` implementada e testada
- `IdentityBinding` entry criada no login com provider interno
- Estrutura pronta para registrar segundo provider sem alterar domínio

---

#### BOW-104 — RBAC por escopo: platform × tenant × operacional × campo
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** BOW-100, BOW-102 | **Bloqueia:** qualquer endpoint sensível

**Contexto:**  
O RBAC atual é simplificado (`UserRole` enum no `User`). O modelo canônico exige escopo hierárquico: um usuário pode ser `PLATFORM_ADMIN` no contexto da plataforma e apenas `OPERATOR` em um tenant específico (via `Membership`).

**Papéis por escopo (derivados de `docs/02-product/01_PERSONAS_E_PAPEIS.md`):**

```
PLATFORM scope:
  PLATFORM_ADMIN    → gerencia tenants, parâmetros globais, integrações externas
  PLATFORM_SUPPORT  → trata incidentes, view-only cross-tenant
  PLATFORM_AUDITOR  → trilha completa, sem mutação

TENANT scope:
  TENANT_ADMIN      → gerencia usuários, políticas e configurações do seu tenant
  COORDINATOR       → organiza fila de jobs e acompanha execução
  DISPATCHER        → distribui jobs por prioridade/região
  INTAKE_ANALYST    → valida inspeções recebidas
  TECH_REVIEWER     → revisa e aprova avaliações
  TECH_SIGNER       → assina laudos (profissional habilitado)
  AUDITOR           → trilha do tenant, sem mutação

FIELD scope:
  FIELD_OPERATOR    → aceita e executa jobs via app mobile
  REGIONAL_COORD    → acompanha rede de campo
```

**O que construir:**
- `@RequiresTenantRole(roles = {TENANT_ADMIN, COORDINATOR})` — annotation custom
- `TenantSecurityContext` — extrai `tid` do JWT, carrega Membership, injeta no thread local
- Filter Spring Security que popula contexto antes de cada request
- Testes: operação com papel errado retorna `403 Forbidden`

**Critério de pronto:**
- Annotation `@RequiresTenantRole` funcional
- Filter injetando `TenantSecurityContext` a cada request
- Tabela de permissões documentada (qual papel pode fazer o quê)
- Endpoints de `config` e `user` protegidos com anotações corretas
- `403` para chamada com papel insuficiente validado em testes

---

#### BOW-105 — Policy engine: autorização contextual por domínio
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** BOW-104

**Contexto:**  
RBAC simples não é suficiente para regras como "vistoriador só visualiza seus próprios jobs" ou "dispatcher só aloca jobs do seu tenant+região". Precisamos de políticas contextuais — extensão do RBAC com predicados de domínio.

**O que construir:**

```java
interface DomainPolicy<T> {
  boolean isAllowed(String actorId, String tenantId, String action, T resource);
}

// Exemplo
class JobAccessPolicy implements DomainPolicy<Job> {
  boolean isAllowed(actorId, tenantId, action, job) {
    if (action.equals("VIEW") && role == FIELD_OPERATOR)
      return job.assignedTo().equals(actorId);          // vistoriador vê só seus jobs
    if (action.equals("DISPATCH") && role == DISPATCHER)
      return job.tenantId().equals(tenantId);           // dispatcher só no seu tenant
    // ...
  }
}
```

**Critério de pronto:**
- Interface `DomainPolicy` com pelo menos `JobAccessPolicy` e `UserAccessPolicy`
- Políticas registradas no Spring context
- Testes cobrindo cenário positivo e negativo por papel/recurso

---

### Grupo B: Integração Hub e Anti-Corruption Layer

---

#### BOW-110 — Integration Hub: anti-corruption layer para demanda externa
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** BOW-100 | **Bloqueia:** BL-001 (sync real), qualquer integração com financeira

**Contexto:**  
ADR-004: integração externa via ACL (anti-corruption layer). O payload da financeira não pode chegar diretamente no domínio canônico. Precisamos de um adaptador que normalize o contrato externo para as entidades canônicas `Demand → Case → Job`.

**Referência V2:** `docs/06-analysis-design/01_DECISION_LOG_V2.md` e `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`, evento `DemandCreated` como especialização de domínio.

**O que construir:**
```
POST /integration/demands   → recebe payload bruto da financeira, valida, normaliza, emite DemandCreated
GET  /integration/demands/{externalId}   → status de processamento pelo ID externo
POST /integration/webhooks/status        → recebe status updates da financeira
```

**Fluxo de normalização:**
```
Payload financeira
    ↓ IntegrationHubAdapter (validação de schema)
    ↓ DemandNormalizer (mapeamento → Demand canônica)
    ↓ DemandRepository.save() em integration_db
    ↓ Publica evento DemandCreated no RabbitMQ
    ↓ Job Lifecycle consume e cria Case + Job
```

**Regra de negócio:** "Toda demanda externa deve ser normalizada para o modelo canônico" (referência V2: `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`).

**Campos obrigatórios do payload canônico:**
```json
{
  "externalId": "FIN-12345",
  "tenantId": "tenant-uuid",
  "requestedBy": "financeira-slug",
  "propertyAddress": { "street": "...", "city": "...", "state": "...", "zipCode": "..." },
  "inspectionType": "RESIDENTIAL|COMMERCIAL|LAND",
  "requestedDeadline": "2026-05-01T00:00:00Z",
  "clientData": { "masked — somente campos necessários" }
}
```

**Critério de pronto:**
- `POST /integration/demands` valida schema e rejeita payload inválido com `400`
- Demand normalizada salva em `integration_db`
- Evento `DemandCreated` publicado no RabbitMQ (ou simulado em testes)
- `GET /integration/demands/{externalId}` retorna status
- Testes de contrato cobrindo payload válido, inválido e duplicado (idempotência)

---

#### BOW-111 — Contrato de erro canônico: expandir para todos os endpoints
**Onda:** 1 | **Prioridade:** 🟠 Alta | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** nada (extensão do que já existe)

**Contexto:**  
`CanonicalErrorResponse` existe e funciona nos endpoints mobile. Falta aplicar em todos os endpoints (`/auth/*`, `/users/*`, `/config/*`, `/integration/*`).

**O que fazer:**
- Mapear cada tipo de exceção de domínio para `CanonicalErrorResponse` com `code` semântico
- Adicionar ao catálogo: `AUTH_INVALID_CREDENTIALS`, `AUTH_ACCOUNT_LOCKED`, `TENANT_NOT_FOUND`, `DEMAND_ALREADY_EXISTS`, `JOB_NOT_ASSIGNABLE`
- Expandir `ApiExceptionHandler` para cobrir `AccessDeniedException` → `403` com código canônico

**Critério de pronto:**
- Todos os novos endpoints retornam `CanonicalErrorResponse` em cenários de erro
- Testes de contrato para pelo menos `auth` e `integration`

---

### Grupo C: Job Lifecycle — Ciclo canônico de demanda até execução

---

#### BOW-120 — Modelo de domínio: Case e Job
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Em andamento (backend integrado ao Integration Hub em 2026-04-03)  
**Depende de:** BOW-100 | **Bloqueia:** BOW-121, BOW-122, BOW-123, BL-001, BL-012

**Andamento 2026-04-03:**
- ✅ Entregue: migration `V007__job_domain.sql` com tabelas `demands`, `inspection_cases`, `jobs`, `assignments` e `job_timeline_entries`.
- ✅ Entregue: migration `V008__integration_demands_case_job_refs.sql` adicionando `case_id` e `job_id` em `integration_demands`.
- ✅ Entregue: migration `V009__inspection_submissions.sql` com persistência idempotente de submissões mobile vinculadas ao `Job`.
- ✅ Entregue: entidades JPA, repositories, `JobStateMachine`, `CaseService` e `JobService` com transições `ELIGIBLE_FOR_DISPATCH → OFFERED → ACCEPTED` e cancelamento para `CLOSED`.
- ✅ Entregue: APIs `POST /cases`, `GET /jobs`, `GET /jobs/{id}`, `GET /jobs/{id}/timeline`, `POST /jobs/{id}/assign`, `POST /jobs/{id}/accept`, `POST /jobs/{id}/cancel`.
- ✅ Entregue: Integration Hub agora cria `Case` e `Job` automaticamente ao receber `POST /api/integration/demands`, retornando `caseId` e `jobId` na resposta.
- ✅ Entregue: endpoint mobile `GET /api/mobile/jobs` retornando jobs reais por `X-Actor-Id` com isolamento por `tenantId`.
- ✅ Entregue: `POST /api/mobile/inspections/finalized` saiu do stub em memória e passou a persistir submissões idempotentes, gerar `protocolId` real e avançar o `Job` até `SUBMITTED`.
- ✅ Testes: `CaseJobDomainIntegrationTest` com 9 cenários verdes, `IntegrationDemandIntegrationTest` com 3 cenários verdes, `InspectionSubmissionIntegrationTest` com 2 cenários verdes e regressão contratual do `MobileApiController` preservada com 6 testes verdes.
- ⏳ Pendente para concluir o card: expor transições intermediárias de execução no contrato web/mobile, vincular `Inspection` como agregado explícito do domínio e fechar o painel web operacional sobre os novos dados reais.

**Contexto:**  
O domínio canônico define `Demand → Case → Job → Assignment → Inspection`. Hoje não existe nenhuma dessas entidades no backend. O `MobileApiController` usa DTOs sem persistência canônica. Este é o coração do sistema para Stage 1.

**Estados do Job** (ref V2: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`):
```
Created → EligibleForDispatch → Offered → Accepted → InExecution → FieldCompleted → Submitted → Closed
```

**O que construir em `job_db`:**
```java
Demand   { id, externalId, tenantId, source, normalizedPayload, status, createdAt }
Case     { id, demandId, tenantId, number, propertyAddress, inspectionType, deadline, status }
Job      { id, caseId, tenantId, orgUnitId, title, status, assignedTo (nullable), deadlineAt, createdAt }
Assignment { id, jobId, userId, tenantId, offeredAt, respondedAt, response (ACCEPTED|DECLINED) }
```

**APIs a publicar:**
```
GET  /jobs?tenantId=&status=&page=&size=    → lista paginada (web)
GET  /jobs/{id}                              → detalhe do job
GET  /jobs/{id}/timeline                     → histórico de estados
POST /cases                                  → criação manual de case/job
POST /jobs/{id}/assign                       → despacha job para vistoriador
POST /jobs/{id}/accept                       → vistoriador aceita
POST /jobs/{id}/cancel                       → cancelamento com motivo
```

**API mobile (substituir stub em `MobileApiController`):**
```
GET /api/mobile/jobs?userId=&status=        → jobs do vistoriador autenticado
```

**Regra:** "Todo job deve ter contexto de tenant e organização" (Regra 2).

**Critério de pronto:**
- Migrations criadas para `job_db` (separado de `identity_db` — ADR-002)
- Estado machine do Job implementado com transições validadas
- App mobile consegue listar seus jobs reais (não mock)
- Testes de integração: criação de case→job, assign, accept, timeline

---

#### BOW-121 — API de configuração dinâmica check-in (NBR)
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Em andamento (integração real v1 entregue em 2026-04-03)  
**Depende de:** BOW-120 (tenant context), BOW-100

**Andamento 2026-04-03:**
- ✅ Entregue: `GET /api/mobile/checkin-config` deixou o stub fixo e passou a resolver configuração efetiva real a partir de `ConfigPackage` ativo por tenant/usuário.
- ✅ Entregue: versionamento v1 por hash temporal (`cfg-<epoch>`) derivado do pacote ativo mais recente, preservando fallback `v1-default` quando não há pacote ativo.
- ✅ Entregue: adaptação retrocompatível do contrato atual com `photoPolicy`, `featureFlags` e `presentation` derivados das regras efetivas de `ConfigPackage`.
- ✅ Entregue: modelagem canônica NBR persistida no banco com migration `V010__checkin_sections.sql` e tabela `checkin_sections` (key, label, mandatory, photos min/max, desiredItems).
- ✅ Entregue: contrato mobile expandido com `publishedAt` e `sections[]` canônicas, mantendo retrocompatibilidade de `step1/step2`.
- ✅ Testes: `MobileCheckinConfigIntegrationTest` com 2 cenários verdes cobrindo pacote ativo e fallback sem pacote.
- ⏳ Pendente para concluir o card: expor gestão web operacional das `sections` (publicação/edição/rollback por tenant) e conectar consumo mobile fim-a-fim sem dependência de fallback default.

**Contexto:**  
O mobile já consome `GET /api/mobile/checkin-config` (ver `MobileApiController`). Hoje retorna stub. Este item conecta ao banco real com versionamento, rollback e filtro por tipo de imóvel.

**O que construir:**
```
GET /api/mobile/checkin-config?tipoImovel=RESIDENTIAL&version=current
```

**Response canônica:**
```json
{
  "version": "v3",
  "publishedAt": "2026-04-01T10:00:00Z",
  "sections": [
    {
      "key": "fachada",
      "label": "Fachada",
      "mandatory": true,
      "photos": { "min": 1, "max": 5 },
      "desiredItems": ["orientacao", "material"]
    }
  ]
}
```

**Relação com `ConfigPackage`:** O `ConfigPackageEntity` existente pode suportar isso ou criar modelo específico de `CheckinConfig` — avaliar durante implementação. Preservar compatibilidade com mobile atual.

**Critério de pronto:**
- Endpoint retorna config real do banco (não stub)
- Versionamento: mobile recebe versão e pode checar se mudou
- Rollback: admin pode reverter para versão anterior via web
- Mobile atualiza config apenas quando versão mudar (evitar re-download)

---

#### BOW-122 — API de recebimento de vistoria (idempotente)
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Em andamento (persistência idempotente entregue em 2026-04-03)  
**Depende de:** BOW-120, BOW-100

**Andamento 2026-04-03 (incremento adicional):**
- ✅ Entregue: migration `V011__inspections.sql` com agregado explícito `inspections` vinculado à submissão mobile e ao `job`.
- ✅ Entregue: `InspectionSubmissionService` passou a persistir `Inspection` explícita no recebimento e a responder status operacional `SUBMITTED`.
- ✅ Entregue: idempotência preservada em `inspection_submissions` e `inspections` por `(tenant_id, idempotency_key)`.
- ✅ Testes: `InspectionSubmissionIntegrationTest` atualizado e verde cobrindo persistência do agregado + reenvio idempotente.

**Contexto:**  
`POST /api/mobile/inspections/finalized` existe como stub. Precisa de persistência real, idempotência obrigatória e retorno de protocolo.

**Regra:** "Todo sync mobile deve ser idempotente" (ref V2: `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`).

**Fluxo UC-07:**
```
Mobile → POST /api/mobile/inspections/finalized
  → Valida X-Idempotency-Key
  → Se já processado: retorna 200 com mesmo protocolo (não reprocessa)
  → Se novo: persiste InspectionSubmission + Inspection em field_ops_db
  → Emite evento InspectionSubmitted
  → Retorna { "protocol": "INS-2026-00123", "status": "SUBMITTED" }
```

**Chave de idempotência:** `jobId + exportedAt + payloadChecksum` — derivada pelo mobile.

**Persistência em `field_ops_db`:**
```
Inspection { id, jobId, tenantId, vistoriadorId, idempotencyKey, status, submittedAt, payload (jsonb) }
```

**Critério de pronto:**
- Reenvio do mesmo payload retorna mesmo protocolo sem duplicar
- `InspectionSubmitted` event registrado
- Mobile recebe protocolo real e exibe ao usuário
- Testes: envio novo, reenvio idempotente, payload inválido

---

#### BOW-123 — Painel web de vistorias recebidas
**Onda:** 1 | **Prioridade:** 🟠 Alta | **Status:** ✅ Concluído (2026-04-03)  
**Depende de:** BOW-122

**O que construir (web `apps/web-backoffice`):**
- Rota `/backoffice/inspections` — lista com filtros: status, data, tenant, vistoriador
- Rota `/backoffice/inspections/[id]` — detalhe técnico completo com fotos e payload
- Indicadores: total recebido hoje, pendentes de intake, erros de sync

**Andamento 2026-04-03:**
- ✅ Entregue: backend `GET /api/backoffice/inspections` com filtros por `status`, janela (`from`/`to`) e `vistoriadorId`.
- ✅ Entregue: backend `GET /api/backoffice/inspections/{id}` com detalhe técnico do payload persistido.
- ✅ Entregue: rotas Next.js `/api/inspections` e `/api/inspections/[inspectionId]` como bridge para o backend.
- ✅ Entregue: página `apps/web-backoffice/app/backoffice/inspections/page.tsx` com indicadores, filtros, paginação inicial, listagem e painel de detalhe técnico do payload.
- ✅ Entregue: indicadores do painel conectados a métricas de backend (`receivedToday`, `pendingIntake`, `syncErrors`, `submitted`) na resposta de listagem.
- ✅ Entregue: entrada de navegação no dashboard inicial do backoffice.
- ✅ Testes backend focados: `InspectionBackofficeIntegrationTest`, `InspectionSubmissionIntegrationTest` e `MobileCheckinConfigIntegrationTest` verdes (6 testes).
- ✅ Validações web executadas: `npm --prefix apps/web-backoffice run lint` limpo; `npm --prefix apps/web-backoffice test` verde (16 testes).
- ⚠️ Observação operacional: após reinstalação limpa de dependências, foi necessário adicionar `get-tsconfig` como `devDependency` direta para estabilizar o runner `tsx` no Windows.
- ⏳ Pendente para concluir o card: confirmar deterministicamente o `next build` neste ambiente local (travando sem saída após o banner do Next.js).

**Critério de pronto:**
- Lista paginada funcional com dados reais
- Detalhe mostra payload completo da vistoria
- Filtros: status + data funcionando

---

### Grupo D: Field Operations — Mobile conectado ao backend real

---

#### BOW-130 — Configuração dinâmica de check-in conectada ao mobile
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Pendente  
**Depende de:** BOW-121, BL-012

**Contexto:**  
BL-012 já tem o fluxo de leitura no mobile: mock local → API → cache → fallback hardcoded. Este item conecta a API real e valida o ciclo completo end-to-end.

**O que validar/implementar:**
- Mobile recebe config real do `BOW-121`
- Fallback mock continua funcionando em modo dev
- Cache local atualiza apenas quando versão mudar
- Testes Maestro cobrindo: config carregada → checkin com obrigatoriedades NBR

**Critério de pronto:**
- Ciclo completo: admin publica config no web → mobile recebe → checkin aplica regras
- Rollback de config reflete no mobile na próxima sincronização

---

#### BOW-131 — Sync de vistoria conectado ao backend real
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Pendente  
**Depende de:** BOW-122, BL-001, BL-002

**Contexto:**  
BL-001 e BL-002 já têm fila offline e retry no mobile. Este item conecta ao `BOW-122` real e valida o ciclo completo, incluindo recebimento de protocolo.

**O que validar:**
- Fila offline drena automaticamente quando conexão volta
- Protocolo retornado exibido na tela de conclusão
- Retry não duplica (idempotência)
- Evento `InspectionSubmitted` gerado corretamente

---

### Grupo E: Valuation Core — Ciclo técnico da vistoria até o laudo

---

#### BOW-140 — Modelo canônico de avaliação e intake
**Onda:** 1 | **Prioridade:** 🔴 Crítica | **Status:** Pendente  
**Depende de:** BOW-122

**Contexto:**  
UC-10 ("Processar valuation") define que "Valuation só processa após intake válido" (Regra 5). O intake é a porta de entrada da vistoria no ciclo técnico.

**Estados do ValuationProcess** (ref V2: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`):
```
PendingIntake → IntakeValidated → Enriched → Processing → Completed → Approved
```

**O que construir em `valuation_db`:**
```
ValuationProcess { id, inspectionId, tenantId, status, method, assignedAnalystId, createdAt }
IntakeValidation  { id, valuationProcessId, validatedBy, issues (jsonb), validatedAt, result }
```

**API:**
```
POST /valuation/processes                           → cria processo a partir de inspection
GET  /valuation/processes/{id}                      → status detalhado
POST /valuation/processes/{id}/validate-intake      → analista valida intake
```

**Critério de pronto:**
- Processo criado automaticamente quando `InspectionSubmitted` é consumido
- Analista consegue validar/rejeitar intake via web
- Estado `IntakeValidated` emite evento para próxima fase

---

#### BOW-141 — Composer de laudo básico (estrutura mínima)
**Onda:** 1 | **Prioridade:** 🟠 Alta | **Status:** Pendente  
**Depende de:** BOW-140

**Contexto:**  
Estados do Report: `Draft → Generated → UnderReview → ReadyForSign → Signed → Published → Archived`.

**O que construir (MVP do laudo):**
- Template básico de laudo em HTML/JSON com campos do processo
- `POST /reports/{valuationProcessId}/generate` — gera rascunho
- `GET /reports/{id}` — retorna laudo atual
- Workspace web para revisor técnico anotar e aprovar
- "Laudo só pode ser publicado após sign-off" (Regra 6)

**Critério de pronto:**
- Rascunho gerado a partir do processo
- Revisor técnico consegue aprovar ou devolver no web
- Estado `ReadyForSign` atingível pelo fluxo

---

### Grupo F: Observabilidade e Contratos

---

#### BOW-150 — Correlation ID e OpenTelemetry básico
**Onda:** 1 | **Prioridade:** 🟠 Alta | **Status:** Pendente

**O que construir:**
- Propagação de `X-Correlation-Id` de entrada até logs, eventos e respostas de erro
- `traceId` disponível em todos os logs estruturados
- Health checks: `GET /actuator/health` com status de DB, Redis e RabbitMQ
- Métrica básica: contagem de requests por endpoint, latência p95

**Critério de pronto:**
- Qualquer request tem `correlationId` rastreável nos logs
- `actuator/health` reporta status dos componentes downstream

---

#### BOW-151 — Contract tests mobile-backend em CI
**Onda:** 1 | **Prioridade:** 🟠 Alta | **Status:** Pendente  
**Depende de:** BOW-121, BOW-122, BOW-102

**O que construir:**
- Testes de contrato para `GET /api/mobile/checkin-config`
- Testes de contrato para `POST /api/mobile/inspections/finalized`
- Testes de contrato para `GET /auth/me`
- Gate no CI que bloqueia PR se contrato quebrar (extensão do INT-025)

---

## Onda 2 — Backlog detalhado

### Grupo: Workforce & Dispatch

---

#### BOW-200 — Workforce: modelo de vistoriador elegível
**Onda:** 2 | **Prioridade:** 🟠 Alta | **Status:** Pendente  
**Depende de:** BOW-100, BOW-120

**Contexto:**  
Regra 4: "Um vistoriador só pode receber job se elegível." Elegibilidade inclui: ativo, com habilitação válida, cobertura geográfica e sem conflito de agenda.

**O que construir em `workforce_db`:**
```
WorkforceProfile  { userId, tenantId, regionCoverage (jsonb), qualifications (jsonb), status }
WorkforceAvailability { userId, date, availableSlots, bookedSlots }
```

**API:**
```
GET /workforce/available?region=&date=&inspectionType=  → lista elegíveis para dispatch
GET /workforce/{userId}/profile                          → perfil completo do vistoriador
```

---

#### BOW-201 — Dispatch: oferta e aceite de job
**Onda:** 2 | **Prioridade:** 🟠 Alta | **Status:** Pendente  
**Depende de:** BOW-200, BOW-120

**Contexto:**  
UC-03: "Distribuir job". Dispatcher seleciona vistoriador elegível, oferta job, vistoriador aceita ou recusa via mobile.

**O que construir:**
- Lógica de dispatch: seleção por region/qualificação/disponibilidade
- Evento `JobAssigned` → notificação push para vistoriador
- Mobile: tela de propostas com aceite por deslize (BL-042 já tem UI mock)
- `POST /jobs/{id}/offer` — oferta para vistoriador específico
- Timeout de resposta: se não aceitar em X horas, re-oferta

---

#### BOW-202 — Notification Service: push + email básico
**Onda:** 2 | **Prioridade:** 🟠 Alta | **Status:** Pendente

**O que construir:**
- Registro de device token FCM no backend ao autenticar
- Envio de push: `JobOffered`, `JobDeadlineApproaching`, `InspectionFeedback`
- Envio de email: confirmação de cadastro, aprovação, rejeição
- Fila RabbitMQ para eventos de notificação com retry

---

#### BOW-203 — Process Orchestration: SLA e retries
**Onda:** 2 | **Prioridade:** 🟠 Alta | **Status:** Pendente

**O que construir:**
- SLA tracking por job: alerta quando deadline < 24h e job ainda não iniciado
- Retry de eventos falhos na mensageria (dead letter queue)
- Reprocessamento manual de inspeções com erro de intake
- Dashboard operacional de SLA no web

---

### Grupo: Observabilidade Ampliada

---

#### BOW-210 — Telemetria de fluxo mobile (BL-009)
**Onda:** 2 | **Prioridade:** 🟠 Alta | **Status:** Pendente

**O que construir:**
- Endpoint `POST /telemetry/events` recebendo eventos operacionais do mobile
- Eventos: `inspection_started`, `inspection_resumed`, `inspection_completed`, `sync_failed`, `sync_retried`
- Dashboard web: taxa de sucesso de sync, retentativas, tempo médio de execução

---

#### BOW-211 — Onboarding CLT/PJ e aprovação de cadastro (web)
**Onda:** 2 | **Prioridade:** 🔴 Crítica | **Status:** Pendente  
**Depende de:** BOW-100, BOW-101, BOW-102

**Contexto:**  
BL-032 e BL-033 têm o fluxo mobile. Este item fecha o ciclo com o backoffice web gerenciando aprovação.

**O que construir:**
- `UserLifecycle` entity: `PENDING_ONBOARDING → PENDING_APPROVAL → APPROVED → REJECTED`
- Web: fila de aprovação com documento, dados bancários PJ, validação de CNPJ
- Notificação automática ao aprovar/rejeitar
- Mobile: estado `aguardando aprovação` conectado ao backend real

---

## Onda 3 — Backlog resumido (planejamento)

#### BOW-300 — Multi-tenant real: isolamento de dados por schema ou row-level security
**Onda:** 3 | **Status:** Planejado  
Ativar segundo tenant real na plataforma. Cada tenant com branding, usuários, configurações e dados isolados. Validar que nenhuma query retorna dados cross-tenant.

#### BOW-301 — White label de marca e comportamento
**Onda:** 3 | **Status:** Planejado  
Branding por tenant: logo, cores, domínios, templates de laudo, textos. Web e mobile refletem marca do tenant autenticado.

#### BOW-302 — Federação com Active Directory (OIDC/SAML por tenant)
**Onda:** 3 | **Status:** Planejado  
Depende de BOW-103. Habilitar OIDC/SAML por tenant sem refatorar domínio. Mapeamento de grupos AD para papéis canônicos.

#### BOW-303 — Tenant management panel (platform admin)
**Onda:** 3 | **Status:** Planejado  
Interface para `PLATFORM_ADMIN` criar/configurar/suspender tenants. Branding, políticas, integrações e usuários por tenant.

---

## Onda 4 — Backlog resumido (visão)

#### BOW-400 — Provider Network: rede de empresas de avaliação
**Onda:** 4 | **Status:** Visão  
Múltiplas empresas de avaliação cadastradas como providers. Plataforma distribui demanda entre elas.

#### BOW-401 — Matching automatizado demanda × empresa × vistoriador
**Onda:** 4 | **Status:** Visão  
Algoritmo de matching por especialidade, SLA histórico, cobertura regional e disponibilidade.

#### BOW-402 — Pricing & Settlement multi-partes
**Onda:** 4 | **Status:** Visão  
Regra 7: "Settlement só pode ser calculado após resultado final." Fee da plataforma, repasse à empresa de avaliação, repasse ao vistoriador. Liquidação multi-partes com trilha completa.

#### BOW-403 — Intelligence: control tower e scoring
**Onda:** 4 | **Status:** Visão  
KPIs por tenant/região/vistoriador. Score de qualidade. Control tower para gestão executiva do ecossistema.

---


## ADENDO 2026-04-04 - Reconciliacao por Evidencia de Codigo

- Este backlog foi reconciliado com evidencias reais em `apps/backend` e `apps/web-backoffice`.
- Onda 2 possui avancos parciais tecnicos (dispatch e onboarding/aprovacao web) e deve ser tratada como trilha em andamento parcial.
- Onda 3 possui fundacao parcial (tenant/membership e targeting/rollout por tenant), ainda sem fechamento de isolamento forte e tenant management completo.
- Onda 4 permanece como visao estrategica sem implementacao estrutural fechada no codigo ativo.




## ADENDO 2026-04-08 - Agrupamento operacional em 2 macro-pacotes

### Macro-pacote A - Go-Live Core Web-Mobile
Itens deste backlog incluidos no caminho critico:
1. BOW-121
2. BOW-122
3. BOW-130
4. BOW-131
5. BOW-150
6. BOW-151

Papel do pacote:
1. fechar a API real de configuracao dinamica e sync mobile;
2. consolidar rollback, protocolo, contrato e observabilidade minima;
3. retirar dependencia estrutural de fallback como caminho principal de operacao.

### Macro-pacote B - Backoffice Operational Closure
Itens deste backlog incluidos no fechamento operacional posterior:
1. BOW-100
2. BOW-120
3. BOW-140
4. BOW-141

Papel do pacote:
1. estabilizar o backbone tenant/case/job;
2. fechar o ciclo tecnico de intake e laudo no dominio inspection;
3. sustentar a operacao humana do backoffice apos o fluxo core estar estavel.

### Regra de sequenciamento
1. Nao promover Onda 2 como prioridade principal antes de concluir o Macro-pacote A.
2. O Macro-pacote B deve iniciar com BOW-100/BOW-120 estabilizados antes de expandir intake/laudo.