# PACOTE 13A.3 — Cache do workflow Android CI

## O que foi otimizado
Este pacote acelera o pipeline usando cache seguro em dois pontos:

### 1. Cache de Gradle
Feito via `actions/setup-java@v5` com:
- `cache: gradle`

Isso reaproveita dependências do Gradle entre execuções.

### 2. Cache do Flutter + Pub
Feito via `subosito/flutter-action@v2` com:
- `cache: true`
- `pub-cache: true`

Isso reaproveita:
- SDK do Flutter
- dependências do `flutter pub get`

## O que não foi cacheado
Para manter segurança e previsibilidade, este pacote **não** cacheia:
- outputs do build Android
- pasta `build/`
- APK pronto

Esses caches costumam aumentar risco de sujeira/inconsistência.

## Resultado esperado
- primeira execução ainda pode ser mais lenta
- segunda execução em diante deve ficar perceptivelmente mais rápida
- ganho maior normalmente aparece em:
  - `flutter pub get`
  - resolução Gradle
  - preparação do build Android
