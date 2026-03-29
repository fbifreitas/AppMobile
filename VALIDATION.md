# Checklist de validação pós-implantação

Use este checklist sempre que publicar uma nova versão ou fazer deploy automático.

## Antes do deploy

- [ ] Atualizar `pubspec.yaml` com a nova versão semântica.
- [ ] Garantir que os commits usem o padrão `feat/fix/chore/refactor/release`.
- [ ] Criar tag Git `vX.Y.Z` para a release.

## Após o deploy

- [ ] Confirmar que o build foi gerado com sucesso no pipeline.
- [ ] Verificar que o app abre corretamente no dispositivo.
- [ ] Testar fluxo de retomada de vistoria:
  - [ ] Iniciar uma vistoria até `CheckinScreen` ou `CheckinStep2Screen`.
  - [ ] Fechar o app ou navegar para outra tela.
  - [ ] Voltar ao app e usar o botão `RETOMAR VISTORIA`.
  - [ ] Confirmar que o app retorna à última etapa salva.
- [ ] Verificar persistência de dados das etapas:
  - [ ] `step1Payload` deve restaurar o formulário de check-in 1.
  - [ ] `step2Payload` deve restaurar o modelo de check-in 2.
- [ ] Testar navegação e botões críticos do fluxo de vistoria.

## Observações

- Se o app estiver em fase de protótipo, você pode reduzir frequência de tags, mas mantenha `pubspec.yaml` atualizado.
- Use `git push origin main` ou `git push origin --tags` conforme seu fluxo de CI/CD.
