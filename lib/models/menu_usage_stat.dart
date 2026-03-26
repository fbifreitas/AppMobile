class MenuUsageStat {
  final String nodeId;
  final String scopeKey;
  int usageCount;
  DateTime? lastUsedAt;

  MenuUsageStat({
    required this.nodeId,
    required this.scopeKey,
    required this.usageCount,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'scopeKey': scopeKey,
        'usageCount': usageCount,
        'lastUsedAt': lastUsedAt?.toIso8601String(),
      };

  factory MenuUsageStat.fromJson(Map<String, dynamic> json) {
    return MenuUsageStat(
      nodeId: json['nodeId'],
      scopeKey: json['scopeKey'],
      usageCount: json['usageCount'] ?? 0,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'])
          : null,
    );
  }
}
