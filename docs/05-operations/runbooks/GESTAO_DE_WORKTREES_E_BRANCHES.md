# Gestao De Worktrees E Branches

> [FONTE OFICIAL - WORKTREES E BRANCHES]
> Este documento define como criar, usar, encerrar e limpar branches e worktrees sem perder codigo e sem degradar o estado do Git.

## Objetivo
Padronizar o uso de branches e worktrees no repositorio, reduzindo:
- perda de codigo
- locks em `.git`
- branches esquecidas
- worktrees presos a branches encerradas
- uso incorreto de `main`

## Escopo
Aplica-se a:
- branches tecnicas
- branches `release/*`
- branches `hotfix/*`
- worktrees auxiliares
- limpeza pos-ciclo

## Regras Mandatorias
1. Cada worktree auxiliar deve usar branch propria.
2. `main` nao deve ser usada como branch permanente em worktree auxiliar.
3. Nao apagar branch sem validar se existe codigo exclusivo fora de `main`.
4. Nao apagar branch em uso por worktree ativo.
5. Branch `release/*` e `hotfix/*` encerrada deve ser limpa apos o ciclo, salvo justificativa registrada.

## Tipos De Branch

### Branch tecnica
Exemplos:
- `codex/*`
- `claude/*`
- `feature/*`

Uso:
- implementacao
- validacao local
- testes de desenvolvimento

### Branch candidata
Exemplos:
- `release/vX.Y.Z+N`
- `homolog/*`

Uso:
- homologacao
- consolidacao do pacote
- PR para `main`

### Branch corretiva
Exemplo:
- `hotfix/*`

Uso:
- correcoes pontuais apos regressao em `main`

## Como Criar Branch Com Seguranca
1. Confirmar a branch base correta.
2. Confirmar que nao existe outra IA usando a mesma branch alvo.
3. Criar branch com nome coerente com o papel.
4. Registrar ownership quando o ciclo for sensivel.

Regra:
- branch tecnica nasce da base funcional correta
- hotfix nasce de `main`
- release nasce da branch tecnica pronta para corte

## Como Criar Worktree Com Seguranca
1. Criar branch propria para o worktree.
2. Criar o worktree apontando para essa branch.
3. Registrar o path e o dono operacional do worktree.
4. Evitar reuso de worktree antigo sem revisar o estado da branch.

Regra:
- worktree existe para isolar contexto, nao para compartilhar `main`

## O Que Nao Fazer Com Worktree
1. Nao usar `main` como branch de trabalho auxiliar permanente.
2. Nao esquecer worktree ativo apos encerrar o ciclo.
3. Nao apagar branch antes de remover o worktree correspondente.
4. Nao assumir que worktree em `.claude/` e descartavel.

## Como Saber Se O Codigo Esta Seguro Em `main`
Usar sempre a leitura de divergencia:
- `mergeada + x/0` = codigo seguro em `main`
- `x/y` com `y > 0` = existe codigo fora de `main`

Interpretacao:
1. `mergeada` significa que a ponta da branch esta alcancavel a partir de `main`
2. `x/0` significa que a branch nao carrega commits exclusivos
3. se houver commits exclusivos, a branch nao deve ser apagada sem decisao consciente

## Passo A Passo Para Encerrar Branch
1. Confirmar se a branch esta mergeada em `main`.
2. Confirmar a divergencia `main...branch`.
3. Confirmar se existe worktree ativo usando a branch.
4. Confirmar se existe necessidade operacional de mantela.
5. Se tudo estiver seguro:
   - remover branch local
   - remover branch remota, quando aplicavel
6. Registrar a limpeza no fechamento do ciclo, quando fizer parte de release/hotfix.

## Passo A Passo Para Encerrar Worktree
1. Confirmar se nao ha processo ativo usando o diretório.
2. Confirmar se a branch associada nao precisa mais existir.
3. Remover a worktree.
4. So depois considerar apagar a branch associada.

## Higiene Pos-Ciclo
Ao final de release ou hotfix:
1. listar branches `release/*`
2. listar branches `hotfix/*`
3. listar branches tecnicas do ciclo
4. listar worktrees ativos
5. validar quais estao mergeadas e sem commits exclusivos
6. remover apenas as comprovadamente seguras
7. registrar o que ficou aberto e por qual motivo

## Sinais De Problema
Interromper e diagnosticar quando houver:
1. `Permission denied` em `.git/index.lock`
2. `Permission denied` em `.git/refs/...lock`
3. branch ocupada por worktree
4. falha de `checkout` por branch em uso
5. impossibilidade de apagar branch que deveria estar livre

## Anti-Padroes
- usar `main` em worktree auxiliar por conveniencia
- apagar branch porque "ja parece antiga"
- ignorar commits exclusivos fora de `main`
- acumular `release/*` e `hotfix/*` encerradas sem limpeza
- confundir branch abandonada com branch segura para apagar

## Referencias
- [FLUXO_OFICIAL_DE_RELEASE.md](C:\src\AppMobile\docs\05-operations\runbooks\FLUXO_OFICIAL_DE_RELEASE.md)
- [GOVERNANCA_MULTIAGENTE_REPOSITORIO.md](C:\src\AppMobile\docs\05-operations\runbooks\GOVERNANCA_MULTIAGENTE_REPOSITORIO.md)
- [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md)
