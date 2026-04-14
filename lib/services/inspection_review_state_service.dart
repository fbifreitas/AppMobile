import '../models/inspection_review_models.dart';
import '../models/overlay_camera_capture_result.dart';

class InspectionReviewStateService {
  const InspectionReviewStateService();

  static const InspectionReviewStateService instance =
      InspectionReviewStateService();

  void appendCapture({
    required List<OverlayCameraCaptureResult> captures,
    required List<InspectionReviewEditableCapture> items,
    required OverlayCameraCaptureResult capture,
  }) {
    captures.add(capture);
    items.add(InspectionReviewEditableCapture.fromCapture(capture));
  }

  void appendReviewCapture({
    required List<OverlayCameraCaptureResult> captures,
    required List<InspectionReviewEditableCapture> items,
    required OverlayCameraCaptureResult capture,
  }) => appendCapture(captures: captures, items: items, capture: capture);

  void applySubtype(InspectionReviewNodeGroup group) {
    if (group.items.isEmpty) return;
    final source = group.items.firstWhere(
      (item) => item.hasAnyClassification,
      orElse: () => group.items.first,
    );

    for (final item in group.items) {
      item.copyClassificationFrom(source);
      item.recalculateStatus(forceClassified: true);
    }
  }

  void applyClassificationGroup(InspectionReviewNodeGroup group) =>
      applySubtype(group);

  void acceptSuggestions(InspectionReviewNodeGroup group) {
    for (final item in group.items) {
      if (item.status == InspectionReviewPhotoStatus.suggested) {
        item.recalculateStatus(forceClassified: true);
      }
    }
  }

  void acceptSuggestedClassifications(InspectionReviewNodeGroup group) =>
      acceptSuggestions(group);

  void applySimilar(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  ) {
    for (final item in group.items) {
      item.copyClassificationFrom(source);
      item.recalculateStatus(forceClassified: true);
    }
  }

  void applyClassificationFromSource(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  ) => applySimilar(group, source);

  List<OverlayCameraCaptureResult> rebuildCapturesFromItems({
    required List<OverlayCameraCaptureResult> captures,
    required Iterable<InspectionReviewEditableCapture> items,
  }) {
    final byPath = <String, InspectionReviewEditableCapture>{
      for (final item in items) item.filePath: item,
    };

    return captures.map((capture) {
      final item = byPath[capture.filePath];
      if (item == null) {
        return capture.clearClassification(
          ambiente: capture.ambienteBaseLabel,
          ambienteBase: capture.ambienteBase,
          ambienteInstanceIndex: capture.ambienteInstanceIndex,
        );
      }

      return capture.copyWith(
        macroLocal: item.macroLocal,
        ambiente: item.ambiente,
        ambienteBase: item.ambienteBase,
        ambienteInstanceIndex: item.ambienteInstanceIndex,
        elemento: item.elemento,
        material: item.material,
        estado: item.estado,
        classificationConfirmed:
            item.status == InspectionReviewPhotoStatus.classified,
      );
    }).toList(growable: false);
  }

  List<OverlayCameraCaptureResult> rebuildReviewCaptures({
    required List<OverlayCameraCaptureResult> captures,
    required Iterable<InspectionReviewEditableCapture> items,
  }) => rebuildCapturesFromItems(captures: captures, items: items);

  void syncCapturesFromItems({
    required List<OverlayCameraCaptureResult> captures,
    required Iterable<InspectionReviewEditableCapture> items,
    bool classificationConfirmed = false,
  }) {
    for (final item in items) {
      final index = captures.indexWhere(
        (capture) => capture.filePath == item.filePath,
      );
      if (index < 0) continue;

      captures[index] = captures[index].copyWith(
        macroLocal: item.macroLocal,
        ambiente: item.ambiente,
        ambienteBase: item.ambienteBase,
        ambienteInstanceIndex: item.ambienteInstanceIndex,
        elemento: item.elemento,
        material: item.material,
        estado: item.estado,
        classificationConfirmed:
            classificationConfirmed ||
            item.status == InspectionReviewPhotoStatus.classified,
      );
    }
  }

  void syncReviewCaptures({
    required List<OverlayCameraCaptureResult> captures,
    required Iterable<InspectionReviewEditableCapture> items,
    bool classificationConfirmed = false,
  }) => syncCapturesFromItems(
    captures: captures,
    items: items,
    classificationConfirmed: classificationConfirmed,
  );
}
