import 'dart:convert';
import 'dart:io';

import '../models/checkin_step2_model.dart';
import 'integration_context_service.dart';

class MobileJobActionResult {
  const MobileJobActionResult({
    required this.success,
    required this.message,
    this.statusCode,
  });

  final bool success;
  final String message;
  final int? statusCode;
}

class MobileJobActionService {
  const MobileJobActionService({
    String? baseUrl,
    String? jobsEndpoint,
    HttpClient Function()? httpClientFactory,
  }) : _baseUrlOverride = baseUrl,
       _jobsEndpointOverride = jobsEndpoint,
       _httpClientFactory = httpClientFactory;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _jobsEndpoint = String.fromEnvironment(
    'APP_MOBILE_JOBS_ENDPOINT',
    defaultValue: '/api/mobile/jobs',
  );

  final String? _baseUrlOverride;
  final String? _jobsEndpointOverride;
  final HttpClient Function()? _httpClientFactory;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedJobsEndpoint =>
      (_jobsEndpointOverride ?? _jobsEndpoint).trim();

  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  Future<MobileJobActionResult> requestSchedulingAfterClientAbsent({
    required String jobId,
    required String responderName,
    required CheckinStep2PhotoAnswer evidence,
    String? reason,
  }) async {
    if (!isConfigured) {
      return const MobileJobActionResult(
        success: false,
        message: 'API nao configurada para tratativa operacional.',
      );
    }
    if (responderName.trim().isEmpty) {
      return const MobileJobActionResult(
        success: false,
        message: 'Informe o nome de quem atendeu no local.',
      );
    }
    if (!evidence.hasImage || evidence.imagePath == null || evidence.geoPoint == null) {
      return const MobileJobActionResult(
        success: false,
        message: 'Capture a foto de evidencia com geolocalizacao antes de continuar.',
      );
    }

    try {
      final context = await const IntegrationContextService().buildContext();
      final imageFile = File(evidence.imagePath!);
      if (!await imageFile.exists()) {
        return const MobileJobActionResult(
          success: false,
          message: 'A foto de evidencia nao foi encontrada no dispositivo.',
        );
      }
      final imageBytes = await imageFile.readAsBytes();
      final client = (_httpClientFactory ?? HttpClient.new)();
      try {
        final request = await client.postUrl(_buildUri(jobId));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
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

        request.add(
          utf8.encode(
            jsonEncode({
              'reason':
                  (reason ?? '').trim().isEmpty
                      ? 'Cliente ausente confirmado no check-in etapa 1. Aguardando reagendamento.'
                      : reason!.trim(),
              'responderName': responderName.trim(),
              'evidence': {
                'fileName': imageFile.uri.pathSegments.isEmpty
                    ? 'cliente-ausente.jpg'
                    : imageFile.uri.pathSegments.last,
                'contentType': _resolveContentType(imageFile.path),
                'imageBase64': base64Encode(imageBytes),
                'capturedAt': (evidence.capturedAt ?? evidence.geoPoint!.capturedAt)
                    .toUtc()
                    .toIso8601String(),
                'latitude': evidence.geoPoint!.latitude,
                'longitude': evidence.geoPoint!.longitude,
                'accuracy': evidence.geoPoint!.accuracy,
              },
            }),
          ),
        );

        final response = await request.close();
        final rawBody = await utf8.decoder.bind(response).join();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return const MobileJobActionResult(
            success: true,
            message:
                'Solicitacao enviada ao backoffice. O job agora aguarda reagendamento.',
          );
        }

        return MobileJobActionResult(
          success: false,
          statusCode: response.statusCode,
          message: _extractErrorMessage(rawBody, response.statusCode),
        );
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return const MobileJobActionResult(
        success: false,
        message:
            'Nao foi possivel comunicar o backoffice para reagendamento. Tente novamente.',
      );
    }
  }

  Uri _buildUri(String jobId) {
    final normalizedBase =
        _resolvedBaseUrl.endsWith('/')
            ? _resolvedBaseUrl.substring(0, _resolvedBaseUrl.length - 1)
            : _resolvedBaseUrl;
    final normalizedPath =
        _resolvedJobsEndpoint.startsWith('/')
            ? _resolvedJobsEndpoint
            : '/$_resolvedJobsEndpoint';
    return Uri.parse(
      '$normalizedBase$normalizedPath/${jobId.trim()}/client-absent',
    );
  }

  String _extractErrorMessage(String rawBody, int statusCode) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        final error = decoded['error']?.toString().trim();
        if (error != null && error.isNotEmpty) {
          return error;
        }
      }
    } catch (_) {
      // Keep generic fallback.
    }

    return 'Nao foi possivel registrar a ausencia do cliente (HTTP $statusCode).';
  }

  String _resolveContentType(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
