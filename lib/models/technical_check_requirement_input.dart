class InspectionNormativeRequirementInput {
  final String title;
  final bool fulfilled;
  final bool blockingOnFinish;
  final bool blockingOnCapture;

  const InspectionNormativeRequirementInput({
    required this.title,
    required this.fulfilled,
    this.blockingOnFinish = true,
    this.blockingOnCapture = false,
  });
}

class InspectionCaptureCoverageRequirementInput {
  final String title;
  final String subtipo;
  final String? elemento;

  const InspectionCaptureCoverageRequirementInput({
    required this.title,
    required this.subtipo,
    this.elemento,
  });
}

class TechnicalCheckRequirementInput extends InspectionNormativeRequirementInput {
  const TechnicalCheckRequirementInput({
    required super.title,
    required super.fulfilled,
    super.blockingOnFinish = true,
    super.blockingOnCapture = false,
  });
}

class TechnicalCoverageRequirementInput
    extends InspectionCaptureCoverageRequirementInput {
  const TechnicalCoverageRequirementInput({
    required super.title,
    required super.subtipo,
    super.elemento,
  });
}
