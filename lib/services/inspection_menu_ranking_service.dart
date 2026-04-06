import '../config/inspection_menu_package.dart';

class InspectionMenuRankingService {
  const InspectionMenuRankingService();

  static const InspectionMenuRankingService instance =
      InspectionMenuRankingService();

  List<T> rankOptions<T extends RankedMenuOption>({
    required List<T> options,
    required Map<String, dynamic> usage,
    required RankingPolicyConfig? rankingPolicy,
    required String scope,
  }) {
    final pinnedTop = <T>[];
    final middle = <T>[];
    final pinnedBottom = <T>[];

    for (final option in options) {
      if (option.pinnedTop) {
        pinnedTop.add(option);
      } else if (option.pinnedBottom) {
        pinnedBottom.add(option);
      } else {
        middle.add(option);
      }
    }

    int compareByScore(T a, T b) {
      final aScore = _score(
        option: a,
        usage: usage,
        rankingPolicy: rankingPolicy,
        scope: scope,
      );
      final bScore = _score(
        option: b,
        usage: usage,
        rankingPolicy: rankingPolicy,
        scope: scope,
      );
      return bScore.compareTo(aScore);
    }

    pinnedTop.sort(compareByScore);
    middle.sort(compareByScore);
    pinnedBottom.sort(compareByScore);

    return [...pinnedTop, ...middle, ...pinnedBottom];
  }

  double _score({
    required RankedMenuOption option,
    required Map<String, dynamic> usage,
    required RankingPolicyConfig? rankingPolicy,
    required String scope,
  }) {
    final policy = rankingPolicy ?? const RankingPolicyConfig.fallback();
    final editorial = option.baseScore * policy.editorialWeight;

    final entry = Map<String, dynamic>.from(
      usage[_usageCompoundKey(scope, option.label)] as Map? ??
          const <String, dynamic>{},
    );
    if (entry.isEmpty) {
      return editorial;
    }

    final count = (entry['count'] as num?)?.toInt() ?? 0;
    final usageScore =
        count >= policy.minUsesToReorder
            ? count * 10 * policy.localUsageWeight
            : 0.0;

    double recency = 0;
    final lastUsedAt =
        entry['lastUsedAt'] is String
            ? DateTime.tryParse(entry['lastUsedAt'] as String)
            : null;
    if (lastUsedAt != null) {
      final days = DateTime.now().difference(lastUsedAt).inDays;
      if (days <= policy.decayDays) {
        recency =
            ((policy.decayDays - days) / policy.decayDays) *
            100 *
            policy.recencyWeight;
      }
    }

    return editorial + usageScore + recency;
  }

  String _usageCompoundKey(String scope, String value) => '$scope::$value';
}
