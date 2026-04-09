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
- [RESUMO_EXECUTIVO_CONTINUO.md](C:\src\AppMobile\docs\05-operations\release-governance\RESUMO_EXECUTIVO_CONTINUO.md)
- [AGENTE_LICOES_APRENDIDAS.md](C:\src\AppMobile\docs\05-operations\agent-onboarding\AGENTE_LICOES_APRENDIDAS.md)
