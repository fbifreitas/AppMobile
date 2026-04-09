#!/usr/bin/env bash
# =============================================================================
# validate_brand_setup.sh — Validação da estrutura mínima de uma marca
# =============================================================================
# Uso:
#   ./scripts/validate_brand_setup.sh --brand-id <id>
#
# Verifica:
#   - Existência do manifest Dart
#   - Existência do entrypoint Dart
#   - Existência da pasta de assets
#   - Presença dos placeholders mínimos (logo.png, icon.png)
#   - Presença das chaves de copy mínimas no manifest
#   - Existência do xcconfig iOS
#   - Flavor Android no build.gradle.kts
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND_ID=""
ERRORS=0
WARNINGS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand-id) BRAND_ID="$2"; shift 2 ;;
    *) echo "Argumento desconhecido: $1"; exit 1 ;;
  esac
done

if [[ -z "$BRAND_ID" ]]; then
  echo "❌  --brand-id é obrigatório."
  echo "Uso: ./scripts/validate_brand_setup.sh --brand-id <id>"
  exit 1
fi

echo "============================================================"
echo " Validando marca: ${BRAND_ID}"
echo "============================================================"
echo ""

# --- Helper ---
check_file() {
  local PATH_TO_CHECK="$1"
  local LABEL="$2"
  if [[ -f "$PATH_TO_CHECK" ]]; then
    echo "  ✅  $LABEL"
  else
    echo "  ❌  $LABEL AUSENTE: $PATH_TO_CHECK"
    ERRORS=$((ERRORS + 1))
  fi
}

check_dir() {
  local PATH_TO_CHECK="$1"
  local LABEL="$2"
  if [[ -d "$PATH_TO_CHECK" ]]; then
    echo "  ✅  $LABEL"
  else
    echo "  ❌  $LABEL AUSENTE: $PATH_TO_CHECK"
    ERRORS=$((ERRORS + 1))
  fi
}

check_key_in_file() {
  local FILE="$1"
  local KEY="$2"
  if grep -q "'${KEY}'" "$FILE" 2>/dev/null; then
    echo "  ✅  copy key '${KEY}'"
  else
    echo "  ⚠️   copy key '${KEY}' ausente em $FILE"
    WARNINGS=$((WARNINGS + 1))
  fi
}

check_string_in_file() {
  local FILE="$1"
  local PATTERN="$2"
  local LABEL="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "  ✅  $LABEL"
  else
    echo "  ❌  $LABEL ausente em $FILE"
    ERRORS=$((ERRORS + 1))
  fi
}

# --- 1. Arquivos Dart ---
echo "📄 Arquivos Dart"
MANIFEST_FILE="$REPO_ROOT/lib/branding/${BRAND_ID}_brand.dart"
MAIN_FILE="$REPO_ROOT/lib/main_${BRAND_ID}.dart"
check_file "$MANIFEST_FILE" "Manifest: lib/branding/${BRAND_ID}_brand.dart"
check_file "$MAIN_FILE"     "Entrypoint: lib/main_${BRAND_ID}.dart"
echo ""

# --- 2. Assets ---
echo "🎨 Assets"
ASSETS_DIR="$REPO_ROOT/assets/brands/${BRAND_ID}"
check_dir  "$ASSETS_DIR"             "Pasta: assets/brands/${BRAND_ID}/"
check_file "$ASSETS_DIR/logo.png"    "Placeholder: assets/brands/${BRAND_ID}/logo.png"
check_file "$ASSETS_DIR/icon.png"    "Placeholder: assets/brands/${BRAND_ID}/icon.png"
echo ""

# --- 3. Copy keys mínimas ---
echo "📝 Copy keys mínimas (no manifest)"
REQUIRED_KEYS=(
  "jobs_section_title"
  "home_header_subtitle"
  "login_welcome"
  "job_start_label"
  "job_resume_label"
  "job_start_blocked_label"
  "proposal_swipe_label"
  "proposal_accept_label"
  "proposal_snackbar_accept_success"
  "proposal_empty_title"
)

if [[ -f "$MANIFEST_FILE" ]]; then
  for KEY in "${REQUIRED_KEYS[@]}"; do
    check_key_in_file "$MANIFEST_FILE" "$KEY"
  done
else
  echo "  ⚠️   Manifest ausente — pulando validação de copy keys"
  WARNINGS=$((WARNINGS + 1))
fi
echo ""

# --- 4. iOS xcconfig ---
echo "🍎 iOS"
IOS_XCCONFIG="$REPO_ROOT/ios/Flutter/${BRAND_ID}.xcconfig"
check_file "$IOS_XCCONFIG" "xcconfig: ios/Flutter/${BRAND_ID}.xcconfig"
if [[ -f "$IOS_XCCONFIG" ]]; then
  check_string_in_file "$IOS_XCCONFIG" "PRODUCT_BUNDLE_IDENTIFIER" "  PRODUCT_BUNDLE_IDENTIFIER definido"
  check_string_in_file "$IOS_XCCONFIG" "DISPLAY_NAME"              "  DISPLAY_NAME definido"
  check_string_in_file "$IOS_XCCONFIG" "FLUTTER_TARGET"            "  FLUTTER_TARGET definido"
fi
echo ""

# --- 5. Android flavor ---
echo "🤖 Android"
GRADLE_FILE="$REPO_ROOT/android/app/build.gradle.kts"
if [[ -f "$GRADLE_FILE" ]]; then
  if grep -q "\"${BRAND_ID}\"" "$GRADLE_FILE"; then
    echo "  ✅  Flavor '${BRAND_ID}' em build.gradle.kts"
  else
    echo "  ❌  Flavor '${BRAND_ID}' NÃO encontrado em android/app/build.gradle.kts"
    ERRORS=$((ERRORS + 1))
  fi
  ANDROID_SRC="$REPO_ROOT/android/app/src/${BRAND_ID}"
  if [[ -d "$ANDROID_SRC" ]]; then
    echo "  ✅  Source set: android/app/src/${BRAND_ID}/"
  else
    echo "  ⚠️   Source set android/app/src/${BRAND_ID}/ ausente (opcional, mas recomendado)"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "  ⚠️   build.gradle.kts não encontrado"
  WARNINGS=$((WARNINGS + 1))
fi
echo ""

# --- Resultado ---
echo "============================================================"
if [[ $ERRORS -gt 0 ]]; then
  echo " ❌  FALHOU — $ERRORS erro(s), $WARNINGS aviso(s)"
  echo " Execute ./scripts/create_brand.sh para gerar os itens faltantes."
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo " ⚠️   PASSOU com avisos — $WARNINGS aviso(s)"
  echo " Revise os avisos acima antes de publicar a marca."
  exit 0
else
  echo " ✅  PASSOU — estrutura mínima completa para a marca '${BRAND_ID}'"
  exit 0
fi
