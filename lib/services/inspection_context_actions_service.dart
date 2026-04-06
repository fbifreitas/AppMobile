import 'inspection_environment_instance_service.dart';

class InspectionContextActionsService {
  const InspectionContextActionsService({
    InspectionEnvironmentInstanceService environmentInstanceService =
        InspectionEnvironmentInstanceService.instance,
  }) : _environmentInstanceService = environmentInstanceService;

  static const InspectionContextActionsService instance =
      InspectionContextActionsService();

  final InspectionEnvironmentInstanceService _environmentInstanceService;

  String? duplicateActionLabelFor(String? selectedAmbiente) {
    final parsed = _environmentInstanceService.parse(selectedAmbiente);
    if (parsed.baseLabel.trim().isEmpty) {
      return null;
    }
    return 'Novo ${parsed.baseLabel}';
  }

  String nextDuplicatedAmbienteLabel({
    required String selectedAmbiente,
    required Iterable<String> existingLabels,
  }) {
    return _environmentInstanceService.nextDisplayLabel(
      selectedLabel: selectedAmbiente,
      existingLabels: existingLabels,
    );
  }
}
