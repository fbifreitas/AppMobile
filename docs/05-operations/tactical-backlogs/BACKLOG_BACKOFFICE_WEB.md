> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Backlog de Desenvolvimento â€” Plataforma (Backend + Web Backoffice + IntegraÃ§Ã£o Mobile)

Atualizado em: 2026-04-08

> **Fonte canÃ´nica obrigatÃ³ria antes de implementar qualquer item:**
> - Arquitetura corporativa: `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
> - Foundations e core: `docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
> - Modelo canÃ´nico corporativo: `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
> - Domain pack inspection: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`
> - Tenant e white-label: `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
> - Guardrails de engenharia: `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`
> - DecisÃµes V2: `docs/06-analysis-design/01_DECISION_LOG_V2.md`
> - PortfÃ³lio e roadmap corporativo: `docs/02-product/01_PORTFOLIO_VIEW.md` e `docs/02-product/02_ROADMAP_CORPORATE_AND_DOMAINS.md`

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

## Estado atual do cÃ³digo (auditoria 2026-04-03)

### O que existe hoje

| MÃ³dulo | Arquivos | Alinhamento com modelo canÃ´nico |
|---|---|---|
| `api.config` | ConfigPackage*, ConfigAudit*, ConfigPolicy*, ConfigScope* | Parcial â€” tenant guard implementado, mas sem Tenant entity real |
| `api.contract` | CanonicalErrorResponse, ApiExceptionHandler, RequestContextValidator | OK â€” envelope canÃ´nico funcional |
| `api.mobile` | MobileApiController, CheckinConfigResponse, InspectionFinalizedRequest | OK â€” contratos v1 publicados |
| `api.user` | User, UserRole, UserSource, UserStatus, UserAuditEntry* | Incompleto â€” sem Tenant entity, sem Membership, sem IdentityBinding |
| `api.openapi` | OpenApiConfiguration, OpenApiUiRedirectController | OK |
| `api.storage` | StorageService, LocalStorageAdapter, R2StorageAdapter | OK |
| Web: backoffice/users | list, create, import, pending, audit pages | Parcial â€” sem tenant context real |
| Web: components | config_targeting_panel, operational_status_panel | OK |

### DÃ­vidas crÃ­ticas a endereÃ§ar antes de evoluir

1. **`User` entity sem `tenantId` como coluna de isolamento real** â€” toda query de usuÃ¡rio vaza entre tenants
2. **AusÃªncia de `Tenant`, `OrganizationUnit`, `Membership`** â€” fundaÃ§Ã£o do modelo IAM nÃ£o existe no banco
3. **Auth via mock no mobile** â€” `AuthState` em `lib/state/auth_state.dart` sem backend real
4. **`ConfigPackage` sem vÃ­nculo com `Tenant` entity** â€” tenant guard por campo, nÃ£o por FK

---

## Ondas de implementaÃ§Ã£o

Derivadas de `docs/02-product/04_ROADMAP_EPICOS.md` e `docs/05-operations/02_PLANO_IMPLEMENTACAO_90_DIAS.md`.

### Onda 1 â€” Go live controlado com empresa Ã¢ncora (0â€“90 dias)
Objetivo: plataforma funcionando em produÃ§Ã£o para 1 empresa de avaliaÃ§Ã£o + 1 financeira.

### Onda 2 â€” Robustez operacional + observabilidade (90â€“180 dias)
Objetivo: orchestration, notifications, E2E observability, mÃºltiplas financeiras.

### Onda 3 â€” White label multi-tenant (180â€“270 dias)
Objetivo: mÃºltiplas empresas de avaliaÃ§Ã£o operando de forma isolada.

### Onda 4 â€” Marketplace (270â€“365+ dias)
Objetivo: plataforma encontra empresa de avaliaÃ§Ã£o e vistoriador por demanda.

---

## Onda 1 â€” Backlog detalhado

### Grupo A: FundaÃ§Ã£o de Identidade e Tenant (prÃ©-requisito de tudo)

---

#### BOW-100 â€” Modelo de domÃ­nio IAM: Tenant, OrganizationUnit, Membership
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Em andamento (parcial backend entregue em 2026-04-03)  
**Bloqueia:** BOW-101, BOW-102, BOW-103, BOW-110, BOW-120, toda integraÃ§Ã£o mobile real

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
- Entregue: teste de integraÃ§Ã£o `IdentityTenantMembershipIntegrationTest` validando isolamento por tenant.
- Pendente para concluir card: migrations Flyway (`V002` a `V006`) e FK real em `users`/`config_packages`.

**Contexto:**  
Todos os dados do sistema precisam estar isolados por tenant desde o inÃ­cio (ADR-002, ADR-005). Hoje o backend tem `tenantId` como campo string solto nas entidades. Isso nÃ£o garante integridade referencial nem permite evoluir para white label real.

**O que construir:**  
Backend (`identity_db`) â€” entidades JPA com migrations Flyway:

```java
// Tenant: representa a empresa cliente da plataforma (Onda 3: mÃºltiplos tenants)
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
  UUID tenantId;        // FK â†’ tenants.id
  UUID parentId;        // nullable, self-referential para hierarquia
  String name;
  String type;          // REGIONAL, DEPARTMENT, TEAM
}

// Membership: vÃ­nculo entre User Ã— Tenant Ã— OrganizationUnit Ã— Role
@Entity @Table(name = "memberships")
class Membership {
  UUID id;
  UUID userId;          // FK â†’ users.id
  UUID tenantId;        // FK â†’ tenants.id
  UUID organizationUnitId; // nullable, FK â†’ organization_units.id
  String role;          // PLATFORM_ADMIN, TENANT_ADMIN, COORDINATOR, OPERATOR, AUDITOR
  String status;        // ACTIVE, SUSPENDED, REVOKED
  Instant grantedAt;
  Instant revokedAt;    // nullable
}
```

**Migrations Flyway obrigatÃ³rias:**
- `V002__create_tenants.sql`
- `V003__create_organization_units.sql`
- `V004__create_memberships.sql`
- `V005__add_tenantid_fk_to_users.sql` (adicionar FK real na tabela `users`)
- `V006__add_tenantid_fk_to_config_packages.sql`

**Regras de negÃ³cio (referÃªncia V2: docs/06-analysis-design/01_DECISION_LOG_V2.md):**
- Todo job deve ter contexto de tenant e organizaÃ§Ã£o (Regra 2)
- Toda mudanÃ§a crÃ­tica deve gerar trilha de auditoria (Regra 8)

**CritÃ©rio de pronto:**
- Migrations aplicadas sem erro no schema `identity_db`
- `TenantRepository` com `findBySlug`, `findById`
- `MembershipRepository` com `findByUserIdAndTenantId`, `findByTenantId`
- Seed de tenant Ã¢ncora para testes de integraÃ§Ã£o
- Testes de integraÃ§Ã£o cobrindo criaÃ§Ã£o e isolamento bÃ¡sico

---

#### BOW-101 â€” Alinhamento de User entity ao modelo canÃ´nico
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do (2026-04-03)  
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
- âœ… Entregue: novo agregado `UserLifecycle` separado da entidade `User` para fluxo de onboarding/aprovaÃ§Ã£o.
- âœ… Entregue: `UserService` atualizado para transicionar lifecycle em create/approve/reject sem quebrar endpoints atuais.
- âœ… Entregue: `UserResponse` com `lifecycleStatus` para observabilidade da transiÃ§Ã£o durante migraÃ§Ã£o.
- âœ… Entregue: teste de integraÃ§Ã£o `UserLifecycleTransitionIntegrationTest` validando APPROVED/REJECTED no lifecycle.
- âœ… Entregue: `UserService` com dual-write em todas as mutaÃ§Ãµes (create/import/approve/reject) com mapeamento `UserRole â†” MembershipRole`.
- âœ… Entregue: leituras de usuÃ¡rio resolvendo role por `Membership` como fonte primÃ¡ria de autoridade.
- âœ… Entregue: backfill automÃ¡tico de `Membership` para usuÃ¡rios legados sem vÃ­nculo (role padrÃ£o: FIELD_OPERATOR).
- âœ… Entregue: campo `role` removido da persistÃªncia (`@Transient`); domÃ­nio de autorizaÃ§Ã£o delegado integralmente ao `Membership`.
- âœ… Entregue: Flyway introduzido como fonte Ãºnica de verdade do schema â€” V001 (schema completo), V002 (FK `users.tenant_id â†’ tenants.id`), V003 (DROP COLUMN role).
- âœ… Testes: 30 testes, 0 falhas, 0 erros apÃ³s todas as entregas.

**Contexto:**  
`User.java` atual tem `tenantId` como `String` solto, sem FK real para `Tenant`. A entidade mistura responsabilidades de identidade (`email`, `password`) com vÃ­nculo organizacional (`role`, `status`). Segundo o modelo V2 (tenant/white-label + domain boundaries): identidade e contexto de acesso devem ficar desacoplados e com escopo de tenant explÃ­cito.

**O que revisar/refatorar em `User.java`:**
```java
// ANTES (problema): role e status de acesso dentro da entidade de identidade
// DEPOIS: User guarda apenas identidade; Membership guarda acesso/contexto
@Entity @Table(name = "users")
class User {
  UUID id;
  UUID tenantId;        // FK â†’ tenants.id (adicionar via BOW-100/V005)
  String email;
  String externalId;    // null para provider interno, IdP sub claim para OIDC
  String source;        // WEB_CREATED, MOBILE_ONBOARDING, AD_IMPORT
  String identityStatus; // PENDING_VERIFICATION, ACTIVE, SUSPENDED, ARCHIVED
  Instant createdAt;
  Instant updatedAt;
  // REMOVER: role (migrar para Membership)
  // REMOVER: approvalStatus da User entity â†’ usar UserLifecycle separado
}
```

**O que adicionar:**
- `UserLifecycle` entity: fluxo de onboarding/aprovaÃ§Ã£o separado da identidade
- MigraÃ§Ã£o dos dados existentes de `role`/`status` para `Membership`

**Testes a manter verde:**
- `UserManagementControllerTest` â€” validar que nenhum endpoint quebra
- Novo: `UserTenantIsolationTest` â€” queries de usuÃ¡rio scopadas por tenant

**CritÃ©rio de pronto:**
- `User` sem campo `role` (migrado para `Membership`)
- FK `tenantId â†’ tenants.id` aplicada no banco
- Todos os endpoints de usuÃ¡rio filtram por `X-Tenant-Id` via FK, nÃ£o apenas por campo string
- Testes de regressÃ£o e isolamento passando

---

#### BOW-102 â€” AutenticaÃ§Ã£o backend-first: JWT + sessÃ£o persistida
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do  
**Depende de:** BOW-100, BOW-101 | **Bloqueia:** BL-031, BOW-103, toda API mobile autenticada

**Contexto:**  
Hoje o app mobile usa `AuthState` mockado (`lib/state/auth_state.dart`). Qualquer uso real em campo requer autenticaÃ§Ã£o real. Este item implementa o provider interno de identidade â€” a Etapa 1 do modelo evolutivo de login (ver seÃ§Ã£o "Modelo de login evolutivo" neste prÃ³prio documento).

**O que construir â€” Backend:**

```
POST /auth/login        â†’ valida email+senha, emite access_token (15min) + refresh_token (7d)
POST /auth/refresh      â†’ troca refresh_token por novo access_token
POST /auth/logout       â†’ revoga refresh_token (persiste revogaÃ§Ã£o em Redis)
GET  /auth/me           â†’ retorna User + Membership ativa + permissions do tenant context
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

**PersistÃªncia de sessÃ£o:**
- Tabela `sessions` (ou Redis): `id`, `userId`, `tenantId`, `refreshTokenHash`, `expiresAt`, `revokedAt`, `deviceInfo`
- RevogaÃ§Ã£o armazenada em Redis com TTL = tempo restante do token

**Rate limiting / lockout:**
- Max 5 tentativas em 10min por email+IP â†’ Redis counter com TTL
- ApÃ³s 5 falhas: `423 Locked` com `retryAfterSeconds`
- Log de tentativa bloqueada como evento de auditoria

**O que construir â€” Mobile (`lib/state/auth_state.dart`):**
- Substituir mock por chamadas reais ao backend
- Persistir `access_token` + `refresh_token` em `flutter_secure_storage`
- Interceptor HTTP que renova token automaticamente antes do call principal

**ReferÃªncias:**
- `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md` â€” governanÃ§a de identidade e escopo por tenant
- `docs/06-analysis-design/01_DECISION_LOG_V2.md` â€” decisÃµes de transiÃ§Ã£o e governanÃ§a arquitetural

**CritÃ©rio de pronto:**
- Endpoints testados com `AuthIntegrationTest` (login, refresh, logout, me)
- Lockout testado: 6Âª tentativa retorna 423
- Mobile autentica contra backend real em ambiente de dev
- `GET /auth/me` retorna tenant context correto

---

#### BOW-103 â€” IdP Adapter: abstraÃ§Ã£o de provedor de identidade
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do  
**Depende de:** BOW-102 | **Bloqueia:** BOW-132 (AD/OIDC), BOW-133

**Contexto:**  
ADR-005 exige que a arquitetura seja ready para estÃ¡gio 4 desde o stÃ¡gio 1. Para IAM, isso significa que o provider de identidade deve ser plugÃ¡vel â€” hoje provider interno, amanhÃ£ Keycloak/OIDC/SAML, depois AD por tenant. O cÃ³digo de autenticaÃ§Ã£o nÃ£o pode estar acoplado ao mecanismo de verificaÃ§Ã£o de senha.

**O que construir:**

```java
// Interface que isola o domÃ­nio do protocolo de autenticaÃ§Ã£o
interface IdentityProvider {
  AuthenticationResult authenticate(AuthenticationRequest request);
  UserIdentity resolveIdentity(String providerToken, String tenantId);
  void revokeSession(String sessionId);
}

// ImplementaÃ§Ã£o interna (Onda 1)
class InternalIdentityProvider implements IdentityProvider { ... }

// Futuro â€” registrado por tenant no TenantIdentityConfig
// class OidcIdentityProvider implements IdentityProvider { ... }
// class SamlIdentityProvider implements IdentityProvider { ... }
```

**Tabela `identity_bindings`:**
```sql
-- vÃ­nculo entre User canÃ´nico e provedor de identidade
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

**CritÃ©rio de pronto:**
- Interface `IdentityProvider` documentada com contrato explÃ­cito
- `InternalIdentityProvider` implementada e testada
- `IdentityBinding` entry criada no login com provider interno
- Estrutura pronta para registrar segundo provider sem alterar domÃ­nio

---

#### BOW-104 â€” RBAC por escopo: platform Ã— tenant Ã— operacional Ã— campo
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do (2026-04-03)  
**Depende de:** BOW-100, BOW-102 | **Bloqueia:** qualquer endpoint sensÃ­vel

**Contexto:**  
O RBAC atual Ã© simplificado (`UserRole` enum no `User`). O modelo canÃ´nico exige escopo hierÃ¡rquico: um usuÃ¡rio pode ser `PLATFORM_ADMIN` no contexto da plataforma e apenas `OPERATOR` em um tenant especÃ­fico (via `Membership`).

**PapÃ©is por escopo (derivados de `docs/02-product/01_PERSONAS_E_PAPEIS.md`):**

```
PLATFORM scope:
  PLATFORM_ADMIN    â†’ gerencia tenants, parÃ¢metros globais, integraÃ§Ãµes externas
  PLATFORM_SUPPORT  â†’ trata incidentes, view-only cross-tenant
  PLATFORM_AUDITOR  â†’ trilha completa, sem mutaÃ§Ã£o

TENANT scope:
  TENANT_ADMIN      â†’ gerencia usuÃ¡rios, polÃ­ticas e configuraÃ§Ãµes do seu tenant
  COORDINATOR       â†’ organiza fila de jobs e acompanha execuÃ§Ã£o
  DISPATCHER        â†’ distribui jobs por prioridade/regiÃ£o
  INTAKE_ANALYST    â†’ valida inspeÃ§Ãµes recebidas
  TECH_REVIEWER     â†’ revisa e aprova avaliaÃ§Ãµes
  TECH_SIGNER       â†’ assina laudos (profissional habilitado)
  AUDITOR           â†’ trilha do tenant, sem mutaÃ§Ã£o

FIELD scope:
  FIELD_OPERATOR    â†’ aceita e executa jobs via app mobile
  REGIONAL_COORD    â†’ acompanha rede de campo
```

**O que construir:**
- `@RequiresTenantRole(roles = {TENANT_ADMIN, COORDINATOR})` â€” annotation custom
- `TenantSecurityContext` â€” extrai `tid` do JWT, carrega Membership, injeta no thread local
- Filter Spring Security que popula contexto antes de cada request
- Testes: operaÃ§Ã£o com papel errado retorna `403 Forbidden`

**CritÃ©rio de pronto:**
- Annotation `@RequiresTenantRole` funcional
- Filter injetando `TenantSecurityContext` a cada request
- Tabela de permissÃµes documentada (qual papel pode fazer o quÃª)
- Endpoints de `config` e `user` protegidos com anotaÃ§Ãµes corretas
- `403` para chamada com papel insuficiente validado em testes

---

#### BOW-105 â€” Policy engine: autorizaÃ§Ã£o contextual por domÃ­nio
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do (2026-04-03)  
**Depende de:** BOW-104

**Contexto:**  
RBAC simples nÃ£o Ã© suficiente para regras como "vistoriador sÃ³ visualiza seus prÃ³prios jobs" ou "dispatcher sÃ³ aloca jobs do seu tenant+regiÃ£o". Precisamos de polÃ­ticas contextuais â€” extensÃ£o do RBAC com predicados de domÃ­nio.

**O que construir:**

```java
interface DomainPolicy<T> {
  boolean isAllowed(String actorId, String tenantId, String action, T resource);
}

// Exemplo
class JobAccessPolicy implements DomainPolicy<Job> {
  boolean isAllowed(actorId, tenantId, action, job) {
    if (action.equals("VIEW") && role == FIELD_OPERATOR)
      return job.assignedTo().equals(actorId);          // vistoriador vÃª sÃ³ seus jobs
    if (action.equals("DISPATCH") && role == DISPATCHER)
      return job.tenantId().equals(tenantId);           // dispatcher sÃ³ no seu tenant
    // ...
  }
}
```

**CritÃ©rio de pronto:**
- Interface `DomainPolicy` com pelo menos `JobAccessPolicy` e `UserAccessPolicy`
- PolÃ­ticas registradas no Spring context
- Testes cobrindo cenÃ¡rio positivo e negativo por papel/recurso

---

### Grupo B: IntegraÃ§Ã£o Hub e Anti-Corruption Layer

---

#### BOW-110 â€” Integration Hub: anti-corruption layer para demanda externa
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** âœ… ConcluÃ­do (2026-04-03)  
**Depende de:** BOW-100 | **Bloqueia:** BL-001 (sync real), qualquer integraÃ§Ã£o com financeira

**Contexto:**  
ADR-004: integraÃ§Ã£o externa via ACL (anti-corruption layer). O payload da financeira nÃ£o pode chegar diretamente no domÃ­nio canÃ´nico. Precisamos de um adaptador que normalize o contrato externo para as entidades canÃ´nicas `Demand â†’ Case â†’ Job`.

**ReferÃªncia V2:** `docs/06-analysis-design/01_DECISION_LOG_V2.md` e `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`, evento `DemandCreated` como especializaÃ§Ã£o de domÃ­nio.

**O que construir:**
```
POST /integration/demands   â†’ recebe payload bruto da financeira, valida, normaliza, emite DemandCreated
GET  /integration/demands/{externalId}   â†’ status de processamento pelo ID externo
POST /integration/webhooks/status        â†’ recebe status updates da financeira
```

**Fluxo de normalizaÃ§Ã£o:**
```
Payload financeira
    â†“ IntegrationHubAdapter (validaÃ§Ã£o de schema)
    â†“ DemandNormalizer (mapeamento â†’ Demand canÃ´nica)
    â†“ DemandRepository.save() em integration_db
    â†“ Publica evento DemandCreated no RabbitMQ
    â†“ Job Lifecycle consume e cria Case + Job
```

**Regra de negÃ³cio:** "Toda demanda externa deve ser normalizada para o modelo canÃ´nico" (referÃªncia V2: `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`).

**Campos obrigatÃ³rios do payload canÃ´nico:**
```json
{
  "externalId": "FIN-12345",
  "tenantId": "tenant-uuid",
  "requestedBy": "financeira-slug",
  "propertyAddress": { "street": "...", "city": "...", "state": "...", "zipCode": "..." },
  "inspectionType": "RESIDENTIAL|COMMERCIAL|LAND",
  "requestedDeadline": "2026-05-01T00:00:00Z",
  "clientData": { "masked â€” somente campos necessÃ¡rios" }
}
```

**CritÃ©rio de pronto:**
- `POST /integration/demands` valida schema e rejeita payload invÃ¡lido com `400`
- Demand normalizada salva em `integration_db`
- Evento `DemandCreated` publicado no RabbitMQ (ou simulado em testes)
- `GET /integration/demands/{externalId}` retorna status
- Testes de contrato cobrindo payload vÃ¡lido, invÃ¡lido e duplicado (idempotÃªncia)

---

#### BOW-111 â€” Contrato de erro canÃ´nico: expandir para todos os endpoints
**Onda:** 1 | **Prioridade:** ðŸŸ  Alta | **Status:** âœ… ConcluÃ­do (2026-04-03)  
**Depende de:** nada (extensÃ£o do que jÃ¡ existe)

**Contexto:**  
`CanonicalErrorResponse` existe e funciona nos endpoints mobile. Falta aplicar em todos os endpoints (`/auth/*`, `/users/*`, `/config/*`, `/integration/*`).

**O que fazer:**
- Mapear cada tipo de exceÃ§Ã£o de domÃ­nio para `CanonicalErrorResponse` com `code` semÃ¢ntico
- Adicionar ao catÃ¡logo: `AUTH_INVALID_CREDENTIALS`, `AUTH_ACCOUNT_LOCKED`, `TENANT_NOT_FOUND`, `DEMAND_ALREADY_EXISTS`, `JOB_NOT_ASSIGNABLE`
- Expandir `ApiExceptionHandler` para cobrir `AccessDeniedException` â†’ `403` com cÃ³digo canÃ´nico

**CritÃ©rio de pronto:**
- Todos os novos endpoints retornam `CanonicalErrorResponse` em cenÃ¡rios de erro
- Testes de contrato para pelo menos `auth` e `integration`

---

### Grupo C: Job Lifecycle â€” Ciclo canÃ´nico de demanda atÃ© execuÃ§Ã£o

---

#### BOW-120 â€” Modelo de domÃ­nio: Case e Job
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Em andamento (backend integrado ao Integration Hub em 2026-04-03)  
**Depende de:** BOW-100 | **Bloqueia:** BOW-121, BOW-122, BOW-123, BL-001, BL-012

**Andamento 2026-04-03:**
- âœ… Entregue: migration `V007__job_domain.sql` com tabelas `demands`, `inspection_cases`, `jobs`, `assignments` e `job_timeline_entries`.
- âœ… Entregue: migration `V008__integration_demands_case_job_refs.sql` adicionando `case_id` e `job_id` em `integration_demands`.
- âœ… Entregue: migration `V009__inspection_submissions.sql` com persistÃªncia idempotente de submissÃµes mobile vinculadas ao `Job`.
- âœ… Entregue: entidades JPA, repositories, `JobStateMachine`, `CaseService` e `JobService` com transiÃ§Ãµes `ELIGIBLE_FOR_DISPATCH â†’ OFFERED â†’ ACCEPTED` e cancelamento para `CLOSED`.
- âœ… Entregue: APIs `POST /cases`, `GET /jobs`, `GET /jobs/{id}`, `GET /jobs/{id}/timeline`, `POST /jobs/{id}/assign`, `POST /jobs/{id}/accept`, `POST /jobs/{id}/cancel`.
- âœ… Entregue: Integration Hub agora cria `Case` e `Job` automaticamente ao receber `POST /api/integration/demands`, retornando `caseId` e `jobId` na resposta.
- âœ… Entregue: endpoint mobile `GET /api/mobile/jobs` retornando jobs reais por `X-Actor-Id` com isolamento por `tenantId`.
- âœ… Entregue: `POST /api/mobile/inspections/finalized` saiu do stub em memÃ³ria e passou a persistir submissÃµes idempotentes, gerar `protocolId` real e avanÃ§ar o `Job` atÃ© `SUBMITTED`.
- âœ… Testes: `CaseJobDomainIntegrationTest` com 9 cenÃ¡rios verdes, `IntegrationDemandIntegrationTest` com 3 cenÃ¡rios verdes, `InspectionSubmissionIntegrationTest` com 2 cenÃ¡rios verdes e regressÃ£o contratual do `MobileApiController` preservada com 6 testes verdes.
- â³ Pendente para concluir o card: expor transiÃ§Ãµes intermediÃ¡rias de execuÃ§Ã£o no contrato web/mobile, vincular `Inspection` como agregado explÃ­cito do domÃ­nio e fechar o painel web operacional sobre os novos dados reais.

**Contexto:**  
O domÃ­nio canÃ´nico define `Demand â†’ Case â†’ Job â†’ Assignment â†’ Inspection`. Hoje nÃ£o existe nenhuma dessas entidades no backend. O `MobileApiController` usa DTOs sem persistÃªncia canÃ´nica. Este Ã© o coraÃ§Ã£o do sistema para Stage 1.

**Estados do Job** (ref V2: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`):
```
Created â†’ EligibleForDispatch â†’ Offered â†’ Accepted â†’ InExecution â†’ FieldCompleted â†’ Submitted â†’ Closed
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
GET  /jobs?tenantId=&status=&page=&size=    â†’ lista paginada (web)
GET  /jobs/{id}                              â†’ detalhe do job
GET  /jobs/{id}/timeline                     â†’ histÃ³rico de estados
POST /cases                                  â†’ criaÃ§Ã£o manual de case/job
POST /jobs/{id}/assign                       â†’ despacha job para vistoriador
POST /jobs/{id}/accept                       â†’ vistoriador aceita
POST /jobs/{id}/cancel                       â†’ cancelamento com motivo
```

**API mobile (substituir stub em `MobileApiController`):**
```
GET /api/mobile/jobs?userId=&status=        â†’ jobs do vistoriador autenticado
```

**Regra:** "Todo job deve ter contexto de tenant e organizaÃ§Ã£o" (Regra 2).

**CritÃ©rio de pronto:**
- Migrations criadas para `job_db` (separado de `identity_db` â€” ADR-002)
- Estado machine do Job implementado com transiÃ§Ãµes validadas
- App mobile consegue listar seus jobs reais (nÃ£o mock)
- Testes de integraÃ§Ã£o: criaÃ§Ã£o de caseâ†’job, assign, accept, timeline

---

#### BOW-121 â€” API de configuraÃ§Ã£o dinÃ¢mica check-in (NBR)
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Em andamento (integraÃ§Ã£o real v1 entregue em 2026-04-03)  
**Depende de:** BOW-120 (tenant context), BOW-100

**Andamento 2026-04-03:**
- âœ… Entregue: `GET /api/mobile/checkin-config` deixou o stub fixo e passou a resolver configuraÃ§Ã£o efetiva real a partir de `ConfigPackage` ativo por tenant/usuÃ¡rio.
- âœ… Entregue: versionamento v1 por hash temporal (`cfg-<epoch>`) derivado do pacote ativo mais recente, preservando fallback `v1-default` quando nÃ£o hÃ¡ pacote ativo.
- âœ… Entregue: adaptaÃ§Ã£o retrocompatÃ­vel do contrato atual com `photoPolicy`, `featureFlags` e `presentation` derivados das regras efetivas de `ConfigPackage`.
- âœ… Entregue: modelagem canÃ´nica NBR persistida no banco com migration `V010__checkin_sections.sql` e tabela `checkin_sections` (key, label, mandatory, photos min/max, desiredItems).
- âœ… Entregue: contrato mobile expandido com `publishedAt` e `sections[]` canÃ´nicas, mantendo retrocompatibilidade de `step1/step2`.
- âœ… Testes: `MobileCheckinConfigIntegrationTest` com 2 cenÃ¡rios verdes cobrindo pacote ativo e fallback sem pacote.
- â³ Pendente para concluir o card: expor gestÃ£o web operacional das `sections` (publicaÃ§Ã£o/ediÃ§Ã£o/rollback por tenant) e conectar consumo mobile fim-a-fim sem dependÃªncia de fallback default.

**Contexto:**  
O mobile jÃ¡ consome `GET /api/mobile/checkin-config` (ver `MobileApiController`). Hoje retorna stub. Este item conecta ao banco real com versionamento, rollback e filtro por tipo de imÃ³vel.

**O que construir:**
```
GET /api/mobile/checkin-config?tipoImovel=RESIDENTIAL&version=current
```

**Response canÃ´nica:**
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

**RelaÃ§Ã£o com `ConfigPackage`:** O `ConfigPackageEntity` existente pode suportar isso ou criar modelo especÃ­fico de `CheckinConfig` â€” avaliar durante implementaÃ§Ã£o. Preservar compatibilidade com mobile atual.

**CritÃ©rio de pronto:**
- Endpoint retorna config real do banco (nÃ£o stub)
- Versionamento: mobile recebe versÃ£o e pode checar se mudou
- Rollback: admin pode reverter para versÃ£o anterior via web
- Mobile atualiza config apenas quando versÃ£o mudar (evitar re-download)

---

#### BOW-122 â€” API de recebimento de vistoria (idempotente)
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Em andamento (persistÃªncia idempotente entregue em 2026-04-03)  
**Depende de:** BOW-120, BOW-100

**Andamento 2026-04-03 (incremento adicional):**
- âœ… Entregue: migration `V011__inspections.sql` com agregado explÃ­cito `inspections` vinculado Ã  submissÃ£o mobile e ao `job`.
- âœ… Entregue: `InspectionSubmissionService` passou a persistir `Inspection` explÃ­cita no recebimento e a responder status operacional `SUBMITTED`.
- âœ… Entregue: idempotÃªncia preservada em `inspection_submissions` e `inspections` por `(tenant_id, idempotency_key)`.
- âœ… Testes: `InspectionSubmissionIntegrationTest` atualizado e verde cobrindo persistÃªncia do agregado + reenvio idempotente.

**Contexto:**  
`POST /api/mobile/inspections/finalized` existe como stub. Precisa de persistÃªncia real, idempotÃªncia obrigatÃ³ria e retorno de protocolo.

**Regra:** "Todo sync mobile deve ser idempotente" (ref V2: `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`).

**Fluxo UC-07:**
```
Mobile â†’ POST /api/mobile/inspections/finalized
  â†’ Valida X-Idempotency-Key
  â†’ Se jÃ¡ processado: retorna 200 com mesmo protocolo (nÃ£o reprocessa)
  â†’ Se novo: persiste InspectionSubmission + Inspection em field_ops_db
  â†’ Emite evento InspectionSubmitted
  â†’ Retorna { "protocol": "INS-2026-00123", "status": "SUBMITTED" }
```

**Chave de idempotÃªncia:** `jobId + exportedAt + payloadChecksum` â€” derivada pelo mobile.

**PersistÃªncia em `field_ops_db`:**
```
Inspection { id, jobId, tenantId, vistoriadorId, idempotencyKey, status, submittedAt, payload (jsonb) }
```

**CritÃ©rio de pronto:**
- Reenvio do mesmo payload retorna mesmo protocolo sem duplicar
- `InspectionSubmitted` event registrado
- Mobile recebe protocolo real e exibe ao usuÃ¡rio
- Testes: envio novo, reenvio idempotente, payload invÃ¡lido

---

#### BOW-123 â€” Painel web de vistorias recebidas
**Onda:** 1 | **Prioridade:** ðŸŸ  Alta | **Status:** âœ… ConcluÃ­do (2026-04-03)  
**Depende de:** BOW-122

**O que construir (web `apps/web-backoffice`):**
- Rota `/backoffice/inspections` â€” lista com filtros: status, data, tenant, vistoriador
- Rota `/backoffice/inspections/[id]` â€” detalhe tÃ©cnico completo com fotos e payload
- Indicadores: total recebido hoje, pendentes de intake, erros de sync

**Andamento 2026-04-03:**
- âœ… Entregue: backend `GET /api/backoffice/inspections` com filtros por `status`, janela (`from`/`to`) e `vistoriadorId`.
- âœ… Entregue: backend `GET /api/backoffice/inspections/{id}` com detalhe tÃ©cnico do payload persistido.
- âœ… Entregue: rotas Next.js `/api/inspections` e `/api/inspections/[inspectionId]` como bridge para o backend.
- âœ… Entregue: pÃ¡gina `apps/web-backoffice/app/backoffice/inspections/page.tsx` com indicadores, filtros, paginaÃ§Ã£o inicial, listagem e painel de detalhe tÃ©cnico do payload.
- âœ… Entregue: indicadores do painel conectados a mÃ©tricas de backend (`receivedToday`, `pendingIntake`, `syncErrors`, `submitted`) na resposta de listagem.
- âœ… Entregue: entrada de navegaÃ§Ã£o no dashboard inicial do backoffice.
- âœ… Testes backend focados: `InspectionBackofficeIntegrationTest`, `InspectionSubmissionIntegrationTest` e `MobileCheckinConfigIntegrationTest` verdes (6 testes).
- âœ… ValidaÃ§Ãµes web executadas: `npm --prefix apps/web-backoffice run lint` limpo; `npm --prefix apps/web-backoffice test` verde (16 testes).
- âš ï¸ ObservaÃ§Ã£o operacional: apÃ³s reinstalaÃ§Ã£o limpa de dependÃªncias, foi necessÃ¡rio adicionar `get-tsconfig` como `devDependency` direta para estabilizar o runner `tsx` no Windows.
- â³ Pendente para concluir o card: confirmar deterministicamente o `next build` neste ambiente local (travando sem saÃ­da apÃ³s o banner do Next.js).

**CritÃ©rio de pronto:**
- Lista paginada funcional com dados reais
- Detalhe mostra payload completo da vistoria
- Filtros: status + data funcionando

---

### Grupo D: Field Operations â€” Mobile conectado ao backend real

---

#### BOW-130 â€” ConfiguraÃ§Ã£o dinÃ¢mica de check-in conectada ao mobile
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Pendente  
**Depende de:** BOW-121, BL-012

**Contexto:**  
BL-012 jÃ¡ tem o fluxo de leitura no mobile: mock local â†’ API â†’ cache â†’ fallback hardcoded. Este item conecta a API real e valida o ciclo completo end-to-end.

**O que validar/implementar:**
- Mobile recebe config real do `BOW-121`
- Fallback mock continua funcionando em modo dev
- Cache local atualiza apenas quando versÃ£o mudar
- Testes Maestro cobrindo: config carregada â†’ checkin com obrigatoriedades NBR

**CritÃ©rio de pronto:**
- Ciclo completo: admin publica config no web â†’ mobile recebe â†’ checkin aplica regras
- Rollback de config reflete no mobile na prÃ³xima sincronizaÃ§Ã£o

---

#### BOW-131 â€” Sync de vistoria conectado ao backend real
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Pendente  
**Depende de:** BOW-122, BL-001, BL-002

**Contexto:**  
BL-001 e BL-002 jÃ¡ tÃªm fila offline e retry no mobile. Este item conecta ao `BOW-122` real e valida o ciclo completo, incluindo recebimento de protocolo.

**O que validar:**
- Fila offline drena automaticamente quando conexÃ£o volta
- Protocolo retornado exibido na tela de conclusÃ£o
- Retry nÃ£o duplica (idempotÃªncia)
- Evento `InspectionSubmitted` gerado corretamente

---

### Grupo E: Valuation Core â€” Ciclo tÃ©cnico da vistoria atÃ© o laudo

---

#### BOW-140 â€” Modelo canÃ´nico de avaliaÃ§Ã£o e intake
**Onda:** 1 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Pendente  
**Depende de:** BOW-122

**Contexto:**  
UC-10 ("Processar valuation") define que "Valuation sÃ³ processa apÃ³s intake vÃ¡lido" (Regra 5). O intake Ã© a porta de entrada da vistoria no ciclo tÃ©cnico.

**Estados do ValuationProcess** (ref V2: `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`):
```
PendingIntake â†’ IntakeValidated â†’ Enriched â†’ Processing â†’ Completed â†’ Approved
```

**O que construir em `valuation_db`:**
```
ValuationProcess { id, inspectionId, tenantId, status, method, assignedAnalystId, createdAt }
IntakeValidation  { id, valuationProcessId, validatedBy, issues (jsonb), validatedAt, result }
```

**API:**
```
POST /valuation/processes                           â†’ cria processo a partir de inspection
GET  /valuation/processes/{id}                      â†’ status detalhado
POST /valuation/processes/{id}/validate-intake      â†’ analista valida intake
```

**CritÃ©rio de pronto:**
- Processo criado automaticamente quando `InspectionSubmitted` Ã© consumido
- Analista consegue validar/rejeitar intake via web
- Estado `IntakeValidated` emite evento para prÃ³xima fase

---

#### BOW-141 â€” Composer de laudo bÃ¡sico (estrutura mÃ­nima)
**Onda:** 1 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente  
**Depende de:** BOW-140

**Contexto:**  
Estados do Report: `Draft â†’ Generated â†’ UnderReview â†’ ReadyForSign â†’ Signed â†’ Published â†’ Archived`.

**O que construir (MVP do laudo):**
- Template bÃ¡sico de laudo em HTML/JSON com campos do processo
- `POST /reports/{valuationProcessId}/generate` â€” gera rascunho
- `GET /reports/{id}` â€” retorna laudo atual
- Workspace web para revisor tÃ©cnico anotar e aprovar
- "Laudo sÃ³ pode ser publicado apÃ³s sign-off" (Regra 6)

**CritÃ©rio de pronto:**
- Rascunho gerado a partir do processo
- Revisor tÃ©cnico consegue aprovar ou devolver no web
- Estado `ReadyForSign` atingÃ­vel pelo fluxo

---

### Grupo F: Observabilidade e Contratos

---

#### BOW-150 â€” Correlation ID e OpenTelemetry bÃ¡sico
**Onda:** 1 | **Prioridade:** ðŸŸ  Alta | **Status:** Em andamento (control tower operacional entregue em 2026-04-08)

**O que construir:**
- PropagaÃ§Ã£o de `X-Correlation-Id` de entrada atÃ© logs, eventos e respostas de erro
- `traceId` disponÃ­vel em todos os logs estruturados
- Health checks: `GET /actuator/health` com status de DB, Redis e RabbitMQ
- MÃ©trica bÃ¡sica: contagem de requests por endpoint, latÃªncia p95

**CritÃ©rio de pronto:**
- Qualquer request tem `correlationId` rastreÃ¡vel nos logs
- `actuator/health` reporta status dos componentes downstream

---

#### BOW-151 â€” Contract tests mobile-backend em CI
**Onda:** 1 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente  
**Depende de:** BOW-121, BOW-122, BOW-102

**O que construir:**
- Testes de contrato para `GET /api/mobile/checkin-config`
- Testes de contrato para `POST /api/mobile/inspections/finalized`
- Testes de contrato para `GET /auth/me`
- Gate no CI que bloqueia PR se contrato quebrar (extensÃ£o do INT-025)

---

## Onda 2 â€” Backlog detalhado

### Grupo: Workforce & Dispatch

---

#### BOW-200 â€” Workforce: modelo de vistoriador elegÃ­vel
**Onda:** 2 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente  
**Depende de:** BOW-100, BOW-120

**Contexto:**  
Regra 4: "Um vistoriador sÃ³ pode receber job se elegÃ­vel." Elegibilidade inclui: ativo, com habilitaÃ§Ã£o vÃ¡lida, cobertura geogrÃ¡fica e sem conflito de agenda.

**O que construir em `workforce_db`:**
```
WorkforceProfile  { userId, tenantId, regionCoverage (jsonb), qualifications (jsonb), status }
WorkforceAvailability { userId, date, availableSlots, bookedSlots }
```

**API:**
```
GET /workforce/available?region=&date=&inspectionType=  â†’ lista elegÃ­veis para dispatch
GET /workforce/{userId}/profile                          â†’ perfil completo do vistoriador
```

---

#### BOW-201 â€” Dispatch: oferta e aceite de job
**Onda:** 2 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente  
**Depende de:** BOW-200, BOW-120

**Contexto:**  
UC-03: "Distribuir job". Dispatcher seleciona vistoriador elegÃ­vel, oferta job, vistoriador aceita ou recusa via mobile.

**O que construir:**
- LÃ³gica de dispatch: seleÃ§Ã£o por region/qualificaÃ§Ã£o/disponibilidade
- Evento `JobAssigned` â†’ notificaÃ§Ã£o push para vistoriador
- Mobile: tela de propostas com aceite por deslize (BL-042 jÃ¡ tem UI mock)
- `POST /jobs/{id}/offer` â€” oferta para vistoriador especÃ­fico
- Timeout de resposta: se nÃ£o aceitar em X horas, re-oferta

---

#### BOW-202 â€” Notification Service: push + email bÃ¡sico
**Onda:** 2 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente

**O que construir:**
- Registro de device token FCM no backend ao autenticar
- Envio de push: `JobOffered`, `JobDeadlineApproaching`, `InspectionFeedback`
- Envio de email: confirmaÃ§Ã£o de cadastro, aprovaÃ§Ã£o, rejeiÃ§Ã£o
- Fila RabbitMQ para eventos de notificaÃ§Ã£o com retry

---

#### BOW-203 â€” Process Orchestration: SLA e retries
**Onda:** 2 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente

**O que construir:**
- SLA tracking por job: alerta quando deadline < 24h e job ainda nÃ£o iniciado
- Retry de eventos falhos na mensageria (dead letter queue)
- Reprocessamento manual de inspeÃ§Ãµes com erro de intake
- Dashboard operacional de SLA no web

---

### Grupo: Observabilidade Ampliada

---

#### BOW-210 â€” Telemetria de fluxo mobile (BL-009)
**Onda:** 2 | **Prioridade:** ðŸŸ  Alta | **Status:** Pendente

**O que construir:**
- Endpoint `POST /telemetry/events` recebendo eventos operacionais do mobile
- Eventos: `inspection_started`, `inspection_resumed`, `inspection_completed`, `sync_failed`, `sync_retried`
- Dashboard web: taxa de sucesso de sync, retentativas, tempo mÃ©dio de execuÃ§Ã£o

---

#### BOW-211 â€” Onboarding CLT/PJ e aprovaÃ§Ã£o de cadastro (web)
**Onda:** 2 | **Prioridade:** ðŸ”´ CrÃ­tica | **Status:** Pendente  
**Depende de:** BOW-100, BOW-101, BOW-102

**Contexto:**  
BL-032 e BL-033 tÃªm o fluxo mobile. Este item fecha o ciclo com o backoffice web gerenciando aprovaÃ§Ã£o.

**O que construir:**
- `UserLifecycle` entity: `PENDING_ONBOARDING â†’ PENDING_APPROVAL â†’ APPROVED â†’ REJECTED`
- Web: fila de aprovaÃ§Ã£o com documento, dados bancÃ¡rios PJ, validaÃ§Ã£o de CNPJ
- NotificaÃ§Ã£o automÃ¡tica ao aprovar/rejeitar
- Mobile: estado `aguardando aprovaÃ§Ã£o` conectado ao backend real

---

## Onda 3 â€” Backlog resumido (planejamento)

#### BOW-300 â€” Multi-tenant real: isolamento de dados por schema ou row-level security
**Onda:** 3 | **Status:** Planejado  
Ativar segundo tenant real na plataforma. Cada tenant com branding, usuÃ¡rios, configuraÃ§Ãµes e dados isolados. Validar que nenhuma query retorna dados cross-tenant.

#### BOW-301 â€” White label de marca e comportamento
**Onda:** 3 | **Status:** Planejado  
Branding por tenant: logo, cores, domÃ­nios, templates de laudo, textos. Web e mobile refletem marca do tenant autenticado.

#### BOW-302 â€” FederaÃ§Ã£o com Active Directory (OIDC/SAML por tenant)
**Onda:** 3 | **Status:** Planejado  
Depende de BOW-103. Habilitar OIDC/SAML por tenant sem refatorar domÃ­nio. Mapeamento de grupos AD para papÃ©is canÃ´nicos.

#### BOW-303 â€” Tenant management panel (platform admin)
**Onda:** 3 | **Status:** Planejado  
Interface para `PLATFORM_ADMIN` criar/configurar/suspender tenants. Branding, polÃ­ticas, integraÃ§Ãµes e usuÃ¡rios por tenant.

---

## Onda 4 â€” Backlog resumido (visÃ£o)

#### BOW-400 â€” Provider Network: rede de empresas de avaliaÃ§Ã£o
**Onda:** 4 | **Status:** VisÃ£o  
MÃºltiplas empresas de avaliaÃ§Ã£o cadastradas como providers. Plataforma distribui demanda entre elas.

#### BOW-401 â€” Matching automatizado demanda Ã— empresa Ã— vistoriador
**Onda:** 4 | **Status:** VisÃ£o  
Algoritmo de matching por especialidade, SLA histÃ³rico, cobertura regional e disponibilidade.

#### BOW-402 â€” Pricing & Settlement multi-partes
**Onda:** 4 | **Status:** VisÃ£o  
Regra 7: "Settlement sÃ³ pode ser calculado apÃ³s resultado final." Fee da plataforma, repasse Ã  empresa de avaliaÃ§Ã£o, repasse ao vistoriador. LiquidaÃ§Ã£o multi-partes com trilha completa.

#### BOW-403 â€” Intelligence: control tower e scoring
**Onda:** 4 | **Status:** VisÃ£o  
KPIs por tenant/regiÃ£o/vistoriador. Score de qualidade. Control tower para gestÃ£o executiva do ecossistema.

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
## Adendo 2026-04-08 - Pos-release v1.2.40+60

- BOW-100 avancou alem da fundacao conceitual: tenant guard ativo, ownership por tenant e gate de operador aprovado ja estao no codigo promovido.
- BOW-120 saiu de backlog abstrato e passou a backbone operacional real para `Case -> Job -> Assignment -> Inspection`, ainda com hardening residual de contexto organizacional.
- BOW-140 e BOW-141 avancaram para baseline operacional entregue: `ValuationProcess`, `IntakeValidation` e `Report` persistidos, APIs web/backoffice reais e fluxo minimo `PENDING_INTAKE -> READY_FOR_SIGN`.
- BOW-150 e BOW-151 tambem deixaram de ser puramente pendentes: correlation headers, secret validator e gates de contrato/CI ja participam do release promovido.

## Adendo 2026-04-08 - Control tower operacional entregue

- BOW-150 avancou de correlation path basico para baseline operacional real: requests relevantes agora geram eventos persistidos com `correlationId`, `traceId`, status e latencia para a control tower.
- O backend passou a expor agregados unificados de observabilidade, alerta, retention e continuidade em `/api/backoffice/operations/control-tower`, reduzindo dependencia de leitura manual de logs brutos.
- O restante de BOW-150 deixa de ser ausencia de superficie operacional e passa a ser evolucao incremental de instrumentacao/telemetria mais profunda.
