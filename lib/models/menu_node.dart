class MenuNode {
  final String id;
  final String type;
  final String label;
  final bool active;
  final String? parentId;
  final List<String> allowedPropertyTypes;
  final List<String> allowedStages;
  final int manualOrder;
  final double baseScore;
  final bool pinnedTop;
  final bool pinnedBottom;

  MenuNode({
    required this.id,
    required this.type,
    required this.label,
    required this.active,
    required this.parentId,
    required this.allowedPropertyTypes,
    required this.allowedStages,
    required this.manualOrder,
    required this.baseScore,
    required this.pinnedTop,
    required this.pinnedBottom,
  });

  factory MenuNode.fromJson(Map<String, dynamic> json) {
    return MenuNode(
      id: json['id'],
      type: json['type'],
      label: json['label'],
      active: json['active'] ?? true,
      parentId: json['parentId'],
      allowedPropertyTypes: List<String>.from(json['allowedPropertyTypes'] ?? []),
      allowedStages: List<String>.from(json['allowedStages'] ?? []),
      manualOrder: json['manualOrder'] ?? 999,
      baseScore: (json['baseScore'] ?? 0).toDouble(),
      pinnedTop: json['pinnedTop'] ?? false,
      pinnedBottom: json['pinnedBottom'] ?? false,
    );
  }
}
