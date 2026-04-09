#!/usr/bin/env bash
# =============================================================================
# create_brand.sh — Onboarding rápido de nova marca no repositório
# =============================================================================
# Uso:
#   ./scripts/create_brand.sh \
#     --brand-id    <id>               # ex: "velocity" (lowercase, sem espaços)
#     --app-name    <nome>             # ex: "Velocity Inspeções"
#     --android-id  <packageId>        # ex: "com.velocity.field"
#     --ios-bundle  <bundleId>         # ex: "com.velocity.field"
#     --product-mode <marketplace|corporate>
#
# Resultado:
#   - lib/branding/<brand_id>_brand.dart
#   - assets/brands/<brand_id>/logo.png    (placeholder)
#   - assets/brands/<brand_id>/icon.png    (placeholder)
#   - ios/Flutter/<brand_id>.xcconfig
#   - Instruções impressas para Android, iOS e assets
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argumentos ---
BRAND_ID=""
APP_NAME=""
ANDROID_ID=""
IOS_BUNDLE=""
PRODUCT_MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand-id)    BRAND_ID="$2";    shift 2 ;;
    --app-name)    APP_NAME="$2";    shift 2 ;;
    --android-id)  ANDROID_ID="$2";  shift 2 ;;
    --ios-bundle)  IOS_BUNDLE="$2";  shift 2 ;;
    --product-mode) PRODUCT_MODE="$2"; shift 2 ;;
    *) echo "Argumento desconhecido: $1"; exit 1 ;;
  esac
done

# --- Validação ---
if [[ -z "$BRAND_ID" || -z "$APP_NAME" || -z "$ANDROID_ID" || -z "$IOS_BUNDLE" || -z "$PRODUCT_MODE" ]]; then
  echo "❌  Todos os argumentos são obrigatórios."
  echo ""
  echo "Uso:"
  echo "  ./scripts/create_brand.sh \\"
  echo "    --brand-id    <id> \\"
  echo "    --app-name    \"<nome>\" \\"
  echo "    --android-id  <com.x.y> \\"
  echo "    --ios-bundle  <com.x.y> \\"
  echo "    --product-mode <marketplace|corporate>"
  exit 1
fi

if [[ "$PRODUCT_MODE" != "marketplace" && "$PRODUCT_MODE" != "corporate" ]]; then
  echo "❌  --product-mode deve ser 'marketplace' ou 'corporate'."
  exit 1
fi

BRAND_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< "${BRAND_ID:0:1}")${BRAND_ID:1}"

# --- Dart: determinar ProductMode e BrandFeatureFlags ---
if [[ "$PRODUCT_MODE" == "marketplace" ]]; then
  DART_PRODUCT_MODE="ProductMode.marketplace"
  DART_FEATURE_FLAGS="BrandFeatureFlags.kaptur"
else
  DART_PRODUCT_MODE="ProductMode.corporate"
  DART_FEATURE_FLAGS="BrandFeatureFlags.compass"
fi

# --- 1. lib/branding/<brand_id>_brand.dart ---
DART_FILE="$REPO_ROOT/lib/branding/${BRAND_ID}_brand.dart"

if [[ -f "$DART_FILE" ]]; then
  echo "⚠️  $DART_FILE já existe. Pulando geração do manifest."
else
  cat > "$DART_FILE" <<DART
import 'package:flutter/material.dart';

import '../config/brand_feature_flags.dart';
import '../config/product_mode.dart';
import 'brand_manifest.dart';

/// Manifesto da marca ${APP_NAME}.
///
/// Identidade: definir cores e linguagem específicas desta marca.
/// Modo: ${PRODUCT_MODE}.
const BrandManifest ${BRAND_ID}Manifest = BrandManifest(
  brandId: '${BRAND_ID}',
  appName: '${APP_NAME}',
  primaryColor: Color(0xFF000000),    // TODO: substituir pela cor primária da marca
  secondaryColor: Color(0xFF333333),  // TODO: substituir pela cor secundária
  accentColor: Color(0xFF666666),     // TODO: substituir pela cor de destaque
  logoAsset: 'assets/brands/${BRAND_ID}/logo.png',
  iconAsset: 'assets/brands/${BRAND_ID}/icon.png',
  productMode: ${DART_PRODUCT_MODE},
  featureFlags: ${DART_FEATURE_FLAGS},
  copyOverrides: {
    // Seções
    'jobs_section_title': 'MEUS JOBS DE HOJE',
    'proposals_section_title': 'NOVAS PROPOSTAS',
    // Home
    'home_header_subtitle': 'Seu painel operacional de hoje',
    // Login
    'login_welcome': 'Bem-vindo ao ${APP_NAME}',
    // Jobs
    'job_start_label': 'INICIAR',
    'job_resume_label': 'RETOMAR',
    'job_start_blocked_label': 'Fora da área de atendimento.',
    // Propostas
    'proposal_swipe_label': 'DESLIZE PARA ACEITAR',
    'proposal_accept_label': 'ACEITAR',
    'proposal_snackbar_accept_success': 'Item aceito! Adicionado ao seu painel.',
    'proposal_empty_title': 'Nenhum item disponível no momento.',
  },
);
DART
  echo "✅  Manifest criado: $DART_FILE"
fi

# --- 2. Assets: pasta + placeholders ---
ASSETS_DIR="$REPO_ROOT/assets/brands/${BRAND_ID}"
mkdir -p "$ASSETS_DIR"

for ASSET in logo.png icon.png; do
  ASSET_PATH="$ASSETS_DIR/$ASSET"
  if [[ ! -f "$ASSET_PATH" ]]; then
    # Cria um PNG placeholder de 1x1 pixel (base64 mínimo válido)
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > "$ASSET_PATH"
    echo "✅  Placeholder criado: $ASSET_PATH"
  else
    echo "⚠️  $ASSET_PATH já existe. Mantendo arquivo atual."
  fi
done

# --- 3. iOS xcconfig ---
IOS_XCCONFIG="$REPO_ROOT/ios/Flutter/${BRAND_ID}.xcconfig"

if [[ -f "$IOS_XCCONFIG" ]]; then
  echo "⚠️  $IOS_XCCONFIG já existe. Pulando."
else
  cat > "$IOS_XCCONFIG" <<XCCONFIG
// =============================================================================
// ${APP_NAME} — iOS build configuration
// =============================================================================
// Inclua este arquivo no scheme Xcode "${BRAND_CAPITALIZED}".
// Referência: docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md
// =============================================================================

#include "Generated.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = ${IOS_BUNDLE}
DISPLAY_NAME = ${APP_NAME}
FLUTTER_TARGET = lib/main_${BRAND_ID}.dart
XCCONFIG
  echo "✅  xcconfig iOS criado: $IOS_XCCONFIG"
fi

# --- 4. Entrypoint Dart ---
MAIN_FILE="$REPO_ROOT/lib/main_${BRAND_ID}.dart"
if [[ -f "$MAIN_FILE" ]]; then
  echo "⚠️  $MAIN_FILE já existe. Pulando geração do entrypoint."
else
  cat > "$MAIN_FILE" <<DARTMAIN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'branding/brand_provider.dart';
import 'branding/${BRAND_ID}_brand.dart';
import 'branding/remote/brand_config_resolver.dart';
import 'branding/remote/remote_brand_overrides.dart';
import 'repositories/fake_job_repository.dart';
import 'repositories/preferences_repository.dart';
import 'screens/awaiting_approval_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_onboarding_screen.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';
import 'state/inspection_state.dart';
import 'theme/app_theme.dart';

/// Entrypoint do flavor **${APP_NAME}**.
void main() {
  final config = BrandConfigResolver.resolve(
    ${BRAND_ID}Manifest,
    overrides: RemoteBrandOverrides.empty,
  );

  runApp(
    BrandProvider(
      config: config,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(
              FakeJobRepository(),
              const SharedPreferencesRepository(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => InspectionState()),
          ChangeNotifierProvider(
            create: (_) => AuthState(const SharedPreferencesRepository()),
          ),
        ],
        child: const _${BRAND_CAPITALIZED}App(),
      ),
    ),
  );
}

class _${BRAND_CAPITALIZED}App extends StatelessWidget {
  const _${BRAND_CAPITALIZED}App();

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: AppTheme.fromConfig(config),
      home: const _AppEntryPoint(),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.requiresPermissionsOnboarding) {
      return const PermissionsOnboardingScreen();
    }
    switch (auth.status) {
      case AppAuthStatus.unauthenticated:
        return const LoginScreen();
      case AppAuthStatus.onboarding:
        return const OnboardingScreen();
      case AppAuthStatus.awaitingApproval:
        return const AwaitingApprovalScreen();
      case AppAuthStatus.active:
        return const HomeScreen();
    }
  }
}
DARTMAIN
  echo "✅  Entrypoint Dart criado: $MAIN_FILE"
fi

# --- Instruções finais ---
echo ""
echo "============================================================"
echo " Nova marca '${APP_NAME}' (${BRAND_ID}) criada."
echo "============================================================"
echo ""
echo "📱 PRÓXIMOS PASSOS — ANDROID"
echo "  Adicione o flavor em android/app/build.gradle.kts:"
echo ""
echo "    create(\"${BRAND_ID}\") {"
echo "        dimension = \"brand\""
echo "        applicationId = \"${ANDROID_ID}\""
echo "        resValue(\"string\", \"app_name\", \"${APP_NAME}\")"
echo "    }"
echo ""
echo "  Crie o source set:"
echo "    android/app/src/${BRAND_ID}/AndroidManifest.xml"
echo ""
echo "  Rode o app:"
echo "    flutter run --flavor ${BRAND_ID} -t lib/main_${BRAND_ID}.dart"
echo ""
echo "🍎 PRÓXIMOS PASSOS — iOS"
echo "  1. Abra ios/Runner.xcworkspace no Xcode."
echo "  2. Duplique o target Runner → renomeie para Runner${BRAND_CAPITALIZED}."
echo "  3. Em Runner${BRAND_CAPITALIZED} > Build Settings, aplique ios/Flutter/${BRAND_ID}.xcconfig."
echo "  4. Defina PRODUCT_BUNDLE_IDENTIFIER = ${IOS_BUNDLE}."
echo "  5. Crie scheme '${BRAND_CAPITALIZED}' apontando para Runner${BRAND_CAPITALIZED}."
echo "  6. Marque o scheme como Shared."
echo "  7. Rode: flutter run --flavor ${BRAND_ID} -t lib/main_${BRAND_ID}.dart"
echo ""
echo "🎨 PRÓXIMOS PASSOS — ASSETS"
echo "  Substitua os placeholders em assets/brands/${BRAND_ID}/:"
echo "    - logo.png  (logo da marca, uso interno na UI)"
echo "    - icon.png  (ícone interno da UI)"
echo "  Para launcher icon nativo:"
echo "    - Android: coloque ic_launcher.png em android/app/src/${BRAND_ID}/res/mipmap-*/"
echo "    - iOS: configure Assets.xcassets no target Runner${BRAND_CAPITALIZED}"
echo ""
echo "🔍 VALIDAÇÃO"
echo "  Execute: ./scripts/validate_brand_setup.sh --brand-id ${BRAND_ID}"
echo ""
echo "📋 CORES"
echo "  Edite lib/branding/${BRAND_ID}_brand.dart:"
echo "    - primaryColor, secondaryColor, accentColor"
echo ""
