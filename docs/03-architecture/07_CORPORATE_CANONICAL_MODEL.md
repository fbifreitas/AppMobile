# CORPORATE CANONICAL MODEL

## Purpose

Fornecer um backbone canônico corporativo sem impor a semântica de um domínio específico aos demais.

## Corporate workflow backbone

```text
Intake → Case → Work Item → Assignment → Execution → Outcome → Financial Event
```

## Notes

- `Case` permanece como agrupador contextual.
- `Work Item` é a unidade operacional neutra.
- `Assignment` representa alocação/roteamento.
- `Execution` representa a realização da atividade.
- `Outcome` representa o resultado consumível.
- `Financial Event` representa o efeito financeiro associado.

## Domain specialization

### Inspection
Pode especializar para:
`Demand → Case → Job → Inspection → Valuation → Report → Settlement`

### Wellness
Pode especializar para:
`Intake → Case → Appointment/Session → Attendance → Outcome → Billing Event`

### Church
Pode especializar para:
`Intake → Case/Event/Request → Assignment/Participation → Outcome → Financial Event`

## Rule

O modelo corporativo orienta integração e governança.
O modelo do domínio orienta operação e linguagem do negócio.
