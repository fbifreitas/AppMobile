# LANGUAGE MIGRATION DASHBOARD

## Goal

Track the repository migration from:

- Portuguese and domain-specialized shared code

to:

- English-first, neutral shared vocabulary
- explicit domain-pack specialization

## Progress display

- `W1` Baseline + Vocabulary: `100%`
- `W2` Internal Normalization: `92%`
- `W3` Contract Migration: `100%`
- `W4` UI + Final Cleanup: `88%`

## Completed in this cycle

### Documentation

- root glossary created
- naming style guide created
- data dictionary created
- normalization plan created

### Mobile shared layer

- English aliases added to `Job`
- English wrappers added to `AppState`
- `AssetType` alias introduced on top of `TipoImovel`
- English aliases added to `CheckinStep2Config`
- step1 recovery payload now stores both legacy and neutral keys
- review export payload now emits both legacy and neutral keys
- review and capture models now expose neutral aliases for:
  - capture context
  - target item
  - target qualifier
  - condition state
  - note
  - asset type
- review finalization now uses neutral internal names such as:
  - `assetType`
  - `note`
  - `technicalJustification`
- review closing widgets now use `noteController`
- capture services now expose neutral aliases such as:
  - `captureCameraPhotoEvidence(...)`
  - `pickGalleryPhotoEvidence(...)`
- camera services now expose canonical aliases such as:
  - `resolveCanonical(...)`
  - `buildSectionsCanonical(...)`
  - `canonicalLevelId(...)`
  - `canonicalSelectorLevelForCommand(...)`
- review UI copy now uses locale-driven strings in the migrated runtime flow
- camera flow started consuming locale-driven strings in the main capture runtime flow
- legacy inspection menu and checkout runtime entry points now consume the locale-driven string layer in their migrated labels
- mobile app now has a lightweight `pt`/`en` UI language layer driven by device locale
- backoffice now has a lightweight `pt`/`en` UI language layer started in the config targeting panel
- config targeting panel now consumes locale-driven labels for the main multi-scope, canonical-tree, step1 and step2 headings and controls

### Backend contract layer

- `/api/mobile/checkin-config` now accepts `assetType` as alias for `tipoImovel`
- step1 response now emits neutral aliases such as:
  - `assetTypes`
  - `assetSubtypesByType`
  - `entryPoints`
  - `requestedAssetType`
- step2 response now emits neutral aliases such as:
  - `byAssetType`
  - `photoFields`
  - `optionGroups`
- `MobileCheckinConfigService` now uses `assetType` as its internal semantic parameter
- review recovery payload now emits `assetType` together with `tipoImovel`
- backend DTOs and entities now expose neutral aliases such as:
  - `fieldAgentId()`
  - `getAssetType()`
  - `setAssetType(...)`
- physical persistence migration validated:
  - `inspection_submissions.field_agent_id`
  - `inspections.field_agent_id`
  - `checkin_sections.asset_type`
- backend container build completed successfully with the new schema-mapped entities and migration-aligned services
- app local storage migration started:
  - recovery draft key moved to `inspection_recovery_snapshot_v2` with fallback from the legacy key
  - dynamic config cache keys moved from `checkin_dynamic_*` to `asset_dynamic_*` with fallback from legacy keys

### Web/backoffice

- config targeting types now support `assetType`
- check-in section payload now emits both `assetType` and `tipoImovel`
- neutral helper type added for normalized check-in section rules
- section draft and payload builder now prioritize `assetType` internally
- inspections page now uses locale-driven UI strings and clean ASCII copy

## Remaining work

### W2. Internal Normalization

- rename internal identifiers still using Portuguese in:
  - `checkin` flow widgets
  - `review` screens and editor flows
  - backend services and entities
  - web/backoffice helper types

### W4. UI + Final Cleanup

- migrate remaining hardcoded UI copy in:
  - `camera_flow_screen.dart`
  - `config_targeting_panel.tsx`
  - additional backoffice pages beyond inspections/config
  - legacy mobile flow screens not yet covered by `AppStrings`
  - remaining backoffice sections not yet covered by `ui_strings.ts`
- remove legacy aliases after all channels stabilize
- finalize regression coverage
