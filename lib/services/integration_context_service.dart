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
    final raw = payload.toString();
    final hash = _fnv1a64(raw);
    return 'idem-$hash';
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
