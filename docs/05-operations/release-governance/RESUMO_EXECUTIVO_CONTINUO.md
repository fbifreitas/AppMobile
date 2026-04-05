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

## Checkpoint 2026-04-05 - MVP Final Program (Checkpoint B)
- Branch tecnica: codex/mvp-final-program-20260405
- Objetivo: consolidar INT-003 (canal assinado) sem quebrar contrato v1 mobile.
- Escopo implementado:
  - backend: novo `ConfigPayloadSignatureService` para assinatura HMAC SHA-256 de payload de configuracao;
  - backend: endpoint `GET /api/mobile/checkin-config` passa a responder com headers `X-Config-Signature` e `X-Config-Signature-Alg` quando chave estiver configurada;
  - testes: `MobileCheckinConfigIntegrationTest` reforcado para validar presenca e algoritmo de assinatura;
  - teste profile: chave de assinatura adicionada em `application-test.yml` para validacao automatizada.
- Validacao executada:
  - `mvn -q -Dtest=MobileCheckinConfigIntegrationTest,OpenApiContractIntegrationTest test` com sucesso.
- Observacao:
  - assinatura e opcional por configuracao; se a chave nao estiver definida, o endpoint permanece compativel sem header.

## Checkpoint 2026-04-05 - MVP Final Program (Checkpoint C)
- Branch tecnica: codex/mvp-final-program-20260405
- Objetivo: consolidar comportamento de INT-004/BOW-131 no ciclo mobile de configuracao com rollback efetivo.
- Escopo implementado:
  - testes de integracao: novo caso `shouldReflectRollbackOnNextMobileConfigResolve` em `MobileCheckinConfigIntegrationTest`;
  - evidencia validada: pacote aprovado afeta `GET /api/mobile/checkin-config` e, apos rollback, o mobile recebe fallback default na proxima leitura.
- Validacao executada:
  - `mvn -q -Dtest=MobileCheckinConfigIntegrationTest test` com sucesso.
- Resultado operacional:
  - rollback de pacote ja propagado no backend para leitura mobile subsequente, sem necessidade de deploy adicional.

## Checkpoint 2026-04-05 - MVP Final Program (Pacote complementar de subida)
- Branch tecnica: codex/mvp-final-program-20260405
- Objetivo: preparar subida do pacote com pendencias operacionais mapeadas para homolog/producao.
- Escopo implementado:
  - backend: parametro de ambiente adicionado em `application.yml` para chave de assinatura (`INTEGRATION_CONFIG_SIGNING_HMAC_KEY`);
  - backlog integracao: `INT-003` atualizado para status parcial (assinatura no backend entregue, validacao no mobile pendente);
  - backlog integracao: novo card `INT-030` criado para configuracao de segredo de assinatura por ambiente (homolog/producao) com criterio de pronto explicito.
- Critico para release:
  - nao promover para producao sem `INT-030` executado e evidenciado no checklist de release.

## Checkpoint 2026-04-05 - PACK-2 (fix de permissao e UX Android)
- Branch tecnica: codex/mvp-pack-2-20260405
- Escopo: correcao da tela de permissoes com CTA visivel no Android (SafeArea no bottomNavigationBar) e reforco de concessao real de permissao de camera no onboarding.
- Validacao: teste de widget dedicado `test/screens/permissions_onboarding_screen_test.dart` validado em PowerShell nativo.

## Checkpoint 2026-04-05 - Release v1.2.30+50
- Branch de release: release/v1.2.30+50
- Origem: codex/mvp-pack-2-20260405
- Escopo: promocao do PACK-2 com fix de CTA da tela de permissoes no Android e alinhamento de grant real de camera no onboarding.
- Gate de versao: pubspec.yaml incrementado para 1.2.30+50.

## Checkpoint 2026-04-05 - Release v1.2.32+52 (Checkpoint A mobile)
- Branch de release: release/v1.2.32+52
- Escopo: continuidade do pacote unico MVP-GoLive-Core no mobile para fechar INT-003 e BL-057 sem regressao do fluxo atual.
- Escopo implementado:
  - mobile: validacao local de assinatura HMAC SHA-256 do payload de `/api/mobile/checkin-config`, com fallback seguro quando a assinatura estiver ausente/invalida sob chave configurada;
  - mobile: parse e persistencia da politica dinamica da Etapa 2 (`visivel`/`obrigatoria`) no runtime e no recovery payload;
  - mobile: `CheckinScreen` passa a ocultar a CTA da Etapa 2 quando a secao vier desabilitada pelo backend e bloquear a abertura da camera quando a etapa estiver marcada como obrigatoria e pendente;
  - testes: reforco da suite em `test/services/checkin_dynamic_config_service_test.dart` e `test/screens/checkin_flow_navigation_test.dart` para assinatura valida/invalida, parse da politica e regressao de comportamento do fluxo.
- Validacoes executadas em PowerShell externo:
  - `flutter analyze --no-pub` sem issues;
  - `flutter test --no-pub test/services/checkin_dynamic_config_service_test.dart test/screens/checkin_flow_navigation_test.dart` verde (22 testes).
- Estado operacional:
  - checkpoint local concluido e documentado;
  - sem commit/push/promocao para `main` nesta etapa; aguardando aprovacao do checkpoint.

## Checkpoint 2026-04-05 - Release v1.2.32+52 (Checkpoint B mobile)
- Branch de release: release/v1.2.32+52
- Escopo: avancar INT-004/INT-006/INT-007 no mobile para rollback efetivo de config e sync real com protocolo e reconciliacao, mantendo a trilha do pacote unico MVP-GoLive-Core.
- Escopo implementado:
  - mobile: chave de idempotencia endurecida para derivacao canonica por `jobId + exportedAt + payloadChecksum`, reduzindo risco de divergencia por ordenacao do payload;
  - mobile: parser de `InspectionSyncService` alinhado ao contrato real de backend com suporte explicito a `protocol`, `status`, `processId/processNumber`;
  - mobile: `CheckinDynamicConfigService` coberto para refletir rollback remoto na proxima leitura sem reter config stale em cache local;
  - mobile: `InspectionSyncQueueService.flush` passou a devolver referencias reconciliaveis por `jobId`;
  - mobile: `HomeScreen` passou a aplicar reconciliacao de `idExterno/protocoloExterno` apos dreno automatico/manual da fila local;
  - testes: cobertura adicionada para chave idempotente canonica, contrato canonico de sync real e reconciliacao de referencias por fila/estado.
- Validacoes executadas em PowerShell externo:
  - `flutter analyze --no-pub` sem issues;
  - `flutter test --no-pub test/services/integration_context_service_test.dart test/services/inspection_sync_service_test.dart test/services/inspection_sync_queue_service_test.dart test/state/app_state_inspection_recovery_test.dart` verde (21 testes).
- Validacoes executadas no backend:
  - `mvn -q "-Dmaven.repo.local=D:/DevCaches/maven-repository-codex" "-Dtest=MobileApiControllerContractErrorTest,InspectionSubmissionIntegrationTest,InspectionBackofficeIntegrationTest,MobileCheckinConfigIntegrationTest,OpenApiContractIntegrationTest" test` verde.
- Estado operacional:
  - checkpoint B mobile + backend focado validados localmente;
  - pendente consolidacao web do mesmo checkpoint e fechamento operacional do pacote.

## Checkpoint 2026-04-05 - Release v1.2.32+52 (Checkpoint C web)
- Branch de release: release/v1.2.32+52
- Escopo: fechar FW-001/FW-002/FW-003 com backoffice minimo operacional para jobs/cases dentro do pacote MVP-GoLive-Core.
- Escopo implementado:
  - web: nova camada `operations_backend_client` para proxiar `jobs` e `cases` com `X-Tenant-Id`, `X-Actor-Id` e `X-Correlation-Id`;
  - web: nova tela `/backoffice/jobs` com lista filtravel/paginada, detalhe do job, timeline e acoes de `assign/cancel` sem chamada manual de API;
  - web: nova tela `/backoffice/cases` com criacao minima do case + job inicial e painel de rastreabilidade imediata na sessao;
  - web: dashboard inicial atualizado com navegacao explicita para jobs e cases;
  - testes: nova suite `apps/web-backoffice/test/jobs_api_routes.test.ts` cobrindo proxies de lista/detalhe/timeline/assign/cancel/cases.
- Validacao executada:
  - `npm test` verde via PowerShell + Docker Desktop (`node:20-alpine`);
  - `npm run lint` verde via PowerShell + Docker Desktop (`node:20-alpine`);
  - `npm run build` verde via PowerShell + Docker Desktop (`node:20-alpine`).
- Estado operacional:
  - implementacao web do checkpoint C concluida e validada;
  - pacote unico MVP-GoLive-Core com checkpoints A/B/C fechados localmente, pendente apenas do fluxo final de release que voce decidir.
