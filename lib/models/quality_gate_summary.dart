import 'stability_check_result.dart';

class QualityGateSummary {
  final List<StabilityCheckResult> checks;

  const QualityGateSummary({
    required this.checks,
  });

  int get total => checks.length;
  int get passed => checks.where((item) => item.passed).length;
  int get failed => checks.where((item) => !item.passed).length;
  int get blocking => checks.where((item) => item.isBlocking).length;
  int get warnings => checks.where((item) => item.isWarning).length;

  bool get canPromote => blocking == 0;
}
