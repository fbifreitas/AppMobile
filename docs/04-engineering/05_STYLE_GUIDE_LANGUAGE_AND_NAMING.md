# STYLE GUIDE: LANGUAGE AND NAMING

## Primary rule

Use English for:

- code identifiers
- shared contracts
- engineering documentation

Portuguese is allowed only in:

- legacy compatibility layers during migration
- UI copy that has not yet been migrated
- historical documents

## Naming policy

### Shared artifacts

Use neutral names.

Examples:

- `assetType`
- `assetSubtype`
- `fieldAgentId`
- `entryPoint`
- `executionState`
- `technicalJustification`

### Domain-pack artifacts

Use explicit domain language only inside that domain.

Examples allowed inside inspection modules:

- `inspection`
- `inspectionReview`
- `inspectionReport`

Examples not allowed in shared modules:

- `property`
- `tipoImovel`
- `vistoriadorId`

## Taxonomy rule

Shared taxonomy must not hardcode property semantics.

Prefer:

- `taxonomyLevel1`
- `taxonomyLevel2`
- `taxonomyLevel3`
- `conditionState`

Avoid in shared contracts:

- `ambiente`
- `elemento`
- `material`
- `estado`

If a domain needs user-facing labels such as `Environment` or `Component`, those labels belong to configuration or domain-specific UI, not to the shared contract shape.

## Method naming

Prefer:

- `loadJobs`
- `selectJob`
- `finalizeWorkItem`
- `updateCurrentJobReferences`

Avoid:

- `carregarJobs`
- `selecionarJob`
- `finalizarJob`
- `atualizarReferenciasExternasJobAtual`

## Field naming

Prefer:

- `note`
- `technicalJustification`
- `contactPresent`
- `assetType`

Avoid:

- `observacao`
- `justificativaTecnica`
- `clientePresente`
- `tipoImovel`

## Migration discipline

1. internal identifier rename
2. compatibility alias for contract fields
3. contract rollout across channels
4. legacy field removal
