import 'code_audit_issue.dart';

class CodeAuditSummary {
  final List<CodeAuditIssue> issues;

  const CodeAuditSummary({
    required this.issues,
  });

  int get total => issues.length;
  int get blocking => issues.where((item) => item.isBlocking).length;
  int get warnings =>
      issues.where((item) => item.severity == CodeAuditSeverity.warning).length;
  int get infos =>
      issues.where((item) => item.severity == CodeAuditSeverity.info).length;

  bool get shouldRefactorBeforeGoLive => blocking > 0;
}
