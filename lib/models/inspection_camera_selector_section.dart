class InspectionCameraSelectorSection {
  final String levelId;
  final String title;
  final List<String> values;
  final String? selected;
  final bool allowVoiceSelection;
  final bool allowDuplicate;
  final String? duplicateLabel;

  const InspectionCameraSelectorSection({
    required this.levelId,
    required this.title,
    required this.values,
    required this.selected,
    this.allowVoiceSelection = false,
    this.allowDuplicate = false,
    this.duplicateLabel,
  });
}
