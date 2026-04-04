# Checklist E2E — CI/CD AppMobile

## 1. Código local
- [ ] código atualizado localmente
- [ ] alterações desejadas concluídas
- [ ] sem arquivos acidentais no commit

## 2. Git
- [ ] commit realizado
- [ ] push realizado para `main`

## 3. Android CI
- [ ] workflow executado
- [ ] `flutter analyze` verde
- [ ] `flutter test` verde
- [ ] `flutter build apk --debug` verde
- [ ] artifact do APK disponível

## 4. Android Distribution
- [ ] workflow executado manualmente
- [ ] `release_notes` preenchido
- [ ] `tester_group` preenchido
- [ ] distribuição concluída com sucesso

## 5. Firebase App Distribution
- [ ] release visível no Firebase
- [ ] grupo correto informado
- [ ] notes corretas
- [ ] build recente disponível

## 6. Instalação no celular
- [ ] build recebido pelo tester
- [ ] instalação concluída
- [ ] app abriu sem travar

## 7. Validação funcional mínima
- [ ] Home abriu
- [ ] localização exibida
- [ ] jobs carregaram
- [ ] `COMO CHEGAR` respondeu
- [ ] `INICIAR VISTORIA` abriu fluxo
- [ ] hub operacional abriu
- [ ] central de operação de campo abriu

## 8. Registro
- [ ] execução registrada
- [ ] defeitos registrados
- [ ] decisão final tomada
