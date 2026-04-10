# LANCAMENTO COMPASS - CAMINHO CRITICO

## Objetivo

Definir o menor conjunto viavel para colocar a Compass em producao usando o produto como SaaS, com app mobile por marca, licenciamento por usuario e sem depender do billing automatico na primeira entrada.

## Premissas

1. A Compass entra primeiro como tenant SaaS, nao como fork do produto.
2. O app da Compass convive com o app da Kaptu usando o mesmo motor.
3. A estrategia V3 adotada para marca e distribuicao e:
   - app por marca
   - branding nativo no build
   - runtime remoto apenas para ajustes leves
4. O billing automatico pode ficar fora do primeiro go-live.
5. O controle comercial minimo continua obrigatorio:
   - tenant ativo comercialmente
   - limite/licenca de usuarios governado
   - trilha de ativacao e go-live

## Leitura arquitetural aplicada

Fontes consideradas:
- `.tmp_docs_v3/docs_v3_package/docs/03-architecture/06_BRAND_AND_DISTRIBUTION_MODEL.md`
- `.tmp_docs_v3/docs_v3_package/docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
- `.tmp_docs_v3/docs_v3_package/docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`

Conclusao aplicada ao caso Compass:
1. Compass nao deve entrar como tenant dentro do mesmo app final da Kaptu.
2. Compass deve ter app proprio em loja, com:
   - nome
   - application id / bundle id
   - icone
   - splash
   - Firebase/analytics
   - flavor/entrypoint
3. O core continua compartilhado.
4. O white label inicial deve ser orientado a build/distribuicao, nao a customizacao runtime pesada.

## Escopo minimo de go-live

### Entra no MVP de producao

1. tenant Compass provisionado e ativado
2. admin inicial da Compass criado com handoff controlado
3. login web real para plataforma e backoffice
4. usuarios Compass criados/aprovados para operar
5. login mobile real com backend
6. primeiro acesso no app para usuario provisionado via backoffice
7. fluxo operacional completo:
   - case
   - job
   - inspection
   - valuation
   - report
8. configuracao operacional por tenant publicada via web
9. observabilidade minima via control tower
10. app Compass separado do app Kaptu no build/distribuicao
11. licenciamento SaaS por usuario com controle manual ou semiautomatico de seats
12. deploy e operacao minima de producao

### Fica explicitamente fora do primeiro go-live

1. billing automatico completo
2. CRM proprio
3. onboarding web externo self-serve
4. SSO enterprise
5. MFA obrigatorio completo
6. billing gateway/ERP
7. offboarding avancado
8. multi-parceiro financeiro

## Caminho critico recomendado

### Bloco 1 - Entrada administrativa e tenant Compass

Sem isso, nao existe operacao SaaS real.

Itens:
1. `BOW-152`
2. `BOW-153`
3. `BOW-154`
4. `BOW-155`
5. `FW-009`
6. `FW-010`
7. `FW-011`
8. `FW-016`
9. `INT-033`
10. `INT-034`
11. `INT-036`
12. `INT-037`

Gate:
1. Compass nasce como tenant governado
2. existe admin inicial
3. status comercial e operacional ficam visiveis
4. tenant pode ser ativado sem operacao manual escondida

### Bloco 2 - Entrada real de administradores e operadores

Sem isso, nem Kaptu nem Compass operam de forma segura.

Itens:
1. `BOW-176`
2. `FW-031`
3. `INT-053`
4. `BL-031`
5. `BL-056`
6. `BL-062`

Gate:
1. `PLATFORM_ADMIN` e `TENANT_ADMIN` entram pelo web com sessao real
2. operador Compass entra no app com autenticacao backend real
3. usuario criado pelo backoffice nao depende de auto-cadastro mobile

### Bloco 3 - Distribuicao por marca e app Compass

Este bloco vem direto da V3 e e obrigatorio para convivencia Compass/Kaptu.

Itens:
1. `BL-011`
2. `BL-068`
3. `BOW-177`
4. `FW-032`
5. `INT-054`

Gate:
1. app Compass tem build proprio
2. app Kaptu continua independente
3. identificadores nativos, assets e distribuicao nao dependem de gambiarra runtime

### Bloco 4 - Operacao SaaS minima por usuario

Sem billing automatico, mas com controle comercial minimo.

Itens:
1. `BOW-158`
2. `BOW-170`
3. `BOW-178`
4. `FW-018`
5. `FW-026`
6. `FW-033`
7. `INT-040`
8. `INT-048`
9. `INT-055`

Gate:
1. Compass possui plano/oferta SaaS por usuario
2. seats/licencas ficam visiveis
3. bloqueio comercial/licenciamento pode impedir crescimento irregular
4. faturamento automatico continua opcional para fase seguinte

### Bloco 5 - Fluxo operacional ponta a ponta

Esse e o fluxo que de fato prova o produto.

Itens minimos ja existentes ou em andamento:
1. `FW-001`
2. `FW-004`
3. `FW-005`
4. `FW-006`
5. `FW-007`
6. `BL-001`
7. `BL-012`
8. `BL-051`
9. `BL-052`
10. `INT-001`
11. `INT-004`
12. `INT-009`
13. `INT-018`

Gate:
1. Compass recebe configuracao operacional
2. operador executa vistoria no app Compass
3. web recebe inspection
4. valuation nasce
5. report e gerado
6. operacao acompanha pela control tower

### Bloco 6 - Go-live e producao

Sem isso, o produto ate funciona, mas nao entra em producao de verdade.

Itens:
1. `BOW-163`
2. `FW-020`
3. `INT-043`
4. documentacao de deploy e seguranca ja criada:
   - `docs/05-operations/runbooks/IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md`
   - `docs/05-operations/runbooks/SEGURANCA_E_HARDENING_PRODUCAO.md`
   - `docs/05-operations/runbooks/AMBIENTE_FUNCIONAL_CAIXA_PRETA.md`
   - `docs/05-operations/manuals/GUIA_QA_CAMINHO_FELIZ_END_TO_END.md`

Gate:
1. tenant Compass com go-live certificado
2. smoke funcional ponta a ponta verde
3. deploy e lojas preparados para marca Compass

## Itens novos necessarios para o caso Compass

### BOW-177 - Catalogo de aplicativos por marca e distribuicao white label

Objetivo:
- governar app por marca como capacidade de plataforma, sem transformar tenant em fork

Criterio de pronto:
- plataforma registra app/marca com nome, package ids, bundle ids e referencias de distribuicao
- tenant Compass e vinculado ao app Compass
- Kaptu e Compass coexistem sem compartilhar identidade nativa de distribuicao

### BOW-178 - Licenciamento SaaS por usuario com controle de seats

Objetivo:
- permitir operacao SaaS por usuario antes do billing automatico

Criterio de pronto:
- tenant possui quantidade de seats/licencas contratadas
- plataforma enxerga consumo atual e limite
- criacao/ativacao de usuarios respeita regra de seats
- bloqueio de excedente fica visivel e auditavel

### FW-032 - Painel de branding e distribuicao por aplicativo/marca

Objetivo:
- dar visibilidade operacional ao app Compass e sua distribuicao separada da Kaptu

Criterio de pronto:
- plataforma visualiza app por marca, identificadores nativos, status de distribuicao e tenant vinculado

### FW-033 - Painel de licenciamento SaaS por usuario

Objetivo:
- operar Compass por licenca de uso antes do billing automatico

Criterio de pronto:
- tenant mostra seats contratados, seats ocupados e bloqueios por excedente

### INT-054 - Contrato de identidade de aplicativo por marca

Objetivo:
- formalizar o vinculo canonico entre tenant, app/marca, distribuicao e configuracao de build

Criterio de pronto:
- appId, bundleId, flavor, firebase app e referencias de distribuicao ficam versionados e auditaveis

### INT-055 - Contrato de licenciamento SaaS por usuario

Objetivo:
- formalizar seats, consumo e bloqueio operacional sem depender do billing automatico

Criterio de pronto:
- plataforma e web consomem limite/licenca por usuario por contrato canonico

### BL-068 - Aplicativo Compass por flavor/marca com identidade nativa propria

Objetivo:
- materializar a regra V3 de app por marca para a Compass

Criterio de pronto:
- app Compass possui entrypoint, nome, icone, splash, application id/bundle id e referencia de distribuicao proprios
- app Kaptu continua operando com o mesmo core sem fork do dominio

## Pacotes grandes executaveis por frente

## Pacote A - Plataforma SaaS Compass

### Frente
- backend
- backoffice administrativo
- governanca comercial do tenant

### Objetivo

Fechar a entrada da Compass como tenant SaaS governado, com admin inicial, estados comercial/operacional, login web real e licenciamento por usuario.

### Itens

#### Backoffice / plataforma
1. `BOW-152`
2. `BOW-153`
3. `BOW-154`
4. `BOW-158`
5. `BOW-176`
6. `BOW-177`
7. `BOW-178`

#### Web / backoffice
1. `FW-009`
2. `FW-010`
3. `FW-011`
4. `FW-016`
5. `FW-031`
6. `FW-032`
7. `FW-033`

#### Integracao / contratos
1. `INT-033`
2. `INT-034`
3. `INT-036`
4. `INT-037`
5. `INT-040`
6. `INT-053`
7. `INT-054`
8. `INT-055`

### Gate de saida
1. Compass existe como tenant governado
2. ha admin inicial e handoff controlado
3. login web real funciona para plataforma e backoffice
4. app/marca Compass fica registrado separadamente da Kaptu
5. seats/licencas por usuario ficam visiveis e governados

### Dependencia
- este pacote nao depende do mobile para avancar
- este pacote e a base para o go-live, mas sozinho nao prova operacao de campo

## Pacote B - Mobile Compass Brand Build

### Frente
- mobile
- distribuicao
- branding nativo

### Objetivo

Materializar o app Compass como app por marca, separado da Kaptu, com autenticacao real e primeiro acesso para usuario provisionado.

### Itens

#### Mobile
1. `BL-011`
2. `BL-031`
3. `BL-056`
4. `BL-062`
5. `BL-068`

### Gate de saida
1. existe build Compass separado do build Kaptu
2. login mobile usa backend real
3. usuario provisionado pelo backoffice entra sem auto-cadastro indevido
4. onboarding de permissoes e primeiro acesso residual ficam fechados

### Nota 2026-04-10 - Login mobile Compass

- O login backend-first do app mobile deve ser ativado no build Compass com `--dart-define=APP_API_BASE_URL=<backend>` e `--dart-define=APP_TENANT_ID=tenant-compass`.
- Sem `APP_API_BASE_URL`, o app preserva o fluxo mock local para desenvolvimento, mas isso nao satisfaz o gate de homologacao do Pacote B.
- O primeiro acesso de usuario provisionado pelo backoffice deve autenticar no backend e, se ainda nao tiver permissao/onboarding concluido, cair na tela dedicada de permissoes antes da Home.
- As chamadas operacionais de configuracao dinamica e sincronizacao de vistoria devem usar o tenant, ator e bearer token da sessao autenticada; `APP_API_TOKEN` fica restrito a fallback tecnico/diagnostico.
- O CI Android e a homologacao devem compilar `kaptur` e `compass` com entrypoints explicitos; o artefato Compass usa `COMPASS_APP_API_BASE_URL` e `APP_TENANT_ID=tenant-compass` para validar build separado.

### Dependencia
- depende do `Pacote A` para:
  - login real
  - tenant Compass
  - admin e usuarios provisionados
  - contrato de app/marca

## Pacote C - Operacao Fim A Fim Compass

### Frente
- web operacional
- backend operacional
- integracao mobile-web

### Objetivo

Garantir que o tenant Compass consiga operar o fluxo de negocio completo ate o laudo, com configuracao, ingestao, valuation, report e control tower.

### Itens

#### Web / backoffice operacional
1. `FW-001`
2. `FW-004`
3. `FW-005`
4. `FW-006`
5. `FW-007`

#### Mobile operacional
1. `BL-001`
2. `BL-012`
3. `BL-051`
4. `BL-052`

#### Integracao
1. `INT-001`
2. `INT-004`
3. `INT-009`
4. `INT-018`

### Gate de saida
1. Compass publica configuracao operacional por tenant
2. operador executa vistoria no app Compass
3. web recebe a inspection
4. valuation e report funcionam
5. a operacao acompanha saude e rastreabilidade na control tower

### Nota 2026-04-10 - Preparacao web/backend sem mobile

- O primeiro recorte permitido apos `Pacote A`, sem tocar em mobile, e a publicacao de configuracao operacional por tenant no backoffice.
- Para Compass, as rotas web de configuracao devem operar com sessao real do backoffice e tenant derivado do login/handoff, nao por `tenantId`/`actorRole` confiados do cliente.
- A validacao de campo real permanece dependente do `Pacote B`, mas a governanca web do tenant ja pode ser endurecida antes disso.

### Dependencia
- depende do `Pacote A` para tenant, usuarios, licenciamento e auth web
- depende do `Pacote B` para o app Compass real em campo

## Pacote D - Go-Live e Implantacao Compass

### Frente
- operacao
- QA
- producao
- lojas

### Objetivo

Fechar a passagem de homolog para producao da Compass com smoke, documentacao, deploy, loja e criterios formais de go-live.

### Itens

#### Plataforma / governanca
1. `BOW-163`

#### Web
1. `FW-020`

#### Integracao
1. `INT-043`

#### Runbooks obrigatorios
1. `docs/05-operations/runbooks/IMPLANTACAO_VPS_E_PUBLICACAO_LOJAS.md`
2. `docs/05-operations/runbooks/SEGURANCA_E_HARDENING_PRODUCAO.md`
3. `docs/05-operations/runbooks/AMBIENTE_FUNCIONAL_CAIXA_PRETA.md`
4. `docs/05-operations/manuals/GUIA_QA_CAMINHO_FELIZ_END_TO_END.md`

### Gate de saida
1. Compass possui go-live certificado
2. smoke funcional ponta a ponta esta verde
3. ambiente e lojas estao preparados para a marca Compass

### Dependencia
- depende de `Pacote A`
- depende de `Pacote B`
- depende de `Pacote C`

## Sequencia executiva recomendada

1. `Pacote A` primeiro
2. `Pacote B` em paralelo assim que o contrato de app/marca do `Pacote A` estiver estabilizado
3. `Pacote C` quando `Pacote A` estiver funcional e o `Pacote B` ja tiver build utilizavel
4. `Pacote D` por ultimo, como gate final de producao

## Leitura para sua estrategia de implantacao

### Pode andar em paralelo ao mobile
1. tenant Compass e governanca comercial
2. login web/backoffice
3. catalogo de app por marca
4. seats/licenciamento por usuario
5. configuracao inicial do tenant
6. workspace comercial e administrativo da Compass

### Depende diretamente do mobile
1. flavor/app Compass
2. login mobile real
3. primeiro acesso de usuario provisionado
4. vistoria ponta a ponta no app Compass
5. validacao final de go-live em campo

## Priorizacao executiva consolidada

### M0 - Viabilizar Compass como produto SaaS operavel
1. `Pacote A`
2. `Pacote B`

### M1 - Provar operacao ponta a ponta
1. `Pacote C`

### M2 - Entrar em producao formalmente
1. `Pacote D`

## Decisao pratica recomendada

Para a Compass, o minimo viavel de producao nao e:
- white label runtime completo
- billing automatico
- CRM

O minimo viavel correto e:
1. app Compass separado por marca
2. tenant Compass governado
3. login real web/mobile
4. seat licensing basico por usuario
5. fluxo operacional fim a fim
6. go-live auditavel
