# Passo a passo — Firebase App Distribution

## 1. Criar projeto no Firebase
1. abra o console do Firebase
2. clique em **Criar projeto**
3. escolha um nome para o projeto

## 2. Adicionar app Android
1. dentro do projeto Firebase, clique em **Adicionar app**
2. escolha **Android**
3. informe o **package name** do AppMobile
4. conclua o cadastro

Importante:
o package name deve ser exatamente o mesmo do app Android. O Firebase destaca que esse valor é sensível e precisa bater com o app registrado.
Referência oficial: Firebase Android setup e App Distribution. 

## 3. Abrir App Distribution
1. no menu do Firebase, abra **App Distribution**
2. habilite o recurso no projeto

## 4. Criar testers ou grupo
Você pode:
- adicionar e-mails de testers manualmente
- criar um grupo, por exemplo:
  - `testers-internos`

A documentação do Firebase App Distribution suporta distribuição por testers ou por grupos.

## 5. Obter FIREBASE_APP_ID_ANDROID
No Firebase, abra a configuração do app Android e copie o App ID.

## 6. Gerar FIREBASE_TOKEN
No seu computador, com Firebase CLI instalado, rode:
```bash
firebase login:ci
```

O comando retorna um token. Guarde esse valor.

## 7. Cadastrar os secrets no GitHub
No repositório:
1. Settings
2. Secrets and variables
3. Actions
4. New repository secret

Crie:
- `FIREBASE_APP_ID_ANDROID`
- `FIREBASE_TOKEN`

## 8. Rodar a distribuição
No GitHub:
1. abra **Actions**
2. clique em **Android Distribution**
3. clique em **Run workflow**
4. opcionalmente edite:
   - release notes
   - tester group
5. execute

## 9. Resultado esperado
- o workflow gera o APK debug
- envia para o Firebase App Distribution
- testers recebem acesso para instalar
