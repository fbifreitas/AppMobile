import 'package:appmobile/branding/brand_provider.dart';
import 'package:appmobile/branding/kaptur_brand.dart';
import 'package:appmobile/branding/remote/brand_config_resolver.dart';
import 'package:appmobile/branding/remote/remote_brand_overrides.dart';
import 'package:appmobile/branding/resolved_brand_config.dart';
import 'package:flutter/widgets.dart';

/// Resolved brand config used across all widget tests.
///
/// Uses the Kaptur manifest (the default / main brand).
/// Tests that exercise Compass-specific behavior should build their own
/// config via [BrandConfigResolver.resolve(compassManifest)].
final ResolvedBrandConfig testBrandConfig = BrandConfigResolver.resolve(
  kapturManifest,
  overrides: RemoteBrandOverrides.empty,
);

/// Wraps [child] with a [BrandProvider] using [testBrandConfig].
///
/// Use this helper in `pumpWidget` calls wherever a widget under test
/// (or its subtree) calls [BrandProvider.configOf].
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   withBrand(MaterialApp(home: HomeHeader(...))),
/// );
/// ```
Widget withBrand(Widget child) {
  return BrandProvider(config: testBrandConfig, child: child);
}
