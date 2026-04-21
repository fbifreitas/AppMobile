import 'dart:convert';
import 'dart:io';

import '../models/job.dart';
import '../models/job_status.dart';
import '../services/integration_context_service.dart';
import '../services/smart_execution_plan_decoder.dart';
import 'job_repository.dart';

class BackendJobRepository implements JobRepository {
  const BackendJobRepository({
    String? baseUrl,
    String? jobsEndpoint,
    JobRepository? fallbackRepository,
    HttpClient Function()? httpClientFactory,
    IntegrationContextService? integrationContextService,
    SmartExecutionPlanDecoder? smartExecutionPlanDecoder,
  }) : _baseUrlOverride = baseUrl,
       _jobsEndpointOverride = jobsEndpoint,
       _fallbackRepository = fallbackRepository,
       _httpClientFactory = httpClientFactory,
       _integrationContextService =
           integrationContextService ?? const IntegrationContextService(),
       _smartExecutionPlanDecoder =
           smartExecutionPlanDecoder ?? SmartExecutionPlanDecoder.instance;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _jobsEndpoint = String.fromEnvironment(
    'APP_MOBILE_JOBS_ENDPOINT',
    defaultValue: '/api/mobile/jobs',
  );

  final String? _baseUrlOverride;
  final String? _jobsEndpointOverride;
  final JobRepository? _fallbackRepository;
  final HttpClient Function()? _httpClientFactory;
  final IntegrationContextService _integrationContextService;
  final SmartExecutionPlanDecoder _smartExecutionPlanDecoder;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedJobsEndpoint =>
      (_jobsEndpointOverride ?? _jobsEndpoint).trim();

  @override
  Future<List<Job>> getJobs() async {
    if (_resolvedBaseUrl.isEmpty) {
      final fallback = _fallbackRepository;
      if (fallback != null) return fallback.getJobs();
      return const <Job>[];
    }

    final context = await _integrationContextService.buildContext();
    final uri = _uri(_resolvedJobsEndpoint);
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
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BackendJobRepositoryException(
          'Falha ao carregar jobs: HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_jobFromJson)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  Uri _uri(String path) {
    final normalizedBase =
        _resolvedBaseUrl.endsWith('/')
            ? _resolvedBaseUrl.substring(0, _resolvedBaseUrl.length - 1)
            : _resolvedBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Job _jobFromJson(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final caseId = map['caseId']?.toString();
    final title = map['title']?.toString().trim();
    final propertyAddress = map['propertyAddress']?.toString().trim();
    final propertyLatitude = _doubleOrNull(map['propertyLatitude']);
    final propertyLongitude = _doubleOrNull(map['propertyLongitude']);
    final inspectionType = map['inspectionType']?.toString().trim();
    final executionPlan = _smartExecutionPlanDecoder.decodeEnvelope(
      _extractMap(map['executionPlan']),
      fallbackJobId: id,
    );
    final resolvedAssetType =
        executionPlan?.initialAssetType?.trim().isNotEmpty == true
            ? executionPlan!.initialAssetType
            : (inspectionType == null || inspectionType.isEmpty
                ? null
                : inspectionType);
    final resolvedAssetSubtype =
        executionPlan?.initialAssetSubtype?.trim().isNotEmpty == true
            ? executionPlan!.initialAssetSubtype
            : null;
    return Job(
      id: id,
      titulo: title == null || title.isEmpty ? 'Job $id' : title,
      endereco:
          propertyAddress == null || propertyAddress.isEmpty
              ? 'Endereco pendente de detalhe operacional'
              : propertyAddress,
      latitude: propertyLatitude ?? executionPlan?.propertyLatitude,
      longitude: propertyLongitude ?? executionPlan?.propertyLongitude,
      deadlineAt: _dateTimeOrNull(map['deadlineAt']),
      createdAt: _dateTimeOrNull(map['createdAt']),
      status: _statusFromBackend(map['status']?.toString()),
      tipoImovel: resolvedAssetType,
      subtipoImovel: resolvedAssetSubtype,
      idExterno: caseId == null || caseId.isEmpty ? null : caseId,
      smartExecutionPlan: executionPlan,
    );
  }

  Map<String, dynamic>? _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, item) => MapEntry('$key', item)),
      );
    }
    return null;
  }

  JobStatus _statusFromBackend(String? rawStatus) {
    switch ((rawStatus ?? '').trim().toUpperCase()) {
      case 'ACCEPTED':
        return JobStatus.aceito;
      case 'AWAITING_SCHEDULING':
        return JobStatus.aguardandoAgendamento;
      case 'IN_EXECUTION':
      case 'SUBMITTED':
        return JobStatus.emAndamento;
      case 'FIELD_COMPLETED':
        return JobStatus.finalizado;
      case 'CLOSED':
        return JobStatus.encerrado;
      case 'CREATED':
      case 'ELIGIBLE_FOR_DISPATCH':
      case 'OFFERED':
      default:
        return JobStatus.novo;
    }
  }

  double? _doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  DateTime? _dateTimeOrNull(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

class BackendJobRepositoryException implements Exception {
  const BackendJobRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
