import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/home_screen.dart';
import 'package:appmobile/services/app_navigation_coordinator.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_helper.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

class _FakeAppNavigationCoordinator extends AppNavigationCoordinator {
  int notificationsOpenCount = 0;
  int settingsOpenCount = 0;
  int hubOpenCount = 0;

  @override
  void openAppIntegrationCenter(BuildContext context) {}

  @override
  void openAppShortcut(BuildContext context, {required String routeKey}) {}

  @override
  void openNotifications(BuildContext context) {
    notificationsOpenCount += 1;
  }

  @override
  void openOperationalHub(BuildContext context) {
    hubOpenCount += 1;
  }

  @override
  void openOperationalHubItem(BuildContext context, {required String itemId}) {}

  @override
  void openSettings(BuildContext context) {
    settingsOpenCount += 1;
  }
}

void main() {
  testWidgets(
    'HomeScreen delegates header actions to app navigation coordinator',
    (tester) async {
      SharedPreferences.setMockInitialValues({'developer_mode_enabled': true});

      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _TestHttpOverrides();
      addTearDown(() {
        HttpOverrides.global = previousOverrides;
      });

      final navigationCoordinator = _FakeAppNavigationCoordinator();
      final appState = AppState(_ImmediateJobRepository());
      appState.jobs = [
        Job(
          id: 'job-1',
          titulo: 'Vistoria A',
          endereco: 'Rua A, 1',
          nomeCliente: 'Cliente A',
        ),
      ];

      await tester.pumpWidget(
        withBrand(ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: HomeScreen(appNavigationCoordinator: navigationCoordinator),
          ),
        )),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
      await tester.pump();

      expect(navigationCoordinator.notificationsOpenCount, 1);
      expect(navigationCoordinator.settingsOpenCount, 1);
      expect(navigationCoordinator.hubOpenCount, 1);
    },
  );
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final Uint8List _imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn4n8sAAAAASUVORK5CYII=',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<Socket> detachSocket() async {
    throw UnimplementedError();
  }

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  Future<T> fold<T>(
    T initialValue,
    T Function(T previous, List<int> element) combine,
  ) async {
    return combine(initialValue, _imageBytes);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_imageBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
