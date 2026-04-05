import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';
import '../models/overlay_camera_capture_result.dart';

class InspectionFieldRequirementStatus {
  final CheckinStep2PhotoFieldConfig field;
  final bool isDone;
  final bool matchedPersistedPhoto;
  final bool matchedCapture;

  const InspectionFieldRequirementStatus({
    required this.field,
    required this.isDone,
    required this.matchedPersistedPhoto,
    required this.matchedCapture,
  });
}

class InspectionRequirementPolicyService {
  const InspectionRequirementPolicyService();

  static const InspectionRequirementPolicyService instance =
      InspectionRequirementPolicyService();

  List<InspectionFieldRequirementStatus> evaluateMandatoryFieldStatuses({
    required Iterable<CheckinStep2PhotoFieldConfig> fields,
    required CheckinStep2Model persistedModel,
    required Iterable<OverlayCameraCaptureResult> captures,
  }) {
    return fields.where((field) => field.obrigatorio).map((field) {
      final matchedCapture =
          findMatchingCapture(captures: captures, field: field) != null;
      final matchedPersistedPhoto = persistedModel.isPhotoCaptured(field.id);

      return InspectionFieldRequirementStatus(
        field: field,
        isDone: matchedCapture || matchedPersistedPhoto,
        matchedPersistedPhoto: matchedPersistedPhoto,
        matchedCapture: matchedCapture,
      );
    }).toList(growable: false);
  }

  int countCompletedMandatoryFields({
    required Iterable<CheckinStep2PhotoFieldConfig> fields,
    required CheckinStep2Model persistedModel,
    Iterable<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
  }) {
    return evaluateMandatoryFieldStatuses(
      fields: fields,
      persistedModel: persistedModel,
      captures: captures,
    ).where((status) => status.isDone).length;
  }

  OverlayCameraCaptureResult? findMatchingCapture({
    required Iterable<OverlayCameraCaptureResult> captures,
    required CheckinStep2PhotoFieldConfig field,
  }) {
    for (final capture in captures.toList().reversed) {
      final sameAmbiente =
          normalizeComparableText(capture.ambienteBaseLabel) ==
          normalizeComparableText(field.cameraAmbiente);
      final sameElemento =
          field.cameraElementoInicial == null ||
          normalizeComparableText(capture.elemento) ==
              normalizeComparableText(field.cameraElementoInicial);

      if (sameAmbiente && sameElemento) {
        return capture;
      }
    }
    return null;
  }

  String normalizeComparableText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return '';

    return text
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã¢', 'a')
        .replaceAll('Ã£', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ãª', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('Ã­', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ã´', 'o')
        .replaceAll('Ãµ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('Ãº', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('Ã§', 'c')
        .replaceAll('•', '')
        .replaceAll('â€¢', '');
  }
}
