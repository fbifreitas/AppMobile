import 'package:flutter/material.dart';

import 'resolved_brand_config.dart';

/// Ponto único de consumo da configuração de marca ativa.
///
/// Expõe o [ResolvedBrandConfig] para toda a árvore de widgets.
/// Deve ser colocado **acima** do [MaterialApp] no entrypoint do flavor,
/// para que o tema possa ser construído a partir dos tokens da marca.
///
/// ## Uso básico (config estática, sem override remoto)
/// ```dart
/// BrandProvider(
///   config: BrandConfigResolver.resolve(kapturManifest),
///   child: MyApp(),
/// )
/// ```
///
/// ## Uso dinâmico (com override remoto assíncrono)
/// ```dart
/// final notifier = ValueNotifier(BrandConfigResolver.resolve(kapturManifest));
/// BrandProvider.withNotifier(notifier: notifier, child: MyApp());
/// // Após fetch:
/// notifier.value = BrandConfigResolver.resolve(kapturManifest, overrides: fetched);
/// ```
///
/// ## Leitura em widgets
/// ```dart
/// final config = BrandProvider.configOf(context);
/// final tokens = config.tokens;
/// final flags  = config.featureFlags;
/// final copy   = config.copyText('jobs_section_title', defaultValue: 'MEUS JOBS');
/// ```
class BrandProvider extends InheritedNotifier<ValueNotifier<ResolvedBrandConfig>> {
  /// Construtor simples para config estática (sem updates em runtime).
  ///
  /// Cria internamente um [ValueNotifier] que é descartado junto com o widget.
  /// Use [withNotifier] quando precisar atualizar a config via override remoto.
  BrandProvider({
    super.key,
    required ResolvedBrandConfig config,
    required super.child,
  }) : super(notifier: ValueNotifier(config));

  // ignore: prefer_const_constructors_in_immutables
  BrandProvider._withNotifier({ // ValueNotifier cannot be const; lint suppressed intentionally.
    super.key,
    required ValueNotifier<ResolvedBrandConfig> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Lê a configuração de marca resolvida do contexto.
  /// Lança assertion se [BrandProvider] não estiver na árvore.
  static ResolvedBrandConfig configOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<BrandProvider>();
    assert(
      provider != null,
      'BrandProvider.configOf chamado sem BrandProvider na árvore. '
      'Verifique se o entrypoint do flavor envolve o app com BrandProvider.',
    );
    return provider!.notifier!.value;
  }

  /// Cria um [BrandProvider] com suporte a atualização dinâmica de config.
  /// O [notifier] passado é gerenciado pelo chamador (lifecycle externo).
  static Widget withNotifier({
    Key? key,
    required ValueNotifier<ResolvedBrandConfig> notifier,
    required Widget child,
  }) {
    return BrandProvider._withNotifier(
      key: key,
      notifier: notifier,
      child: child,
    );
  }
}
