enum DataGovernanceSeverity { info, warning, blocking }

class DataGovernanceIssue {
  final String id;
  final String title;
  final String description;
  final DataGovernanceSeverity severity;
  final bool resolved;

  const DataGovernanceIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.resolved,
  });

  bool get isBlocking =>
      severity == DataGovernanceSeverity.blocking && !resolved;
}
