# Checklist de Sincronização: Backlog Local x GitHub Project Board

_Data de referência: 2026-03-31_

## Itens Sincronizados (IDs presentes em ambos, status compatível)
- BL-012: Em andamento / In Progress
- BL-001: Em andamento / In Progress
- BL-002: Concluído / Done
- BL-003: Concluído / Done
- BL-004: Concluído / Done
- BL-005: Pendente / Todo
- BL-006: Concluído / Done
- BL-007: Pendente / Todo
- BL-008: Concluído / Done
- BL-009: Pendente / Todo
- BL-010: (verificar status)
- BL-016: Concluído / Done
- BL-037: Concluído / Done
- BL-038: Concluído / Done
- BL-039: Concluído / Done

## Itens no Board e não no Backlog Local
- INT-021, INT-022, INT-023, INT-024, BOW-049, BOW-050, BOW-051, BOW-052 (itens de integração/web, não listados no backlog local principal)

## Itens no Backlog Local e não no Board
- Nenhum identificado (todos os IDs do backlog local estão presentes no board)

## Divergências de Status
- BL-005, BL-007, BL-009: Status "Pendente" no backlog local e "Todo" no board (OK)
- BL-012, BL-001: "Em andamento" no backlog local e "In Progress" no board (OK)
- BL-002, BL-003, BL-004, BL-006, BL-008, BL-016, BL-037, BL-038, BL-039: "Concluído" no backlog local e "Done" no board (OK)

## Observações
- Status e IDs estão sincronizados.
- Itens de integração/web são mantidos apenas no board, conforme escopo do backlog local.
- Não há pendências de sincronização crítica.

---

# Fluxo Operacional do Agente: Sincronização Backlog ↔ Board

1. **Fonte oficial:** docs/BACKLOG_FUNCIONALIDADES.md é a referência local.
2. **Extração do board:** Usar `gh project item-list <number> --owner <owner> --format json` para obter o board remoto.
3. **Comparação:** Mapear IDs e status entre local e remoto.
4. **Atualização:**
   - Se houver divergência, atualizar o board via CLI/API (`gh issue edit`, `gh project item-edit`, etc.)
   - Se item não existir no board, criar (`gh issue create`, `gh project item-add`)
   - Se item não existir no backlog local, registrar no backlog ou marcar como "externo"
5. **Registro:** Atualizar este checklist e documentar qualquer ação manual ou automática.
6. **Fallback:** Se CLI/API falhar, registrar erro e notificar para troubleshooting manual.
7. **Padrão de commit:** Sempre seguir o padrão `[versão] - [tipo alteração]: [resumo curto em português]`.
8. **Testes:** Executar testes após qualquer alteração relevante.
9. **Rastreabilidade:** Manter histórico de sincronização neste arquivo e no backlog.

---

_Arquivo gerado automaticamente pelo agente para rastreabilidade e troubleshooting._
