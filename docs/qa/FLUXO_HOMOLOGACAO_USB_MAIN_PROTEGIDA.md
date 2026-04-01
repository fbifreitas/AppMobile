# Fluxo de Homologacao USB com Main Protegida

Objetivo: impedir push direto em main, validar pacote candidato em branch de homologacao e promover apenas versao estavel.

## Estrategia adotada

1. Desenvolvimento em branch de trabalho.
2. Publicacao em branch `release/*` ou `homolog/*`.
3. CI de homologacao gera APK candidato.
4. Smoke Maestro roda no celular via USB apos push de homologacao.
5. Somente apos smoke verde: abrir PR para `main`.
6. `main` recebe apenas codigo aprovado em homologacao.

## Regras locais de Git (hooks)

- Hook `pre-push` bloqueia push direto em `main`.
- Hook `post-push` executa Maestro apenas em `release/*` e `homolog/*`.

## Como habilitar hooks e ferramentas no repositorio

Executar uma vez:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup_git_post_push_maestro.ps1
```

Esse comando:
- configura `core.hooksPath`
- ativa bloqueio de push direto para `main`
- instala/valida Java, adb e Maestro

## Fluxo operacional por entrega

1. Criar branch de homologacao:

```powershell
git checkout -b release/vX.Y.Z+N
```

2. Rodar gates locais obrigatorios:

```powershell
flutter analyze
flutter test
```

3. Fazer push da branch de homologacao:

```powershell
git push origin release/vX.Y.Z+N
```

4. Validar:
- workflow `Android Homologation` verde
- smoke Maestro USB verde

5. Abrir PR de `release/*` para `main`.

6. Apos merge em `main`, manter validacoes CI e distribuicao.

## Protecao de branch no GitHub

O hook local ajuda, mas a garantia para todo o time vem da regra de branch no servidor.

Guia: `docs/cicd/BRANCH_PROTECTION_MAIN.md`.

## Modulo desenvolvedor no pacote

Status atual:
- bloqueio de uso em release esta implementado (BL-010 concluido)
- remocao fisica do modulo do binario nao esta implementada

Diretriz:
- para reduzir tamanho real do pacote, implementar separacao por flavors/entrypoints (BL-011 + item dedicado de empacotamento)
- enquanto isso, manter modulo dev inacessivel em release
