enum GoLiveCheckSeverity { info, warning, blocking }

class GoLiveCheckItem {
  final String id;
  final String title;
  final String description;
  final GoLiveCheckSeverity severity;
  final bool done;

  const GoLiveCheckItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.done,
  });

  bool get isBlocking => severity == GoLiveCheckSeverity.blocking && !done;
}
