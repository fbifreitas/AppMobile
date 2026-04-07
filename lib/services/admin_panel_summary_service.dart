import '../models/admin_panel_summary.dart';
import 'admin_action_catalog_service.dart';
import 'remote_config_catalog_service.dart';

class AdminPanelSummaryService {
  const AdminPanelSummaryService();

  AdminPanelSummary build() {
    final configs = const RemoteConfigCatalogService().items();
    final actions = const AdminActionCatalogService().items();

    return AdminPanelSummary(
      totalConfigs: configs.length,
      editableConfigs: configs.where((item) => item.editable).length,
      totalActions: actions.length,
      availableActions: actions.where((item) => item.available).length,
    );
  }
}
