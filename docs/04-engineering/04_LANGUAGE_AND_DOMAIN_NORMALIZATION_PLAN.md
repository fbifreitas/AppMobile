# LANGUAGE AND DOMAIN NORMALIZATION PLAN

## Objective

Standardize the repository around:

- English-first code and engineering terminology
- neutral shared vocabulary
- explicit domain-pack specialization

This plan follows the active platform documentation:

- [Platform Core And Shared Foundations](../03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md)
- [Domain Pack Inspection](../03-architecture/03_DOMAIN_PACK_INSPECTION.md)
- [Corporate Canonical Model](../03-architecture/07_CORPORATE_CANONICAL_MODEL.md)

## Why this exists

The codebase still contains:

- Portuguese identifiers
- property-specific terms inside shared flows
- inspection-only semantics leaking into reusable artifacts

That creates friction for:

- new developers
- multi-domain expansion
- contract stability across mobile, backend, and web

## Milestone display

- `W1` Baseline + Vocabulary: `100%`
- `W2` Internal Normalization: `92%`
- `W3` Contract Migration: `100%`
- `W4` UI + Final Cleanup: `88%`

## Large implementation waves

### W1. Baseline + Vocabulary

Goal:

- map current Portuguese and specialized terms
- define target English neutral vocabulary
- classify what is shared vs inspection-specific

Deliverables:

- root [GLOSSARY.md](../../GLOSSARY.md)
- [06_DATA_DICTIONARY_DOMAIN_TERMS.md](06_DATA_DICTIONARY_DOMAIN_TERMS.md)
- [05_STYLE_GUIDE_LANGUAGE_AND_NAMING.md](05_STYLE_GUIDE_LANGUAGE_AND_NAMING.md)

Status:

- completed

### W2. Internal Normalization

Goal:

- rename internal code identifiers without changing public contracts yet

Scope:

- Flutter classes, methods, variables, services, widgets
- backend private methods and internal mappers
- web internal state and helper types

Rules:

- shared modules use neutral names
- inspection modules can keep `inspection` terms
- property-specific names must be removed from shared paths

Target examples:

- `tipoImovel -> assetType`
- `subtipoImovel -> assetSubtype`
- `clientePresente -> contactPresent`
- `porOndeComecar -> entryPoint`
- `vistoriadorId -> fieldAgentId`

### W3. Contract Migration

Goal:

- migrate external and persisted contracts safely

Scope:

- mobile payloads
- backend DTOs
- web/backoffice config payloads
- recovery snapshots
- local storage keys
- database fields only where justified and planned

Rules:

- introduce compatibility aliases first
- version contracts where risk is high
- remove old names only after all channels are updated

### W4. UI + Final Cleanup

Goal:

- align copy, preserve locale-driven UX, remove legacy aliases, and close the migration

Scope:

- user-facing strings through locale-aware dictionaries
- operational messages
- tests
- final cleanup of temporary adapters

Exit criteria:

- shared layers contain no Portuguese identifiers
- shared layers contain no property-specific vocabulary
- glossary, data dictionary, and style guide are aligned with implementation

## Initial hotspots

### Mobile

- `lib/state/app_state.dart`
- `lib/config/checkin_step2_config.dart`
- `lib/models/checkin_step2_model.dart`
- `lib/models/inspection_template_model.dart`
- `lib/widgets/checkin/checkin_step1_question_flow.dart`

### Backend

- `apps/backend/src/main/java/com/appbackoffice/api/mobile/service/MobileCheckinConfigService.java`
- `apps/backend/src/main/java/com/appbackoffice/api/mobile/entity/CheckinSectionEntity.java`
- inspection submission persistence fields such as `vistoriador_id`

### Web / Backoffice

- `apps/web-backoffice/app/components/config_targeting_panel.tsx`
- `apps/web-backoffice/app/lib/config_targeting.ts`

## Current decision

The platform will keep `inspection` as a valid domain-pack term.
The platform will not keep `property`-specific terminology in shared flows.
