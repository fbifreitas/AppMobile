enum StabilityCheckSeverity { info, warning, blocking }

class StabilityCheckResult {
  final String id;
  final String title;
  final String description;
  final StabilityCheckSeverity severity;
  final bool passed;
  final String category;

  const StabilityCheckResult({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.passed,
    required this.category,
  });

  bool get isBlocking => severity == StabilityCheckSeverity.blocking && !passed;
  bool get isWarning => severity == StabilityCheckSeverity.warning && !passed;
}
