import 'package:flutter/material.dart';

import '../branding/brand_tokens.dart';
import '../branding/resolved_brand_config.dart';

/// Factory de ThemeData a partir da configuração de marca resolvida.
///
/// Todos os ThemeData do app são construídos aqui — não inline em main.
/// Cores vêm de [BrandTokens], garantindo que o tema responda à marca ativa.
///
/// ## Transição de AppColors
/// [AppColors] (lib/theme/app_colors.dart) está em transição controlada.
/// Nas áreas refatoradas neste ciclo (Home, entrypoints, tema) usa-se
/// exclusivamente [BrandTokens]. As demais telas continuam usando
/// [AppColors] temporariamente — serão migradas em ciclo subsequente.
class AppTheme {
  const AppTheme._();

  static ThemeData fromConfig(ResolvedBrandConfig config) {
    final tokens = config.tokens;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BrandTokens.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        primary: tokens.primary,
        surface: BrandTokens.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandTokens.surface,
        foregroundColor: BrandTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandTokens.surface,
        selectedColor: tokens.primaryLight,
        side: const BorderSide(color: BrandTokens.border),
        labelStyle: const TextStyle(color: BrandTokens.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: tokens.primary,
        unselectedItemColor: BrandTokens.textSecondary,
        backgroundColor: BrandTokens.surface,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
