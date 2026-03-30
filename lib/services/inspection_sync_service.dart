import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class InspectionSyncResult {
  final bool success;
  final int? statusCode;
  final String message;
  final String? protocolId;
  final String? processId;
  final String? processNumber;
  final String? backendStatus;
  final String? receivedAtIso;

  const InspectionSyncResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.protocolId,
    this.processId,
    this.processNumber,
    this.backendStatus,
    this.receivedAtIso,
  });
}

class InspectionSyncService {
  const InspectionSyncService({
    String? baseUrl,
    String? authToken,
    String? syncEndpoint,
    HttpClient Function()? httpClientFactory,
  })  : _baseUrlOverride = baseUrl,
        _authTokenOverride = authToken,
        _syncEndpointOverride = syncEndpoint,
        _httpClientFactory = httpClientFactory;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _authToken = String.fromEnvironment('APP_API_TOKEN');
  static const String _syncEndpoint = String.fromEnvironment(
    'APP_INSPECTION_SYNC_ENDPOINT',
    defaultValue: '/api/mobile/inspections/finalized',
  );
  static const String _devMockEnabledKey = 'dev_mock_inspection_sync_enabled_v1';
  static const String _devMockResponseKey = 'dev_mock_inspection_sync_response_v1';

  final String? _baseUrlOverride;
  final String? _authTokenOverride;
  final String? _syncEndpointOverride;
  final HttpClient Function()? _httpClientFactory;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedAuthToken => (_authTokenOverride ?? _authToken).trim();
  String get _resolvedSyncEndpoint => (_syncEndpointOverride ?? _syncEndpoint).trim();

  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  Future<void> configureDeveloperMock({
    required bool enabled,
    String? responseJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devMockEnabledKey, enabled);

    final normalized = responseJson?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_devMockResponseKey);
      return;
    }

    try {
      final decoded = jsonDecode(normalized);
      final map = _extractMap(decoded);
      if (map == null) {
        await prefs.remove(_devMockResponseKey);
        return;
      }
      await prefs.setString(_devMockResponseKey, jsonEncode(map));
    } catch (_) {
      await prefs.remove(_devMockResponseKey);
    }
  }

  Future<Map<String, dynamic>> loadDeveloperMockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_devMockEnabledKey) ?? false,
      'responseJson': prefs.getString(_devMockResponseKey) ?? '',
    };
  }

  Future<InspectionSyncResult> syncFinalInspection(Map<String, dynamic> payload) async {
    final devMockResult = await _resolveDeveloperMockResult();
    if (devMockResult != null) {
      return devMockResult;
    }

    if (!isConfigured) {
      return const InspectionSyncResult(
        success: false,
        message: 'API não configurada (APP_API_BASE_URL vazio).',
      );
    }

    try {
      final baseUrl = _resolvedBaseUrl;
      final syncEndpoint = _resolvedSyncEndpoint;
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final normalizedPath = syncEndpoint.startsWith('/') ? syncEndpoint : '/$syncEndpoint';
      final uri = Uri.parse('$normalizedBase$normalizedPath');

      final client = (_httpClientFactory ?? HttpClient.new)();
      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final authToken = _resolvedAuthToken;
        if (authToken.isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
        }

        request.add(utf8.encode(jsonEncode(payload)));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        return _buildResultFromHttpResponse(
          statusCode: response.statusCode,
          responseBody: responseBody,
        );
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      return InspectionSyncResult(
        success: false,
        message: 'Falha ao sincronizar com backend: $error',
      );
    }
  }

  Future<InspectionSyncResult?> _resolveDeveloperMockResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_devMockEnabledKey) ?? false;
      if (!enabled) return null;

      final raw = prefs.getString(_devMockResponseKey);
      if (raw == null || raw.trim().isEmpty) {
        return const InspectionSyncResult(
          success: true,
          statusCode: 200,
          message: 'Sincronização mock concluída (modo desenvolvedor).',
        );
      }

      return _buildResultFromHttpResponse(statusCode: 200, responseBody: raw);
    } catch (_) {
      return const InspectionSyncResult(
        success: true,
        statusCode: 200,
        message: 'Sincronização mock concluída (modo desenvolvedor).',
      );
    }
  }

  InspectionSyncResult _buildResultFromHttpResponse({
    required int statusCode,
    required String responseBody,
  }) {
    final decoded = _extractMap(responseBody.trim().isEmpty ? null : jsonDecodeSafe(responseBody));
    final data = _extractMap(decoded?['data']);
    final isSuccess = statusCode >= 200 && statusCode < 300;

    final protocolId = _pickFirstText(
      decoded?['protocolId'],
      decoded?['process_id'],
      data?['id'],
    );
    final processId = _pickFirstText(decoded?['process_id'], data?['id']);
    final processNumber = _pickFirstText(
      decoded?['process_number'],
      data?['process_number'],
    );
    final backendStatus = _pickFirstText(decoded?['status'], data?['status']);
    final receivedAtIso = _pickFirstText(
      decoded?['receivedAt'],
      data?['updated_date'],
      data?['created_date'],
    );

    final message = _pickFirstText(decoded?['message']) ??
        (isSuccess
            ? 'Sincronização concluída com sucesso.'
            : (responseBody.trim().isEmpty
                ? 'Erro HTTP $statusCode durante sincronização.'
                : responseBody));

    return InspectionSyncResult(
      success: isSuccess,
      statusCode: statusCode,
      message: message,
      protocolId: protocolId,
      processId: processId,
      processNumber: processNumber,
      backendStatus: backendStatus,
      receivedAtIso: receivedAtIso,
    );
  }

  Object? jsonDecodeSafe(String input) {
    try {
      return jsonDecode(input);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, dynamic item) => MapEntry('$key', item)),
      );
    }
    return null;
  }

  String? _pickFirstText(Object? a, [Object? b, Object? c]) {
    for (final value in <Object?>[a, b, c]) {
      if (value == null) continue;
      final text = '$value'.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
