import '../config/checkin_step2_config.dart';
import '../models/flow_selection.dart';
import '../models/overlay_camera_capture_result.dart';

enum InspectionReviewPhotoStatus { pending, suggested, classified }

class InspectionReviewRequirementStatus {
  final CheckinStep2PhotoFieldConfig field;
  final bool isDone;

  const InspectionReviewRequirementStatus({
    required this.field,
    required this.isDone,
  });
}

class InspectionReviewRequirementGroupStatus {
  final String title;
  final dynamic icon;
  final int doneCount;
  final int totalCount;
  final InspectionReviewRequirementStatus? pendingStatus;
  final List<InspectionReviewRequirementStatus> statuses;

  const InspectionReviewRequirementGroupStatus({
    required this.title,
    required this.icon,
    required this.doneCount,
    required this.totalCount,
    required this.pendingStatus,
    required this.statuses,
  });

  bool get isDone => doneCount >= totalCount;
}

class InspectionReviewEditableCapture {
  String filePath;
  String? macroLocal;
  String ambiente;
  String? ambienteBase;
  int? ambienteInstanceIndex;
  String? elemento;
  String? material;
  String? estado;
  DateTime capturedAt;
  InspectionReviewPhotoStatus status;

  InspectionReviewEditableCapture({
    required this.filePath,
    required this.macroLocal,
    required this.ambiente,
    required this.ambienteBase,
    required this.ambienteInstanceIndex,
    required this.elemento,
    required this.material,
    required this.estado,
    required this.capturedAt,
    required this.status,
  });

  factory InspectionReviewEditableCapture.fromCapture(
    OverlayCameraCaptureResult capture,
  ) {
    final hasCompleteClassification =
        (capture.elemento?.trim().isNotEmpty ?? false) &&
        (capture.material?.trim().isNotEmpty ?? false) &&
        (capture.estado?.trim().isNotEmpty ?? false);
    final hasAnyClassification =
        (capture.elemento?.trim().isNotEmpty ?? false) ||
        (capture.material?.trim().isNotEmpty ?? false) ||
        (capture.estado?.trim().isNotEmpty ?? false);

    return InspectionReviewEditableCapture(
      filePath: capture.filePath,
      macroLocal: capture.macroLocal,
      ambiente: capture.ambiente,
      ambienteBase: capture.ambienteBase,
      ambienteInstanceIndex: capture.ambienteInstanceIndex,
      elemento: capture.elemento,
      material: capture.material,
      estado: capture.estado,
      capturedAt: capture.capturedAt,
      status:
          hasCompleteClassification
              ? InspectionReviewPhotoStatus.classified
              : hasAnyClassification
              ? InspectionReviewPhotoStatus.suggested
              : InspectionReviewPhotoStatus.pending,
    );
  }

  /// Canonical view of the capture's domain selection.
  FlowSelection get selection => FlowSelection(
    subjectContext: macroLocal,
    targetItem: ambiente,
    targetItemBase: ambienteBase,
    targetItemInstanceIndex: ambienteInstanceIndex,
    targetQualifier: elemento,
    targetCondition: estado,
    domainAttributes: <String, dynamic>{
      if (material != null && material!.trim().isNotEmpty)
        'inspection.material': material,
    },
  );

  /// Applies a [FlowSelection] back to the mutable fields.
  void applySelection(FlowSelection s) {
    macroLocal = s.subjectContext;
    ambiente = s.targetItem ?? ambiente;
    ambienteBase = s.targetItemBase;
    ambienteInstanceIndex = s.targetItemInstanceIndex;
    elemento = s.targetQualifier;
    material = s.attributeText('inspection.material');
    estado = s.targetCondition;
  }

  bool get hasAnyClassification =>
      (elemento?.trim().isNotEmpty ?? false) ||
      (material?.trim().isNotEmpty ?? false) ||
      (estado?.trim().isNotEmpty ?? false);

  String get hourMinute =>
      '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}';

  String get shortDescription {
    final parts = <String>[
      if (elemento?.trim().isNotEmpty == true) elemento!,
      if (material?.trim().isNotEmpty == true) material!,
      if (estado?.trim().isNotEmpty == true) estado!,
    ];
    return parts.isEmpty ? 'Sem classificação' : parts.join(' • ');
  }

  void copyClassificationFrom(InspectionReviewEditableCapture source) {
    ambiente = source.ambiente;
    ambienteBase = source.ambienteBase;
    ambienteInstanceIndex = source.ambienteInstanceIndex;
    elemento = source.elemento;
    material = source.material;
    estado = source.estado;
    macroLocal = source.macroLocal;
  }

  void recalculateStatus({bool forceClassified = false}) {
    final hasCompleteClassification =
        (elemento?.trim().isNotEmpty ?? false) &&
        (material?.trim().isNotEmpty ?? false) &&
        (estado?.trim().isNotEmpty ?? false);
    final hasAnyClassification =
        (elemento?.trim().isNotEmpty ?? false) ||
        (material?.trim().isNotEmpty ?? false) ||
        (estado?.trim().isNotEmpty ?? false);

    if (forceClassified && hasAnyClassification) {
      status = InspectionReviewPhotoStatus.classified;
      return;
    }
    if (hasCompleteClassification) {
      status = InspectionReviewPhotoStatus.classified;
    } else if (hasAnyClassification) {
      status = InspectionReviewPhotoStatus.suggested;
    } else {
      status = InspectionReviewPhotoStatus.pending;
    }
  }
}

class InspectionReviewNodeGroup {
  final String title;
  final List<InspectionReviewEditableCapture> items;
  final int pending;
  final int suggested;
  final int classified;

  const InspectionReviewNodeGroup({
    required this.title,
    required this.items,
    required this.pending,
    required this.suggested,
    required this.classified,
  });
}
