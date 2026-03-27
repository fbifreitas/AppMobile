enum TechnicalRuleSeverity { blocking, advisory }

enum TechnicalRuleStage { checkin, capture, review, finalization }

class TechnicalRuleResult {
  final String id;
  final String title;
  final String description;
  final String? subtipo;
  final TechnicalRuleSeverity severity;
  final TechnicalRuleStage stage;
  final bool justificationAllowed;

  const TechnicalRuleResult({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.stage,
    this.subtipo,
    this.justificationAllowed = false,
  });

  bool get isBlocking => severity == TechnicalRuleSeverity.blocking;
  bool get isAdvisory => severity == TechnicalRuleSeverity.advisory;
}
