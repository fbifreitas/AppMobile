# Guia Rapido De Onboarding De Agentes

> [FONTE DE ENTRADA - ONBOARDING]
> Este documento e a porta de entrada para novos agentes no repositorio. Ele organiza a leitura minima, aponta a fonte oficial por tema e evita que documentos historicos sejam usados como runbook.

## Objetivo
Permitir que um agente novo:
- entenda rapidamente a ordem correta de leitura
- encontre a fonte normativa certa para cada decisao operacional
- identifique o backlog correto da frente em que vai atuar
- saiba onde registrar evidencia e quando parar para alinhar

## Leitura Minima Obrigatoria
1. `README.md`
2. `GEMINI.md`
3. `.github/copilot-instructions.md`
4. [00_INDEX_GERAL.md](C:\src\AppMobile\docs\00-overview\00_INDEX_GERAL.md)
5. [01_OPERATING_MODEL.md](C:\src\AppMobile\docs\05-operations\01_OPERATING_MODEL.md)
6. [AGENT_OPERATING_SYSTEM.md](C:\src\AppMobile\docs\05-operations\AGENT_OPERATING_SYSTEM.md)
7. [GOVERNANCA_INDEX.md](C:\src\AppMobile\docs\05-operations\GOVERNANCA_INDEX.md)
8. [SOURCE_OF_TRUTH_MATRIX.md](C:\src\AppMobile\docs\05-operations\SOURCE_OF_TRUTH_MATRIX.md)
9. [DONE_CHECKLIST_BY_WORK_TYPE.md](C:\src\AppMobile\docs\05-operations\DONE_CHECKLIST_BY_WORK_TYPE.md)
10. [WHEN_TO_STOP_AND_ASK.md](C:\src\AppMobile\docs\05-operations\WHEN_TO_STOP_AND_ASK.md)

## Se A Tarefa For Operacional Ou De Release
Ler tambem:
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [GOVERNANCA_MULTIAGENTE_REPOSITORIO.md](C:\src\AppMobile\docs\05-operations\runbooks\GOVERNANCA_MULTIAGENTE_REPOSITORIO.md)
- [GESTAO_DE_WORKTREES_E_BRANCHES.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_WORKTREES_E_BRANCHES.md)

## Como Escolher O Backlog Correto
- Mobile e operacao do app: [BACKLOG_FUNCIONALIDADES.md](C:\src\AppMobile\docs\05-operations\tactical-backlogs\BACKLOG_FUNCIONALIDADES.md)
- Web e backoffice/plataforma: [BACKLOG_BACKOFFICE_WEB.md](C:\src\AppMobile\docs\05-operations\tactical-backlogs\BACKLOG_BACKOFFICE_WEB.md)
- Front web e experiencia operacional: [BACKLOG_FRONT_WEB.md](C:\src\AppMobile\docs\05-operations\tactical-backlogs\BACKLOG_FRONT_WEB.md)
- Integracao web-mobile-backend: [BACKLOG_INTEGRACAO_WEB_MOBILE.md](C:\src\AppMobile\docs\05-operations\tactical-backlogs\BACKLOG_INTEGRACAO_WEB_MOBILE.md)
- Prioridades V2 e fronteira estrategica: `docs/BACKLOG_V2_PRIORIDADES.md`

## Como Operar Sem Se Perder
1. Descobrir o tema da tarefa.
2. Abrir a fonte oficial pelo [GOVERNANCA_INDEX.md](C:\src\AppMobile\docs\05-operations\GOVERNANCA_INDEX.md) e pela [SOURCE_OF_TRUTH_MATRIX.md](C:\src\AppMobile\docs\05-operations\SOURCE_OF_TRUTH_MATRIX.md).
3. Confirmar o backlog correto da frente.
4. Executar no menor escopo possivel.
5. Validar conforme [DONE_CHECKLIST_BY_WORK_TYPE.md](C:\src\AppMobile\docs\05-operations\DONE_CHECKLIST_BY_WORK_TYPE.md).
6. Registrar evidencias e atualizar backlog/docs quando houver impacto.

## Onde Registrar Evidencia
- Ciclo de release, checkpoints e encerramento: [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md)
- Licoes aprendidas e recorrencias historicas: [AGENTE_LICOES_APRENDIDAS.md](C:\src\AppMobile\docs\05-operations\agent-onboarding\AGENTE_LICOES_APRENDIDAS.md)

## O Que Nao Usar Como Fonte Primaria
- `RESUMO_EXECUTIVO_CONTINUO.md` nao e runbook
- `AGENTE_LICOES_APRENDIDAS.md` nao e guia principal de onboarding
- backlog nao ensina governanca
- documento historico nao substitui runbook

## Quando Parar E Alinhar
Parar e consultar [WHEN_TO_STOP_AND_ASK.md](C:\src\AppMobile\docs\05-operations\WHEN_TO_STOP_AND_ASK.md) quando houver:
- conflito entre docs ativos
- duvida de ownership entre agentes
- risco de mexer em branch/worktree de outra IA
- necessidade de release, bypass ou hotfix
- mudanca sem backlog ou sem criterio de pronto

## Prompt Oficial Para Novo Agente

Use o texto abaixo para iniciar um novo agente neste repositorio:

```text
Assuma este repositorio como agente de desenvolvimento.

Antes de qualquer alteracao:
1. Localize a fonte oficial do tema da tarefa usando:
   - `docs/05-operations/agent-onboarding/GUIA_RAPIDO_ONBOARDING_AGENTES.md`
   - `docs/05-operations/GOVERNANCA_INDEX.md`
   - `docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md`

2. Leia apenas os documentos necessarios para a tarefa no menor conjunto possivel.
3. Descubra qual frente esta sendo afetada:
   - mobile
   - web/backoffice
   - integracao
   - arquitetura/engenharia
   - operacao/release

4. Confirme o backlog ou runbook correto antes de implementar.
5. Execute a mudanca no menor escopo possivel.
6. Rode os testes relevantes.
7. Atualize backlog e documentacao quando houver impacto.

Regras obrigatorias:
- Release, PR, versionamento e promocao para `main` seguem somente `docs/05-operations/runbooks/FLUXO_OFICIAL_DE_RELEASE.md`
- Multiagente, ownership de branch/worktree e locks de Git seguem somente:
  - `docs/05-operations/runbooks/GOVERNANCA_MULTIAGENTE_REPOSITORIO.md`
  - `docs/05-operations/runbooks/GESTAO_DE_WORKTREES_E_BRANCHES.md`
- Nao mexa em residuos, arquivos, worktrees ou branches de outra IA
- Em caso de conflito entre documentos, prevalece o runbook primario do tema
- Se houver risco, ambiguidade ou falta de criterio de pronto, siga `docs/05-operations/WHEN_TO_STOP_AND_ASK.md`
```
