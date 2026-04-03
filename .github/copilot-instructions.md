# Copilot Instructions — V2 Multi-Domain Direction

## Mandatory repository direction

This repository must no longer be treated as a single inspection product.

The official direction is now:

**a corporate multi-domain, multi-tenant, white-label ecosystem platform**.

Current domain packs:

- Inspection
- Wellness
- Church

Inspection remains strategically important, but it no longer defines the global platform semantics.

## Architectural layers

Every proposal, file, module, class, endpoint, entity, workflow or backlog item must be understood within one of these layers:

1. `corporate`
2. `platform-core`
3. `shared-foundation`
4. `domain-inspection`
5. `domain-wellness`
6. `domain-church`
7. `experience-layer`
8. `data-intelligence`
9. `legacy`

## Core rules

1. Platform Core must remain domain-agnostic.
2. Shared Foundations may be reused across domains, but must not carry semantics exclusive to one domain.
3. Domain packs are independent.
4. One domain must not depend directly on the internal model of another domain.
5. Cross-domain interaction must happen through contracts, APIs, events, read models or anti-corruption layers.
6. White-label must be implemented through configuration, policies, branding and enablement, never through code forks.
7. Tenant is a structural concern for authorization, configuration, integration, observability and data isolation.

## Naming rules

Do not promote inspection-specific terminology into global platform artifacts.

These names must remain inside `domain-inspection` unless explicitly domain-scoped:

- inspection
- vistoria
- valuation
- report
- settlement
- NBR check-in
- mandatory evidence

When creating shared abstractions, prefer neutral naming such as:

- intake
- case
- work item
- execution
- outcome
- financial event
- media asset
- workflow instance
- schedule slot
- payment transaction
- tenant policy

## Canonical model rules

The corporate canonical backbone is not the same as the inspection canonical model.

### Corporate canonical backbone

- Intake
- Case
- Work Item
- Assignment
- Execution
- Outcome
- Financial Event

### Inspection specialization

- Demand
- Case
- Job
- Inspection
- Valuation
- Report
- Settlement

Inspection may specialize the backbone, but must not redefine the global platform model.

## Documentation policy

Whenever a change touches:

- naming
- architecture
- canonical model
- backlog
- tenant / white-label
- shared APIs
- cross-domain boundaries
- folder/module organization

the corresponding documentation must be updated in the same change.

Never keep two active documents with contradictory guidance.

## Legacy policy

Older inspection-centric documents may still exist for historical value.
If they no longer represent the active corporate direction, they must be moved to `docs/legacy/` or clearly marked as legacy.

## Required reading order before suggesting significant changes

Before proposing architecture, refactoring, new modules, backlog changes, shared entities or documentation changes, read the following:

1. `README.md`
2. `GEMINI.md`
3. `docs/00-overview/00_INDEX_GERAL.md`
4. `docs/00-overview/01_DOCUMENTATION_INDEX.md`
5. `docs/00-overview/02_DIRECTION_CHANGE_NOTICE.md`
6. `docs/00-overview/03_PLANO_DE_MIGRACAO_DOCUMENTAL.md`
7. `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
8. `docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
9. `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`
10. `docs/03-architecture/04_DOMAIN_PACK_WELLNESS.md`
11. `docs/03-architecture/05_DOMAIN_PACK_CHURCH.md`
12. `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
13. `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
14. `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`
15. `docs/04-engineering/02_REPO_TARGET_STRUCTURE.md`
16. `docs/04-engineering/03_SHORT_PATH_TRANSITION_PLAN.md`
17. `docs/BACKLOG_V2_PRIORIDADES.md`

If any of these files are missing, incomplete or contradictory, stop and propose the documentation fix first.

## Behavior expected from Copilot

Before editing:

1. Identify the layer.
2. Identify the affected domain, if any.
3. Check whether a shared artifact is receiving domain-specific semantics.
4. Check whether documentation and backlog must be updated.
5. Prefer the shortest path that preserves the new direction.

## Prohibited shortcuts

Do not:

- treat inspection as the total identity of the company
- create shared abstractions with inspection-specific names
- couple wellness or church to inspection internals
- implement white-label by duplicating codebases
- treat tenant as a UI-only filter
- continue writing active docs as if the company were only an inspection platform
