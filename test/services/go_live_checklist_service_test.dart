import 'package:appmobile/services/go_live_checklist_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('go live checklist blocks release when analyze fails', () {
    final summary = const GoLiveChecklistService().build(
      analyzeOk: false,
      testsOk: true,
      mainFlowOk: true,
      syncFlowOk: true,
      voiceFlowOk: true,
      technicalFlowOk: true,
      platformReady: true,
      accessibilityReviewed: true,
    );

    expect(summary.ready, isFalse);
    expect(summary.blockingCount, greaterThan(0));
  });

  test('go live checklist is ready when blocking items pass', () {
    final summary = const GoLiveChecklistService().build(
      analyzeOk: true,
      testsOk: true,
      mainFlowOk: true,
      syncFlowOk: true,
      voiceFlowOk: true,
      technicalFlowOk: true,
      platformReady: true,
      accessibilityReviewed: false,
    );

    expect(summary.ready, isTrue);
  });
}
