> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# OPERACIONAL: Sincronização Backlog ↔ GitHub Project Board

## Objetivo
Garantir que o backlog local (docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md) esteja sempre sincronizado com o board do GitHub Project, com rastreabilidade e fallback documentado.

## Passos do Agente

0. **Registro prévio obrigatório**
   - Antes de iniciar pacote documental, operacional ou técnico relevante, registrar item rastreável no backlog tático correspondente.
   - Se o pacote já foi executado sem registro, criar entrada retroativa com evidências (commits/PR) no mesmo ciclo.

1. **Leitura do Backlog Local**
   - Fonte: docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md
   - IDs, status e critérios de pronto são extraídos e normalizados.

2. **Extração do Board Remoto**
   - Comando: `gh project item-list <number> --owner <owner> --format json`
   - Owner e número do projeto obtidos via `gh project list --format json`
   - Resultado: JSON com todos os itens, status, IDs e campos customizados.

3. **Comparação e Mapeamento**
   - IDs do backlog local são comparados com os do board.
   - Status são normalizados (Pendente/Todo, Em andamento/In Progress, Concluído/Done).
   - Divergências são listadas em CHECKLIST_SINCRONIZACAO_BACKLOG_BOARD.md.

4. **Ações de Sincronização**
   - Se item existe no backlog mas não no board: criar no board (`gh issue create`, `gh project item-add`).
   - Se item existe no board mas não no backlog: registrar como "externo" ou revisar escopo.
   - Se status diverge: atualizar board via CLI/API (`gh issue edit`, `gh project item-edit`).

5. **Fallback e Troubleshooting**
   - Se CLI/API falhar, registrar erro e notificar para troubleshooting manual.
   - Documentar qualquer limitação ou ação manual neste arquivo.

6. **Rastreabilidade**
   - Checklist de sincronização atualizado a cada ciclo.
   - Histórico de comandos e ações mantido para auditoria.

## Observações
- Sempre seguir padrão de commit e versionamento definido no projeto.
- Executar testes após alterações relevantes.
- Atualizar este documento e o checklist a cada sincronização.

---

_Este arquivo serve como referência operacional para auto-localização do agente e troubleshooting futuro._
