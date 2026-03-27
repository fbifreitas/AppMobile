import '../models/stability_check_result.dart';

class QualitySyncHealthService {
  const QualitySyncHealthService();

  List<StabilityCheckResult> build({
    required int pendingQueue,
    required int failedQueue,
    required int conflictQueue,
    required bool syncScreenAvailable,
  }) {
    return <StabilityCheckResult>[
      StabilityCheckResult(
        id: 'sync_screen',
        title: 'Central operacional disponível',
        description: syncScreenAvailable
            ? 'A tela operacional de sync está disponível para diagnóstico.'
            : 'A tela operacional de sync não foi disponibilizada.',
        severity: StabilityCheckSeverity.blocking,
        passed: syncScreenAvailable,
        category: 'sync',
      ),
      StabilityCheckResult(
        id: 'sync_failures',
        title: 'Falhas de sincronização sob controle',
        description: failedQueue == 0
            ? 'Nenhum item falhou na fila atual.'
            : 'Existem $failedQueue item(ns) com falha de sincronização.',
        severity: StabilityCheckSeverity.warning,
        passed: failedQueue == 0,
        category: 'sync',
      ),
      StabilityCheckResult(
        id: 'sync_conflicts',
        title: 'Conflitos de sincronização sob controle',
        description: conflictQueue == 0
            ? 'Nenhum conflito foi detectado na fila atual.'
            : 'Existem $conflictQueue item(ns) em conflito.',
        severity: StabilityCheckSeverity.warning,
        passed: conflictQueue == 0,
        category: 'sync',
      ),
      StabilityCheckResult(
        id: 'sync_queue_visibility',
        title: 'Fila operacional monitorável',
        description: 'A fila atual contém $pendingQueue item(ns) pendente(s).',
        severity: StabilityCheckSeverity.info,
        passed: true,
        category: 'sync',
      ),
    ];
  }
}
