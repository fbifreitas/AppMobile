# Glossary

## Purpose

This repository uses English as the primary language for code, shared contracts, and engineering documentation.

Domain-specific language is allowed only inside the correct domain pack boundary.
Shared platform artifacts must use neutral terminology.

## Canonical rule

- `Platform Core` and `Shared Foundations` use neutral vocabulary.
- `Inspection` is a domain pack specialization, not the default language of the whole platform.
- `Property`-specific terms must not leak into shared artifacts.

## Current normalization status

- `W1` Baseline + Vocabulary: `100%`
- `W2` Internal Normalization: `0%`
- `W3` Contract Migration: `0%`
- `W4` UI + Final Cleanup: `0%`

## Preferred vocabulary

| Current term | Preferred term | Scope | Notes |
| --- | --- | --- | --- |
| `tipoImovel` | `assetType` | shared contracts and code | Replace property-specific meaning with asset-neutral meaning. |
| `subtipoImovel` | `assetSubtype` | shared contracts and code | Keeps specialization without binding to property. |
| `clientePresente` | `contactPresent` | check-in, intake, runtime state | Use when the tracked concept is the presence of the responsible contact. |
| `porOndeComecar` | `entryPoint` | flow state and config | Represents the selected starting point of the execution flow. |
| `vistoriadorId` | `fieldAgentId` | shared contracts and persistence | Use `inspectorId` only inside inspection-specific modules if needed. |
| `vistoria` | `inspection` | inspection domain pack | Keep only where the domain is explicitly inspection. |
| `avaliacao` | `assessment` | shared UI/copy when not inspection-specific | Use `inspection` if the flow is still part of the inspection domain. |
| `imovel` | `asset` | shared contracts and code | Covers property, vehicle, equipment, or any inspectable subject. |
| `ambiente` | `taxonomyLevel1` or domain label | shared taxonomy contracts | Shared layers must not hardcode property room semantics. |
| `elemento` | `taxonomyLevel2` or domain label | shared taxonomy contracts | Same rule as above. |
| `material` | `taxonomyAttributeMaterial` or domain label | shared taxonomy contracts | Use only if material is truly cross-domain; otherwise domain-specific. |
| `estado` / `estadoConservacao` | `conditionState` | shared contracts when applicable | Prefer explicit condition vocabulary. |
| `observacao` | `note` | runtime state, payload, UI | Neutral and short. |
| `justificativaTecnica` | `technicalJustification` | review and validation flows | Acceptable in shared contracts if still generic to execution review. |

## Boundary examples

### Allowed in shared layers

- `assetType`
- `assetSubtype`
- `fieldAgentId`
- `entryPoint`
- `technicalJustification`
- `taxonomyLevel1`
- `taxonomyLevel2`

### Allowed only in the inspection domain pack

- `inspection`
- `inspectionReview`
- `inspectionReport`
- `inspectionChecklist`

### Must not remain in shared layers

- `tipoImovel`
- `subtipoImovel`
- `vistoriadorId`
- `clientePresente`
- `porOndeComecar`
- `ambiente`
- `elemento`

## Migration rule

When renaming a term:

1. rename internal identifiers first
2. migrate shared contracts with compatibility aliases
3. update persisted keys and DTOs
4. remove legacy aliases only after all channels are stable
