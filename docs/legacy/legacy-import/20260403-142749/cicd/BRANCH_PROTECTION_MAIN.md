# Branch Protection da main

Objetivo: impedir push direto em `main` para todo o time e exigir validacao antes de merge.

## Configuracao recomendada (GitHub)

1. Abrir: Settings -> Branches -> Add branch protection rule.
2. Branch name pattern: `main`.
3. Ativar:
- Require a pull request before merging
- Require approvals (minimo 1)
- Dismiss stale pull request approvals when new commits are pushed
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Restrict who can push to matching branches (opcional para endurecimento)
- Do not allow bypassing the above settings

## Checks obrigatorios sugeridos

Usar como obrigatorio o check que realmente valida PR para `main` hoje:

- `validate-and-build-debug`

Checks observados no repositorio e que nao devem ser marcados automaticamente como obrigatorios para `main` sem confirmar o gatilho do workflow:

- `sync-project-visuals`
- `build-and-distribute-debug`
- `validate-and-build-debug`

Observacao: `validate-and-build-homolog` pertence ao fluxo de homologacao em `release/*` e `homolog/*`; portanto, ele nao deve ser exigido na regra de `main` se nao executar em PR para `main`.

## Fluxo alvo

1. Push em `release/*` ou `homolog/*`
2. CI de homologacao + smoke USB Maestro aprovados
3. PR para `main`
4. PR validado pelo check `validate-and-build-debug`
5. Merge somente com checks verdes
