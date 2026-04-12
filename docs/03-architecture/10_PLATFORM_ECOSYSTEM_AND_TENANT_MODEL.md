# Platform Ecosystem and Tenant Model

> Fonte arquitetural para a V3 da plataforma como ecossistema multi-canal e multi-dominio.
> Este documento complementa o blueprint corporativo e nao substitui a estrategia de onboarding mobile nem o documento de branding/distribuicao do canal mobile.

## Objetivo

Definir a plataforma como ecossistema corporativo transversal, deixando explicito que:
- o app mobile white-label e apenas um canal;
- tenant e um conceito de plataforma, nao de canal isolado;
- brand e identidade de distribuicao, nao a definicao completa de isolamento;
- backend, web, integracoes, dados e observabilidade participam do mesmo modelo.

## Conceitos centrais

### Plataforma

Plataforma e o conjunto de capacidades compartilhadas e de dominio operadas de forma coerente, com identidade, dados, seguranca, observabilidade e canais de acesso.

Ela nao se resume ao app mobile, ao backoffice ou a um tenant especifico.

### Tenant

`Tenant` e a unidade organizacional e operacional isolavel da plataforma.

Na V3, tenant participa de:
- identidade
- autorizacao
- dados
- integracoes
- observabilidade
- configuracao de canais
- politicas de distribuicao
- capacidades habilitadas

Tenant nao e sinonimo de app.
Tenant tambem nao e sinonimo de brand visual.

### Brand

`Brand` e a identidade distribuida de um tenant ou de uma oferta operada por tenant.

Regra pratica:
- tenant define isolamento operacional e de plataforma;
- brand define identidade de distribuicao e experiencia;
- um tenant pode operar uma ou mais brands;
- uma brand nao substitui as regras de isolamento do tenant.

### Canal

`Canal` e a forma de acesso a capacidades da plataforma.

Exemplos no contexto atual:
- mobile white-label
- web/backoffice
- integracoes externas

Canal nao redefine o modelo de dados nem o core da plataforma. Ele consome e expoe capacidades conforme seu papel.

## Relacao entre tenant, brand e canal

```text
Plataforma
  -> Tenant
    -> capacidades habilitadas
    -> politicas e isolamento
    -> canais ativos
      -> mobile
      -> web/backoffice
      -> integracoes
    -> brands de distribuicao
```

Regras:
1. Tenant governa identidade, acesso, dados e observabilidade.
2. Brand governa apresentacao, distribuicao e experiencia.
3. Canal governa forma de interacao e limites operacionais.
4. Dominio governa semantica de negocio e contratos internos.

## Implicacoes para a implementacao

1. O mobile white-label deve continuar sendo tratado como canal especializado, nao como a definicao inteira da plataforma.
2. O backoffice/plataforma deve governar tenant, app, licenciamento, onboarding e operacao de forma transversal.
3. Integracoes devem herdar contexto minimo de tenant, actor e correlationId.
4. Onboarding por marca deve ser modular, mas subordinado ao modelo de tenant/app/canal da plataforma.

## Fronteira com outros documentos

- Plataforma corporativa e principios gerais: `01_CORPORATE_BLUEPRINT.md`
- Modelo canonico corporativo: `07_CORPORATE_CANONICAL_MODEL.md`
- Canal mobile white-label, branding e distribuicao: `08_BRAND_AND_DISTRIBUTION_MODEL.md`
- Onboarding white-label mobile: `09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Fronteiras entre capacidades e canais: `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md`
- Maturidade real da V3: `12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md`

## Decisao pratica para o projeto

O repositorio deve deixar de usar referencias ativas ao antigo `06_TENANT_AND_WHITE_LABEL_MODEL.md` como fonte vigente.

O caminho correto passa a ser:
- `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md` para tenant transversal e ecossistema de plataforma;
- `08_BRAND_AND_DISTRIBUTION_MODEL.md` para canal mobile white-label;
- `09_WHITE_LABEL_ONBOARDING_STRATEGY.md` para onboarding por marca/produto no mobile.
