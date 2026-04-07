import '../models/operational_snapshot_item.dart';

class OperationalSnapshotExportService {
  const OperationalSnapshotExportService();

  List<OperationalSnapshotItem> build({
    required bool checkinReady,
    required bool fieldOpsReady,
    required bool assistiveReady,
    required bool qualityReady,
    required bool observabilityReady,
    required bool governanceReady,
    required bool productionReady,
    required bool adminReady,
  }) {
    return <OperationalSnapshotItem>[
      OperationalSnapshotItem(title: 'Check-in', value: checkinReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Operação de campo', value: fieldOpsReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'IA assistiva', value: assistiveReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Qualidade', value: qualityReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Observabilidade', value: observabilityReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Governança', value: governanceReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Prontidão para produção', value: productionReady ? 'Disponível' : 'Pendente'),
      OperationalSnapshotItem(title: 'Administração', value: adminReady ? 'Disponível' : 'Pendente'),
    ];
  }

  String buildPlainText({
    required String appName,
    required List<OperationalSnapshotItem> items,
  }) {
    final lines = <String>[
      'Snapshot operacional - $appName',
      'Gerado em: ${DateTime.now().toIso8601String()}',
      '',
      ...items.map((item) => '- ${item.title}: ${item.value}'),
    ];
    return lines.join('\n');
  }
}
