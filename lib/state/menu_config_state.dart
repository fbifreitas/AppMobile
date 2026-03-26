import 'package:flutter/foundation.dart';

import '../models/menu_node.dart';
import '../models/menu_scope.dart';
import '../models/menu_update_package.dart';
import '../models/menu_usage_stat.dart';
import '../services/menu_package_service.dart';
import '../services/menu_ranking_service.dart';
import '../services/menu_storage_service.dart';

class MenuConfigState extends ChangeNotifier {
  final MenuPackageService packageService;
  final MenuStorageService storageService;
  final MenuRankingService rankingService;

  MenuUpdatePackage? package;
  Map<String, MenuUsageStat> usageStats = {};

  MenuConfigState({
    required this.packageService,
    required this.storageService,
    required this.rankingService,
  });

  Future<void> init() async {
    package = await packageService.loadFromAssets();
    usageStats = await storageService.loadUsageStats();
    notifyListeners();
  }

  MenuScope? findScope(String stage, String propertyType) {
    if (package == null) return null;
    try {
      return package!.scopes.firstWhere(
        (s) => s.stage == stage && s.propertyType == propertyType,
      );
    } catch (_) {
      return null;
    }
  }

  List<MenuNode> getLocals(String stage, String propertyType) {
    if (package == null) return [];
    final scope = findScope(stage, propertyType);
    if (scope == null) return [];

    final nodes = package!.nodes.where((n) {
      return n.type == 'local' &&
          n.active &&
          scope.availableLocals.contains(n.id);
    }).toList();

    return rankingService.rankNodes(
      nodes: nodes,
      policy: package!.rankingPolicy,
      usageStats: usageStats,
      scopeKey: '$stage.$propertyType.locals',
    );
  }

  List<MenuNode> getElements(String stage, String propertyType, String localId) {
    if (package == null) return [];

    final nodes = package!.nodes.where((n) {
      return n.type == 'element' &&
          n.active &&
          n.parentId == localId &&
          n.allowedStages.contains(stage) &&
          n.allowedPropertyTypes.contains(propertyType);
    }).toList();

    return rankingService.rankNodes(
      nodes: nodes,
      policy: package!.rankingPolicy,
      usageStats: usageStats,
      scopeKey: '$stage.$propertyType.$localId.elements',
    );
  }

  Future<void> registerUsage({
    required String scopeKey,
    required String nodeId,
  }) async {
    final statKey = '$scopeKey:$nodeId';
    final stat = usageStats.putIfAbsent(
      statKey,
      () => MenuUsageStat(
        nodeId: nodeId,
        scopeKey: scopeKey,
        usageCount: 0,
        lastUsedAt: null,
      ),
    );

    stat.usageCount += 1;
    stat.lastUsedAt = DateTime.now();

    await storageService.saveUsageStats(usageStats);
    notifyListeners();
  }
}
