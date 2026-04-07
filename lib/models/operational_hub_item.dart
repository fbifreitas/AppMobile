class OperationalHubItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String iconKey;
  final bool highlighted;

  const OperationalHubItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconKey,
    this.highlighted = false,
  });
}
