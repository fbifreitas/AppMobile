# Padrão de versionamento e commits

## Versão do app

No Flutter, a versão do app é controlada em `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` é a versão semântica.
- `+1` é o número de build interno.

### Como atualizar

- `x.y.z` deve ser alterado quando houver uma nova entrega de release.
- `build` pode ser incrementado a cada deploy ou build importante.

## Convenção de mensagens de commit

Use mensagens claras e em português, com prefixos semânticos:

- `feat: ...` — nova funcionalidade
- `fix: ...` — correção de bug
- `chore: ...` — tarefa de manutenção ou ajustes internos
- `refactor: ...` — refatoração de código sem mudança de comportamento
- `release: vX.Y.Z` — commit de versão final

### Exemplos

- `feat: adicionar recuperação de etapa de vistoria`
- `fix: corrigir retorno para checkin_step2`
- `chore: atualizar dependências do projeto`
- `release: v1.0.0`

## Tags de release

Quando estiver pronto para publicar uma versão:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin --tags
```

## Fluxo sugerido

1. Crie uma branch `feature/<nome>` para cada mudança.
2. Faça commits claros e pequenos.
3. Quando estiver pronto, faça merge em `main`.
4. Atualize `pubspec.yaml` e crie a tag de release.
5. Se o CI/CD rodar automaticamente, valide o build e o checklist em `VALIDATION.md`.
