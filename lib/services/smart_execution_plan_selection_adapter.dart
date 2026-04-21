import '../models/flow_selection.dart';
import '../models/smart_execution_plan.dart';

class SmartExecutionPlanSelectionAdapter {
  const SmartExecutionPlanSelectionAdapter();

  static const SmartExecutionPlanSelectionAdapter instance =
      SmartExecutionPlanSelectionAdapter();

  FlowSelection resolveInitialSelection(SmartExecutionPlan? plan) {
    if (plan == null) {
      return FlowSelection.empty;
    }

    final subjectContext = _normalizeContext(plan.initialContext);
    final targetItem = _normalizeEnvironment(plan.firstEnvironment);
    final targetQualifier = _normalizeElement(plan.firstElement);
    final material = _normalizeText(plan.firstMaterial);
    final targetCondition = _normalizeText(plan.firstCondition);

    return FlowSelection(
      subjectContext: subjectContext,
      targetItem: targetItem,
      targetQualifier: targetQualifier,
      targetCondition: targetCondition,
      domainAttributes: {
        if (material != null) 'inspection.material': material,
      },
    );
  }

  FlowSelection resolveSelectionForCapturePlanItem(
    SmartExecutionCapturePlanItem item,
  ) {
    final subjectContext = _normalizeContext(item.macroLocal);
    final targetItem = _normalizeEnvironment(item.environment);
    final targetQualifier = _normalizeElement(item.element);
    final material = _normalizeText(item.material);
    final targetCondition = _normalizeText(item.condition);

    return FlowSelection(
      subjectContext: subjectContext,
      targetItem: targetItem,
      targetQualifier: targetQualifier,
      targetCondition: targetCondition,
      domainAttributes: {
        if (material != null) 'inspection.material': material,
      },
    );
  }

  String? _normalizeContext(String? raw) {
    final value = _normalizeText(raw);
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'street':
        return 'Rua';
      case 'external area':
        return 'Área externa';
      case 'internal area':
        return 'Área interna';
      default:
        return value;
    }
  }

  String? _normalizeEnvironment(String? raw) => _normalizeText(raw);

  String? _normalizeElement(String? raw) => _normalizeText(raw);

  String? _normalizeText(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}
