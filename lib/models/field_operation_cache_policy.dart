class FieldOperationCachePolicy {
  final int maxQueueItems;
  final int maxResumeStates;
  final Duration staleResumeAfter;
  final int maxFileReferences;

  const FieldOperationCachePolicy({
    this.maxQueueItems = 500,
    this.maxResumeStates = 50,
    this.staleResumeAfter = const Duration(days: 7),
    this.maxFileReferences = 1000,
  });
}
