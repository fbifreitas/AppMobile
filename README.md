# AppMobile — Plataforma Multi-Brand

Mesmo core Flutter para **Kaptur** (marketplace) e **Compass Avaliações** (corporativo).
Branding, copy, feature flags e flavor nativo resolvidos por marca em compile-time.

Entrypoints:
- `lib/main_kaptur.dart` — `flutter run --flavor kaptur -t lib/main_kaptur.dart`
- `lib/main_compass.dart` — `flutter run --flavor compass -t lib/main_compass.dart`

## Leitura obrigatória antes de mudanças estruturais

1. `docs/04-engineering/BRAND_SETUP_AND_RELEASE_FLOW.md`
2. `docs/00-overview/00_INDEX_GERAL.md`
3. `docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md`

## Regra arquitetural central

Toda UI lê apenas `ResolvedBrandConfig` via `BrandProvider.configOf(context)`.
Nenhum widget lê `BrandManifest` ou `RemoteBrandOverrides` diretamente.
Copy vem de `config.copyText(key, defaultValue: ...)`.
Tokens visuais de marca vêm de `config.tokens`.

## Documentação ativa

Consulte `docs/` como fonte oficial.
Os documentos ativos estão organizados em duas classes complementares:

- engenharia e arquitetura multi-brand (04-engineering, 03-architecture, 07-diagrams)
- operação corrente ativa (runbooks, setup, onboarding, backlog tático) em `docs/05-operations/`

System docs do agente (operação autônoma):

- `docs/05-operations/AGENT_OPERATING_SYSTEM.md`
- `docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md`
- `docs/05-operations/TASK_BRIEF_TEMPLATE.md`
- `docs/05-operations/DONE_CHECKLIST_BY_WORK_TYPE.md`
- `docs/05-operations/WHEN_TO_STOP_AND_ASK.md`

O histórico preservado está em `docs/99-legacy/`, com mapa ativo em `docs/99-legacy/LEGACY_MIGRATION_MAP.md`.

## Versionamento

Este projeto usa `pubspec.yaml` no formato `x.y.z+build`.
Antes de release, atualizar versão e validar esteiras conforme governança do repositório.
