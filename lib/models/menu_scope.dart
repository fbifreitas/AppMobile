class MenuScope {
  final String id;
  final String stage;
  final String propertyType;
  final List<String> availableLocals;

  MenuScope({
    required this.id,
    required this.stage,
    required this.propertyType,
    required this.availableLocals,
  });

  factory MenuScope.fromJson(Map<String, dynamic> json) {
    return MenuScope(
      id: json['id'],
      stage: json['stage'],
      propertyType: json['propertyType'],
      availableLocals: List<String>.from(json['availableLocals'] ?? []),
    );
  }
}
