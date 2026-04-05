> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Resumo Executivo Continuo - Implantacao Homolog para Main

Atualizado em: 2026-04-01 (pos-merge PR #4)

## Objetivo
Consolidar o estado atual do desenvolvimento e da esteira para suportar a decisao de promocao da branch de homologacao para `main` com rastreabilidade.

## Snapshot tecnico da promocao
- PR promovida para `main`: https://github.com/fbifreitas/AppMobile/pull/4
- Commit de merge em `main`: `0b8c1c6be31167c1ef0c8cf774825a99509ab2e5`.
- Versao promovida no ciclo: `v1.2.21+40`.
- Protecao de branch `main`: excecao temporaria aplicada (aprovacao minima 0) e restaurada para 1 aprovacao apos merge.
- Estado da esteira pos-merge: `Android CI` sucesso e `Android Distribution` sucesso.

## Leitura executiva do codigo (escopo amplo)
Foi realizada varredura ampla da base Flutter para consolidacao arquitetural e riscos de release:
- Estrutura modular em `lib/models`, `lib/services`, `lib/screens`, `lib/state`, `lib/repositories`, `lib/widgets`.
- Fluxo principal consolidado: Login -> Check-in etapa 1 -> Check-in etapa 2 -> Camera -> Revisao -> Sync.
- Coordenacao de navegacao centralizada por `InspectionFlowCoordinator` e `AppNavigationCoordinator`, com foco em testabilidade.
- Configuracao dinamica de check-in/camera com prioridade de leitura mock -> API -> cache -> fallback.
- Suite de testes com foco em navegacao e regressao do fluxo critico (incluindo `test/screens/checkin_flow_navigation_test.dart`).

## Status de backlog para gate de promocao
- Criticos em andamento: BL-001, BL-012, BL-051, BL-052.
- Governanca de backlog em andamento: BL-049.
- Ja concluido com impacto direto no fluxo: BL-037, BL-038, BL-039, BL-040, BL-041, BL-042, BL-043, BL-044, BL-045, BL-046, BL-047, BL-048, BL-050.

## Gates obrigatorios antes de promover para main
1. Confirmar homologacao verde da branch candidata (`homolog/*` ou `release/*`).
2. Executar smoke Maestro USB no fluxo critico (login + navegacao principal + finalizacao).
3. Validar `flutter analyze` e `flutter test` sem regressao.
4. Confirmar incremento de versao no artefato que ira para `main`.
5. Abrir PR da branch homologada para `main` (sem push direto em `main`).

## Decisao operacional atual
- Promocao homolog -> main concluida no ciclo.
- Distribuicao Android disparada e concluida com sucesso no run `23863162292`.
- Pendencia operacional em acompanhamento: validar divergencia de recebimento de e-mail de distribuicao entre homolog e main/producao.

## Proxima atualizacao deste documento
Atualizar este arquivo sempre que ocorrer um destes eventos:
- nova branch candidata de homologacao,
- mudanca de versao em `pubspec.yaml`,
- aprovacao/reprovacao de smoke Maestro,
- merge aprovado em `main`.

## Checkpoint 2026-04-05 - Pacote release v1.2.28+48
- Branch de release: `release/v1.2.28+48`
- Branch tecnica de origem: `codex/cicd-esteira-alinhamento-20260405`
- Commit do pacote: `d96c6d2`
- Objetivo do pacote: alinhar esteira automatica CI/CD e restaurar portal interno ativo fora de `legacy`.

### Escopo implementado
- CI backend:
  - ajuste no `openapi-compatibility-gate` para nao falhar hard quando o OpenAPI current estiver indisponivel no run;
  - manutencao do gate semantico com fallback seguro.
- CI docs:
  - restauracao de `docs/internal-portal/*` na area ativa;
  - workflow `internal_docs_ci.yml` apontando novamente para `docs/internal-portal/mkdocs.yml`.
- Backend test:
  - alinhamento de asserts do `ConfigPackageControllerContractErrorTest` para mensagem canonica atual (`e obrigatorio`).
- Operacao:
  - procedimento anti-travamento adicionado em `AGENT_OPERATING_SYSTEM.md` (execucao serial, timeout explicito, preferencia por `--no-pub` e fallback para terminal nativo).
- Versionamento:
  - `pubspec.yaml` atualizado para `1.2.28+48`.

### Checkpoints operacionais
1. Codigo e docs atualizados no pacote.
2. Branch de release publicada para disparar `Android Homologation`.
3. Gate de homologacao aguardando conclusao para seguir com validacao de QA/smoke.
4. Promocao para `main` somente apos esteira verde e validacao de processo.


## Checkpoint 2026-04-05 - PACK-1 (MVP em 2 pacotes)
- Branch tecnica: codex/mvp-pack-1-20260405
- Objetivo: consolidar BL-056 em fluxo hibrido e manter base de BL-001/BL-012/INT-006/BOW-130 para fechamento do pacote funcional.
- Validacoes executadas no mobile: flutter analyze (sem issues) e flutter test (115 testes verdes).
- Resultado parcial: regra de gate de permissoes movida para AuthState (requiresPermissionsOnboarding) e aplicada no app entrypoint.
- Incremento tecnico do pacote: servicos mobile de checkin-config e sync cobertos com testes de headers obrigatorios (tenant/correlation/actor/api-version) e idempotency-key no uplink final.
- Correcao de esteira: workflow `internal_docs_ci.yml` ajustado para gerar `site_dir` fora de `docs_dir` (`../../build/internal-docs-site`), eliminando erro de build recursivo no MkDocs.


## Checkpoint 2026-04-05 - Release v1.2.29+49
- Branch de release: release/v1.2.29+49
- Origem: codex/mvp-pack-1-20260405
- Escopo: consolidacao PACK-1 (BL-056 + hardening de integracao BL-001/BL-012/INT-006) e correcao do Internal Docs CI.
- Gate de versao: pubspec.yaml incrementado para 1.2.29+49.

## Checkpoint 2026-04-05 - MVP Final Program (Checkpoint A)
- Branch tecnica: codex/mvp-final-program-20260405
- Objetivo: fechar lacuna do BOW-130 para permitir que secoes de check-in do mobile sejam publicadas via pacote de configuracao web e resolvidas pela API mobile.
- Escopo implementado:
  - backend: novo DTO `ConfigCheckinSectionRuleDto` e extensao de `ConfigRulesDto` com `checkinSections`;
  - backend: persistencia em `config_packages.checkin_sections_json` com migracao `V012__config_package_checkin_sections.sql`;
  - backend: `ConfigPackageService` atualizado para serializar/desserializar `checkinSections` e incluir no resolve efetivo;
  - mobile-api: `MobileCheckinConfigService` atualizado para priorizar secoes vindas de rules publicadas antes do fallback em repositorio local;
  - testes: novo caso de integracao `shouldResolveSectionsFromPublishedRulesBeforeRepositoryFallback`;
  - web-backoffice: painel de targeting com campo JSON para publicar `rules.checkinSections`.
- Validacao executada:
  - `mvn -q -Dtest=MobileCheckinConfigIntegrationTest,OpenApiContractIntegrationTest test` com sucesso.
- Pendencia conhecida:
  - validacao automatica do web-backoffice nao executada nesta maquina porque `npm` nao esta disponivel no PATH da sessao.
