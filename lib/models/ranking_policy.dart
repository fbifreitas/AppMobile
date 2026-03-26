class RankingPolicy {
  final double editorialWeight;
  final double localUsageWeight;
  final double recencyWeight;
  final int minUsesToReorder;
  final int maxRisePerCycle;
  final bool pinnedTopAlwaysFirst;
  final bool pinnedBottomAlwaysLast;
  final int decayDays;

  RankingPolicy({
    required this.editorialWeight,
    required this.localUsageWeight,
    required this.recencyWeight,
    required this.minUsesToReorder,
    required this.maxRisePerCycle,
    required this.pinnedTopAlwaysFirst,
    required this.pinnedBottomAlwaysLast,
    required this.decayDays,
  });

  factory RankingPolicy.fromJson(Map<String, dynamic> json) {
    return RankingPolicy(
      editorialWeight: (json['editorialWeight'] ?? 0.7).toDouble(),
      localUsageWeight: (json['localUsageWeight'] ?? 0.2).toDouble(),
      recencyWeight: (json['recencyWeight'] ?? 0.1).toDouble(),
      minUsesToReorder: json['minUsesToReorder'] ?? 3,
      maxRisePerCycle: json['maxRisePerCycle'] ?? 2,
      pinnedTopAlwaysFirst: json['pinnedTopAlwaysFirst'] ?? true,
      pinnedBottomAlwaysLast: json['pinnedBottomAlwaysLast'] ?? true,
      decayDays: json['decayDays'] ?? 30,
    );
  }
}
