# DATA DICTIONARY: DOMAIN TERMS

## Purpose

This dictionary maps current repository terms to the target canonical vocabulary.

## Shared contract mappings

| Current field | Target field | Classification | Notes |
| --- | --- | --- | --- |
| `tipoImovel` | `assetType` | shared | Property-specific today, must become asset-neutral. |
| `subtipoImovel` | `assetSubtype` | shared | Same rule as `assetType`. |
| `clientePresente` | `contactPresent` | shared | Represents presence of the responsible contact. |
| `porOndeComecar` | `entryPoint` | shared | Start point of execution or capture flow. |
| `vistoriadorId` | `fieldAgentId` | shared | Neutral operational actor name. |
| `observacao` | `note` | shared | Free-text note. |
| `justificativaTecnica` | `technicalJustification` | shared | Validation/finalization note. |

## Taxonomy mappings

| Current field | Target direction | Classification | Notes |
| --- | --- | --- | --- |
| `ambiente` | `taxonomyLevel1` | shared taxonomy | Domain labels come from config. |
| `elemento` | `taxonomyLevel2` | shared taxonomy | Domain labels come from config. |
| `material` | `taxonomyAttributeMaterial` or domain label | conditional | Keep only if cross-domain value is justified. |
| `estado` | `conditionState` | shared taxonomy | Prefer explicit condition semantics. |
| `estadoConservacao` | `conditionState` | shared taxonomy | Same semantic target. |

## Method mappings

| Current method | Target method |
| --- | --- |
| `carregarJobs` | `loadJobs` |
| `selecionarJob` | `selectJob` |
| `finalizarJob` | `finalizeJob` or `finalizeWorkItem` |
| `atualizarReferenciasExternasJobAtual` | `updateCurrentJobExternalReferences` |

## Domain boundary rule

### Shared

- `asset`
- `work item`
- `field agent`
- `execution`
- `outcome`

### Inspection specialization

- `inspection`
- `inspection review`
- `inspection report`

### Property-only specialization

Property-only labels must stay configurable or isolated inside the property specialization layer.
