import 'technical_rule_result.dart';

class TechnicalPendingMatrix {
  final List<TechnicalRuleResult> items;

  const TechnicalPendingMatrix({
    required this.items,
  });

  List<TechnicalRuleResult> byStage(TechnicalRuleStage stage) {
    return items.where((item) => item.stage == stage).toList();
  }

  List<TechnicalRuleResult> get checkin => byStage(TechnicalRuleStage.checkin);
  List<TechnicalRuleResult> get capture => byStage(TechnicalRuleStage.capture);
  List<TechnicalRuleResult> get review => byStage(TechnicalRuleStage.review);
  List<TechnicalRuleResult> get finalization => byStage(TechnicalRuleStage.finalization);

  int get totalBlocking => items.where((item) => item.isBlocking).length;
  int get totalAdvisory => items.where((item) => item.isAdvisory).length;
  bool get hasBlocking => totalBlocking > 0;
  bool get hasAny => items.isNotEmpty;
}
