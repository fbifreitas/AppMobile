# Brand and Distribution Model

> **Escopo oficial:** canal mobile white-label, branding, flavors, distribuicao e runtime do app
> **Nao cobre sozinho:** tenant transversal, ecossistema de plataforma ou fronteiras globais de capability

---

## Papel Deste Documento Na V3

Este documento permanece oficial para o canal mobile white-label.

Ele define:
- branding e distribuicao por marca
- compile-time vs runtime no app
- manifestos de brand, overrides leves e contrato consumido pela UI
- flavors, entrypoints e limites de override remoto

Ele nao substitui:
- `10_PLATFORM_ECOSYSTEM_AND_TENANT_MODEL.md` para tenant transversal e ecossistema de plataforma
- `11_PLATFORM_CHANNELS_AND_CAPABILITY_BOUNDARIES.md` para fronteiras entre core, dominio e canais
- `09_WHITE_LABEL_ONBOARDING_STRATEGY.md` para onboarding mobile por marca/produto

---
## Modelo Atual

Este app adota o modelo **single-codebase, separate-apps-per-brand** via
Android productFlavors (e iOS schemes â€” ver `iOS_FLAVOR_SETUP_GUIDE.md`).

NÃ£o existe multi-tenancy em runtime: cada brand resulta em um APK/IPA
independente, distribuÃ­do separadamente nas lojas.

---

## Marcas Ativas

| Brand             | Flavor    | App ID                    | ProductMode   | Lojas              |
|-------------------|-----------|---------------------------|---------------|--------------------|
| **Kaptur**        | `kaptur`  | `com.kaptur.field`        | marketplace   | Play Store / App Store (Kaptur) |
| **Compass Aval.** | `compass` | `com.compass.avaliacoes`  | corporate     | Play Store / App Store (Compass) |

---

## TrÃªs Camadas de ConfiguraÃ§Ã£o

```
BrandManifest          (compile-time / flavor)
    +
RemoteBrandOverrides   (runtime leve / opcional)
    â†“
ResolvedBrandConfig    (contrato Ãºnico consumido pela UI)
```

### Camada 1 â€” BrandManifest (compile-time)

Definido em `lib/branding/kaptur_brand.dart` e `lib/branding/compass_brand.dart`.

ContÃ©m: `brandId`, `appName`, `primaryColor`, `primaryLightColor`,
`productMode`, `featureFlags`, `copyOverrides`, `logoAsset`, `iconAsset`.

**ImutÃ¡vel em runtime.** Nunca sobrescrito por config remota.

### Camada 2 â€” RemoteBrandOverrides (runtime leve)

Definido em `lib/branding/remote/remote_brand_overrides.dart`.

Pode sobrescrever: labels de seÃ§Ã£o, textos de home, feature flags leves.

**NÃ£o pode alterar:** package id, bundle id, Ã­cone do app, splash, nome do app no OS,
`productMode`, `brandId`.

### Camada 3 â€” ResolvedBrandConfig (contrato da UI)

Produzido por `BrandConfigResolver.resolve(manifest, overrides: ...)`.

Widgets **nunca** leem o manifest diretamente â€” apenas `BrandProvider.configOf(context)`.

---

## ProductMode

| Valor         | Brand     | Comportamento                                             |
|---------------|-----------|-----------------------------------------------------------|
| `marketplace` | Kaptur    | Propostas habilitadas, swipe, linguagem uberizada         |
| `corporate`   | Compass   | Ordens do dia, sem propostas, linguagem operacional       |

O onboarding tambem segue `ProductMode`, mas nao deve virar um fluxo unico com condicionais internos. A fonte funcional da substituicao/evolucao do onboarding por marca e `docs/03-architecture/09_WHITE_LABEL_ONBOARDING_STRATEGY.md`.

---

## BrandFeatureFlags

| Flag                      | Kaptur | Compass |
|---------------------------|--------|---------|
| `proposalsEnabled`        | âœ…      | âŒ       |
| `proposalsBlockEnabled`   | âœ…      | âŒ       |
| `geofenceRequired`        | âœ…      | âœ…       |
| `swipeRequired`           | âœ…      | âŒ       |
| `financialSummaryEnabled` | âœ…      | âŒ       |
| `marketplaceCopyEnabled`  | âœ…      | âŒ       |

---

## Fluxo de Build

```
flutter run --flavor kaptur  -t lib/main_kaptur.dart   # dev Kaptur
flutter run --flavor compass -t lib/main_compass.dart  # dev Compass

flutter build apk --flavor kaptur  -t lib/main_kaptur.dart   # release Kaptur
flutter build apk --flavor compass -t lib/main_compass.dart  # release Compass
```

Compass em homologacao deve receber tambem:

```bash
--dart-define=APP_TENANT_ID=tenant-compass
--dart-define=APP_API_BASE_URL=<backend-homolog>
```

Firebase App Distribution usa apps separados por marca:

| Brand   | Secret GitHub Actions              |
|---------|------------------------------------|
| Kaptur  | `FIREBASE_APP_ID_ANDROID`          |
| Compass | `FIREBASE_APP_ID_ANDROID_COMPASS`  |

Android tambem possui recursos nativos por flavor em `android/app/src/<brand>/res/` para splash e adaptive icon.

iOS usa `ios/Flutter/kaptur.xcconfig` e `ios/Flutter/compass.xcconfig` para `APP_DISPLAY_NAME`, `APP_BUNDLE_NAME` e `APP_BUNDLE_IDENTIFIER`. O target/scheme Compass deve apontar para o xcconfig Compass no Xcode.

---

## Adicionando uma Nova Marca

1. Criar `lib/branding/<nova_marca>_brand.dart` com `const novaMarcaManifest`.
2. Criar `lib/main_<nova_marca>.dart` com `_runWithBrand(config: BrandConfigResolver.resolve(novaMarcaManifest))`.
3. Adicionar flavor em `android/app/build.gradle.kts`.
4. Criar source set `android/app/src/<nova_marca>/AndroidManifest.xml`.
5. Criar diretÃ³rio `assets/brands/<nova_marca>/`.
6. Declarar `assets/brands/<nova_marca>/` em `pubspec.yaml`.
7. Configurar target + scheme iOS (ver `iOS_FLAVOR_SETUP_GUIDE.md`).
8. Adicionar assets finais (logo, Ã­cone) â€” fallback silencioso atÃ© entÃ£o.

---

## Fronteira Compile-Time vs Runtime

| Atributo                      | Camada         | AlterÃ¡vel em runtime? |
|-------------------------------|----------------|-----------------------|
| Package ID / Bundle ID        | Flavor (OS)    | âŒ Nunca               |
| Ãcone do app / Splash         | Flavor (assets)| âŒ Nunca               |
| Nome do app no OS             | Flavor (res)   | âŒ Nunca               |
| Cor primÃ¡ria                  | BrandManifest  | âŒ NÃ£o                 |
| ProductMode                   | BrandManifest  | âŒ NÃ£o                 |
| Labels de seÃ§Ã£o               | RemoteOverrides| âœ… Sim (leve)          |
| Feature flags leves           | RemoteOverrides| âœ… Sim (leve)          |

---

## Arquivos Relevantes

```
lib/branding/
  brand_manifest.dart          â† Modelo compile-time
  brand_tokens.dart            â† Semantic color layer
  brand_provider.dart          â† InheritedNotifier (Ãºnico ponto de consumo)
  resolved_brand_config.dart   â† Contrato da UI
  kaptur_brand.dart            â† Manifest Kaptur
  compass_brand.dart           â† Manifest Compass
  remote/
    remote_brand_overrides.dart  â† Override leve
    brand_config_resolver.dart   â† Merge manifest + overrides

lib/config/
  product_mode.dart            â† Enum marketplace / corporate
  brand_feature_flags.dart     â† Feature flags por brand

lib/theme/
  app_theme.dart               â† ThemeData factory (AppTheme.fromConfig)
  app_colors.dart              â† Cores neutras (brand-independent)

android/app/build.gradle.kts  â† productFlavors kaptur / compass
docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md
```

