class OperationalCenterEntry {
  final String id;
  final String title;
  final String description;
  final String routeName;
  final String category;
  final bool enabled;

  const OperationalCenterEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.routeName,
    required this.category,
    required this.enabled,
  });
}
