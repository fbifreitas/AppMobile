import 'dart:convert';
import 'dart:io';

import '../models/smart_execution_plan.dart';
import 'integration_context_service.dart';
import 'smart_execution_plan_decoder.dart';

class SmartExecutionPlanService {
  const SmartExecutionPlanService({
    String? baseUrl,
    String? executionPlanPathTemplate,
    HttpClient Function()? httpClientFactory,
    IntegrationContextService? integrationContextService,
    SmartExecutionPlanDecoder? decoder,
  }) : _baseUrlOverride = baseUrl,
       _executionPlanPathTemplateOverride = executionPlanPathTemplate,
       _httpClientFactory = httpClientFactory,
       _integrationContextService =
           integrationContextService ?? const IntegrationContextService(),
       _decoder = decoder ?? SmartExecutionPlanDecoder.instance;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _executionPlanPathTemplate = String.fromEnvironment(
    'APP_MOBILE_EXECUTION_PLAN_ENDPOINT',
    defaultValue: '/api/mobile/jobs/{jobId}/execution-plan',
  );

  final String? _baseUrlOverride;
  final String? _executionPlanPathTemplateOverride;
  final HttpClient Function()? _httpClientFactory;
  final IntegrationContextService _integrationContextService;
  final SmartExecutionPlanDecoder _decoder;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedPathTemplate =>
      (_executionPlanPathTemplateOverride ?? _executionPlanPathTemplate).trim();

  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  Future<SmartExecutionPlan?> fetchForJob(String jobId) async {
    final normalizedJobId = jobId.trim();
    if (!isConfigured || normalizedJobId.isEmpty) {
      return null;
    }

    final context = await _integrationContextService.buildContext();
    final uri = _buildUri(normalizedJobId);
    final client = (_httpClientFactory ?? HttpClient.new)();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('X-Tenant-Id', context.tenantId);
      request.headers.set('X-Correlation-Id', context.correlationId);
      request.headers.set('X-Actor-Id', context.actorId);
      request.headers.set('X-Api-Version', context.apiVersion);
      if (context.authToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${context.authToken}',
        );
      }

      final response = await request.close();
      final raw = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.notFound) {
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SmartExecutionPlanServiceException(
          'Falha ao carregar execution plan: HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
      return _decoder.decodeEnvelope(map, fallbackJobId: normalizedJobId);
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildUri(String jobId) {
    final normalizedBase =
        _resolvedBaseUrl.endsWith('/')
            ? _resolvedBaseUrl.substring(0, _resolvedBaseUrl.length - 1)
            : _resolvedBaseUrl;
    final resolvedPath = _resolvedPathTemplate.replaceAll('{jobId}', jobId);
    final normalizedPath =
        resolvedPath.startsWith('/') ? resolvedPath : '/$resolvedPath';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

}

class SmartExecutionPlanServiceException implements Exception {
  const SmartExecutionPlanServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
