import 'package:flutter/material.dart';

// ignore_for_file: deprecated_member_use_from_same_package
// =============================================================================
// LEGADO TRANSITÓRIO — NÃO USAR EM CÓDIGO NOVO
// =============================================================================
// [AppColors] é uma classe de transição para a arquitetura multi-brand.
//
// Regra: todo código novo deve usar [BrandTokens] via [ResolvedBrandConfig]:
//   final tokens = BrandProvider.configOf(context).tokens;
//
// As cores primary/primaryLight aqui refletem o flavor Kaptur como baseline
// histórico. Em código novo, obtenha cores de marca por tokens.primary /
// tokens.primaryLight a partir do config resolvido.
//
// Cores neutras (success, warning, danger, surface, background, text, border)
// são brand-independentes e existem como constantes em [BrandTokens].
// =============================================================================
class AppColors {
  // ignore: deprecated_member_use
  @Deprecated('Use BrandTokens.fromManifest(manifest).primary via ResolvedBrandConfig')
  static const Color primary = Color(0xFF0D3B92);
  @Deprecated('Use BrandTokens.fromManifest(manifest).primaryLight via ResolvedBrandConfig')
  static const Color primaryLight = Color(0xFFE8F0FF);

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
}