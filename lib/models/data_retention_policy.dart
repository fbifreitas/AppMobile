enum DataRetentionScope {
  voiceHistory,
  observabilityLogs,
  syncQueue,
  resumeState,
  assistiveLearning,
}

class DataRetentionPolicy {
  final DataRetentionScope scope;
  final int maxEntries;
  final int maxAgeDays;
  final bool sensitive;
  final String description;

  const DataRetentionPolicy({
    required this.scope,
    required this.maxEntries,
    required this.maxAgeDays,
    required this.sensitive,
    required this.description,
  });
}
