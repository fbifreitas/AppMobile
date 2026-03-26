import 'dart:convert';

import 'menu_node.dart';
import 'menu_scope.dart';
import 'ranking_policy.dart';

class MenuUpdatePackage {
  final int packageVersion;
  final String schemaVersion;
  final RankingPolicy rankingPolicy;
  final List<MenuNode> nodes;
  final List<MenuScope> scopes;
  final Map<String, dynamic> featureFlags;

  MenuUpdatePackage({
    required this.packageVersion,
    required this.schemaVersion,
    required this.rankingPolicy,
    required this.nodes,
    required this.scopes,
    required this.featureFlags,
  });

  factory MenuUpdatePackage.fromJson(Map<String, dynamic> json) {
    return MenuUpdatePackage(
      packageVersion: json['meta']['packageVersion'] ?? 1,
      schemaVersion: json['meta']['schemaVersion'] ?? '1.0.0',
      rankingPolicy: RankingPolicy.fromJson(json['rankingPolicy'] ?? {}),
      nodes: (json['catalog']['nodes'] as List<dynamic>? ?? [])
          .map((e) => MenuNode.fromJson(e))
          .toList(),
      scopes: (json['scopes'] as List<dynamic>? ?? [])
          .map((e) => MenuScope.fromJson(e))
          .toList(),
      featureFlags: Map<String, dynamic>.from(json['featureFlags'] ?? {}),
    );
  }

  factory MenuUpdatePackage.fromRawJson(String raw) {
    return MenuUpdatePackage.fromJson(jsonDecode(raw));
  }
}
