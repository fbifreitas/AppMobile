import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/admin_remote_config_center_screen.dart';
import '../screens/app_integration_center_screen.dart';
import '../screens/assistive_intelligence_center_screen.dart';
import '../screens/clean_code_audit_center_screen.dart';
import '../screens/data_governance_center_screen.dart';
import '../screens/fallback_audit_center_screen.dart';
import '../screens/field_operations_center_screen.dart';
import '../screens/mock_data_control_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/observability_support_center_screen.dart';
import '../screens/operational_hub_screen.dart';
import '../screens/operational_snapshot_export_screen.dart';
import '../screens/production_readiness_center_screen.dart';
import '../screens/quality_stability_center_screen.dart';
import '../screens/settings_screen.dart';
import '../services/inspection_flow_coordinator.dart';
import '../state/field_operation_state.dart';

abstract class AppNavigationCoordinator {
  const AppNavigationCoordinator();

  void openNotifications(BuildContext context);

  void openSettings(BuildContext context);

  void openOperationalHub(BuildContext context);

  void openAppIntegrationCenter(BuildContext context);

  void openOperationalHubItem(BuildContext context, {required String itemId});

  void openAppShortcut(BuildContext context, {required String routeKey});
}

class DefaultAppNavigationCoordinator implements AppNavigationCoordinator {
  const DefaultAppNavigationCoordinator({
    this.inspectionFlowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  final InspectionFlowCoordinator inspectionFlowCoordinator;

  @override
  void openNotifications(BuildContext context) {
    _push(context, const NotificationsScreen());
  }

  @override
  void openSettings(BuildContext context) {
    _push(context, const SettingsScreen());
  }

  @override
  void openOperationalHub(BuildContext context) {
    _push(context, OperationalHubScreen(navigationCoordinator: this));
  }

  @override
  void openAppIntegrationCenter(BuildContext context) {
    _push(context, AppIntegrationCenterScreen(navigationCoordinator: this));
  }

  @override
  void openOperationalHubItem(BuildContext context, {required String itemId}) {
    switch (itemId) {
      case 'checkin':
        inspectionFlowCoordinator.openCheckin(context);
        return;
      case 'field_ops':
        _push(
          context,
          ChangeNotifierProvider<FieldOperationState>(
            create: (_) => FieldOperationState.demo(),
            child: const FieldOperationsCenterScreen(),
          ),
        );
        return;
      case 'assistive':
        _push(context, const AssistiveIntelligenceCenterScreen());
        return;
      case 'quality':
        _push(context, const QualityStabilityCenterScreen());
        return;
      case 'fallback_audit':
        _push(context, const FallbackAuditCenterScreen());
        return;
      case 'observability':
        _push(context, const ObservabilitySupportCenterScreen());
        return;
      case 'governance':
        _push(context, const DataGovernanceCenterScreen());
        return;
      case 'production':
        _push(context, const ProductionReadinessCenterScreen());
        return;
      case 'admin':
        _push(context, const AdminRemoteConfigCenterScreen());
        return;
      case 'clean_code':
        _push(context, const CleanCodeAuditCenterScreen());
        return;
      case 'export':
        _push(context, const OperationalSnapshotExportScreen());
        return;
      case 'mock_data':
        _push(context, const MockDataControlScreen());
        return;
      default:
        inspectionFlowCoordinator.openCheckin(context);
    }
  }

  @override
  void openAppShortcut(BuildContext context, {required String routeKey}) {
    switch (routeKey) {
      case 'checkin':
        inspectionFlowCoordinator.openCheckin(context);
        return;
      case 'hub':
        openOperationalHub(context);
        return;
      case 'snapshot':
        _push(context, const OperationalSnapshotExportScreen());
        return;
      default:
        openOperationalHub(context);
    }
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
