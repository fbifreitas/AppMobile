# Governanca Multiagente No Repositorio

> [FONTE OFICIAL - GOVERNANCA MULTIAGENTE]
> Este documento define como duas ou mais IAs podem operar no mesmo repositorio sem perder codigo, sem corromper estado de Git e sem interferir em ciclos de release.

## Objetivo
Definir regras praticas de convivencia entre agentes no mesmo repositorio, com foco em:
- ownership de branch
- ownership de worktree
- seguranca de codigo
- locks de `.git`
- coordenacao durante release, hotfix e limpeza pos-ciclo

## Escopo
Aplica-se a:
- branches tecnicas
- branches `release/*`
- branches `hotfix/*`
- worktrees auxiliares
- residuos locais da outra IA
- operacoes Git que possam afetar o trabalho de outro agente

## Principios
1. Nao perder codigo e mais importante do que limpar branch.
2. Nao assumir que arquivo, branch ou worktree "parado" esta abandonado.
3. Cada agente deve ter ownership claro sobre sua branch e seu worktree.
4. Locks em `.git` devem ser tratados como sinal de coordenacao, nao como lixo automatico.
5. Em release ou hotfix, o agente responsavel pela promocao tem prioridade operacional sobre escrita no Git.

## Modelo Operacional Recomendado

### Regra 1. Uma IA por branch de trabalho
Cada agente deve trabalhar em branch propria.

Exemplos validos:
- `codex/*`
- `claude/*`
- `feature/*`
- `hotfix/*`

Nao usar:
- duas IAs fazendo commit na mesma branch tecnica
- duas IAs alterando a mesma branch `release/*` sem coordenacao explicita

### Regra 2. Uma IA por worktree
Cada worktree auxiliar deve ter um unico dono operacional.

Regras:
1. worktree auxiliar deve usar branch propria
2. worktree auxiliar nao deve usar `main` como branch permanente
3. a branch associada ao worktree nao deve ser apagada enquanto o worktree existir
4. o worktree deve ser removido ou encerrado ao fim do uso

### Regra 3. `main` e branch protegida
`main` nao e branch de colaboracao entre agentes.

Regras:
1. nao usar `main` para desenvolvimento corrente
2. nao usar `main` em worktree auxiliar como conveniencia
3. promocao para `main` segue o runbook oficial de release

Referencia:
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)

## Ownership Obrigatorio
Antes de comecar trabalho relevante, cada agente deve saber:
1. qual branch e sua
2. qual worktree e seu, se existir
3. se existe outra IA em release/hotfix
4. se existe branch compartilhada em estado sensivel

### Branches de release e hotfix
Branches `release/*` e `hotfix/*` devem ter dono operacional explicito.

Regras:
1. uma unica IA conduz a promocao por vez
2. outra IA nao deve fazer `commit`, `push`, `checkout`, `merge` ou limpeza nessas branches sem alinhamento
3. mudanca documental tardia nao entra em branch de release pronta, salvo decisao consciente de reabrir o ciclo

## Regras De Seguranca No Workspace

### Nao mexer no que nao e seu
Sem autorizacao explicita:
1. nao apagar residuos da outra IA
2. nao limpar `.claude`
3. nao apagar worktree que nao foi aberto por voce
4. nao reverter arquivo alterado pela outra IA
5. nao matar processo sem identificar se ele pertence ao outro agente

### Residuos e artefatos
Arquivos nao rastreados ou auxiliares podem ser parte do fluxo da outra IA.

Regra:
- se nao estiver claro que o artefato e descartavel, preservar

Exemplos de artefatos que podem exigir preservacao:
- `.claude/`
- worktrees auxiliares
- scripts temporarios de depuracao
- arquivos de teste nao rastreados

## Regras Para Locks De Git

### Como interpretar lock
Lock em `.git` pode significar:
1. outro agente fazendo `checkout`, `commit`, `merge` ou `push`
2. worktree ativo usando a branch
3. ACL/permissao quebrada
4. lock residual de processo encerrado

Regra:
- nao assumir automaticamente que `index.lock` ou `refs/...lock` pode ser removido

### Como agir diante de lock
1. confirmar se outra IA esta usando Git no repositorio
2. verificar worktrees ativos
3. verificar branch atual do workspace e das worktrees
4. so remover lock residual quando houver certeza de que nao existe processo Git legitimo rodando

### Sinais de escalacao
Parar e alinhar com o outro agente quando houver:
1. `Permission denied` em `.git/index.lock`
2. `Permission denied` em `.git/refs/...lock`
3. branch em uso por worktree
4. falha de `checkout` por branch ocupada
5. ACL estranha ou `Deny` no subtree `.git`

## Coordenacao Durante Release E Hotfix

### Prioridade operacional
Se houver uma release ou hotfix em promocao:
1. a IA responsavel pela promocao tem prioridade sobre escrita no Git
2. a outra IA evita operacoes de branch, merge, push e limpeza estrutural
3. a outra IA pode continuar em implementacao local desde que nao dispute o mesmo estado de Git

### O que a outra IA nao deve fazer durante promocao
1. criar ou apagar branches no mesmo repositorio sem alinhamento
2. commitar em branch de release pronta
3. alterar protecao de branch
4. mexer em worktree ligado ao ciclo em promocao
5. tentar "destravar" `.git` sem diagnostico

## Regra Para Mudancas Docs-Only
Mudancas documentais em ambiente multiagente exigem cuidado adicional porque podem parecer pequenas, mas podem reabrir esteiras inteiras.

Regras:
1. `docs-only` em branch `release/*` ja verde nao entra por reflexo
2. se a PR ja estiver pronta, usar branch documental separada ou adiar para depois do merge
3. so alterar a branch candidata se houver decisao consciente de rerun do ciclo

Referencia:
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)

## Higiene Multiagente Pos-Ciclo
Ao final de release/hotfix:
1. listar branches locais e remotas relevantes
2. listar worktrees ativos
3. validar quais branches estao mergeadas em `main`
4. validar se ha commits exclusivos fora de `main`
5. apagar apenas o que estiver comprovadamente seguro
6. registrar o que ficou aberto e por qual motivo

### Criterio de remocao segura
Uma branch so pode ser removida quando:
1. estiver mergeada em `main`
2. nao tiver commits exclusivos fora de `main`
3. nao estiver em uso por worktree
4. nao tiver dono operacional ativo

Leitura pratica:
- `mergeada + x/0` = codigo seguro em `main`
- `x/y` com `y > 0` = existe codigo fora de `main`

## Quando Parar E Perguntar
Interromper a execucao e alinhar com o outro agente quando ocorrer:
1. arquivo inesperadamente alterado por outra pessoa/IA
2. branch atual nao e a esperada
3. worktree desconhecido aparece no repo
4. lock em `.git` persiste sem causa clara
5. release/hotfix ativa entra em conflito com sua operacao
6. limpeza de branch pode atingir codigo ainda nao mergeado

## Checklist Rapido Antes De Operar
1. Qual e a minha branch?
2. Existe outra IA em release ou hotfix?
3. Existe worktree ativo ligado ao meu fluxo?
4. Vou mexer em algo que nao e meu?
5. Existe risco de rerun de esteira por causa do meu commit?
6. Existe risco de apagar branch com codigo fora de `main`?

Se qualquer resposta estiver incerta:
- parar
- diagnosticar
- alinhar

## Anti-Padroes Proibidos
- duas IAs commitarando na mesma branch tecnica
- usar `main` como branch normal de worktree auxiliar
- apagar `.claude` por limpeza automatica
- apagar branch so porque "parece antiga"
- remover lock de `.git` sem diagnostico
- empurrar `docs-only` em release pronta sem aceitar rerun
- matar processo da outra IA por conveniencia

## Evidencia Minima Em Encerramentos
Quando o ciclo envolver mais de uma IA, o fechamento deve registrar:
1. qual agente ficou com a promocao
2. quais branches foram usadas por cada agente
3. quais worktrees permaneceram ativos
4. quais branches foram encerradas
5. quais branches permaneceram abertas e por qual motivo

## Referencias
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [WHEN_TO_STOP_AND_ASK.md](C:\src\AppMobile\docs\05-operations\WHEN_TO_STOP_AND_ASK.md)
- [AGENTE_LICOES_APRENDIDAS.md](C:\src\AppMobile\docs\05-operations\agent-onboarding\AGENTE_LICOES_APRENDIDAS.md)
- [SOURCE_OF_TRUTH_MATRIX.md](C:\src\AppMobile\docs\05-operations\SOURCE_OF_TRUTH_MATRIX.md)
