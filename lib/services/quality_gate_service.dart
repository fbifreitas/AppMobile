import '../models/quality_gate_summary.dart';
import '../models/stability_check_result.dart';
import 'quality_integrity_audit_service.dart';
import 'quality_sync_health_service.dart';
import 'quality_technical_health_service.dart';
import 'quality_voice_health_service.dart';

class QualityGateService {
  final QualityIntegrityAuditService integrityAudit;
  final QualitySyncHealthService syncHealth;
  final QualityVoiceHealthService voiceHealth;
  final QualityTechnicalHealthService technicalHealth;

  const QualityGateService({
    this.integrityAudit = const QualityIntegrityAuditService(),
    this.syncHealth = const QualitySyncHealthService(),
    this.voiceHealth = const QualityVoiceHealthService(),
    this.technicalHealth = const QualityTechnicalHealthService(),
  });

  QualityGateSummary build({
    required bool checkinScreenAvailable,
    required bool cameraScreenAvailable,
    required bool reviewScreenAvailable,
    required bool fieldOpsAvailable,
    required bool assistiveCenterAvailable,
    required int pendingQueue,
    required int failedQueue,
    required int conflictQueue,
    required bool syncScreenAvailable,
    required bool voiceServiceAvailable,
    required bool commandBarAvailable,
    required bool recentHistoryAvailable,
    required bool rankingAvailable,
    required bool technicalSummaryAvailable,
    required bool pendingMatrixAvailable,
    required bool justificationFlowAvailable,
    required int technicalBlockingCount,
  }) {
    final checks = <StabilityCheckResult>[
      ...integrityAudit.build(
        checkinScreenAvailable: checkinScreenAvailable,
        cameraScreenAvailable: cameraScreenAvailable,
        reviewScreenAvailable: reviewScreenAvailable,
        fieldOpsAvailable: fieldOpsAvailable,
        assistiveCenterAvailable: assistiveCenterAvailable,
      ),
      ...syncHealth.build(
        pendingQueue: pendingQueue,
        failedQueue: failedQueue,
        conflictQueue: conflictQueue,
        syncScreenAvailable: syncScreenAvailable,
      ),
      ...voiceHealth.build(
        voiceServiceAvailable: voiceServiceAvailable,
        commandBarAvailable: commandBarAvailable,
        recentHistoryAvailable: recentHistoryAvailable,
        rankingAvailable: rankingAvailable,
      ),
      ...technicalHealth.build(
        technicalSummaryAvailable: technicalSummaryAvailable,
        pendingMatrixAvailable: pendingMatrixAvailable,
        justificationFlowAvailable: justificationFlowAvailable,
        technicalBlockingCount: technicalBlockingCount,
      ),
    ];

    return QualityGateSummary(checks: checks);
  }
}
