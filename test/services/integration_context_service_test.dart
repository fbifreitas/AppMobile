import 'package:appmobile/services/integration_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildIdempotencyKey is stable for equivalent payloads with different map order', () {
    const service = IntegrationContextService();

    final payloadA = <String, dynamic>{
      'exportedAt': '2026-04-05T10:00:00Z',
      'job': {
        'id': 'job-123',
        'titulo': 'Vistoria A',
      },
      'review': {
        'tipoImovel': 'Urbano',
        'capturas': [
          {'filePath': '/tmp/a.jpg', 'ambiente': 'Fachada'},
        ],
      },
    };

    final payloadB = <String, dynamic>{
      'review': {
        'capturas': [
          {'ambiente': 'Fachada', 'filePath': '/tmp/a.jpg'},
        ],
        'tipoImovel': 'Urbano',
      },
      'job': {
        'titulo': 'Vistoria A',
        'id': 'job-123',
      },
      'exportedAt': '2026-04-05T10:00:00Z',
    };

    expect(
      service.buildIdempotencyKey(payloadA),
      service.buildIdempotencyKey(payloadB),
    );
  });

  test('buildIdempotencyKey changes when exportedAt changes', () {
    const service = IntegrationContextService();

    final payloadA = <String, dynamic>{
      'exportedAt': '2026-04-05T10:00:00Z',
      'job': {'id': 'job-123'},
    };
    final payloadB = <String, dynamic>{
      'exportedAt': '2026-04-05T10:01:00Z',
      'job': {'id': 'job-123'},
    };

    expect(
      service.buildIdempotencyKey(payloadA),
      isNot(service.buildIdempotencyKey(payloadB)),
    );
  });
}
