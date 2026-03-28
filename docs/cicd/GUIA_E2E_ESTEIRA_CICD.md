# Guia end-to-end da esteira CI/CD do AppMobile

## Objetivo
Executar o processo completo da esteira, do GitHub ao Firebase App Distribution e à instalação do build no celular.

## Visão geral do fluxo
1. alterar código localmente
2. validar localmente o necessário
3. fazer commit e push no GitHub
4. GitHub Actions roda `Android CI`
5. GitHub gera artifact APK debug
6. GitHub roda `Android Distribution` sob demanda
7. Firebase App Distribution recebe o build
8. tester instala no celular
9. execução de validação funcional do app
10. registro de evidências, falhas e decisão

## Fluxo operacional detalhado

### Etapa 1 — preparação local
Antes do push:
- garantir que o código está no estado que você quer testar
- opcionalmente rodar:
  - `flutter analyze`
  - `flutter test`
  - `flutter run`

### Etapa 2 — push no GitHub
Execute:
```bash
git status
git add .
git commit -m "DESCRICAO DO AJUSTE"
git push origin main
```

### Etapa 3 — validar o workflow Android CI
No GitHub:
1. abrir o repositório
2. clicar em **Actions**
3. abrir **Android CI**
4. abrir a execução mais recente

Critério de sucesso:
- checkout verde
- setup Java verde
- setup Flutter verde
- `flutter analyze` verde
- `flutter test` verde
- `flutter build apk --debug` verde
- artifact do APK disponível

### Etapa 4 — baixar artifact opcionalmente
Se quiser validar o artifact do CI:
1. abrir a execução do `Android CI`
2. baixar o artifact `app-debug-apk`

### Etapa 5 — rodar Android Distribution
No GitHub:
1. abrir **Actions**
2. clicar em **Android Distribution**
3. clicar em **Run workflow**
4. informar:
   - `release_notes`
   - `tester_group`
5. executar

Critério de sucesso:
- workflow verde
- etapa de distribuição verde
- artifact final disponível
- build aparece no Firebase App Distribution

### Etapa 6 — validar Firebase
No Firebase Console:
1. abrir o projeto
2. abrir **App Distribution**
3. confirmar que a release apareceu
4. confirmar data, notas e grupo de testers

### Etapa 7 — validar no celular
No celular do tester:
1. abrir link/e-mail/app do Firebase App Tester
2. instalar build
3. abrir app
4. validar:
   - startup
   - home
   - navegação
   - localização
   - jobs
   - check-in
   - hub
   - distribuição e versão recebida

### Etapa 8 — registrar o resultado
Use:
- `templates/qa/REGISTRO_EXECUCAO_TESTES.md`
- `templates/qa/REGISTRO_DEFEITOS.md`

## Saídas possíveis
### 1. Aprovado
- esteira funcionou
- build chegou no Firebase
- build instalou
- app validado sem bloqueadores

### 2. Aprovado com ressalvas
- esteira funcionou
- app abriu
- existem falhas não bloqueadoras para corrigir depois

### 3. Reprovado
- falha no CI/CD
- falha na distribuição
- falha na instalação
- falha crítica no app
