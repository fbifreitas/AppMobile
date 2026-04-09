# Fluxo Oficial de Release

> [FONTE OFICIAL - RELEASE E PUBLICACAO]
> Este documento e a fonte oficial do processo de release, versionamento, PR e promocao para `main`.
> Em caso de conflito interpretativo com checkpoints historicos, este runbook prevalece.

## Objetivo
Definir, de forma unica e operacional, como um pacote sai de branch tecnica, passa por homologacao e e promovido para `main` com rastreabilidade, gates claros e excecao controlada para mantenedor unico.

## Escopo
Aplica-se a:
- versionamento em `pubspec.yaml`
- branch tecnica
- branch `release/*` ou `homolog/*`
- esteiras `Android CI`, `Android Homologation`, `Android Distribution`
- PR para `main`
- bypass controlado de aprovacao minima

## Regras Mandatorias
1. Nao fazer push direto para `main` como caminho padrao.
2. Todo pacote Flutter que segue para release deve ter `version` incrementada em `pubspec.yaml`.
3. A branch candidata deve ser `release/*` ou `homolog/*`.
4. PR para `main` so pode ser aberta depois da homologacao verde da branch candidata.
5. Promocao para `main` so pode ocorrer com autorizacao explicita do usuario na mesma sessao.
6. Em fluxo de mantenedor unico, a excecao de aprovacao minima deve ser temporaria e restaurada imediatamente apos o merge.
7. Nao usar merge administrativo direto (`--admin`) como caminho padrao quando a excecao controlada estiver disponivel.
8. O ciclo so e considerado encerrado apos monitorar as esteiras pos-merge e confirmar a distribuicao esperada.

## Branches E Papeis
- Branch tecnica:
  - exemplo: `codex/*`, `claude/*`, `feature/*`
  - uso: implementacao e validacao local
- Branch candidata:
  - formato: `release/vX.Y.Z+N` ou `homolog/*`
  - uso: disparar homologacao e consolidar pacote candidato
- Branch protegida:
  - `main`
  - uso: somente codigo aprovado e promovido

## Regra De Versionamento
Arquivo fonte:
- [pubspec.yaml](C:\src\AppMobile\pubspec.yaml)

Formato:
- `semver+build`
- exemplo: `1.2.43+63`

Regras:
1. O valor deve ser incrementado antes do commit da branch candidata.
2. O bump faz parte do pacote de release; nao deixar para depois da homologacao.
3. Em novo pacote, a versao deve ser maior que a ultima promovida ou ultima candidata vigente.
4. Se `Android CI`, `Android Homologation` ou `Android Distribution` falharem por `Validate app version bump`, corrigir primeiro o `pubspec.yaml`.

## Sequencia Oficial Do Processo
1. Implementar e validar o pacote na branch tecnica.
2. Atualizar backlog e documentacao operacional da entrega.
3. Incrementar a versao em `pubspec.yaml`.
4. Criar a branch candidata `release/*` ou `homolog/*`.
5. Commitar e publicar a branch candidata.
6. Aguardar `Android Homologation` e demais gates da branch candidata.
7. Com homologacao verde, abrir PR da branch candidata para `main`.
8. Monitorar os checks da PR.
9. Com checks verdes e autorizacao explicita do usuario, promover para `main`.
10. Aplicar excecao controlada de aprovacao minima apenas no instante do merge, se necessario.
11. Restaurar imediatamente a protecao da `main`.
12. Monitorar esteiras pos-merge ate o estado esperado de distribuicao.
13. Equalizar os ambientes/branches operacionais quando aplicavel.
14. Registrar o encerramento no resumo executivo continuo.

## Passo A Passo Detalhado

### Cenario 1. Pacote normal partindo de branch tecnica
Usar quando:
- o pacote ainda esta em branch tecnica
- ainda nao existe branch `release/*` ou `homolog/*` aberta para o ciclo

Passos:
1. Implementar o pacote na branch tecnica.
2. Rodar as validacoes locais proporcionais ao stack alterado.
3. Atualizar backlog, runbooks e checkpoints operacionais do pacote.
4. Incrementar `version` em [pubspec.yaml](C:\src\AppMobile\pubspec.yaml).
5. Criar a branch candidata `release/vX.Y.Z+N` ou `homolog/*`.
6. Commitar o pacote completo, incluindo o bump de versao.
7. Publicar a branch candidata no remoto.
8. Aguardar `Android Homologation` e os demais gates da branch candidata.
9. So abrir PR para `main` depois da homologacao verde.
10. Monitorar os checks da PR.
11. Com autorizacao explicita do usuario, promover para `main`.
12. Restaurar imediatamente a protecao da `main` se houve bypass controlado.
13. Monitorar as esteiras pos-merge.
14. Equalizar ou encerrar a branch operacional.
15. Registrar o encerramento formal no resumo executivo.

### Cenario 2. Ajuste no pacote antes da homologacao verde
Usar quando:
- a branch `release/*` ou `homolog/*` ja existe
- a homologacao da branch candidata ainda nao ficou verde
- o ajuste faz parte do pacote em homologacao

Passos:
1. Confirmar que a mudanca faz parte do pacote funcional em homologacao.
2. Aplicar a mudanca na propria branch candidata.
3. Se a mudanca alterar o app Flutter, validar se o bump de versao continua coerente.
4. Commitar a correcao na branch candidata.
5. Fazer push da branch candidata.
6. Aceitar explicitamente que as esteiras da branch candidata vao rodar de novo.
7. Esperar nova rodada verde antes de abrir ou promover PR.

Regra:
- enquanto a branch candidata ainda nao estiver homologada, ajustes do proprio pacote podem continuar nela
- isso nao e desvio de processo; e a finalizacao normal da release

### Cenario 3. Mudanca documental depois que a branch candidata ficou verde
Usar quando:
- a branch candidata ja esta homologada
- a PR ja esta aberta ou pronta para abrir
- a mudanca e apenas documental ou administrativa

Passos:
1. Nao commitar `docs-only` na mesma branch `release/*` ou `homolog/*` ja verde, salvo decisao explicita de reabrir o ciclo.
2. Avaliar se a mudanca documental e:
   - evidencia obrigatoria do proprio pacote
   - ou melhoria geral de processo
3. Se for melhoria geral de processo, criar branch separada a partir de `main`.
4. Se o pacote ja estiver em PR, preferir:
   - esperar o merge do pacote principal
   - e depois abrir PR documental separada
5. Se a mudanca for obrigatoria para evidenciar o pacote antes do merge, aceitar conscientemente que a branch candidata sera alterada e que os checks vao rodar de novo.
6. Registrar no resumo executivo que a branch candidata foi reaberta por ajuste documental.

Regra:
- branch de release verde nao e lugar para melhoria documental tardia
- se empurrar commit novo para ela, a esteira completa pode rodar de novo

### Cenario 4. Mudanca documental depois da PR aberta e checks verdes
Usar quando:
- a PR ja esta tecnicamente pronta
- os checks ja estao verdes
- surgiu melhoria de documentacao, runbook, onboarding ou licao aprendida

Passos:
1. Nao adicionar esse commit na mesma branch da PR pronta, a menos que a intencao seja reabrir toda a rodada.
2. Se a PR ainda nao foi mergeada, manter o pacote como esta.
3. Abrir branch separada para a mudanca documental ou adiar para depois do merge.
4. Se a mudanca for urgente, abrir PR separada de docs.
5. Se a mudanca nao for urgente, aplicar direto no ciclo seguinte.

Regra:
- `docs-only` em branch de release pronta para merge e um gatilho desnecessario para rerun completo

### Cenario 5. Hotfix pos-merge em `main`
Usar quando:
- a release ja foi promovida
- uma regressao real apareceu em `main`

Passos:
1. Abrir branch de hotfix a partir de `main`.
2. Corrigir apenas o problema necessario para restaurar a esteira ou a operacao.
3. Se a stack Android for afetada pela regra de versao, incrementar `pubspec.yaml`.
4. Abrir PR da hotfix para `main`.
5. Esperar os checks da PR da hotfix.
6. Com autorizacao explicita do usuario, promover a hotfix para `main`.
7. Monitorar novamente as esteiras pos-merge ate estabilizar o ambiente.

Regra:
- hotfix pos-merge nao volta para a branch de release antiga
- a correcao nasce de `main` e retorna para `main`

## Regra Especifica Para Commits Docs-Only
Aplicar esta tabela antes de qualquer commit documental:

| Situacao | Branch correta | Pode usar a branch de release atual? | Efeito esperado |
|---|---|---|---|
| Documentacao faz parte do pacote e a release ainda nao ficou verde | `release/*` atual | sim | rerun normal da release |
| Documentacao e melhoria de processo e a release ja ficou verde | branch separada a partir de `main` | nao | evita rerun da release |
| PR ja esta aberta e checks verdes | branch separada ou depois do merge | nao | evita reabrir rodada pronta |
| Merge em `main` ja ocorreu | branch separada a partir de `main` | nao se a release antiga ainda existir | fluxo documental proprio |

Checklist rapido:
1. A mudanca altera produto entregue ou so documentacao?
2. A branch candidata ja ficou verde?
3. A PR ja esta aberta ou pronta para merge?
4. Existe motivo real para aceitar rerun completo?

Se a resposta for:
- `so documentacao`
- `sim`
- `sim`
- `nao`

Entao:
- nao commitar na branch candidata atual
- abrir branch separada

## Esteiras E Papel De Cada Uma

### Android CI
Arquivo:
- [android_ci.yml](C:\src\AppMobile\.github\workflows\android_ci.yml)

Quando roda:
- `push` em `main`
- `pull_request` para `main`
- manual

Objetivo:
- validar tecnicamente o app Android

Gates:
- valida `version` no `pubspec.yaml`
- `flutter analyze`
- `flutter test`
- build de `debug APK`

Leitura pratica:
- responde se o app esta tecnicamente valido para seguir

### Android Homologation
Arquivo:
- [android_homologation.yml](C:\src\AppMobile\.github\workflows\android_homologation.yml)

Quando roda:
- `push` em `main`
- `push` em `release/*`
- `push` em `homolog/*`
- `pull_request` para `main`
- manual

Objetivo:
- validar e distribuir o build candidato para QA/homologacao

Gates:
- `flutter analyze`
- `flutter test`
- build de `debug APK`
- upload de artefato de homologacao
- distribuicao para Firebase App Distribution no grupo `testers-internos`

Observacao:
- em `release/*`, o passo interno de version bump e ignorado por regra do workflow

Leitura pratica:
- responde se o pacote candidato chegou ao canal de homologacao

### Android Distribution
Arquivo:
- [android_distribution.yml](C:\src\AppMobile\.github\workflows\android_distribution.yml)

Quando roda automaticamente:
- apos `Android Homologation` verde
- somente quando o branch do evento e `main` ou `release/prod`

Objetivo:
- distribuir build no canal operacional de distribuicao

Destino:
- automatico: grupo `prod-testers`
- manual: grupo informado no dispatch

Leitura pratica:
- responde se o build foi de fato distribuido no canal operacional esperado

## Ordem Esperada Das Esteiras

### Antes Da PR
Na branch `release/*` ou `homolog/*`:
1. `Android Homologation`
2. `Internal Docs CI`
3. Demais esteiras do pacote conforme stack afetada

Regra:
- so abrir PR para `main` depois da branch candidata estar homologada

### Na PR Para Main
Na PR `release/* -> main`:
1. `Backend CI` quando houver backend
2. `Web CI` quando houver web
3. `Internal Docs CI`
4. `Android CI`
5. `Android Homologation` conforme gatilho de PR para `main`

Regra:
- a PR so pode ser promovida com os checks exigidos verdes

### Apos Merge Em Main
No `main`:
1. `Android CI`
2. `Backend CI`
3. `Web CI`
4. `Internal Docs CI`
5. `Backend Deploy`
6. `Web Deploy`
7. `Android Distribution` quando aplicavel

## Criterios Para Abrir PR
Todos os itens abaixo devem estar atendidos:
1. branch candidata publicada
2. `pubspec.yaml` incrementado
3. `Android Homologation` verde
4. documentacao e backlog atualizados
5. validacoes locais ou equivalentes executadas, com justificativa se algo nao rodou

## Criterios Para Promover Para Main
Todos os itens abaixo devem estar atendidos:
1. PR aberta da branch candidata para `main`
2. checks da PR verdes
3. autorizacao explicita do usuario na mesma sessao
4. estrategia de merge definida
5. excecao controlada preparada, se houver bloqueio por aprovacao minima

## Procedimento Oficial De Excecao Para Mantenedor Unico
Usar somente quando:
- a PR esta pronta para merge
- o unico bloqueio restante e a exigencia de aprovacao minima
- ha autorizacao explicita do usuario

Passos:
1. Ler a protecao atual da branch `main`.
2. Confirmar o valor vigente de `required_approving_review_count`.
3. Reduzir temporariamente `required_approving_review_count` para `0`.
4. Executar o merge normal da PR.
5. Restaurar imediatamente `required_approving_review_count` para `1` ou para o valor anterior.
6. Registrar evidencia do before/after e do merge no resumo executivo.

Regras:
- nao usar `--admin` como padrao
- nao deixar a branch `main` desprotegida apos o merge
- se o patch de protecao falhar, abortar a promocao e corrigir antes de prosseguir
- em chamadas `gh api`, usar `-F` para campos boolean/integer quando aplicavel

## Evidencias Minimas Obrigatorias
Registrar no resumo executivo continuo:
1. branch candidata
2. versao promovida
3. commit do pacote
4. status dos gates da branch candidata
5. URL da PR
6. confirmacao de autorizacao do usuario
7. ajuste temporario de protecao, se houver
8. commit de merge em `main`
9. status das esteiras pos-merge
10. confirmacao de distribuicao quando aplicavel
11. evidencias de equalizacao de ambiente/branch quando aplicavel

## Como Registrar O Fechamento Sem Ambiguidade
O encerramento do ciclo nao deve ser um texto livre curto. Ele deve ensinar e deixar prova suficiente para auditoria humana e para outras IAs repetirem o processo sem inferencia.

O fechamento no [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md) deve responder, explicitamente, a estas perguntas:
1. Qual foi a branch candidata promovida?
2. Qual versao foi promovida?
3. Qual foi o commit do pacote?
4. Qual foi a PR usada para promover?
5. Houve autorizacao explicita do usuario?
6. Qual era a protecao antes do bypass?
7. Qual foi a alteracao temporaria aplicada?
8. A protecao foi restaurada para qual valor?
9. Qual foi o commit de merge em `main`?
10. Quais esteiras pos-merge ficaram verdes?
11. Houve distribuicao? Qual esteira confirmou isso?
12. A branch operacional foi equalizada, encerrada ou mantida como historico?

Regra:
- se qualquer uma dessas respostas ficar implicita, o fechamento esta incompleto
- o objetivo nao e "resumir"; o objetivo e deixar o processo reexecutavel e auditavel

### Estrutura Obrigatoria Do Encerramento
Usar, nesta ordem logica:
1. identificacao do ciclo
2. evidencias de promocao
3. evidencias do bypass controlado
4. evidencias das esteiras pos-merge
5. equalizacao ou encerramento da branch operacional
6. conclusao formal

### O Que Nao Fazer No Encerramento
- nao escrever apenas "ciclo encerrado" sem evidencias
- nao escrever apenas "todas as esteiras verdes" sem citar quais
- nao escrever "protecao restaurada" sem informar o valor restaurado
- nao omitir a URL ou numero da PR
- nao omitir se houve autorizacao explicita do usuario
- nao omitir o destino da branch operacional apos o merge
- nao declarar "em producao" se o processo do time so confirmou merge e distribuicao

### Regra Para Tabelas De Encerramento
Se for usar tabela, ela deve ter no minimo estas linhas:
- branch candidata
- versao promovida
- commit do pacote
- PR
- merge commit
- protecao antes
- protecao durante bypass
- protecao restaurada
- Android CI pos-merge
- Android Homologation pos-merge
- Android Distribution pos-merge, quando aplicavel
- equalizacao/encerramento da branch operacional

Se qualquer uma dessas linhas faltar, a tabela nao e suficiente como registro final.

## Equalizacao De Ambiente Pos-Promocao
Objetivo:
- garantir que o ambiente operacional de homologacao/release nao fique divergente de `main` apos a promocao

Quando aplicar:
- sempre que houver branch persistente de homologacao
- sempre que o processo do time exigir comparacao explicita entre `main` e branch operacional
- sempre que houver risco de continuar trabalho em branch desatualizada apos o merge

Procedimento:
1. Confirmar que o merge em `main` foi concluido com sucesso.
2. Aguardar os checks pos-merge necessarios.
3. Atualizar a branch operacional por fast-forward a partir de `origin/main`, quando ela precisar permanecer ativa.
4. Validar divergencia final entre `origin/main` e a branch operacional.
5. Registrar no resumo executivo se o resultado ficou `0/0`, equivalente ou se a branch foi encerrada/removida.

Resultados aceitos:
- branch operacional equalizada com `origin/main`
- branch operacional encerrada/removida apos a promocao
- branch de release descartavel mantida apenas como historico, com decisao registrada

Observacao:
- para branches `release/*` descartaveis, a equalizacao pode ser substituida por encerramento formal da branch, desde que isso fique registrado
- para branches `homolog/*` persistentes, equalizacao explicita e o caminho preferencial

## Higiene Pos-Ciclo
Objetivo:
- impedir acumulacao de branches descartaveis
- evitar worktrees presos a branches ja encerradas
- reduzir locks e falhas de escrita em `.git`
- garantir que o encerramento do ciclo deixe o repositorio operacionalmente saudavel

Este bloco e obrigatorio depois de:
- merge em `main`
- esteiras pos-merge verdes
- distribuicao concluida, quando aplicavel

### Regras Mandatorias De Higiene
1. Branch `release/*` encerrada nao deve permanecer aberta por inercia.
2. Branch `hotfix/*` encerrada nao deve permanecer aberta por inercia.
3. Antes de apagar uma branch, validar que ela nao tem commits exclusivos fora de `main`.
4. Worktree auxiliar nao deve usar `main` como branch de trabalho permanente.
5. Toda worktree auxiliar deve usar branch propria ou ser removida ao fim do uso.
6. Se uma branch permanecer aberta por decisao operacional, o motivo deve ser registrado no encerramento.

### Passo A Passo De Higiene
1. Listar as branches locais relevantes:
   - `release/*`
   - `hotfix/*`
   - branches tecnicas do ciclo
2. Listar as branches remotas relevantes:
   - `origin/release/*`
   - `origin/hotfix/*`
3. Listar worktrees ativos.
4. Para cada branch candidata ou hotfix encerrada, validar:
   - se esta mergeada em `main`
   - se a divergencia contra `main` e `x/0`
5. Se a branch estiver mergeada e sem commits exclusivos, encerrar:
   - branch local
   - branch remota
6. Se houver worktree apontando para branch descartavel, remover a worktree antes de apagar a branch.
7. Se houver worktree usando `main`, registrar isso como excecao operacional e corrigir na primeira janela segura.
8. Registrar no encerramento:
   - quais branches foram removidas
   - quais branches permaneceram
   - quais worktrees permaneceram
   - por que permaneceram

### Criterio De Delecao Segura
Uma branch so pode ser considerada segura para remocao quando:
1. estiver mergeada em `main`
2. nao tiver commits exclusivos fora de `main`
3. nao estiver em uso por worktree ativo
4. nao houver necessidade operacional registrada para mantela

Leitura pratica:
- `mergeada + x/0` = codigo ja esta seguro em `main`
- `nao mergeada` ou `x/y` com `y > 0` = ainda existe codigo fora de `main`

### Anti-Padroes De Higiene
- deixar `release/*` antigas acumulando por meses
- deixar `hotfix/*` abertas apos merge em `main`
- usar `main` em worktree auxiliar por conveniencia
- apagar branch sem validar se ainda ha commits exclusivos
- assumir que "ciclo encerrado" implica limpeza automatica do Git

### Evidencia Minima De Higiene No Fechamento
O encerramento do ciclo deve informar explicitamente:
1. quais branches `release/*` e `hotfix/*` foram encerradas
2. quais branches permaneceram abertas e por qual motivo
3. quais worktrees estavam ativos no momento do fechamento
4. se algum worktree usava `main`
5. se houve equalizacao, encerramento ou manutencao por historico

## O Que Bloqueia O Processo
- `pubspec.yaml` sem bump quando o pacote exige versao nova
- `Android Homologation` falhando na branch candidata
- PR sem checks verdes
- ausencia de autorizacao explicita do usuario
- protecao da `main` alterada e nao restaurada

## Anti-Padroes Proibidos
- push direto em `main` como atalho
- abrir PR antes da homologacao da branch candidata
- promover para `main` sem autorizacao do usuario
- usar merge administrativo direto como rotina
- esquecer de restaurar `required_approving_review_count`
- tratar `RESUMO_EXECUTIVO_CONTINUO` como substituto deste runbook

## Matriz Rapida

| Workflow | Gatilho principal | Papel | Bloqueia o que |
|---|---|---|---|
| `Android CI` | `push/pr` em `main` | validacao tecnica Android | merge/promocao tecnica |
| `Android Homologation` | `push` em `release/*` / `homolog/*` | homologacao e distribuicao QA | abertura da PR e gate de release |
| `Android Distribution` | sucesso de `Android Homologation` em `main`/`release/prod` | distribuicao operacional | encerramento do ciclo |
| `Internal Docs CI` | `main`, `release/*`, `homolog/*` | validar docs operacionais | release com docs quebradas |
| `Backend CI` | PR / `main` | validar backend | merge tecnico |
| `Web CI` | PR / `main` | validar web | merge tecnico |

## Referencias Operacionais
- [PONTO_RESTAURACAO_AMBIENTE_LOCAL.md](C:\src\AppMobile\docs\05-operations\runbooks\PONTO_RESTAURACAO_AMBIENTE_LOCAL.md)
- [GOVERNANCA_MULTIAGENTE_REPOSITORIO.md](C:\src\AppMobile\docs\05-operations\runbooks\GOVERNANCA_MULTIAGENTE_REPOSITORIO.md)
- [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md)
- [AGENTE_LICOES_APRENDIDAS.md](C:\src\AppMobile\docs\05-operations\agent-onboarding\AGENTE_LICOES_APRENDIDAS.md)
