import '../models/menu_node.dart';
import '../models/menu_usage_stat.dart';
import '../models/ranking_policy.dart';

class MenuRankingService {
  List<MenuNode> rankNodes({
    required List<MenuNode> nodes,
    required RankingPolicy policy,
    required Map<String, MenuUsageStat> usageStats,
    required String scopeKey,
  }) {
    final top = <MenuNode>[];
    final middle = <MenuNode>[];
    final bottom = <MenuNode>[];

    for (final node in nodes) {
      if (node.pinnedTop) {
        top.add(node);
      } else if (node.pinnedBottom) {
        bottom.add(node);
      } else {
        middle.add(node);
      }
    }

    top.sort((a, b) => a.manualOrder.compareTo(b.manualOrder));
    bottom.sort((a, b) => a.manualOrder.compareTo(b.manualOrder));

    middle.sort((a, b) {
      final aScore = _calculateScore(a, usageStats, scopeKey, policy);
      final bScore = _calculateScore(b, usageStats, scopeKey, policy);
      return bScore.compareTo(aScore);
    });

    return [...top, ...middle, ...bottom];
  }

  double _calculateScore(
    MenuNode node,
    Map<String, MenuUsageStat> usageStats,
    String scopeKey,
    RankingPolicy policy,
  ) {
    final statKey = '$scopeKey:${node.id}';
    final stat = usageStats[statKey];

    final editorial = node.baseScore * policy.editorialWeight;

    double usage = 0;
    double recency = 0;

    if (stat != null) {
      if (stat.usageCount >= policy.minUsesToReorder) {
        usage = stat.usageCount * 10 * policy.localUsageWeight;
      }

      if (stat.lastUsedAt != null) {
        final days = DateTime.now().difference(stat.lastUsedAt!).inDays;
        final factor = days <= policy.decayDays
            ? (policy.decayDays - days) / policy.decayDays
            : 0.0;
        recency = factor * 100 * policy.recencyWeight;
      }
    }

    final manualBonus = (1000 - node.manualOrder).toDouble() * 0.001;
    return editorial + usage + recency + manualBonus;
  }
}
