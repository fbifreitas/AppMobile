# Brand Setup and Release Flow — Multi-Brand

> **Fonte de referência para:** estrutura de branding, Android flavors, iOS setup,
> create_brand, validate_brand_setup e limites do override remoto.

---

## 1. Arquitetura de Branding

```
BrandManifest  (compile-time, por flavor)
      │
      ▼
BrandConfigResolver.resolve(manifest, overrides?)
      │
      ▼
ResolvedBrandConfig  ◄─── RemoteBrandOverrides (runtime, opcional)
      │
      ▼
BrandProvider.configOf(context)  ◄─── toda a UI lê daqui
```

### Responsabilidades

| Camada | Arquivo | Papel |
|---|---|---|
| `BrandManifest` | `lib/branding/<brand>_brand.dart` | Identidade fixa da marca (compile-time) |
| `BrandTokens` | `lib/branding/brand_tokens.dart` | Cores semânticas derivadas do manifest |
| `RemoteBrandOverrides` | `lib/branding/remote/remote_brand_overrides.dart` | Sobrescritas leves de runtime |
| `BrandConfigResolver` | `lib/branding/remote/brand_config_resolver.dart` | Merge manifest + overrides |
| `ResolvedBrandConfig` | `lib/branding/resolved_brand_config.dart` | Contrato final da UI |
| `BrandProvider` | `lib/branding/brand_provider.dart` | InheritedWidget — ponto de leitura |

### Leitura em widgets

```dart
final config = BrandProvider.configOf(context);
final tokens = config.tokens;
final title  = config.copyText('jobs_section_title', defaultValue: 'MEUS JOBS');
final flags  = config.featureFlags;
```

**Proibido em widgets:**
- ler `BrandManifest` diretamente
- ler `RemoteBrandOverrides` diretamente
- fazer merge manual de config dentro do widget

---

## 2. Android Flavors

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
flavorDimensions += "brand"

productFlavors {
    create("kaptur") {
        dimension = "brand"
        applicationId = "com.kaptur.field"
        resValue("string", "app_name", "Kaptur")
    }

    create("compass") {
        dimension = "brand"
        applicationId = "com.compass.avaliacoes"
        resValue("string", "app_name", "Compass Avaliações")
    }
}
```

**AndroidManifest.xml** usa `android:label="@string/app_name"` — resolvido por flavor.

**Comandos de execução:**

```bash
# Kaptur
flutter run --flavor kaptur -t lib/main_kaptur.dart

# Compass
flutter run --flavor compass -t lib/main_compass.dart
```

**Build release:**

```bash
flutter build apk --flavor kaptur -t lib/main_kaptur.dart
flutter build apk --flavor compass -t lib/main_compass.dart
```

**Source sets por flavor:**
- `android/app/src/kaptur/` — launcher icon e recursos específicos do Kaptur
- `android/app/src/compass/` — launcher icon e recursos específicos do Compass

---

## 3. iOS — Setup por Marca

**Estratégia:** um target por marca + um scheme por marca.

| Marca | Target Xcode | Scheme | Bundle ID |
|---|---|---|---|
| Kaptur | `Runner` | `Kaptur` | `com.kaptur.field` |
| Compass | `RunnerCompass` | `Compass` | `com.compass.avaliacoes` |

**xcconfig por marca:**
- `ios/Flutter/kaptur.xcconfig` — `PRODUCT_BUNDLE_IDENTIFIER`, `DISPLAY_NAME`, `FLUTTER_TARGET`
- `ios/Flutter/compass.xcconfig` — idem para Compass

**Passo a passo completo:** `docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md`

**Comandos de execução:**

```bash
# Kaptur (requer scheme "Kaptur" no Xcode)
flutter run --flavor kaptur -t lib/main_kaptur.dart

# Compass (requer scheme "Compass" no Xcode)
flutter run --flavor compass -t lib/main_compass.dart
```

---

## 4. Criar Nova Marca

**Script:** `scripts/create_brand.sh`

```bash
./scripts/create_brand.sh \
  --brand-id    velocity \
  --app-name    "Velocity Inspeções" \
  --android-id  com.velocity.field \
  --ios-bundle  com.velocity.field \
  --product-mode marketplace
```

**O script gera:**
- `lib/branding/velocity_brand.dart` com manifest completo e copy keys mínimas
- `lib/main_velocity.dart` com entrypoint do flavor
- `assets/brands/velocity/logo.png` e `icon.png` (placeholders)
- `ios/Flutter/velocity.xcconfig`
- Instruções no terminal para Android, iOS e assets

**Após rodar o script:**
1. Editar `primaryColor`, `secondaryColor`, `accentColor` no manifest
2. Adicionar o flavor no `android/app/build.gradle.kts`
3. Criar source set Android `android/app/src/velocity/`
4. Criar target e scheme no Xcode (ver `iOS_FLAVOR_SETUP_GUIDE.md`)
5. Substituir placeholders por assets reais
6. Validar: `./scripts/validate_brand_setup.sh --brand-id velocity`

---

## 5. Validar Estrutura de Marca

**Script:** `scripts/validate_brand_setup.sh`

```bash
./scripts/validate_brand_setup.sh --brand-id kaptur
./scripts/validate_brand_setup.sh --brand-id compass
```

**Verifica:**
- manifest Dart e entrypoint existem
- pasta de assets e placeholders existem
- copy keys mínimas presentes no manifest
- xcconfig iOS existe e tem os campos obrigatórios
- flavor Android no `build.gradle.kts`

---

## 6. Limites do Override Remoto

### O que `RemoteBrandOverrides` PODE alterar

| Campo | Exemplo |
|---|---|
| Textos e labels da UI | `'login_welcome'`, `'jobs_section_title'` |
| Nomes de seções | `'proposals_section_title'` |
| Textos da Home | `'home_header_subtitle'` |
| Flags leves de feature | `proposalsBlockEnabled`, `financialSummaryEnabled` |
| Pequenas variações de composição | visibilidade de blocos opcionais |

### O que `RemoteBrandOverrides` NUNCA altera

| Campo | Por quê |
|---|---|
| `applicationId` / package name | Definido em compile-time pelo flavor Android |
| `bundle identifier` iOS | Definido em compile-time pelo target/scheme |
| App icon nativo (launcher icon) | Asset nativo do source set do flavor |
| Splash nativa | Asset nativo compilado no binário |
| Nome do app no sistema operacional | `resValue("string", "app_name")` no Gradle / `DISPLAY_NAME` no xcconfig |

**Comentários no código:** ver `remote_brand_overrides.dart` e `brand_config_resolver.dart`.

---

## 7. Chaves de Copy Mínimas por Marca

Toda marca deve ter as seguintes chaves em `copyOverrides`:

```dart
// Seções
'jobs_section_title'
'proposals_section_title'
// Home
'home_header_subtitle'
// Login
'login_welcome'
// Jobs
'job_start_label'
'job_resume_label'
'job_start_blocked_label'
// Propostas
'proposal_swipe_label'
'proposal_accept_label'
'proposal_snackbar_accept_success'
'proposal_empty_title'
```

Use `./scripts/validate_brand_setup.sh` para verificar presença de todas as chaves.

---

## 8. Entrypoints por Flavor

| Marca | Arquivo | Android Flavor | iOS Scheme |
|---|---|---|---|
| Kaptur | `lib/main_kaptur.dart` | `kaptur` | `Kaptur` |
| Compass | `lib/main_compass.dart` | `compass` | `Compass` |

---

## Referências

- `lib/branding/` — todos os manifestos e providers
- `android/app/build.gradle.kts` — flavors Android
- `ios/Flutter/kaptur.xcconfig` e `compass.xcconfig` — configs iOS
- `scripts/create_brand.sh` — criação de nova marca
- `scripts/validate_brand_setup.sh` — validação de estrutura
- `docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md` — setup detalhado iOS
