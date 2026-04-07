import '../config/checkin_step2_config.dart';
import 'flow_selection.dart';
import 'overlay_camera_capture_result.dart';

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
  FlowSelection selection;
  DateTime capturedAt;
  InspectionReviewPhotoStatus status;

  InspectionReviewEditableCapture({
    required this.filePath,
    required this.selection,
    required this.capturedAt,
    required this.status,
  });

  String? get macroLocal => selection.subjectContext;
  set macroLocal(String? value) {
    selection = selection.copyWith(
      subjectContext: value,
      clearSubjectContext: value == null || value.trim().isEmpty,
    );
  }

  String get ambiente => selection.targetItem ?? '';
  set ambiente(String value) {
    selection = selection.copyWith(targetItem: value);
  }

  String? get ambienteBase => selection.targetItemBase;
  set ambienteBase(String? value) {
    selection = selection.copyWith(
      targetItemBase: value,
      clearTargetItemBase: value == null || value.trim().isEmpty,
    );
  }

  int? get ambienteInstanceIndex => selection.targetItemInstanceIndex;
  set ambienteInstanceIndex(int? value) {
    selection = selection.copyWith(
      targetItemInstanceIndex: value,
      clearTargetItemInstanceIndex: value == null,
    );
  }

  String? get elemento => selection.targetQualifier;
  set elemento(String? value) {
    selection = selection.copyWith(
      targetQualifier: value,
      clearTargetQualifier: value == null || value.trim().isEmpty,
    );
  }

  String? get material => selection.attributeText('inspection.material');
  set material(String? value) {
    final nextAttributes = Map<String, dynamic>.from(selection.domainAttributes);
    if (value == null || value.trim().isEmpty) {
      nextAttributes.remove('inspection.material');
    } else {
      nextAttributes['inspection.material'] = value;
    }
    selection = selection.copyWith(
      domainAttributes: nextAttributes,
      clearDomainAttributes: nextAttributes.isEmpty,
    );
  }

  String? get estado => selection.targetCondition;
  set estado(String? value) {
    selection = selection.copyWith(
      targetCondition: value,
      clearTargetCondition: value == null || value.trim().isEmpty,
    );
  }

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
      selection: capture.selection,
      capturedAt: capture.capturedAt,
      status:
          hasCompleteClassification
              ? InspectionReviewPhotoStatus.classified
              : hasAnyClassification
              ? InspectionReviewPhotoStatus.suggested
              : InspectionReviewPhotoStatus.pending,
    );
  }

  factory InspectionReviewEditableCapture.fromReviewMap({
    required Map<String, dynamic> reviewed,
    required InspectionReviewEditableCapture fallback,
  }) {
    final merged = <String, dynamic>{
      ...fallback.selection.toMap(includeCanonical: true, includeLegacy: true),
      ...reviewed,
    };
    final editable = InspectionReviewEditableCapture(
      filePath: fallback.filePath,
      selection: FlowSelection.fromMap(merged),
      capturedAt: fallback.capturedAt,
      status: fallback.status,
    );
    editable.recalculateStatus(forceClassified: reviewed['isComplete'] == true);
    return editable;
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
    selection = source.selection;
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

  Map<String, dynamic> toReviewMap() => <String, dynamic>{
    'filePath': filePath,
    ...selection.toMap(includeCanonical: true, includeLegacy: true),
    'isComplete': status == InspectionReviewPhotoStatus.classified,
  };
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
