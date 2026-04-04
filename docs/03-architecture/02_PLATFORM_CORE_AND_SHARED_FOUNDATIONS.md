# PLATFORM CORE AND SHARED FOUNDATIONS

## Platform Core

Capacidades transversais que não devem conhecer regra de domínio:
- Identity & Access
- Tenant & White-label Management
- Integration Hub
- Notification Core
- Audit Core
- Storage / Media Core
- Workflow / Forms Engine
- Offline Sync Core
- Event Bus / Messaging
- Policy / Config Engine
- Observability

## Shared Foundations

Capacidades de negócio reutilizáveis entre domínios:
- Party / Profile Base
- Organization / Unit Base
- Payment Base
- Scheduling Base
- Document / Media Base
- Analytics / Reporting Base

## Decision boundary

### Vai para Platform Core quando:
- é transversal
- não possui semântica forte de um domínio
- deve servir a todos os domínios

### Vai para Shared Foundation quando:
- existe reuso real entre 2+ domínios
- ainda há semântica de negócio
- não é específico o suficiente para ser de um único domínio

### Vai para Domain Pack quando:
- a linguagem é própria daquele negócio
- a regra muda por mercado
- o processo operacional pertence ao domínio
