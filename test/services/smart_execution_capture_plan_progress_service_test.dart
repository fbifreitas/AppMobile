import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/services/smart_execution_capture_plan_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

OverlayCameraCaptureResult _capture({
  required String macroLocal,
  required String ambiente,
  String? elemento,
}) {
  return OverlayCameraCaptureResult(
    filePath: '/tmp/test.jpg',
    macroLocal: macroLocal,
    ambiente: ambiente,
    ambienteBase: ambiente,
    elemento: elemento,
    capturedAt: DateTime(2026, 1, 1),
    latitude: -23,
    longitude: -46,
    accuracy: 5,
  );
}

void main() {
  const service = SmartExecutionCapturePlanProgressService.instance;

  test('resolves next pending required capture plan item', () {
    const plan = SmartExecutionPlan(
      snapshotId: 1,
      caseId: 10,
      status: 'PUBLISHED',
      jobId: 'job-1',
      capturePlan: [
        SmartExecutionCapturePlanItem(
          macroLocal: 'Rua',
          environment: 'Fachada',
          element: 'Porta principal',
          required: true,
          minPhotos: 2,
        ),
        SmartExecutionCapturePlanItem(
          macroLocal: 'Rua',
          environment: 'Garagem',
          required: true,
          minPhotos: 1,
        ),
      ],
    );

    final progress = service.resolve(
      plan: plan,
      captures: [
        _capture(
          macroLocal: 'Rua',
          ambiente: 'Fachada',
          elemento: 'Porta principal',
        ),
      ],
    );

    expect(progress.totalItems, 2);
    expect(progress.completedItems, 0);
    expect(progress.nextPendingItem, isNotNull);
    expect(progress.nextPendingItem!.environment, 'Fachada');
  });

  test('marks required capture plan item as completed when min photos is met', () {
    const plan = SmartExecutionPlan(
      snapshotId: 1,
      caseId: 10,
      status: 'PUBLISHED',
      jobId: 'job-1',
      capturePlan: [
        SmartExecutionCapturePlanItem(
          macroLocal: 'Rua',
          environment: 'Fachada',
          element: 'Porta principal',
          required: true,
          minPhotos: 2,
        ),
        SmartExecutionCapturePlanItem(
          macroLocal: 'Rua',
          environment: 'Garagem',
          required: true,
          minPhotos: 1,
        ),
      ],
    );

    final progress = service.resolve(
      plan: plan,
      captures: [
        _capture(
          macroLocal: 'Rua',
          ambiente: 'Fachada',
          elemento: 'Porta principal',
        ),
        _capture(
          macroLocal: 'Rua',
          ambiente: 'Fachada',
          elemento: 'Porta principal',
        ),
      ],
    );

    expect(progress.totalItems, 2);
    expect(progress.completedItems, 1);
    expect(progress.nextPendingItem, isNotNull);
    expect(progress.nextPendingItem!.environment, 'Garagem');
  });
}
