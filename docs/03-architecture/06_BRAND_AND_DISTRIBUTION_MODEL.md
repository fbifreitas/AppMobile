# Brand And Distribution Model - Nota Complementar

> Documento complementar e curto sobre a estrategia de app por marca.
> Nao e a fonte primaria da arquitetura transversal da plataforma.
> Nao substitui `08_BRAND_AND_DISTRIBUTION_MODEL.md`.

## Papel Deste Documento

Este arquivo existe apenas como nota arquitetural resumida para a tese de distribuicao por marca no canal mobile.

Use como fonte primaria:
- `08_BRAND_AND_DISTRIBUTION_MODEL.md` para branding e distribuicao do canal mobile white-label
- `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md` para tenant transversal e ecossistema de plataforma
- `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md` para fronteiras entre core, dominio e canais

## Principio

A plataforma opera com app por marca no canal mobile, nao com um unico app multiempresa pesado como padrao.

## Porque

- reforca posicionamento comercial de marca
- reduz peso de runtime em aparelhos modestos
- simplifica UX e elimina branching excessivo no cliente final
- facilita publicacao separada em loja

## O Que Fica No Build

- nome do app
- application id / bundle id
- app icon
- splash nativa
- Firebase e analytics por app
- assets principais da marca
- flavor e entrypoint

## O Que Pode Ficar Remoto

- textos de home e menus
- ordem de blocos leves
- feature flags de exposicao
- banners, avisos e copy operacional
- politicas parametrizaveis sem impacto nativo

## Regra

Se a mudanca afeta loja, identidade nativa ou integracao de distribuicao, ela pertence ao build/app e nao ao admin runtime.
