import 'dart:convert';
import 'dart:io';

import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/job_status.dart';
import 'package:appmobile/repositories/backend_job_repository.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FallbackJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => [
    Job(id: 'fallback-1', titulo: 'Fallback', endereco: 'Local'),
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses fallback repository when API base url is empty', () async {
    final repository = BackendJobRepository(
      baseUrl: ' ',
      fallbackRepository: _FallbackJobRepository(),
    );

    final jobs = await repository.getJobs();

    expect(jobs, hasLength(1));
    expect(jobs.single.id, 'fallback-1');
  });

  test('loads mobile jobs with authenticated session headers', () async {
    SharedPreferences.setMockInitialValues({
      'auth_tenant_id': 'tenant-compass',
      'auth_user_id': '77',
      'auth_access_token': 'session-token',
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/mobile/jobs');
      expect(request.headers.value('X-Tenant-Id'), 'tenant-compass');
      expect(request.headers.value('X-Actor-Id'), '77');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer session-token',
      );

      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode([
          {
            'id': 321,
            'caseId': 654,
            'tenantId': 'tenant-compass',
            'title': 'Vistoria Compass',
            'status': 'ACCEPTED',
            'assignedTo': 77,
          },
        ]),
      );
      await request.response.close();
    });

    final repository = BackendJobRepository(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );

    final jobs = await repository.getJobs();

    expect(jobs, hasLength(1));
    expect(jobs.single.id, '321');
    expect(jobs.single.idExterno, '654');
    expect(jobs.single.titulo, 'Vistoria Compass');
    expect(jobs.single.status, JobStatus.aceito);
  });

  test('throws when backend returns non-success status', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      request.response.statusCode = 500;
      request.response.write('erro');
      await request.response.close();
    });

    final repository = BackendJobRepository(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );

    expect(repository.getJobs(), throwsA(isA<BackendJobRepositoryException>()));
  });
}
