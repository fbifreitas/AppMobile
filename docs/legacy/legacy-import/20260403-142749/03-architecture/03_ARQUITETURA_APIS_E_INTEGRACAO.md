# Arquitetura de APIs e Integração

## Síncrono
REST/OpenAPI para autenticação, consulta, status, config remota e dashboards.

## Assíncrono
Eventos para DemandCreated, CaseCreated, JobAssigned, JobAccepted, InspectionSubmitted, ValuationCompleted, ReportGenerated e SettlementCalculated.

## Regras
- versionamento de contrato;
- idempotency key;
- correlation-id;
- erro canônico;
- DTOs explícitos;
- integração externa via ACL.
