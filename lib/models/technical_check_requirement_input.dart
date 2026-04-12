class TechnicalCheckRequirementInput {
  final String title;
  final bool fulfilled;

  const TechnicalCheckRequirementInput({
    required this.title,
    required this.fulfilled,
  });
}

class TechnicalCoverageRequirementInput {
  final String title;
  final String subtipo;
  final String? elemento;

  const TechnicalCoverageRequirementInput({
    required this.title,
    required this.subtipo,
    this.elemento,
  });
}
