# Instrucoes Operacionais do Repositorio (AppMobile)

Estas instrucoes sao obrigatorias para qualquer agente Copilot atuando neste repositorio.

## 1) Ordem de leitura inicial (bootstrap)
1. Ler `docs/AGENTE_LICOES_APRENDIDAS.md`.
2. Ler `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
3. Ler a secao de contexto de negocio em `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
4. Ler `docs/BACKLOG_FUNCIONALIDADES.md`.
5. Ler `docs/BACKLOG_BACKOFFICE_WEB.md`.
6. Ler `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

## 2) Governanca obrigatoria
- Ler contexto completo antes de alterar codigo.
- Usar `docs/BACKLOG_FUNCIONALIDADES.md` como fonte oficial de backlog macro.
- Atualizar backlog e documentacao de rastreabilidade em toda demanda.
- Registrar checkpoint operacional continuo: a cada marco importante, atualizar documentacao com "o que foi feito", "estado atual" e "proximo passo" para facilitar retomada apos reinicio.
- Nao remover codigo/arquivo fora do escopo solicitado.
- Antes de commit/push/publicacao, checar incremento de versao em `pubspec.yaml` (quando aplicavel).
- Executar testes/validacoes apos mudancas no escopo:
  - Flutter: `flutter analyze` e `flutter test`.
  - Web: `npm run lint`, `npm test`, `npm run build`.
  - Backend: `mvn -B -DskipTests package`.
- Se nao for possivel executar teste, registrar justificativa explicita.
- Padrao de commit/publicacao: `[versao] - [tipo]: [resumo curto em portugues]`.

## 3) Seguranca de segredos
- Nao persistir segredos em arquivos versionados (`infra/.env`, `infra.env`, codigo).
- Usar variaveis de ambiente de sessao, cofre (`Get-Secret`) ou prompt seguro.
- Para stack local, priorizar `infra/scripts/start_local_stack.ps1`.

## 4) Regra de release
- Apos envio para homologacao, aguardar aprovacao explicita do usuario na mesma sessao antes de promover para `main`.
- Monitorar CI/CD e considerar ciclo encerrado apenas com confirmacao de distribuicao (incluindo e-mail do Firebase App Distribution, quando aplicavel).

## 5) Continuidade
- Em retomadas de chat, usar `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` como ponto de restauracao.
- Registrar licoes novas em `docs/AGENTE_LICOES_APRENDIDAS.md`.
- Sempre que houver mudanca relevante de status, atualizar imediatamente o ponto de restauracao antes de encerrar o ciclo.
