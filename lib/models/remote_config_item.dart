class RemoteConfigItem {
  final String key;
  final String title;
  final String value;
  final String category;
  final bool editable;
  final String description;

  const RemoteConfigItem({
    required this.key,
    required this.title,
    required this.value,
    required this.category,
    required this.editable,
    required this.description,
  });
}
