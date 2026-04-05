# Canonical Domain v1

Reference source: `docs/BACKLOG_BACKOFFICE_WEB.md` (BOW-054 section).

## Core entities

1. Demand
2. Case
3. Job
4. Inspection
5. Report

## Why this matters

1. Prevents upstream payload coupling.
2. Aligns web, mobile, and integration teams to a single language.
3. Enables compatibility governance for APIs/events.

## Mandatory context envelope

1. `X-Tenant-Id`
2. `X-Correlation-Id`
3. `X-Actor-Id`
4. `X-Idempotency-Key` (for critical writes)

## Compatibility baseline

1. v1 allows only non-breaking additive changes.
2. Removals/renames require new major version.
