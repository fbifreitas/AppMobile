# Legacy Migration Map Addendum - Platform V3

## Objetivo

Registrar a adaptacao documental da V3 sem criar colisao com a numeracao ativa do repositorio.

## Decisao de implantacao

O pacote documental externo apontava para:
- `09_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md`
- `10_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md`
- `11_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md`

No repositorio ativo, o `09` ja era a fonte oficial para onboarding white-label mobile:
- `09_WHITE_LABEL_ONBOARDING_STRATEGY.md`

Por isso, a implantacao correta ficou assim:
- `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md`
- `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md`
- `12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md`

## Justificativa

1. Evitar conflito com a fonte funcional ja ativa do onboarding mobile.
2. Preservar a taxonomia atual do repositorio.
3. Introduzir a separacao entre plataforma transversal e canal mobile sem reabrir ambiguidade.
4. Tratar o antigo `06_TENANT_AND_WHITE_LABEL_MODEL.md` como legado e nao como fonte viva.

## Estado final desejado

- `08_BRAND_AND_DISTRIBUTION_MODEL.md` governa o canal mobile white-label.
- `09_WHITE_LABEL_ONBOARDING_STRATEGY.md` governa onboarding mobile por marca/produto.
- `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md` governa tenant transversal e ecossistema de plataforma.
- `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md` governa fronteiras entre core, dominio e canais.
- `12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md` governa a leitura honesta da maturidade V3.

## Nota de legado

Qualquer referencia ao antigo `06_TENANT_AND_WHITE_LABEL_MODEL.md` deve ser lida como historica, de transicao ou de rastreabilidade.
