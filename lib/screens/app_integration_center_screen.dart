import 'package:flutter/material.dart';

import '../models/app_navigation_entry.dart';
import '../services/app_navigation_registry_service.dart';
import '../services/center_status_resolver_service.dart';
import '../widgets/app_navigation_shortcuts_card.dart';
import '../widgets/app_status_overview_card.dart';
import 'checkin_screen.dart';
import 'operational_hub_screen.dart';
import 'operational_snapshot_export_screen.dart';

class AppIntegrationCenterScreen extends StatelessWidget {
  const AppIntegrationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final status = const CenterStatusResolverService().build();
    final shortcuts = const AppNavigationRegistryService().entries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppStatusOverviewCard(items: status),
          const SizedBox(height: 12),
          AppNavigationShortcutsCard(
            items: shortcuts,
            onTap: (entry) => _open(context, entry),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, AppNavigationEntry entry) {
    Widget screen;
    switch (entry.routeKey) {
      case 'checkin':
        screen = const CheckinScreen();
        break;
      case 'hub':
        screen = const OperationalHubScreen();
        break;
      case 'snapshot':
        screen = const OperationalSnapshotExportScreen();
        break;
      default:
        screen = const OperationalHubScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
