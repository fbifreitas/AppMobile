# 03_PLANO_DE_MIGRACAO_DOCUMENTAL

## Objetivo

Executar a migração documental da direção antiga (inspection-centric) para a direção V2
(corporate multi-domain, multi-tenant, white-label) sem perder histórico e sem deixar
documentos ativos contraditórios no repositório.

---

## Regra principal

Não fazer esta migração diretamente na branch principal.

Criar uma branch dedicada para a mudança documental e estrutural.

### Nome sugerido da branch
- `docs/v2-multidomain-reframe`
ou
- `chore/docs-v2-corporate-blueprint`

---

## Estratégia de execução

### Fase 1 — Preparação
1. Criar a nova branch.
2. Garantir que a nova pasta `docs/` V2 esteja disponível localmente.
3. Adicionar os arquivos de orientação para o agente:
   - `.github/copilot-instructions.md`
   - `GEMINI.md`
   - `COPILOT_MIGRATION_PROMPT.md`
4. Confirmar que a nova estrutura documental V2 existe antes de mover arquivos antigos.

### Fase 2 — Arquivos de entrada do repositório
Substituir primeiro os arquivos que moldam a interpretação do repositório:
1. `README.md`
2. `GEMINI.md`
3. `pubspec.yaml` (description e eventuais metadados textuais)
4. `docs/00-overview/*`

Motivo:
estes arquivos influenciam imediatamente humanos e agentes de código.

### Fase 3 — Direção corporativa
Criar ou substituir os documentos corporativos:
1. `docs/01-executive/*`
2. `docs/02-product/*`
3. `docs/03-architecture/01_CORPORATE_BLUEPRINT.md`
4. `docs/03-architecture/02_PLATFORM_CORE_AND_SHARED_FOUNDATIONS.md`
5. `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`
6. `docs/03-architecture/04_DOMAIN_PACK_WELLNESS.md`
7. `docs/03-architecture/05_DOMAIN_PACK_CHURCH.md`
8. `docs/03-architecture/06_TENANT_AND_WHITE_LABEL_MODEL.md`
9. `docs/03-architecture/07_CORPORATE_CANONICAL_MODEL.md`

### Fase 4 — Reclassificação de inspection
Mover os documentos antigos de blueprint/modelo operacional/modelo canônico centrados em vistoria para:
- `docs/legacy/...`

E criar os equivalentes ativos de domínio:
- `docs/03-architecture/03_DOMAIN_PACK_INSPECTION.md`

### Fase 5 — Demais domínios
Criar os blueprints iniciais:
- `docs/03-architecture/04_DOMAIN_PACK_WELLNESS.md`
- `docs/03-architecture/05_DOMAIN_PACK_CHURCH.md`

### Fase 6 — Engenharia, operação e análise
Atualizar:
- `docs/04-engineering/*`
- `docs/05-operations/*`
- `docs/06-analysis-design/*`

### Fase 7 — Diagramas e imagens
Atualizar:
- `docs/07-diagrams/*`
- `docs/07-diagrams/08-images/*`

### Fase 8 — Backlog e validação
1. Atualizar `docs/BACKLOG_V2_PRIORIDADES.md`
2. Revisar links quebrados
3. Revisar conflitos entre docs ativos e docs legados
4. Verificar se ainda há documento ativo descrevendo a empresa como somente plataforma de vistoria

---

## Política de legado

### Nunca apagar de imediato
Se um documento antigo ainda tiver valor histórico, mover para:
- `docs/legacy/`

### Regra de ouro
- documentos V2 = ativos
- documentos antigos = legado
- nunca manter dois documentos ativos com mensagens contraditórias

---

## Ordem recomendada de commits

### Commit 1
- `.github/copilot-instructions.md`
- `GEMINI.md`
- `README.md`
- `pubspec.yaml`
- `docs/00-overview/*`

### Commit 2
- `docs/01-executive/*`
- `docs/02-product/*`

### Commit 3
- `docs/03-architecture/*`

### Commit 4
- `docs/04-engineering/*`
- `docs/05-operations/*`
- `docs/06-analysis-design/*`

### Commit 5
- `docs/07-diagrams/*`
- `docs/BACKLOG_V2_PRIORIDADES.md`

### Commit 6
- `docs/legacy/*`
- ajustes finais de links e referências cruzadas

---

## Checklist final

Antes de abrir PR, validar:
- [ ] existe branch dedicada
- [ ] README já aponta para a V2
- [ ] GEMINI já foi substituído
- [ ] instruções do Copilot estão na raiz correta
- [ ] docs corporativos existem
- [ ] inspection foi reclassificado como domain pack
- [ ] wellness e church aparecem como domain packs
- [ ] docs antigos relevantes foram movidos para legacy
- [ ] não existem dois documentos ativos com diretrizes conflitantes
- [ ] backlog V2 foi atualizado
- [ ] diagramas V2 foram adicionados

---

## Complemento corretivo pós-migração V2

Após a migração para V2, manter também este checklist de correção taxonômica:

- [ ] docs estratégicos/corporativos continuam ativos sem regressão de nomenclatura
- [ ] docs operacionais correntes estão ativos em `docs/05-operations/`
- [ ] snapshot histórico foi preservado em `docs/legacy/legacy-import/`
- [ ] `docs/99-legacy/LEGACY_MIGRATION_MAP.md` descreve a taxonomia de legado sem conflito
- [ ] não existem dois documentos ativos com mensagens contraditórias
