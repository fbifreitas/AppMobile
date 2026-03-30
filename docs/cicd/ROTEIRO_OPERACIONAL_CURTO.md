# Roteiro operacional curto — esteira CI/CD AppMobile

## Fluxo automático
1. escrever ou atualizar testes antes da implementação (TDD):
```bash
flutter test
```
2. implementar o ajuste de código para passar nos testes
3. validar localmente antes do commit:
```bash
flutter analyze
flutter test
```
4. fazer:
```bash
git status
git add .
git commit -m "DESCRICAO DO AJUSTE"
git push origin main
```
5. o GitHub roda **Android CI**
6. se o **Android CI** ficar verde, o GitHub roda **Android Distribution** sozinho
7. o build vai para o Firebase App Distribution
8. você instala no celular e testa

## O que você precisa olhar
### No GitHub Actions
- **Android CI** verde
- **Android Distribution** verde

### No Firebase
- nova release apareceu no App Distribution

### No celular
- build instalou
- app abriu
- fluxos principais funcionaram

## Quando usar execução manual
Você ainda pode rodar **Android Distribution** manualmente se quiser reenviar um build ou testar outro grupo/notas.

## Regra simples
- `git push` = inicia a esteira
- `Android CI` verde = código validado
- `Android Distribution` verde = build entregue para teste

## Regra de qualidade (obrigatória)
- toda alteração funcional precisa vir acompanhada de testes (novo teste ou atualização de teste existente)
- sem `flutter analyze` verde e `flutter test` verde, não publicar
