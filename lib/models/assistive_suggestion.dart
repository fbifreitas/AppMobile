class AssistiveSuggestion {
  final String id;
  final String context;
  final String title;
  final String description;
  final String? commandId;
  final double score;
  final String source;

  const AssistiveSuggestion({
    required this.id,
    required this.context,
    required this.title,
    required this.description,
    required this.score,
    required this.source,
    this.commandId,
  });
}
