# Secrets necessários para o 13B

## Obrigatórios
### FIREBASE_APP_ID_ANDROID
App ID do app Android cadastrado no Firebase.

### FIREBASE_TOKEN
Token gerado com:
```bash
firebase login:ci
```

## O que este pacote já faz com esses secrets
O workflow:
- valida se os dois existem
- falha cedo com mensagem clara se estiver faltando algum
- usa o App ID para publicar no app correto
- usa o token para autenticar o Firebase CLI

## Observação
Este pacote usa distribuição manual via `workflow_dispatch`.
Ou seja:
- não dispara sozinho a cada push
- você controla quando distribuir
