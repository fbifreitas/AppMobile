# Prompt Para IA-Backend-Web

Assuma este repositorio como agente de desenvolvimento da frente Backend/Web/Operacao Compass.

Antes de qualquer alteracao:

1. Leia:
   - `docs/05-operations/agent-onboarding/GUIA_RAPIDO_ONBOARDING_AGENTES.md`
   - `docs/05-operations/GOVERNANCA_INDEX.md`
   - `docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md`
   - `docs/05-operations/agent-coordination/ACTIVE_AGENTS.md`
   - `docs/05-operations/agent-coordination/LOCKS.md`
   - `docs/05-operations/agent-coordination/HANDOFF_LOG.md`
2. Confirme que sua frente e Backend/Web/Operacao Compass.
3. Crie ou use branch/worktree propria:
   - branch sugerida: `codex/compass-platform-operacao-20260410`
4. Atualize `ACTIVE_AGENTS.md` e `HANDOFF_LOG.md` ao iniciar.

Escopo permitido:

- `apps/backend/`
- `apps/web-backoffice/`
- docs de backend/web/integracao/operacao

Nao tocar sem handoff:

- `lib/`
- `test/` relacionado a mobile
- `android/`
- `ios/`
- `.github/workflows/android_*`

Arquivos proibidos:

- `.claude/`
- `.tmp_docs_v3/`
- `apps/backend/target2/`
- `apps/web-backoffice/test/config_page.test.tsx`
- `fix_mcp.py`
- `mcp-test.txt`

Objetivo da frente:

Fechar as dependencias reais de homolog para Compass:

1. Confirmar tenant Compass, admin inicial e usuario de campo aprovado/provisionado.
2. Validar fluxo real:
   - `POST /auth/login`
   - `GET /auth/me`
   - `POST /auth/refresh`
   - `POST /auth/logout`
3. Validar `GET /api/mobile/jobs` com sessao real:
   - `X-Tenant-Id`
   - `X-Actor-Id`
   - bearer JWT
4. Validar configuracao dinamica e sync mobile com contexto autenticado.
5. Registrar evidencias no runbook/backlogs corretos.

Regras de conflito:

- Nao editar arquivos fora do lock.
- Se precisar alterar contrato mobile, registre pedido de handoff em `HANDOFF_LOG.md` e pare naquela alteracao.
- Nao reverter commits, arquivos ou residuos de outra IA.
- Nao fazer rebase/amend/reset hard.

Ao final:

1. Rode testes relevantes da frente.
2. Commit pequeno e descritivo.
3. Atualize `HANDOFF_LOG.md` com:
   - commit
   - testes
   - impacto para mobile
   - pendencias
