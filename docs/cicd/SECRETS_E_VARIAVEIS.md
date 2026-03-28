# Secrets e variáveis — preparação do CI/CD

## 1. Neste pacote
Nenhum secret é obrigatório para o workflow atual funcionar.
O build debug com artifact roda sem secrets adicionais.

## 2. Secrets para a próxima etapa (Firebase)
Quando você for integrar Firebase App Distribution, crie estes secrets no GitHub:

### FIREBASE_APP_ID_ANDROID
ID do app Android no Firebase.

### FIREBASE_TOKEN
Token do Firebase CLI para publicação automatizada.

## 3. Como criar secrets no GitHub
1. abra o repositório no GitHub
2. vá em **Settings**
3. vá em **Secrets and variables**
4. clique em **Actions**
5. clique em **New repository secret**
6. cadastre os secrets necessários

## 4. Segredos futuros para release Android
Mais adiante, para build release assinado, você provavelmente terá:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

Esses ainda não entram no 13A.
