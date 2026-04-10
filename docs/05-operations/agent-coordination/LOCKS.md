# Locks Multiagente

Atualizado em: 2026-04-10

## Locks Ativos

| Agente | Frente | Branch | Lock | Status |
|---|---|---|---|---|
| IA-Mobile | Mobile Compass Pacote B | `codex/docs-governance-20260409` | `lib/`, `test/`, `android/`, `ios/`, `.github/workflows/android_*`, docs mobile/distribuicao/branding | active |
| IA-Backend-Web | Backend/Web/Operacao Compass | `codex/compass-platform-operacao-20260410` | `apps/backend/`, `apps/web-backoffice/`, docs backend/web/integracao/operacao | reserved |

## Regras De Ownership

- IA-Mobile nao altera `apps/backend/` nem `apps/web-backoffice/` sem pedido de handoff.
- IA-Backend-Web nao altera `lib/`, `android/`, `ios/` nem `.github/workflows/android_*` sem pedido de handoff.
- IA-Release-Governanca nao altera codigo produtivo.
- Nenhum agente altera arquivos proibidos do ciclo.
- Nenhum agente faz rebase, reset hard, amend ou checkout destrutivo em branch de outro agente.
- Cada commit deve pertencer a uma frente clara e registrar testes relevantes.

## Pedido De Handoff

Use este formato em `HANDOFF_LOG.md` quando uma frente precisar tocar lock de outra:

```md
## Pedido de Handoff - AAAA-MM-DD HH:mm - <Agente>
- Precisa alterar:
- Motivo:
- Impacto esperado:
- Bloqueia:
- Status: aguardando resposta
```
