import '../models/stability_check_result.dart';

class QualityIntegrityAuditService {
  const QualityIntegrityAuditService();

  List<StabilityCheckResult> build({
    required bool checkinScreenAvailable,
    required bool cameraScreenAvailable,
    required bool reviewScreenAvailable,
    required bool fieldOpsAvailable,
    required bool assistiveCenterAvailable,
  }) {
    return <StabilityCheckResult>[
      StabilityCheckResult(
        id: 'screen_checkin',
        title: 'Check-in principal disponível',
        description: checkinScreenAvailable
            ? 'A tela principal de check-in está presente.'
            : 'A tela principal de check-in não foi localizada.',
        severity: StabilityCheckSeverity.blocking,
        passed: checkinScreenAvailable,
        category: 'integrity',
      ),
      StabilityCheckResult(
        id: 'screen_camera',
        title: 'Fluxo da câmera disponível',
        description: cameraScreenAvailable
            ? 'A tela da câmera está presente.'
            : 'A tela da câmera não foi localizada.',
        severity: StabilityCheckSeverity.blocking,
        passed: cameraScreenAvailable,
        category: 'integrity',
      ),
      StabilityCheckResult(
        id: 'screen_review',
        title: 'Revisão final disponível',
        description: reviewScreenAvailable
            ? 'A tela de revisão final está presente.'
            : 'A tela de revisão final não foi localizada.',
        severity: StabilityCheckSeverity.blocking,
        passed: reviewScreenAvailable,
        category: 'integrity',
      ),
      StabilityCheckResult(
        id: 'screen_field_ops',
        title: 'Operação de campo disponível',
        description: fieldOpsAvailable
            ? 'A central operacional de campo está presente.'
            : 'A central operacional de campo não foi localizada.',
        severity: StabilityCheckSeverity.warning,
        passed: fieldOpsAvailable,
        category: 'integrity',
      ),
      StabilityCheckResult(
        id: 'screen_assistive',
        title: 'Central assistiva disponível',
        description: assistiveCenterAvailable
            ? 'A central de IA assistiva está presente.'
            : 'A central de IA assistiva não foi localizada.',
        severity: StabilityCheckSeverity.info,
        passed: assistiveCenterAvailable,
        category: 'integrity',
      ),
    ];
  }
}
