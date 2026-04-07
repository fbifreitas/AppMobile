class ObservabilityMetricSnapshot {
  final int totalLogs;
  final int errorLogs;
  final int warningLogs;
  final int syncEvents;
  final int voiceEvents;
  final int technicalEvents;
  final int assistiveEvents;

  const ObservabilityMetricSnapshot({
    required this.totalLogs,
    required this.errorLogs,
    required this.warningLogs,
    required this.syncEvents,
    required this.voiceEvents,
    required this.technicalEvents,
    required this.assistiveEvents,
  });
}
