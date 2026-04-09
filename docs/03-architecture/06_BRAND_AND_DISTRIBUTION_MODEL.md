# BRAND AND DISTRIBUTION MODEL

## Principle

A plataforma opera com **app por marca**, nao com um unico app multiempresa pesado como padrao.

## Porque

- reforca posicionamento comercial de marca
- reduz peso de runtime em aparelhos modestos
- simplifica UX e elimina branching excessivo no cliente final
- facilita publicacao separada em loja

## O que fica no build

- nome do app
- application id / bundle id
- app icon
- splash nativa
- Firebase / analytics por app
- assets principais da marca
- flavor e entrypoint

## O que pode ficar remoto

- textos de home e menus
- ordem de blocos leves
- feature flags de exposicao
- banners, avisos e copy operacional
- politicas parametrizaveis sem impacto nativo

## Rule

Se a mudanca afeta loja, identidade nativa ou integracao de distribuicao, ela pertence ao build/app e nao ao admin runtime.
