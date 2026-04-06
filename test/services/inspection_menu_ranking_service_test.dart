import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_menu_ranking_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps pinned top option ahead of higher-used regular option', () {
    const service = InspectionMenuRankingService();
    final options = <RankedMenuOption>[
      const RankedMenuOption(label: 'Pinned', baseScore: 50, pinnedTop: true),
      const RankedMenuOption(label: 'Regular', baseScore: 60),
    ];

    final ranked = service.rankOptions(
      options: options,
      usage: <String, dynamic>{
        'camera.urbano.macro::Regular': <String, dynamic>{
          'count': 10,
          'lastUsedAt': DateTime.now().toIso8601String(),
        },
      },
      rankingPolicy: const RankingPolicyConfig.fallback(),
      scope: 'camera.urbano.macro',
    );

    expect(ranked.first.label, 'Pinned');
    expect(ranked.last.label, 'Regular');
  });
}
