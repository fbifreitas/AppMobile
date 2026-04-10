# Governanca Operacional - Indice

> [FONTE DE DESCOBERTA - GOVERNANCA]
> Este documento existe para reduzir ambiguidade. Ele nao e a fonte primaria das regras; ele aponta para a fonte correta de cada tipo de decisao operacional.

## Objetivo
Indicar, de forma curta e inequivoca, qual documento deve ser usado para cada tema de governanca operacional do repositorio.

## Uso Correto
1. Descobrir o tema da decisao.
2. Abrir o documento normativo correspondente.
3. Executar o processo naquele documento.
4. Registrar evidencias no documento de rastreabilidade apropriado.

## Matriz De Governanca

| Tema | Documento primario | Uso |
|---|---|---|
| Release, versionamento, PR, bypass, pos-merge | [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md) | executar release e promocao para `main` |
| Implantacao em VPS e publicacao em lojas | [IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md](C:\src\AppMobile\docs\05-operations\runbooks\IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md) | contratar, preparar, publicar e operar em ambiente real |
| Ambiente funcional de caixa preta | [AMBIENTE_FUNCIONAL_CAIXA_PRETA.md](C:\src\AppMobile\docs\05-operations\runbooks\AMBIENTE_FUNCIONAL_CAIXA_PRETA.md) | subir, validar e operar ambiente funcional para QA e teste ponta a ponta |
| Seguranca e hardening de producao | [SEGURANCA_E_HARDENING_PRODUCAO.md](C:\src\AppMobile\docs\05-operations\runbooks\SEGURANCA_E_HARDENING_PRODUCAO.md) | validar controles minimos de seguranca antes de produzir |
| Gestao de segredos e cofre | [GESTAO_DE_SEGREDOS_E_COFRE.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_SEGREDOS_E_COFRE.md) | provisionar, armazenar e revisar segredos por ambiente |
| Manual de uso do backoffice | [MANUAL_OPERACIONAL_BACKOFFICE.md](C:\src\AppMobile\docs\05-operations\manuals\MANUAL_OPERACIONAL_BACKOFFICE.md) | navegar e operar as telas do sistema |
| Fluxo QA ponta a ponta | [GUIA_QA_CAMINHO_FELIZ_END_TO_END.md](C:\src\AppMobile\docs\05-operations\manuals\GUIA_QA_CAMINHO_FELIZ_END_TO_END.md) | executar o caminho feliz do onboarding ao laudo final |
| Duas ou mais IAs no mesmo repositorio | [GOVERNANCA_MULTIAGENTE_REPOSITORIO.md](C:\src\AppMobile\docs\05-operations\runbooks\GOVERNANCA_MULTIAGENTE_REPOSITORIO.md) | coordenar ownership, locks, residuos e convivencia multiagente |
| Branches e worktrees | [GESTAO_DE_WORKTREES_E_BRANCHES.md](C:\src\AppMobile\docs\05-operations\runbooks\GESTAO_DE_WORKTREES_E_BRANCHES.md) | criar, usar, encerrar e limpar branches/worktrees com seguranca |
| Encoding e forma documental | [AGENT_OPERATING_SYSTEM.md](C:\src\AppMobile\docs\05-operations\AGENT_OPERATING_SYSTEM.md) | aplicar padrao de UTF-8, ASCII preferencial e evitar caracteres decorativos |
| Quando interromper e alinhar | [WHEN_TO_STOP_AND_ASK.md](C:\src\AppMobile\docs\05-operations\WHEN_TO_STOP_AND_ASK.md) | identificar stop conditions e pedir alinhamento |
| Rastreabilidade do ciclo atual | [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md) | registrar evidencias, checkpoints e encerramento |
| Aprendizados e recorrencias | [AGENTE_LICOES_APRENDIDAS.md](C:\src\AppMobile\docs\05-operations\agent-onboarding\AGENTE_LICOES_APRENDIDAS.md) | registrar licoes, nao ditar regra primaria |
| Ambiente local e restauracao | [PONTO_RESTAURACAO_AMBIENTE_LOCAL.md](C:\src\AppMobile\docs\05-operations\runbooks\PONTO_RESTAURACAO_AMBIENTE_LOCAL.md) | restaurar setup e ambiente de trabalho |
| Fonte de verdade por tema | [SOURCE_OF_TRUTH_MATRIX.md](C:\src\AppMobile\docs\05-operations\SOURCE_OF_TRUTH_MATRIX.md) | decidir qual documento manda em caso de duvida |

## Regras De Leitura
1. Nao usar `RESUMO_EXECUTIVO_CONTINUO` como runbook.
2. Nao usar `AGENTE_LICOES_APRENDIDAS` como fonte primaria de processo.
3. Nao usar backlog para aprender governanca.
4. Em caso de conflito, prevalece o runbook primario do tema.

## Ordem Recomendada De Consulta
1. [GOVERNANCA_INDEX.md](C:\src\AppMobile\docs\05-operations\GOVERNANCA_INDEX.md)
2. runbook primario do tema
3. `WHEN_TO_STOP_AND_ASK` se houver conflito, risco ou ambiguidade
4. `RESUMO_EXECUTIVO_CONTINUO` para evidencias do ciclo corrente
5. `AGENTE_LICOES_APRENDIDAS` para contexto historico e recorrencias

## Anti-Padroes
- abrir varios docs e inferir regra media entre eles
- tratar documento historico como documento normativo
- usar backlog como fonte de processo
- pular o runbook primario e operar por memoria
- Lancamento Compass como primeiro white label SaaS: `docs/05-operations/runbooks/LANCAMENTO_COMPASS_CAMINHO_CRITICO.md`
