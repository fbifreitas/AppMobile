import 'package:appmobile/services/quality_gate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quality gate blocks promotion when critical checks fail', () {
    final summary = const QualityGateService().build(
      checkinScreenAvailable: false,
      cameraScreenAvailable: true,
      reviewScreenAvailable: true,
      fieldOpsAvailable: true,
      assistiveCenterAvailable: true,
      pendingQueue: 0,
      failedQueue: 0,
      conflictQueue: 0,
      syncScreenAvailable: true,
      voiceServiceAvailable: true,
      commandBarAvailable: true,
      recentHistoryAvailable: true,
      rankingAvailable: true,
      technicalSummaryAvailable: true,
      pendingMatrixAvailable: true,
      justificationFlowAvailable: true,
      technicalBlockingCount: 0,
    );

    expect(summary.canPromote, isFalse);
    expect(summary.blocking, greaterThan(0));
  });

  test('quality gate allows promotion when no blocking checks fail', () {
    final summary = const QualityGateService().build(
      checkinScreenAvailable: true,
      cameraScreenAvailable: true,
      reviewScreenAvailable: true,
      fieldOpsAvailable: true,
      assistiveCenterAvailable: true,
      pendingQueue: 0,
      failedQueue: 0,
      conflictQueue: 0,
      syncScreenAvailable: true,
      voiceServiceAvailable: true,
      commandBarAvailable: true,
      recentHistoryAvailable: true,
      rankingAvailable: true,
      technicalSummaryAvailable: true,
      pendingMatrixAvailable: true,
      justificationFlowAvailable: true,
      technicalBlockingCount: 0,
    );

    expect(summary.canPromote, isTrue);
  });
}
