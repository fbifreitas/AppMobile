import 'package:flutter/material.dart';

import 'brand_manifest.dart';

/// Tokens semânticos de cor resolvidos a partir do [BrandManifest].
///
/// Widgets e temas não leem [BrandManifest] diretamente — consomem
/// [BrandTokens] via [ResolvedBrandConfig.tokens].
///
/// Cores neutras (success, warning, danger, surface, background, texto,
/// borda) são brand-independentes e permanecem fixas.
/// Apenas primary/secondary/accent variam por marca.
class BrandTokens {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;

  // Cores neutras — fixas entre marcas
  static const Color success = Color(0xFF1B8A5A);
  static const Color successLight = Color(0xFFE6F5EE);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerLight = Color(0xFFFDECEC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F7FA);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  const BrandTokens({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
  });

  factory BrandTokens.fromManifest(BrandManifest manifest) {
    return BrandTokens(
      primary: manifest.primaryColor,
      primaryLight: manifest.primaryColor.withValues(alpha: 0.12),
      secondary: manifest.secondaryColor,
      accent: manifest.accentColor,
    );
  }
}
