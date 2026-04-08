import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class IntegrationContext {
  final String tenantId;
  final String actorId;
  final String apiVersion;
  final String correlationId;

  const IntegrationContext({
    required this.tenantId,
    required this.actorId,
    required this.apiVersion,
    required this.correlationId,
  });
}

class IntegrationContextService {
  const IntegrationContextService();

  static const _tenantIdKey = 'integration_tenant_id_v1';
  static const _actorIdKey = 'integration_actor_id_v1';
  static const _apiVersionKey = 'integration_api_version_v1';

  static const String _tenantIdEnv = String.fromEnvironment(
    'APP_TENANT_ID',
    defaultValue: 'tenant-default',
  );
  static const String _actorIdEnv = String.fromEnvironment(
    'APP_ACTOR_ID',
    defaultValue: '1',
  );
  static const String _apiVersionEnv = String.fromEnvironment(
    'APP_API_VERSION',
    defaultValue: 'v1',
  );

  Future<IntegrationContext> buildContext() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId =
        (prefs.getString(_tenantIdKey) ?? _tenantIdEnv).trim();
    final actorId =
        (prefs.getString(_actorIdKey) ?? _actorIdEnv).trim();
    final apiVersion =
        (prefs.getString(_apiVersionKey) ?? _apiVersionEnv).trim();
    return IntegrationContext(
      tenantId: tenantId.isEmpty ? 'tenant-default' : tenantId,
      actorId: actorId.isEmpty ? '1' : actorId,
      apiVersion: apiVersion.isEmpty ? 'v1' : apiVersion,
      correlationId: _newCorrelationId(),
    );
  }

  Future<void> saveContext({
    required String tenantId,
    required String actorId,
    required String apiVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tenantIdKey, tenantId.trim());
    await prefs.setString(_actorIdKey, actorId.trim());
    await prefs.setString(_apiVersionKey, apiVersion.trim());
  }

  Future<Map<String, String>> loadStoredContext() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tenantId': (prefs.getString(_tenantIdKey) ?? _tenantIdEnv).trim(),
      'actorId': (prefs.getString(_actorIdKey) ?? _actorIdEnv).trim(),
      'apiVersion': (prefs.getString(_apiVersionKey) ?? _apiVersionEnv).trim(),
    };
  }

  String buildIdempotencyKey(Map<String, dynamic> payload) {
    final jobId = _extractNestedText(payload, const ['job', 'id'], fallback: 'sem-job');
    final exportedAt = _extractText(payload['exportedAt'], fallback: 'sem-exported-at');
    final payloadChecksum = _fnv1a64(_canonicalizeForHash(payload));
    final raw = '$jobId|$exportedAt|$payloadChecksum';
    final hash = _fnv1a64(raw);
    return 'idem-$hash';
  }

  String buildRequestNonce() {
    final random = Random();
    final epoch = DateTime.now().microsecondsSinceEpoch;
    final suffix = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
    return 'nonce-$epoch-$suffix';
  }

  String buildRequestTimestamp({DateTime? now}) {
    return (now ?? DateTime.now().toUtc()).toIso8601String();
  }

  String _canonicalizeForHash(Object? value) {
    final normalized = _normalizeForHash(value);
    return jsonEncode(normalized);
  }

  Object? _normalizeForHash(Object? value) {
    if (value is Map) {
      final entries =
          value.entries
              .map((entry) => MapEntry('${entry.key}', _normalizeForHash(entry.value)))
              .toList()
            ..sort((left, right) => left.key.compareTo(right.key));
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }
    if (value is List) {
      return value.map(_normalizeForHash).toList(growable: false);
    }
    return value;
  }

  String _extractNestedText(
    Map<String, dynamic> payload,
    List<String> path, {
    required String fallback,
  }) {
    Object? current = payload;
    for (final segment in path) {
      if (current is! Map) {
        return fallback;
      }
      current = current[segment];
    }
    return _extractText(current, fallback: fallback);
  }

  String _extractText(Object? value, {required String fallback}) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  String _newCorrelationId() {
    final random = Random();
    final epoch = DateTime.now().millisecondsSinceEpoch;
    final suffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'mob-$epoch-$suffix';
  }

  String _fnv1a64(String input) {
    const int offsetBasis = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    var hash = offsetBasis;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
