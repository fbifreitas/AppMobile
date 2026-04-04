# Checklist Operacional Pre-Push

Objetivo: evitar publicação com regressão funcional, versão inválida ou rastreabilidade incompleta.

## Gate obrigatório (não pular)

1. Backlog
- Registrar a demanda antes de codar.
- Definir status inicial (Pendente/Em andamento).
- Atualizar status final e observação de entrega.

2. Escopo e segurança de mudança
- Ler contexto do projeto e arquivos impactados.
- Alterar somente o escopo solicitado.
- Não remover código/arquivo fora do requisito explícito.

3. Qualidade técnica
- Aplicar TDD quando viável.
- Escrever ou atualizar testes do fluxo alterado.
- Preservar princípios de Clean Code e SOLID.

4. Validação local
- Executar `flutter analyze`.
- Executar `flutter test`.
- Se algum teste não puder rodar, registrar justificativa no backlog/PR.

5. Versionamento
- Validar o valor atual em `pubspec.yaml`.
- Incrementar `version` antes de merge/push/publicação.
- Exemplo: `1.2.18+35` -> `1.2.18+36`.

6. Mensagem de commit/publicação
- Seguir padrão obrigatório:
- `[versão] - [tipo alteração]: [resumo da mudança em português curto]`
- Exemplo:
- `v1.0.98 - fix: separar fluxo de fallback do fluxo de navegação ao voltar`

7. Publicacao e protecao de branch
- Push direto para `main` e bloqueado localmente por hook.
- Publicar primeiro em `release/*` ou `homolog/*`.
- Validar pipeline de homologacao e smoke Maestro USB no celular.
- Abrir PR para `main` somente apos homologacao verde.

## Comandos de referência

- `flutter analyze`
- `flutter test`
- `git status`
- `git add -A`
- `git commit -m "vX.Y.Z+N - tipo: resumo"`
- `git push origin release/vX.Y.Z+N`
