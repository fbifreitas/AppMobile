class FallbackAuditCheck {
  final String id;
  final String stage;
  final String title;
  final String detail;
  final bool passed;
  final bool warning;

  const FallbackAuditCheck({
    required this.id,
    required this.stage,
    required this.title,
    required this.detail,
    required this.passed,
    this.warning = false,
  });
}

class FallbackAuditReport {
  final String generatedAtIso;
  final String stageKey;
  final String stageLabel;
  final String routeName;
  final int totalChecks;
  final int failedChecks;
  final int warningChecks;
  final List<FallbackAuditCheck> checks;

  const FallbackAuditReport({
    required this.generatedAtIso,
    required this.stageKey,
    required this.stageLabel,
    required this.routeName,
    required this.totalChecks,
    required this.failedChecks,
    required this.warningChecks,
    required this.checks,
  });

  bool get isHealthy => failedChecks == 0;
}
