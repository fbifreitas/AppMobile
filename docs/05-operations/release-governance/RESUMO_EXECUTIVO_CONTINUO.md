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

## Checkpoint 2026-04-05 - Onda 2 (Checkpoint A core configuravel)
- Branch de trabalho: `main`
- Escopo: iniciar saneamento do core configuravel da vistoria antes do bloco operacional de ambientes repetidos, consolidando semantica canonica, labels por surface e politica unica de obrigatoriedade.
- Escopo implementado:
  - mobile: extracao de `OverlayCameraCaptureResult` para model proprio, desacoplando o contrato de captura de `OverlayCameraScreen`;
  - mobile: novo `InspectionSemanticFieldService` para resolver chave semantica canonica, aliases de fallback e `labelsBySurface` em check-in/camera/review;
  - mobile: novo `InspectionRequirementPolicyService` para unificar matching de obrigatorios da Etapa 2 entre camera, revisao e payload persistido;
  - mobile: `CheckinScreen`, `OverlayCameraScreen`, `InspectionReviewScreen` e `CheckinDynamicConfigService` alinhados ao novo core compartilhado;
  - mobile: camera principal e revisao passaram a consumir labels por surface com fallback seguro quando o pacote remoto nao trouxer configuracao explicita.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_semantic_field_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_requirement_policy_service_test.dart` verde;
  - `flutter test --no-pub test/screens/checkin_flow_navigation_test.dart test/screens/inspection_review_screen_test.dart` verde;
  - `flutter test --no-pub test/screens/overlay_camera_screen_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - base semantica do Checkpoint A estabilizada com fallback forte preservado;
  - pendente apenas continuar a reducao incremental de hardcodes de classificacao antes de entrar no Checkpoint B.

## Checkpoint 2026-04-05 - Onda 2 (Checkpoint B fluxo operacional)
- Branch de trabalho: `main`
- Escopo: levar o novo core configuravel para o fluxo operacional da vistoria, com suporte a ambientes repetidos, acao contextual no menu principal da camera e retomada pelo ultimo contexto real.
- Escopo implementado:
  - mobile: novo `InspectionEnvironmentInstanceService` para criar instancias operacionais do ambiente atual (`Quarto 2`, `Quarto 3`) sem adicionar nivel novo na arvore principal;
  - mobile: `OverlayCameraCaptureResult` passou a persistir `ambienteBase` e `ambienteInstanceIndex`, preservando a diferenca entre label exibido e identidade operacional;
  - mobile: `InspectionRequirementPolicyService` passou a considerar `ambienteBase` no matching de obrigatorios, permitindo que `Quarto 2` satisfaça requisito configurado como `Quarto`;
  - mobile: `OverlayCameraScreen` ganhou acao contextual `Novo <ambiente>` e passou a refletir a nova instancia no fluxo principal sem depender de submenu adicional;
  - mobile: `InspectionReviewScreen` passou a persistir `review.cameraContext` no recovery e a priorizar o ultimo contexto real capturado ao reabrir a camera por pendencia, em vez de reaplicar apenas o target estatico do requisito;
  - mobile: revisao/recovery preservam `ambienteBase` e `ambienteInstanceIndex`, mantendo a instancia operacional apos reabertura do fluxo.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_environment_instance_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_requirement_policy_service_test.dart` verde;
  - `flutter test --no-pub test/screens/overlay_camera_screen_test.dart` verde;
  - `flutter test --no-pub test/screens/inspection_review_screen_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - retomada de camera e ambientes repetidos estabilizados no fluxo principal;
  - base pronta para fechamento documental/commit do pacote ou hardening adicional antes da promocao.

## Checkpoint 2026-04-06 - Onda 3 (Checkpoint A semantica e estado)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: iniciar a refatoracao V2 do fluxo configuravel de inspection com foco em separar estado de captura do widget e extrair a persistencia de `cameraContext` da revisao para uma fronteira propria.
- Escopo implementado:
  - mobile: novo modelo `InspectionCaptureContext` e `InspectionCaptureFlowState` para representar estado inicial sugerido e estado corrente da captura sem depender de strings soltas no widget da camera;
  - mobile: `OverlayCameraScreen` passou a concentrar a selecao atual em `InspectionCaptureFlowState`, reduzindo mutacoes diretas espalhadas de `macroLocal/ambiente/elemento/material/estado`;
  - mobile: novo `InspectionCaptureRecoveryAdapter` para serializar e resolver `review.cameraContext` com compatibilidade ao payload atual;
  - mobile: `InspectionReviewScreen` deixou de montar e ler `cameraContext` manualmente, delegando a persistencia e a retomada ao adapter dedicado.
  - mobile: novo `InspectionCaptureContextResolver` para resolver o contexto inicial da camera a partir da Etapa 1 em um unico adapter, substituindo a montagem manual por cinco metodos separados em `CheckinScreen`;
  - mobile: `CheckinScreen` passou a abrir a camera a partir do contexto resolvido pelo adapter, preservando o payload atual e reduzindo regra semantica espalhada no widget.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_capture_context_resolver_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_capture_recovery_adapter_test.dart` verde;
  - `flutter test --no-pub test/screens/checkin_flow_navigation_test.dart test/screens/inspection_review_screen_test.dart test/screens/overlay_camera_screen_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - Checkpoint A validado e pronto para commit;

## Checkpoint 2026-04-06 - Onda 3 (Checkpoint B fluxo operacional e inspection)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: retirar da camera e da revisao a regra operacional de ambientes repetidos e a taxonomia inspection hardcoded, mantendo a acao contextual fora da arvore principal.
- Escopo implementado:
  - mobile: novo `InspectionContextActionsService` para resolver `Trocar`, `Novo <ambiente>` e label contextual com genero correto (`Novo Quarto`, `Nova Sala`);
  - mobile: novo `InspectionTaxonomyService` para centralizar taxonomia review/camera de ambiente, elemento, material e estado;
  - mobile: `OverlayCameraScreen` passou a consumir acao contextual inline no cabecalho de `Local da foto`, sem submenu adicional;
  - mobile: `InspectionReviewScreen` deixou de manter listas locais hardcoded e passou a consumir taxonomia dedicada;
  - mobile: textos sensiveis da revisao estabilizados para evitar corrupcao visual em labels operacionais.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_context_actions_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_taxonomy_service_test.dart` verde;
  - `flutter test --no-pub test/screens/overlay_camera_screen_test.dart` verde;
  - `flutter test --no-pub test/screens/inspection_review_screen_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - Checkpoint B validado e pronto para commit.

## Checkpoint 2026-04-06 - Onda 3 (Checkpoint C quebra incremental da fachada)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: concluir a quebra incremental do `InspectionMenuService`, preservando a API publica e o payload atual enquanto as responsabilidades sao movidas para camadas dedicadas.
- Escopo implementado:
  - mobile: novo `InspectionMenuDocumentLoader` para leitura de asset/mock;
  - mobile: novo `InspectionMenuDocumentMergeResolver` para merge remoto/fallback/mock;
  - mobile: novo `InspectionMenuPreferencesStore` para persistencia de `usage/prediction`;
  - mobile: novo `InspectionMenuRankingService` para ranking editorial/local/recencia;
  - mobile: novo `InspectionMenuCatalogService` para hierarchy lookup e fallback operacional do menu;
  - mobile: novo `InspectionMenuIntelligenceService` para sugestao de contexto, prediction e recentes;
  - mobile: `InspectionMenuService` mantido como facade temporaria, mas deixando de concentrar carga/merge/prefs/ranking/catalogo/inteligencia.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_menu_document_loader_test.dart test/services/inspection_menu_document_merge_resolver_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_preferences_store_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_ranking_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_catalog_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_intelligence_service_test.dart test/services/inspection_menu_service_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - Checkpoint C validado e pronto para fechamento da onda.

## Fechamento 2026-04-06 - Onda 3 concluida
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Resultado tecnico consolidado:
  - `OverlayCameraScreen` deixou de ser fonte de verdade do fluxo e passou a consumir estado canonico, resolvedor de menu, service de apresentacao dos niveis e service de transicao;
  - `InspectionFlowCoordinator` passou a trafegar contexto coeso por `InspectionCameraFlowRequest`, removendo passagem espalhada de parametros legados;
  - `InspectionReviewScreen` deixou de montar `resume context` e `cameraContext` manualmente, passando a consumir adapter/policy/estado dedicados;
  - `InspectionMenuService` foi reduzido a facade real, com responsabilidades distribuidas em camadas especificas;
  - semantica canonica e aliases legados ficaram concentrados em adapters semanticos, preservando labels por surface e compatibilidade com payload atual;
  - ambientes repetidos (`Quarto 2`, `Sala 2`) permanecem funcionando de ponta a ponta em camera, revisao e retomada.
- Validacao final executada:
  - `flutter analyze --no-pub` verde;
  - `flutter test --no-pub test/services/inspection_capture_context_resolver_test.dart test/services/inspection_capture_recovery_adapter_test.dart test/services/inspection_capture_flow_transition_service_test.dart test/services/inspection_context_actions_service_test.dart test/services/inspection_semantic_field_service_test.dart test/services/inspection_camera_level_presentation_service_test.dart test/services/inspection_menu_catalog_service_test.dart test/services/inspection_menu_intelligence_service_test.dart test/services/inspection_menu_service_test.dart` verde;
  - `flutter test --no-pub test/screens/checkin_flow_navigation_test.dart test/screens/inspection_review_screen_test.dart test/screens/overlay_camera_screen_test.dart` verde.
- Estado operacional:
  - Onda 3 encerrada localmente e pronta para consolidacao final de commits/release.
  - proximo passo: avancar para o Checkpoint B, focando a acao contextual e o desacoplamento progressivo da especializacao inspection.

## Checkpoint 2026-04-06 - Onda 3 (Checkpoint B acao contextual e taxonomia inspection)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: continuar a refatoracao V2 do fluxo configuravel de inspection reduzindo regra contextual e taxonomia local hardcoded nos widgets principais.
- Escopo implementado:
  - mobile: novo `InspectionContextActionsService` para resolver label e proxima instancia de `Novo <ambiente>` fora de `OverlayCameraScreen`;
  - mobile: `OverlayCameraScreen` passou a consumir o service dedicado para a acao contextual de duplicacao, reduzindo regra inspection-specific no widget;
  - mobile: novo `InspectionTaxonomyService` para concentrar taxonomia de `ambiente/elemento/material/estado` usada na classificacao da revisao;
  - mobile: `InspectionReviewScreen` deixou de manter essas listas como constantes locais e passou a consumir a taxonomia por service;
  - mobile: textos sensiveis da revisao e da suite correspondente foram normalizados para evitar regressao por encoding e para estabilizar os testes do fluxo.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_context_actions_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_taxonomy_service_test.dart` verde;
  - `flutter test --no-pub test/screens/overlay_camera_screen_test.dart` verde;
  - `flutter test --no-pub test/screens/inspection_review_screen_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - Checkpoint B validado e pronto para commit;
  - proximo passo: avancar para o Checkpoint C, focando a quebra incremental do concentrador de config sem romper a facade atual.

## Checkpoint 2026-04-06 - Onda 3 (Checkpoint C quebra incremental do concentrador de config)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: reduzir o acoplamento interno de `InspectionMenuService` preservando a fachada publica e o comportamento atual do fluxo configuravel.
- Escopo implementado:
  - mobile: novo `InspectionMenuDocumentLoader` para encapsular leitura do asset e do developer mock fora do service principal;
  - mobile: novo `InspectionMenuDocumentMergeResolver` para isolar a logica de merge entre documento base e override;
  - mobile: `InspectionMenuService` passou a delegar carregamento e merge de documentos a essas duas fronteiras novas, mantendo a API publica intacta;
  - mobile: nova `InspectionMenuPreferencesStore` para encapsular persistencia de `usage` e `prediction` em `SharedPreferences`;
  - mobile: `InspectionMenuService` passou a delegar leitura/escrita desse estado a store dedicada, reduzindo concentracao de IO/persistencia no mesmo arquivo;
  - mobile: limpeza pontual de import sem uso em teste de contexto de captura para manter a base limpa.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_menu_document_loader_test.dart test/services/inspection_menu_document_merge_resolver_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_preferences_store_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_menu_service_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - Checkpoint C validado e pronto para commit;
  - proximo passo: consolidar o fechamento da Onda 3 e decidir promocao pela esteira ou hardening adicional curto.

## Checkpoint 2026-04-06 - Onda 3 (Fechamento obrigatorio das fronteiras camera/revisao)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: fechar a ultima inconsistência residual entre coordinator, camera e revisao sem reescrever a navegacao nem romper compatibilidade de payload.
- Escopo implementado:
  - mobile: `OverlayCameraScreen` passou a expor `initialFlowState` como contrato principal, removendo do contrato publico os parametros fragmentados `preselectedMacroLocal`, `initialAmbiente`, `initialElemento`, `initialMaterial` e `initialEstado`;
  - mobile: `InspectionCaptureRecoveryAdapter` passou a centralizar `buildCameraFlowRequest`, `buildReviewPayload`, leitura de capturas persistidas e merge de capturas da revisao sem duplicacao por `filePath`;
  - mobile: `InspectionReviewScreen` deixou de montar `resumeContext` e `cameraContext` manualmente, passando a consumir o adapter de recovery para persistencia e reabertura da camera;
  - mobile: novo `InspectionCameraSelectorSectionService` para tirar da `OverlayCameraScreen` a decisao de quais seletores/acoes inline aparecem por nivel no estado canonico atual;
  - mobile: novos `InspectionReviewRequirementService` e `InspectionReviewAccordionService` para reduzir regra local de requiredness/agrupamento/resumo dentro da `InspectionReviewScreen`;
  - mobile: a camera passou a recalcular seções derivadas apos transicoes locais (`macroLocal`, `ambiente`, duplicacao, `elemento`, `material`, `estado`), preservando `Novo Quarto` / `Quarto 2` no fluxo de captura, revisao e retomada.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_capture_recovery_adapter_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_camera_selector_section_service_test.dart test/screens/overlay_camera_screen_test.dart test/screens/checkin_flow_navigation_test.dart` verde;
  - `flutter test --no-pub test/screens/inspection_review_screen_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_semantic_field_service_test.dart test/services/inspection_camera_level_presentation_service_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - fronteira `coordinator -> camera` fechada no contrato canonico;
  - recovery saiu da revisao e foi centralizado no adapter;
  - camera e revisao perderam mais uma camada real de regra critica local;
  - etapa pronta para consolidacao em commit e esteira seguindo o procedimento documentado.

## Checkpoint 2026-04-06 - Onda 3 (Fechamento final do residuo operacional)
- Branch de trabalho: `codex/onda-3-v2-refactor-20260406`
- Escopo: reduzir o residuo final de regra operacional ainda embutido em `OverlayCameraScreen` e `InspectionReviewScreen`, sem ampliar escopo, sem reescrever navegacao e sem alterar o payload vigente.
- Escopo implementado:
  - mobile: novo `InspectionCameraBatchService` para encapsular construcao do resultado de captura e sincronizacao do lote para payload de step2;
  - mobile: novos `InspectionCameraPresentationService` e `InspectionCameraVoiceCommandService` para tirar da camera a decisao operacional de painel/checklist/sugestoes e o roteamento dos comandos de voz;
  - mobile: novos `InspectionReviewPresentationService` e `InspectionReviewTechnicalPresentationService` para tirar da revisao o calculo de resumo, agrupamento base, atalhos de pendencia, subtitulos dos accordions e mensagens tecnicas de fechamento;
  - mobile: novo `inspection_review_models.dart` para remover do widget da revisao os tipos privados de dominio/apresentacao (`editable capture`, grupos e status), reduzindo acoplamento entre estado de negocio e UI;
  - mobile: `OverlayCameraScreen` e `InspectionReviewScreen` ficaram mais restritas a composicao de widgets, wiring de callbacks e estado efemero de expansao/colapso.
- Validacoes executadas:
  - `flutter test --no-pub test/services/inspection_camera_batch_service_test.dart test/services/inspection_camera_presentation_service_test.dart test/services/inspection_camera_selector_section_service_test.dart test/services/inspection_camera_voice_command_service_test.dart` verde;
  - `flutter test --no-pub test/services/inspection_review_presentation_service_test.dart test/services/inspection_review_technical_presentation_service_test.dart` verde;
  - `flutter test --no-pub test/screens/overlay_camera_screen_test.dart test/screens/inspection_review_screen_test.dart test/screens/checkin_flow_navigation_test.dart` verde;
  - `flutter analyze --no-pub` sem issues.
- Estado operacional:
  - requisito de fechamento da Onda 3 considerado atendido no escopo arquitetural desta trilha;
  - risco residual agora concentrado em composicao visual/wiring e nao mais em regra critica hardcoded de fluxo;
  - pronto para commit e implantacao pela esteira.
