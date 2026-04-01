# Lições Aprendidas e Procedimento Operacional do Agente (Copilot)

## Objetivo
Registrar práticas essenciais, aprendizados e padrões de operação que devem ser seguidos em qualquer workspace, independente do chat ou contexto, para garantir continuidade, rastreabilidade e resiliência.

---

## 1. Princípios Gerais
- Sempre ler o projeto inteiro antes de qualquer mudança.
- Usar docs/BACKLOG_FUNCIONALIDADES.md como fonte oficial de backlog.
- Atualizar backlog local e board do GitHub Project em toda demanda.
- Seguir rigorosamente o padrão de versionamento e commit definido.
- Executar testes após mudanças; se não for possível, justificar.
- Nunca remover código/arquivo fora do escopo explícito.
- Priorizar TDD, Clean Code, SOLID e cobertura de testes.

## 2. Procedimento Operacional Padrão
- Antes de commit/push/publicação:
  - Checar e incrementar versão em pubspec.yaml (quando aplicável).
  - Executar `flutter analyze` e `flutter test`.
  - Validar rastreabilidade no backlog e board.
- Em cada solicitação:
  - Abrir/registrar card de rastreabilidade no backlog antes de implementar.
  - Atualizar status ao concluir.
- Mensagem de commit: `[versão] - [tipo alteração]: [resumo curto em português]`.

## 3. Resiliência e Troubleshooting
- Se um comando/integração falhar (ex: terminal travado, CLI sem acesso, API sem token):
  - Buscar alternativas (ex: executar comandos manualmente, usar scripts, validar variáveis de ambiente, checar permissões de token).
  - Registrar o erro e a solução adotada.
  - Documentar a lição aprendida neste arquivo.
- Sempre validar se há acesso ao GitHub Projects e se o token está configurado antes de tentar sincronização.
- Se não houver acesso, notificar e sugerir configuração do token/secret.

## 4. Continuidade entre sessões
- Este documento deve ser consultado e atualizado em toda nova interação, independente do chat.
- Sempre registrar novas lições aprendidas e padrões operacionais aqui.
- Usar este arquivo como base de conhecimento para auto-localização e troubleshooting futuro.

---

## Exemplos de Lições Aprendidas
- [2026-03-31] Se o terminal travar ou não houver acesso ao GitHub Projects, validar token, tentar comandos alternativos e registrar workaround.
- [2026-03-31] Sempre checar se o secret PROJECT_AUTOMATION_TOKEN está configurado antes de rodar workflows de board.
- [2026-03-31] Se o board não sincronizar, executar scripts manuais e atualizar checklist de sincronização.

---

_Este arquivo é a referência viva do agente para garantir continuidade, resiliência e rastreabilidade operacional._
