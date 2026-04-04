# Critérios de aprovação da esteira CI/CD

## Esteira aprovada
A esteira está aprovada quando:
- o `Android CI` fica verde
- o `Android Distribution` fica verde
- a release aparece no Firebase
- o build instala no celular
- o app abre e permite validar os fluxos principais

## Esteira aprovada com ressalvas
A esteira está aprovada com ressalvas quando:
- CI e distribuição funcionam
- o build instala
- o app abre
- existem falhas não bloqueadoras de UX, conteúdo ou detalhe operacional

## Esteira reprovada
A esteira está reprovada quando ocorre qualquer um dos itens abaixo:
- falha no `Android CI`
- falha no `Android Distribution`
- build não aparece no Firebase
- build não instala no celular
- app não abre
- fluxo crítico bloqueado

## Fluxos críticos considerados
- startup
- home
- jobs
- localização
- navegação principal
- check-in
- hub
- central de operação de campo
