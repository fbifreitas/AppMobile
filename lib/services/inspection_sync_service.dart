import 'dart:convert';
import 'dart:io';

class InspectionSyncResult {
  final bool success;
  final int? statusCode;
  final String message;

  const InspectionSyncResult({
    required this.success,
    required this.message,
    this.statusCode,
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

  final String? _baseUrlOverride;
  final String? _authTokenOverride;
  final String? _syncEndpointOverride;
  final HttpClient Function()? _httpClientFactory;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedAuthToken => (_authTokenOverride ?? _authToken).trim();
  String get _resolvedSyncEndpoint => (_syncEndpointOverride ?? _syncEndpoint).trim();

  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  Future<InspectionSyncResult> syncFinalInspection(Map<String, dynamic> payload) async {
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

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return InspectionSyncResult(
            success: true,
            statusCode: response.statusCode,
            message: 'Sincronização concluída com sucesso.',
          );
        }

        final fallbackMessage = responseBody.trim().isEmpty
            ? 'Erro HTTP ${response.statusCode} durante sincronização.'
            : responseBody;
        return InspectionSyncResult(
          success: false,
          statusCode: response.statusCode,
          message: fallbackMessage,
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
}
