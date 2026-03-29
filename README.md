# AppMobile

App Mobile para vistoria operacional com captura, revisão, voz e suporte assistivo.

## Versionamento e controle de release

Este projeto adota o seguinte padrão de versionamento e commits:

- `pubspec.yaml` usa `version: x.y.z+build`
  - `x.y.z` é a versão semântica
  - `build` é o número de build interno do app
- Para cada entrega formal, crie uma tag Git no formato `vX.Y.Z`
  - `git tag -a v1.0.1 -m "Release v1.0.1"`
  - `git push origin --tags`
- Use commits com mensagens semânticas em português:
  - `feat: adicionar retomada de vistoria`
  - `fix: corrigir restauração de rota de recuperação`
  - `chore: atualizar dependência de versão`
  - `release: v1.0.1`

## Branching

Recomenda-se este fluxo:

- `main` — código integrado
- `feature/<nome>` — desenvolvimento de nova funcionalidade
- `release/<versao>` — preparação de release

> Se o projeto ainda não estiver em produção, você pode trabalhar direto em `main`, mas mantenha disciplina de commits e versionamento.

## Validação pós-implantação

Use o checklist em `VALIDATION.md` para validar a aplicação após cada implantação.

## Documentos úteis

- `VERSIONING.md` — detalhes do padrão de versionamento e commits
- `VALIDATION.md` — checklist de validação após implantação
