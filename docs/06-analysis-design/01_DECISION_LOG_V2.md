# DECISION LOG V2

> Ponte ativa para as decisoes estruturais da V2.
> Este arquivo existe para manter estabilidade dos ponteiros documentais ainda ativos no repositorio.

## Como Usar

Use em conjunto com:
- `01_DECISION_LOG.md` para as decisoes correntes do recorte multi-brand/mobile
- `../99-legacy/DECISION_LOG_V2.md` para o snapshot historico das decisoes estruturais originais da V2

## Escopo Ativo

As decisoes V2 que continuam valendo para a arquitetura ativa sao:

1. A plataforma deixa de ser documentada como solucao vertical unica de vistoria e passa a ser documentada como plataforma multi-dominio.
2. Inspection continua como primeiro domain pack estrategico.
3. Existe um blueprint corporativo acima dos blueprints de dominio.
4. O modelo canonico global e corporativo e neutro; o fluxo especifico de inspection permanece como especializacao do dominio.
5. Tenant e white-label sao capacidades estruturais do core/plataforma.
6. Documentacao antiga relevante deve ser arquivada como legado, nao removida silenciosamente.

## Fonte Historica

O snapshot historico dessas decisoes permanece em:
- `../99-legacy/DECISION_LOG_V2.md`

## Regra De Precedencia

Se houver conflito:
1. `01_CORPORATE_BLUEPRINT.md` e `07_CORPORATE_CANONICAL_MODEL.md` mandam sobre a arquitetura corporativa.
2. `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md`, `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md` e `12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md` refinam a leitura atual da V3.
3. `08_BRAND_AND_DISTRIBUTION_MODEL.md` governa apenas o canal mobile white-label.
