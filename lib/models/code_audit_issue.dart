enum CodeAuditSeverity { info, warning, blocking }

class CodeAuditIssue {
  final String id;
  final String title;
  final String description;
  final String area;
  final CodeAuditSeverity severity;
  final bool plannedForRefactor;

  const CodeAuditIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.severity,
    required this.plannedForRefactor,
  });

  bool get isBlocking =>
      severity == CodeAuditSeverity.blocking && plannedForRefactor;
}
