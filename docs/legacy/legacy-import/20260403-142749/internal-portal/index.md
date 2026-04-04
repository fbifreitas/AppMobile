# AppMobile Internal Engineering Docs

This portal is the internal reference for all development teams.

## Sources of truth

1. Backlog macro: `docs/BACKLOG_FUNCIONALIDADES.md`
2. Backoffice web backlog: `docs/BACKLOG_BACKOFFICE_WEB.md`
3. Integration backlog: `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`
4. Operational checkpoint: `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`

## Current baseline

1. Canonical Domain v1 (BOW-054) documented and published.
2. Docker local stack stabilized and validated by health endpoints.
3. OpenAPI v1 foundation available in backend endpoints.

## Governance rules

1. No secrets in versioned files.
2. Context envelope required (`tenantId`, `correlationId`, `actorId`).
3. Idempotency key required for critical write operations.
4. No breaking contract changes without new major version.
