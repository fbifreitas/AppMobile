class AppNavigationEntry {
  final String id;
  final String title;
  final String description;
  final String routeKey;
  final bool primary;

  const AppNavigationEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.routeKey,
    this.primary = false,
  });
}
