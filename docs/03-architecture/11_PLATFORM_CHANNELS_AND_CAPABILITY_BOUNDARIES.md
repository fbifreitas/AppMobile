# Platform Channels and Capability Boundaries

> Fonte arquitetural para separar o que pertence ao core transversal, ao dominio e aos canais da plataforma.

## Objetivo

Definir o que pertence a:
- plataforma transversal
- dominios de negocio
- canais de acesso
- branding/white-label

E registrar o que nao pode variar apenas por decisao de canal ou de marca.

## Principio central

A plataforma e composta por capacidades transversais e capacidades de dominio, expostas por canais.

Portanto:
- canal nao define sozinho capability;
- brand nao redefine dominio;
- white-label nao pode quebrar o core;
- customizacao visual ou textual nao substitui modelagem de capability.

## Mapa de fronteiras

### Plataforma transversal

Pertence ao core/plataforma:
- identidade e autenticacao
- tenant, membership e autorizacao
- contratos canonicos
- observabilidade
- configuracao e politicas operacionais
- governanca de release e distribuicao
- licenciamento e app registry

### Dominio

Pertence ao dominio:
- semantica de negocio
- workflows especificos
- regras operacionais da jornada
- entidades e estados centrais do negocio

Exemplo atual:
- inspection continua definindo regras especificas do fluxo de vistoria

### Canal

Pertence ao canal:
- experiencia de uso
- composicao de telas
- distribuicao tecnica
- orquestracao de interacao
- constraints do dispositivo ou do browser

Exemplo:
- mobile governa permissoes nativas, captura, biometria e distribuicao por flavor
- web/backoffice governa paineis, formularios administrativos e operacao interna

### White-label

Pertence ao white-label:
- identidade visual
- copy por marca
- feature flags leves
- assets e distribuicao por app
- modularidade da jornada dentro dos limites do core

White-label nao deve:
- redefinir o modelo canonico
- quebrar segregacao por tenant
- introduzir contrato paralelo para o mesmo capability
- esconder dependencias de autenticacao, auditoria ou licenciamento

## Regras de desenho

1. Toda capacidade transversal deve existir de forma reutilizavel entre canais.
2. Toda especializacao de marca deve acontecer por configuracao, modulo ou composicao, nao por duplicacao descontrolada de core.
3. Todo canal deve respeitar o mesmo contexto minimo de tenant, actor e correlationId quando falar com a plataforma.
4. Nenhum dominio deve terceirizar sua semantica para naming de UI ou branding.

## Aplicacao pratica no estado atual

### Mobile white-label

Pode variar por marca:
- login gate
- onboarding
- tutorial
- termos
- copy
- assets

Nao pode variar por marca:
- integridade do contexto autenticado
- regras de contrato da API
- seguranca minima
- envelope de contexto
- governanca de tenant/app/licenca

### Backoffice/plataforma

Deve concentrar:
- tenant registry
- app registry por marca
- licenciamento
- pendencias de onboarding
- administracao de usuarios
- aprovacao operacional

### Integracao

Deve preservar:
- contratos versionados
- seguranca de pacote
- idempotencia
- observabilidade
- compatibilidade de canais

## Fronteira com os documentos oficiais

- Tenant/ecossistema de plataforma: `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md`
- Canal mobile white-label: `08_BRAND_AND_DISTRIBUTION_MODEL.md`
- Onboarding mobile por marca: `09_WHITE_LABEL_ONBOARDING_STRATEGY.md`
- Maturidade da V3: `12_PLATFORM_MATURITY_AND_ALIGNMENT_MATRIX.md`
