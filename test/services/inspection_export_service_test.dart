import 'dart:convert';
import 'dart:io';

import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/services/inspection_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePreferencesRepository implements PreferencesRepository {
  final Map<String, Object?> _store = <String, Object?>{};

  @override
  Future<bool?> getBool(String key) async => _store[key] as bool?;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
}

Map<String, dynamic> _payload({required String jobId}) {
  return {
    'job': {'id': jobId},
    'exportedAt': '2026-03-30T18:00:00.000Z',
    'review': {'capturas': []},
  };
}

void main() {
  test('loadDirectorySettings returns safe defaults', () async {
    final service = InspectionExportService(
      preferencesRepository: _FakePreferencesRepository(),
    );

    final settings = await service.loadDirectorySettings();

    expect(settings.mode, InspectionExportDirectoryMode.internal);
    expect(settings.folderName, 'inspection_exports');
  });

  test('configureExportDirectory persists mode and folder', () async {
    final prefs = _FakePreferencesRepository();
    final service = InspectionExportService(preferencesRepository: prefs);

    await service.configureExportDirectory(
      mode: InspectionExportDirectoryMode.external,
      folderName: 'operacao/json/vistorias',
    );

    final settings = await service.loadDirectorySettings();

    expect(settings.mode, InspectionExportDirectoryMode.external);
    expect(settings.folderName, 'operacao/json/vistorias');
  });

  test(
    'export writes file using internal directory when configured as internal',
    () async {
      final prefs = _FakePreferencesRepository();
      final appDir = await Directory.systemTemp.createTemp(
        'app_export_internal',
      );
      addTearDown(() async {
        if (await appDir.exists()) {
          await appDir.delete(recursive: true);
        }
      });

      final service = InspectionExportService(
        preferencesRepository: prefs,
        appDocumentsDirectoryResolver: () async => appDir,
        externalStorageDirectoryResolver: () async => null,
      );

      await service.configureExportDirectory(
        mode: InspectionExportDirectoryMode.internal,
        folderName: 'inspection_exports',
      );

      final path = await service.export(_payload(jobId: 'job-1'));

      expect(path, contains('inspection_exports'));
      expect(await File(path).exists(), isTrue);
    },
  );

  test(
    'export uses external directory when available and configured',
    () async {
      final prefs = _FakePreferencesRepository();
      final appDir = await Directory.systemTemp.createTemp('app_export_app');
      final externalDir = await Directory.systemTemp.createTemp(
        'app_export_external',
      );

      addTearDown(() async {
        if (await appDir.exists()) {
          await appDir.delete(recursive: true);
        }
        if (await externalDir.exists()) {
          await externalDir.delete(recursive: true);
        }
      });

      final service = InspectionExportService(
        preferencesRepository: prefs,
        appDocumentsDirectoryResolver: () async => appDir,
        externalStorageDirectoryResolver: () async => externalDir,
      );

      await service.configureExportDirectory(
        mode: InspectionExportDirectoryMode.external,
        folderName: 'json/vistorias',
      );

      final path = await service.export(_payload(jobId: 'job-2'));

      expect(path, contains('json/vistorias'));
      expect(path.startsWith(externalDir.path), isTrue);
    },
  );

  test(
    'external mode falls back to internal when external base is unavailable',
    () async {
      final prefs = _FakePreferencesRepository();
      final appDir = await Directory.systemTemp.createTemp(
        'app_export_fallback',
      );
      addTearDown(() async {
        if (await appDir.exists()) {
          await appDir.delete(recursive: true);
        }
      });

      final service = InspectionExportService(
        preferencesRepository: prefs,
        appDocumentsDirectoryResolver: () async => appDir,
        externalStorageDirectoryResolver: () async => null,
      );

      await service.configureExportDirectory(
        mode: InspectionExportDirectoryMode.external,
        folderName: 'exports',
      );

      final effective = await service.resolveEffectiveSettings();
      final path = await service.export(_payload(jobId: 'job-3'));

      expect(effective.mode, InspectionExportDirectoryMode.external);
      expect(effective.usingExternalBase, isFalse);
      expect(path.startsWith(appDir.path), isTrue);
    },
  );

  test('loadLatestPayloadForJob returns latest exported payload', () async {
    final prefs = _FakePreferencesRepository();
    final appDir = await Directory.systemTemp.createTemp(
      'app_export_read_latest',
    );
    addTearDown(() async {
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }
    });

    final service = InspectionExportService(
      preferencesRepository: prefs,
      appDocumentsDirectoryResolver: () async => appDir,
      externalStorageDirectoryResolver: () async => null,
    );

    await service.export(_payload(jobId: 'job-4'));
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final newer = _payload(jobId: 'job-4')..['extra'] = 'novo';
    final path = await service.export(newer);

    final loaded = await service.loadLatestPayloadForJob('job-4');

    expect(await File(path).exists(), isTrue);
    expect(loaded?['job']?['id'], 'job-4');
    expect(loaded?['extra'], 'novo');
    expect(jsonEncode(loaded), contains('job-4'));
  });
}
