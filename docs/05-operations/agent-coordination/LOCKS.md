# Locks Multiagente

Atualizado em: 2026-04-10

## Locks Ativos

| Agente | Frente | Branch | Lock | Status |
|---|---|---|---|---|
| Codex Big Bang Compass | Implantacao integrada Compass | `codex/docs-governance-20260409` | mobile, backend, web-backoffice, integracao, operacao e docs Compass | active ate 2026-04-10 18:00 BRT |
| IA-Backend-Web | Backend/Web/Operacao Compass | `codex/compass-platform-operacao-20260410` | `apps/backend/`, `apps/web-backoffice/`, docs backend/web/integracao/operacao | paused ate 2026-04-10 18:00 BRT |

## Regras De Ownership

- Durante a janela big bang solo, Codex pode alterar mobile/backend/web/docs Compass, mas deve registrar commits e evidencias por frente.
- IA-Backend-Web nao altera `lib/`, `android/`, `ios/` nem `.github/workflows/android_*` sem pedido de handoff.
- IA-Release-Governanca nao altera codigo produtivo.
- Nenhum agente altera arquivos proibidos do ciclo.
- Nenhum agente faz rebase, reset hard, amend ou checkout destrutivo em branch de outro agente.
- Cada commit deve pertencer a uma frente clara e registrar testes relevantes.
- Ao retomar as 18:00 BRT, IA-Backend-Web deve ler `HANDOFF_LOG.md`, confirmar quais locks continuam ativos e nao assumir arquivos alterados na janela big bang sem reconciliar o diff.

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
