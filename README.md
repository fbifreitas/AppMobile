# AppMobile Ecosystem Platform (V2)

Este repositório evoluiu para uma plataforma corporativa:

- multi-domain
- multi-tenant
- white-label

Domain packs atuais:

- Inspection
- Wellness
- Church

Inspection permanece estratégico, mas não define mais a semântica global da plataforma.

## Leitura obrigatória antes de mudanças estruturais

1. `.github/copilot-instructions.md`
2. `GEMINI.md`
3. `docs/00-overview/00_INDEX_GERAL.md`
4. `docs/00-overview/03_PLANO_DE_MIGRACAO_DOCUMENTAL.md`

## Regra arquitetural central

Platform Core deve permanecer agnóstico a domínio.
Shared Foundations devem permanecer neutras e reutilizáveis.
Domain packs são independentes e se integram por contratos/APIs/eventos/ACL.

## Documentação ativa

Consulte `docs/` como fonte oficial da direção V2.
Os documentos ativos estão organizados em duas classes complementares:

- direção estratégica/corporativa V2 (overview, architecture, engineering, backlog V2)
- operação corrente ativa (runbooks, setup, onboarding, backlog tático) em `docs/05-operations/`

O histórico preservado continua em `docs/legacy/`, com mapa ativo em `docs/99-legacy/LEGACY_MIGRATION_MAP.md`.

## Versionamento

Este projeto usa `pubspec.yaml` no formato `x.y.z+build`.
Antes de release, atualizar versão e validar esteiras conforme governança do repositório.
