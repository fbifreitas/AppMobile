# CI/CD Android — base inicial do AppMobile

## O que você ganha com esta etapa
Você deixa de depender exclusivamente de:
- `flutter run`
- cabo USB
- build local manual

E passa a ter:
- build automático na nuvem
- validação técnica automática
- artifact APK para download
- base pronta para distribuição OTA

## Como usar no dia a dia
### Durante desenvolvimento
1. você altera o código localmente
2. roda validações locais que quiser
3. faz commit e push
4. o GitHub Actions executa:
   - analyze
   - test
   - build debug APK

### Para baixar o APK
1. abra o repositório no GitHub
2. vá em **Actions**
3. abra a execução mais recente do workflow `Android CI`
4. no final da execução, baixe o artifact `app-debug-apk`

## Quando esse fluxo já é útil
Mesmo sem loja e sem Firebase, ele já resolve:
- validação automática
- build reprodutível
- APK para testes internos

## O que ainda não está neste pacote
- signing de release
- AAB de produção
- publicação em loja
- TestFlight
- Firebase App Distribution ativado
