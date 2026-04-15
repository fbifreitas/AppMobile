import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_navigation_coordinator.dart';
import '../services/app_navigation_registry_service.dart';
import '../services/center_status_resolver_service.dart';
import '../widgets/app_navigation_shortcuts_card.dart';
import '../widgets/app_status_overview_card.dart';

class AppIntegrationCenterScreen extends StatelessWidget {
  final AppNavigationCoordinator navigationCoordinator;

  const AppIntegrationCenterScreen({
    super.key,
    this.navigationCoordinator = const DefaultAppNavigationCoordinator(),
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status = const CenterStatusResolverService().build();
    final shortcuts = const AppNavigationRegistryService().entries();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.tr('Integração operacional', 'Operational integration'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppStatusOverviewCard(items: status),
          const SizedBox(height: 12),
          AppNavigationShortcutsCard(
            items: shortcuts,
            onTap: (entry) => navigationCoordinator.openAppShortcut(
              context,
              routeKey: entry.routeKey,
            ),
          ),
        ],
      ),
    );
  }
}
