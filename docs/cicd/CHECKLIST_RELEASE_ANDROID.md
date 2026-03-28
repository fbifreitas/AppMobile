# Checklist de preparação Android para CI/CD

## Build debug
- [ ] projeto compila localmente
- [ ] `flutter analyze` sem erros
- [ ] `flutter test` sem falhas
- [ ] `flutter build apk --debug` funciona localmente

## Gradle / Java
- [ ] projeto compatível com Java 17
- [ ] Gradle Wrapper funcional
- [ ] Android SDK local sem erro estrutural

## Repositório
- [ ] código validado antes do push
- [ ] branch `main` estável
- [ ] workflow `.github/workflows/android_ci.yml` presente

## Próxima etapa
Quando quiser distribuir sem cabo USB:
- [ ] criar projeto Firebase
- [ ] cadastrar app Android no Firebase
- [ ] obter `FIREBASE_APP_ID_ANDROID`
- [ ] obter `FIREBASE_TOKEN`
- [ ] ativar bloco de distribuição no workflow

## Etapa posterior
Quando quiser preparar produção:
- [ ] criar keystore de release
- [ ] configurar signing Android
- [ ] gerar AAB
- [ ] integrar Play Console
