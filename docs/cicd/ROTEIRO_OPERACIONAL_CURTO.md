# Roteiro operacional curto — esteira CI/CD AppMobile

## Fluxo automático
1. alterar o código no computador
2. fazer:
```bash
git status
git add .
git commit -m "DESCRICAO DO AJUSTE"
git push origin main
```
3. o GitHub roda **Android CI**
4. se o **Android CI** ficar verde, o GitHub roda **Android Distribution** sozinho
5. o build vai para o Firebase App Distribution
6. você instala no celular e testa

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
