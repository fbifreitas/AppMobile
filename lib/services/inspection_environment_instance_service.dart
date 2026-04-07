import 'contextual_item_instance_service.dart';

class InspectionEnvironmentInstance extends ContextualItemInstance {
  const InspectionEnvironmentInstance({
    required super.baseLabel,
    required super.instanceIndex,
  });
}

class InspectionEnvironmentInstanceService {
  const InspectionEnvironmentInstanceService();

  static const InspectionEnvironmentInstanceService instance =
      InspectionEnvironmentInstanceService();

  static const ContextualItemInstanceService _instanceService =
      ContextualItemInstanceService.instance;

  InspectionEnvironmentInstance parse(String? rawLabel) {
    final parsed = _instanceService.parse(rawLabel);
    return InspectionEnvironmentInstance(
      baseLabel: parsed.baseLabel,
      instanceIndex: parsed.instanceIndex,
    );
  }

  String baseLabelOf(String? rawLabel) => parse(rawLabel).baseLabel;

  String nextDisplayLabel({
    required String selectedLabel,
    required Iterable<String> existingLabels,
  }) {
    return _instanceService.nextDisplayLabel(
      selectedLabel: selectedLabel,
      existingLabels: existingLabels,
    );
  }
}
