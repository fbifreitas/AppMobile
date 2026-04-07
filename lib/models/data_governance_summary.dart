import 'data_governance_issue.dart';

class DataGovernanceSummary {
  final List<DataGovernanceIssue> issues;

  const DataGovernanceSummary({
    required this.issues,
  });

  int get total => issues.length;
  int get blocking => issues.where((item) => item.isBlocking).length;
  int get unresolved => issues.where((item) => !item.resolved).length;
  bool get canProceed => blocking == 0;
}
