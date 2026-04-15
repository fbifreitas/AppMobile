# Painel de Milestones do Fluxo Configuravel de Vistoria

Atualizado em: 2026-04-15

## Objetivo

Registrar o estado operacional da evolucao do fluxo configuravel de vistoria com marcos simples e verificaveis.

Este painel deve ser lido em conjunto com:

- `docs/05-operations/runbooks/MODELO_CANONICO_FLUXO_CONFIGURAVEL_VISTORIA.md`
- `docs/05-operations/runbooks/VALIDACAO_FINAL_FLUXO_CONFIGURAVEL_VISTORIA.md`
- `docs/05-operations/runbooks/PLANO_IMPLANTACAO_INCREMENTO_ENRICHMENT_SMART_APP.md`
- `docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md`

## Painel

| Milestone | Nome | Status | Evidencia principal |
|---|---|---|---|
| `M1` | Estabilizar testes focados do fluxo configuravel mobile | Concluido | `test/screens/checkin_flow_navigation_test.dart`, `test/screens/inspection_review_screen_test.dart`, `test/services/checkin_dynamic_config_service_test.dart` verdes |
| `M2` | Consolidar modelo canonico em codigo e documentacao | Concluido | contrato com `obrigatoriaParaEntrega` e `bloqueiaCaptura`, runbook canonico documentado |
| `M3` | Separar arvore de captura e matriz normativa no runtime | Concluido | revisao, pendencias e matching operacional usando `subjectContext`, `targetItem` e `targetQualifier` |
| `M4` | Validacao integrada final web + backend + mobile | Em andamento | cobertura automatizada do fluxo funcional principal concluida; falta fechamento operacional no ambiente real apos publicacao final |
| `Mx-1` | Programa de orquestracao enrichment/OCR/hints | Planejado | docs incrementais e backlog de execucao publicados |
| `Mx-2` | Storage do retorno mobile e trilha analytics-ready | Planejado | estrategia `raw/normalized/curated` com `inspection-return` e `field-evidence` documentada |
| `Mx-3` | Smart app como execution plan derivado | Planejado | plano operacional publicado ao mobile modelado sem contrato paralelo |

## Detalhamento por milestone

### `M1` Concluido

Entregas:

- endurecimento e saneamento dos testes de navegacao do check-in
- endurecimento e saneamento dos testes da revisao
- remocao de fragilidade por encoding e textos literais instaveis

Validacoes executadas:

- `C:\src\flutter\bin\flutter.bat test --no-pub test\screens\checkin_flow_navigation_test.dart`
- `C:\src\flutter\bin\flutter.bat test --no-pub test\screens\inspection_review_screen_test.dart`
- `C:\src\flutter\bin\flutter.bat test --no-pub test\services\checkin_dynamic_config_service_test.dart`

### `M2` Concluido

Entregas:

- documentacao do modelo canonico
- contrato de `step2` com:
  - `obrigatoriaParaEntrega`
  - `bloqueiaCaptura`
- compatibilidade mantida com payload legado
- editor guiado do web publicado para `step1`, `step2` e `camera`

Arquivos principais:

- `lib/config/checkin_step2_config.dart`
- `lib/services/checkin_dynamic_config_service.dart`
- `apps/web-backoffice/app/components/config_targeting_panel.tsx`
- `docs/05-operations/runbooks/MODELO_CANONICO_FLUXO_CONFIGURAVEL_VISTORIA.md`

### `M3` Concluido

Entregas:

- separacao explicita entre:
  - `arvore de captura`
  - `matriz normativa`
- pendencias da revisao classificadas por origem:
  - `normativeMatrix`
  - `captureTree`
  - `technicalRule`
  - `finalization`
- matching operacional com chave semantica:
  - `subjectContext`
  - `targetItem`
  - `targetQualifier`
- aliases semanticos de evidencias no `step2`

Arquivos principais:

- `lib/models/inspection_review_operational_models.dart`
- `lib/services/inspection_review_operational_service.dart`
- `lib/services/inspection_review_accordion_service.dart`
- `lib/services/inspection_requirement_policy_service.dart`
- `lib/screens/inspection_review_screen.dart`

### `M4` Em andamento

Ja comprovado:

- `step1` continua obrigatorio para abrir a camera
- `step2` obrigatoria para entrega nao bloqueia captura
- revisao bloqueia `Finalizar vistoria` quando a pendencia obrigatoria de `step2` continua aberta

Cobertura automatizada ja existente:

- `test/screens/checkin_flow_navigation_test.dart`
- `test/screens/inspection_review_screen_test.dart`

Fechamento restante:

- repetir a publicacao final no ambiente real
- aprovar pacote no web
- validar refresh no app
- confirmar:
  - camera abre sem cumprimento integral da `etapa 2`
  - revisao bloqueia a entrega enquanto a `etapa 2` obrigatoria estiver incompleta

### `Mx-1` Planejado

Escopo:
- backend/plataforma como orquestrador de enrichment, OCR, reconciliacao e publication
- contracts base para execution hints e execution plan

### `Mx-2` Planejado

Escopo:
- storage preparado para:
  - `research`
  - `documents`
  - `job-config`
  - `inspection-return`
  - `field-evidence`
- trilha `raw/normalized/curated`
- readiness para analytics futura

### `Mx-3` Planejado

Escopo:
- `smart app` como derivacao do backend/plataforma
- payload do mobile alinhado ao fluxo canonico atual de inspection
- retorno operacional do App Mobile como fonte primaria de evidencia

## Regra de atualizacao

Sempre que um milestone mudar de estado:

1. atualizar este painel
2. atualizar o backlog tatico relevante
3. registrar os comandos de teste executados
4. anexar evidencia de runtime quando existir
