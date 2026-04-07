import 'inspection_environment_instance_service.dart';
import 'inspection_domain_adapter.dart';

class InspectionContextActionsService {
  const InspectionContextActionsService({
    InspectionEnvironmentInstanceService environmentInstanceService =
        InspectionEnvironmentInstanceService.instance,
    InspectionDomainAdapter domainAdapter = InspectionDomainAdapter.instance,
  }) : _environmentInstanceService = environmentInstanceService,
       _domainAdapter = domainAdapter;

  static const InspectionContextActionsService instance =
      InspectionContextActionsService();

  final InspectionEnvironmentInstanceService _environmentInstanceService;
  final InspectionDomainAdapter _domainAdapter;

  String? duplicateActionLabelFor(String? selectedAmbiente) {
    return _domainAdapter.duplicateActionLabelFor(selectedAmbiente);
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
