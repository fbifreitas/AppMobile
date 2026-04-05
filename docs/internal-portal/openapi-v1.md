# OpenAPI v1

## Endpoints in scope (critical mobile contracts)

1. `GET /api/mobile/checkin-config`
2. `POST /api/mobile/inspections/finalized`

## Documentation endpoint

When backend is running locally:

1. OpenAPI JSON: `http://localhost/api/openapi/v1`
2. Swagger UI: `http://localhost/api/swagger`

## Contract policy

1. Backward compatibility is mandatory in v1.
2. Breaking changes require a new major version.
3. CI gate for contract policy is tracked by BOW-056 and INT-025.
