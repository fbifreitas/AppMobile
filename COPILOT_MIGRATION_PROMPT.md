# COPILOT_MIGRATION_PROMPT

Quero que você execute uma migração documental controlada neste repositório.

## Objetivo
Migrar a direção do repositório de uma plataforma inspection-centric para uma plataforma corporativa:
- multi-domain
- multi-tenant
- white-label

## Regras obrigatórias
1. Crie e use uma branch dedicada para esta mudança:
   - `docs/v2-multidomain-reframe`
2. Não apague silenciosamente documentos históricos.
3. Mova documentos antigos relevantes para `docs/legacy/`.
4. Não deixe dois documentos ativos com diretrizes conflitantes.
5. Inspection continua existindo, mas agora como `domain-inspection`, e não como identidade global da plataforma.
6. Antes de propor qualquer edição, leia:
   - `.github/copilot-instructions.md`
   - `GEMINI.md`
   - `docs/00-overview/00_INDEX_GERAL.md`
   - `docs/00-overview/03_PLANO_DE_MIGRACAO_DOCUMENTAL.md`
   - `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
   - `docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
   - `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`
   - `docs/03-architecture/04_DOMAIN_PACK_WELLNESS.md`
   - `docs/03-architecture/05_DOMAIN_PACK_CHURCH.md`
   - `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
   - `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`
   - `docs/04-engineering/01_ENGINEERING_GUARDRAILS.md`
   - `docs/BACKLOG_V2_PRIORIDADES.md`

## O que eu quero que você faça
1. Resuma a nova direção da V2.
2. Liste os arquivos que devem ser:
   - substituídos
   - movidos para `docs/legacy/`
   - mantidos
   - criados
3. Proponha a sequência de commits.
4. Só então comece a aplicar a migração de documentação.

## Critérios de qualidade
- platform core deve permanecer agnóstico
- shared foundations devem ser neutras
- domínios devem ser independentes
- tenant e white-label devem ser estruturais
- docs ativos não podem contradizer a V2
- backlog deve refletir a nova taxonomia

## Proibição
Não continue escrevendo ou expandindo código como se o projeto fosse apenas uma plataforma de vistoria.
