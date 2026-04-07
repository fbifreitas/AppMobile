import 'package:flutter/material.dart';

import '../services/admin_action_catalog_service.dart';
import '../services/admin_panel_summary_service.dart';
import '../services/remote_config_catalog_service.dart';
import '../widgets/admin_action_list_card.dart';
import '../widgets/admin_panel_summary_card.dart';
import '../widgets/remote_config_list_card.dart';

class AdminRemoteConfigCenterScreen extends StatelessWidget {
  const AdminRemoteConfigCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = const AdminPanelSummaryService().build();
    final configs = const RemoteConfigCatalogService().items();
    final actions = const AdminActionCatalogService().items();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração e configuração remota'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminPanelSummaryCard(summary: summary),
          const SizedBox(height: 12),
          RemoteConfigListCard(items: configs),
          const SizedBox(height: 12),
          AdminActionListCard(items: actions),
        ],
      ),
    );
  }
}
