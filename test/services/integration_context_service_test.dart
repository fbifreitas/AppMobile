import 'package:appmobile/services/integration_context_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('buildContext prioritizes authenticated mobile session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_tenant_id': 'tenant-compass',
      'auth_user_id': '77',
      'auth_access_token': 'access-token',
      'integration_tenant_id_v1': 'tenant-legacy',
      'integration_actor_id_v1': 'actor-legacy',
      'integration_api_version_v1': 'v2',
    });

    final context = await const IntegrationContextService().buildContext();

    expect(context.tenantId, 'tenant-compass');
    expect(context.actorId, '77');
    expect(context.authToken, 'access-token');
    expect(context.apiVersion, 'v2');
  });

  test(
    'buildIdempotencyKey is stable for equivalent payloads with different map order',
    () {
      const service = IntegrationContextService();

      final payloadA = <String, dynamic>{
        'exportedAt': '2026-04-05T10:00:00Z',
        'job': {'id': 'job-123', 'titulo': 'Vistoria A'},
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
        'job': {'titulo': 'Vistoria A', 'id': 'job-123'},
        'exportedAt': '2026-04-05T10:00:00Z',
      };

      expect(
        service.buildIdempotencyKey(payloadA),
        service.buildIdempotencyKey(payloadB),
      );
    },
  );

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

  test('buildRequestNonce returns prefixed unique tokens', () {
    const service = IntegrationContextService();

    final first = service.buildRequestNonce();
    final second = service.buildRequestNonce();

    expect(first, startsWith('nonce-'));
    expect(second, startsWith('nonce-'));
    expect(first, isNot(second));
  });

  test('buildRequestTimestamp returns UTC ISO-8601 string', () {
    const service = IntegrationContextService();

    final timestamp = service.buildRequestTimestamp(
      now: DateTime.utc(2026, 4, 8, 17, 45, 30),
    );

    expect(timestamp, '2026-04-08T17:45:30.000Z');
  });
}
