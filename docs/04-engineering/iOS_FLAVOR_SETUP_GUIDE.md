# iOS Flavor Setup Guide — Multi-Brand

> **Contexto:** BL-074 introduziu suporte multi-brand via Android productFlavors.
> Este guia documenta o setup equivalente para iOS com Xcode schemes + targets.

---

## Visão Geral

No Android, cada brand é um `productFlavor` em `build.gradle.kts`.
No iOS, o equivalente é ter um **Target** por brand (ou um Target com múltiplos **Build Configurations** + **Schemes**).

A abordagem recomendada para este projeto é:

```
Targets: Runner (Kaptur)  |  RunnerCompass (Compass)
Schemes: Kaptur           |  Compass
```

---

## Passo a Passo

### 1. Duplicar o Target Runner

1. No Xcode, abra `ios/Runner.xcworkspace`.
2. Selecione o projeto `Runner` no navigator.
3. Clique com botão direito no target `Runner` → **Duplicate**.
4. Renomeie o target duplicado para `RunnerCompass`.

### 2. Configurar Bundle ID por Target

| Target        | Bundle Identifier             |
|---------------|-------------------------------|
| Runner        | `com.kaptur.field`            |
| RunnerCompass | `com.compass.avaliacoes`      |

No target `RunnerCompass`:
- **Signing & Capabilities** → Bundle Identifier: `com.compass.avaliacoes`

### 3. Configurar Display Name por Target

Em cada target, edite `Info.plist` (ou adicione override no Build Settings):

| Target        | `CFBundleDisplayName` |
|---------------|-----------------------|
| Runner        | `Kaptur`              |
| RunnerCompass | `Compass Avaliações`  |

### 4. Criar Schemes

1. **Product → Scheme → Manage Schemes...**
2. Renomeie o scheme existente para `Kaptur` (aponta para target `Runner`).
3. Adicione novo scheme `Compass` apontando para target `RunnerCompass`.
4. Marque ambos como **Shared** para aparecerem no CI.

### 5. Entrypoints Flutter

Flutter resolve o entrypoint pela flag `--flavor` + arquivo `main_<brand>.dart`:

```
# Kaptur
flutter run --flavor kaptur -t lib/main_kaptur.dart

# Compass
flutter run --flavor compass -t lib/main_compass.dart
```

No `ios/Runner/AppDelegate.swift` não há mudanças — o entrypoint é resolvido pelo Flutter engine.

### 6. Assets por Target (Ícones / Splash)

Para ícones específicos por brand:
1. Crie `Assets.xcassets` separado por target (ou use um Asset Catalog com variações).
2. Em cada target, configure **App Icons Source** nas Build Settings.

Enquanto os ícones finais não existirem:
- Use o ícone padrão do Flutter como fallback.
- O fallback é silencioso — não quebra o build (mesma política dos assets Dart).

### 7. Build no CI (GitHub Actions)

```yaml
# Exemplo de step para Compass
- name: Build IPA (Compass)
  run: |
    flutter build ipa \
      --flavor compass \
      --target lib/main_compass.dart \
      --export-options-plist ios/ExportOptionsCompass.plist
```

---

## Entrypoints registrados

| Brand   | Arquivo Dart            | Target iOS    | Scheme    | Android Flavor |
|---------|-------------------------|---------------|-----------|----------------|
| Kaptur  | `lib/main_kaptur.dart`  | Runner        | Kaptur    | kaptur         |
| Compass | `lib/main_compass.dart` | RunnerCompass | Compass   | compass        |

---

## Referências

- [Flutter — Build flavors](https://docs.flutter.dev/deployment/flavors)
- `android/app/build.gradle.kts` — Android flavor definitions
- `lib/branding/kaptur_brand.dart` — Kaptur manifest
- `lib/branding/compass_brand.dart` — Compass manifest
