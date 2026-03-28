import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/operational_hub_item.dart';
import '../services/operational_hub_registry_service.dart';
import '../state/field_operation_state.dart';
import '../widgets/operational_hub_grid.dart';
import 'admin_remote_config_center_screen.dart';
import 'assistive_intelligence_center_screen.dart';
import 'checkin_screen.dart';
import 'clean_code_audit_center_screen.dart';
import 'data_governance_center_screen.dart';
import 'field_operations_center_screen.dart';
import 'observability_support_center_screen.dart';
import 'operational_snapshot_export_screen.dart';
import 'production_readiness_center_screen.dart';
import 'quality_stability_center_screen.dart';

class OperationalHubScreen extends StatelessWidget {
  const OperationalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const OperationalHubRegistryService().items();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Centrais integradas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse o fluxo principal e as centrais operacionais a partir de um único ponto.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          OperationalHubGrid(
            items: items,
            onTap: (item) => _open(context, item),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, OperationalHubItem item) {
    Widget destination;

    switch (item.id) {
      case 'checkin':
        destination = const CheckinScreen();
        break;
      case 'field_ops':
        destination = ChangeNotifierProvider<FieldOperationState>(
          create: (_) => FieldOperationState.demo(),
          child: const FieldOperationsCenterScreen(),
        );
        break;
      case 'assistive':
        destination = const AssistiveIntelligenceCenterScreen();
        break;
      case 'quality':
        destination = const QualityStabilityCenterScreen();
        break;
      case 'observability':
        destination = const ObservabilitySupportCenterScreen();
        break;
      case 'governance':
        destination = const DataGovernanceCenterScreen();
        break;
      case 'production':
        destination = const ProductionReadinessCenterScreen();
        break;
      case 'admin':
        destination = const AdminRemoteConfigCenterScreen();
        break;
      case 'clean_code':
        destination = const CleanCodeAuditCenterScreen();
        break;
      case 'export':
        destination = const OperationalSnapshotExportScreen();
        break;
      default:
        destination = const CheckinScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
