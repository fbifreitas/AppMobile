import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/services/smart_execution_plan_selection_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps smart execution plan into canonical flow selection', () {
    const plan = SmartExecutionPlan(
      snapshotId: 5,
      caseId: 77,
      status: 'PUBLISHED',
      jobId: 'job-1',
      initialContext: 'Street',
      firstEnvironment: 'Front elevation',
      firstElement: 'Primary facade',
      firstMaterial: 'Concrete',
      firstCondition: 'Good',
    );

    final selection = SmartExecutionPlanSelectionAdapter.instance
        .resolveInitialSelection(plan);

    expect(selection.subjectContext, 'Rua');
    expect(selection.targetItem, 'Front elevation');
    expect(selection.targetQualifier, 'Primary facade');
    expect(selection.targetCondition, 'Good');
    expect(selection.attributeText('inspection.material'), 'Concrete');
  });

  test('returns empty selection when plan is absent', () {
    expect(
      SmartExecutionPlanSelectionAdapter.instance.resolveInitialSelection(null),
      FlowSelection.empty,
    );
  });
}
