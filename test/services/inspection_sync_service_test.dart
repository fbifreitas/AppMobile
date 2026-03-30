import 'dart:convert';
import 'dart:io';

import 'package:appmobile/services/inspection_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns not configured when base url is empty', () async {
    const service = InspectionSyncService(baseUrl: '   ');

    final result = await service.syncFinalInspection(const {'job': {'id': '1'}});

    expect(result.success, isFalse);
    expect(result.statusCode, isNull);
    expect(result.message, contains('API não configurada'));
  });

  test('returns success for 2xx response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/sync');
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['job']['id'], 'job-123');
      request.response.statusCode = 201;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"ok":true}');
      await request.response.close();
    });

    final service = InspectionSyncService(
      baseUrl: 'http://${server.address.host}:${server.port}',
      syncEndpoint: '/sync',
    );

    final result = await service.syncFinalInspection(
      const {
        'job': {'id': 'job-123'},
      },
    );

    expect(result.success, isTrue);
    expect(result.statusCode, 201);
    expect(result.message, contains('Sincronização concluída'));
  });

  test('returns backend message for non-2xx response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      request.response.statusCode = 500;
      request.response.headers.contentType = ContentType.text;
      request.response.write('erro interno');
      await request.response.close();
    });

    final service = InspectionSyncService(
      baseUrl: 'http://${server.address.host}:${server.port}',
      syncEndpoint: '/sync',
    );

    final result = await service.syncFinalInspection(const {'job': {'id': 'job-500'}});

    expect(result.success, isFalse);
    expect(result.statusCode, 500);
    expect(result.message, 'erro interno');
  });

  test('returns failure message when request throws exception', () async {
    final service = InspectionSyncService(
      baseUrl: 'http://127.0.0.1:1',
      syncEndpoint: '/sync',
    );

    final result = await service.syncFinalInspection(const {'job': {'id': 'job-fail'}});

    expect(result.success, isFalse);
    expect(result.message, contains('Falha ao sincronizar com backend'));
  });
}
