class JobDistanceInfo {
  const JobDistanceInfo({
    required this.label,
    required this.rangeLabel,
    required this.withinRange,
  });

  final String label;
  final String rangeLabel;
  final bool withinRange;

  factory JobDistanceInfo.pending() {
    return const JobDistanceInfo(
      label: 'Localização pendente',
      rangeLabel: 'Sem cálculo',
      withinRange: false,
    );
  }

  factory JobDistanceInfo.onSite() {
    return const JobDistanceInfo(
      label: 'Você está no local',
      rangeLabel: 'Dentro do raio',
      withinRange: true,
    );
  }
}
