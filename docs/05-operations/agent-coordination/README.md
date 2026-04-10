# Coordinacao Multiagente - Compass

Este diretorio registra o estado operacional de agentes trabalhando em paralelo no projeto Compass.

Uso obrigatorio antes de qualquer alteracao:

1. Ler `ACTIVE_AGENTS.md`.
2. Ler `LOCKS.md`.
3. Ler `HANDOFF_LOG.md`.
4. Declarar ou atualizar lock antes de editar.
5. Editar somente arquivos cobertos pelo lock.
6. Registrar handoff quando precisar tocar outra frente.
7. Ao concluir, atualizar `HANDOFF_LOG.md` com commits, testes e pendencias.

Runbooks superiores:

- `docs/05-operations/runbooks/GOVERNANCA_MULTIAGENTE_REPOSITORIO.md`
- `docs/05-operations/runbooks/GESTAO_DE_WORKTREES_E_BRANCHES.md`
- `docs/05-operations/runbooks/FLUXO_OFICIAL_DE_RELEASE.md`

Arquivos proibidos neste ciclo:

- `.claude/`
- `.tmp_docs_v3/`
- `apps/backend/target2/`
- `apps/web-backoffice/test/config_page.test.tsx`
- `fix_mcp.py`
- `mcp-test.txt`
