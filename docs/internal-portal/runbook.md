# Delivery Runbook

## Before coding

1. Read `docs/AGENTE_LICOES_APRENDIDAS.md`.
2. Read `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
3. Read business and backlog context.

## During coding

1. Update backlog and traceability docs.
2. Keep a continuous checkpoint (`done`, `current`, `next`).
3. Do not persist secrets in repo files.

## Validation

1. Flutter: `flutter analyze`, `flutter test`
2. Web: `npm run lint`, `npm test`, `npm run build`
3. Backend: `mvn -B -DskipTests package`

## Release rule

1. Homologation first.
2. Wait for explicit approval before promoting to `main`.
3. Monitor CI/CD and distribution confirmation.
