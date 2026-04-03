# Fluxos críticos do app para validação

## Fluxo 1 — Startup até Home
1. instalar build
2. abrir app
3. validar startup
4. validar chegada na Home

## Fluxo 2 — Home até Job
1. abrir Home
2. validar jobs carregados
3. validar distância
4. clicar em `COMO CHEGAR`
5. voltar
6. clicar em `INICIAR VISTORIA`

## Fluxo 3 — Home até Hub
1. abrir Home
2. abrir hub operacional
3. abrir operação de campo
4. validar ausência de Provider error
5. voltar

## Fluxo 4 — Localização operacional
1. abrir Home
2. clicar em `Atualizar`
3. validar posição atual
4. validar atualização do card
5. validar impacto nos jobs

## Fluxo 5 — Distribuição OTA
1. rodar Android Distribution
2. validar release no Firebase
3. abrir build no celular
4. instalar
5. abrir app
