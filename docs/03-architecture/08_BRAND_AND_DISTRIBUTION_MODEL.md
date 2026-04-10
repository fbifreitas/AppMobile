# Brand and Distribution Model

> **Versão:** BL-074 — v1.2.46+66
> **Substitui:** `06_TENANT_AND_WHITE_LABEL_MODEL.md` (movido para `99-legacy`)

---

## Modelo Atual

Este app adota o modelo **single-codebase, separate-apps-per-brand** via
Android productFlavors (e iOS schemes — ver `iOS_FLAVOR_SETUP_GUIDE.md`).

Não existe multi-tenancy em runtime: cada brand resulta em um APK/IPA
independente, distribuído separadamente nas lojas.

---

## Marcas Ativas

| Brand             | Flavor    | App ID                    | ProductMode   | Lojas              |
|-------------------|-----------|---------------------------|---------------|--------------------|
| **Kaptur**        | `kaptur`  | `com.kaptur.field`        | marketplace   | Play Store / App Store (Kaptur) |
| **Compass Aval.** | `compass` | `com.compass.avaliacoes`  | corporate     | Play Store / App Store (Compass) |

---

## Três Camadas de Configuração

```
BrandManifest          (compile-time / flavor)
    +
RemoteBrandOverrides   (runtime leve / opcional)
    ↓
ResolvedBrandConfig    (contrato único consumido pela UI)
```

### Camada 1 — BrandManifest (compile-time)

Definido em `lib/branding/kaptur_brand.dart` e `lib/branding/compass_brand.dart`.

Contém: `brandId`, `appName`, `primaryColor`, `primaryLightColor`,
`productMode`, `featureFlags`, `copyOverrides`, `logoAsset`, `iconAsset`.

**Imutável em runtime.** Nunca sobrescrito por config remota.

### Camada 2 — RemoteBrandOverrides (runtime leve)

Definido em `lib/branding/remote/remote_brand_overrides.dart`.

Pode sobrescrever: labels de seção, textos de home, feature flags leves.

**Não pode alterar:** package id, bundle id, ícone do app, splash, nome do app no OS,
`productMode`, `brandId`.

### Camada 3 — ResolvedBrandConfig (contrato da UI)

Produzido por `BrandConfigResolver.resolve(manifest, overrides: ...)`.

Widgets **nunca** leem o manifest diretamente — apenas `BrandProvider.configOf(context)`.

---

## ProductMode

| Valor         | Brand     | Comportamento                                             |
|---------------|-----------|-----------------------------------------------------------|
| `marketplace` | Kaptur    | Propostas habilitadas, swipe, linguagem uberizada         |
| `corporate`   | Compass   | Ordens do dia, sem propostas, linguagem operacional       |

---

## BrandFeatureFlags

| Flag                      | Kaptur | Compass |
|---------------------------|--------|---------|
| `proposalsEnabled`        | ✅      | ❌       |
| `proposalsBlockEnabled`   | ✅      | ❌       |
| `geofenceRequired`        | ✅      | ✅       |
| `swipeRequired`           | ✅      | ❌       |
| `financialSummaryEnabled` | ✅      | ❌       |
| `marketplaceCopyEnabled`  | ✅      | ❌       |

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

---

## Adicionando uma Nova Marca

1. Criar `lib/branding/<nova_marca>_brand.dart` com `const novaMarcaManifest`.
2. Criar `lib/main_<nova_marca>.dart` com `_runWithBrand(config: BrandConfigResolver.resolve(novaMarcaManifest))`.
3. Adicionar flavor em `android/app/build.gradle.kts`.
4. Criar source set `android/app/src/<nova_marca>/AndroidManifest.xml`.
5. Criar diretório `assets/brands/<nova_marca>/`.
6. Declarar `assets/brands/<nova_marca>/` em `pubspec.yaml`.
7. Configurar target + scheme iOS (ver `iOS_FLAVOR_SETUP_GUIDE.md`).
8. Adicionar assets finais (logo, ícone) — fallback silencioso até então.

---

## Fronteira Compile-Time vs Runtime

| Atributo                      | Camada         | Alterável em runtime? |
|-------------------------------|----------------|-----------------------|
| Package ID / Bundle ID        | Flavor (OS)    | ❌ Nunca               |
| Ícone do app / Splash         | Flavor (assets)| ❌ Nunca               |
| Nome do app no OS             | Flavor (res)   | ❌ Nunca               |
| Cor primária                  | BrandManifest  | ❌ Não                 |
| ProductMode                   | BrandManifest  | ❌ Não                 |
| Labels de seção               | RemoteOverrides| ✅ Sim (leve)          |
| Feature flags leves           | RemoteOverrides| ✅ Sim (leve)          |

---

## Arquivos Relevantes

```
lib/branding/
  brand_manifest.dart          ← Modelo compile-time
  brand_tokens.dart            ← Semantic color layer
  brand_provider.dart          ← InheritedNotifier (único ponto de consumo)
  resolved_brand_config.dart   ← Contrato da UI
  kaptur_brand.dart            ← Manifest Kaptur
  compass_brand.dart           ← Manifest Compass
  remote/
    remote_brand_overrides.dart  ← Override leve
    brand_config_resolver.dart   ← Merge manifest + overrides

lib/config/
  product_mode.dart            ← Enum marketplace / corporate
  brand_feature_flags.dart     ← Feature flags por brand

lib/theme/
  app_theme.dart               ← ThemeData factory (AppTheme.fromConfig)
  app_colors.dart              ← Cores neutras (brand-independent)

android/app/build.gradle.kts  ← productFlavors kaptur / compass
docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md
```
