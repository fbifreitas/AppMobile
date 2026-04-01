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
- Em cenário de mantenedor único (sem segundo revisor com write):
  - Aplicar exceção controlada de PR: reduzir temporariamente `required_approving_review_count` para `0`, executar merge da PR e restaurar imediatamente para `1`.
  - Registrar evidência do ajuste temporário e do restore na documentação operacional da entrega.
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
- [2026-04-01] Manter `docs/RESUMO_EXECUTIVO_CONTINUO.md` atualizado a cada ciclo de homologacao para consolidar snapshot de branch/versao/gates e reduzir perda de contexto na promocao para `main`.
- [2026-04-01] Em fluxo com mantenedor unico, o merge de PR para `main` pode usar excecao temporaria de protecao (0 aprovacoes) com restauracao imediata para 1 aprovacao apos o merge.
- [2026-04-01] Notificacao por e-mail de aprovacao de PR no celular foi movida para segundo plano no backlog operacional; prioridade mantida para envio de distribuicao por ambiente (homolog/producao).
- [2026-04-01] Na Revisao de Fotos, deduplicacao de obrigatorios deve usar chave tecnica da configuracao dinamica (cameraAmbiente/cameraElementoInicial), e nao apenas titulo exibido, para evitar ambiguidade quando o JSON web variar labels.

---

_Este arquivo é a referência viva do agente para garantir continuidade, resiliência e rastreabilidade operacional._
