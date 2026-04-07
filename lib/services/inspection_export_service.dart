import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../repositories/preferences_repository.dart';

enum InspectionExportDirectoryMode { internal, external }

class InspectionExportDirectorySettings {
  final InspectionExportDirectoryMode mode;
  final String folderName;
  final bool usingExternalBase;

  const InspectionExportDirectorySettings({
    required this.mode,
    required this.folderName,
    required this.usingExternalBase,
  });
}

class InspectionExportService {
  InspectionExportService({
    PreferencesRepository? preferencesRepository,
    Future<Directory> Function()? appDocumentsDirectoryResolver,
    Future<Directory?> Function()? externalStorageDirectoryResolver,
  }) : _preferencesRepository =
           preferencesRepository ?? const SharedPreferencesRepository(),
       _appDocumentsDirectoryResolver =
           appDocumentsDirectoryResolver ?? getApplicationDocumentsDirectory,
       _externalStorageDirectoryResolver =
           externalStorageDirectoryResolver ?? getExternalStorageDirectory;

  static const String _defaultFolderName = 'inspection_exports';
  static const String _modePreferenceKey =
      'inspection_export_directory_mode_v1';
  static const String _folderPreferenceKey =
      'inspection_export_directory_folder_v1';

  static const String _retentionDaysKey = 'inspection_export_retention_days_v1';
  static const int _defaultRetentionDays = 30;

  final PreferencesRepository _preferencesRepository;
  final Future<Directory> Function() _appDocumentsDirectoryResolver;
  final Future<Directory?> Function() _externalStorageDirectoryResolver;

  Future<String> export(Map<String, dynamic> payload) async {
    final directory = await _resolveExportDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final now = DateTime.now();
    final timestamp = now.toIso8601String().replaceAll(':', '-');
    final jobId = '${payload['job']?['id'] ?? 'sem_job'}';
    final file = File('${directory.path}/vistoria_${jobId}_$timestamp.json');

    final encoder = const JsonEncoder.withIndent('  ');
    final json = encoder.convert(payload);
    await file.writeAsString(json);
    return file.path;
  }

  Future<void> configureExportDirectory({
    required InspectionExportDirectoryMode mode,
    required String folderName,
  }) async {
    final normalizedFolder = _normalizeFolderName(folderName);

    await _preferencesRepository.setString(_modePreferenceKey, mode.name);
    await _preferencesRepository.setString(
      _folderPreferenceKey,
      normalizedFolder,
    );
  }

  Future<InspectionExportDirectorySettings> loadDirectorySettings() async {
    final modeRaw = await _preferencesRepository.getString(_modePreferenceKey);
    final folderRaw = await _preferencesRepository.getString(
      _folderPreferenceKey,
    );

    final mode =
        modeRaw == InspectionExportDirectoryMode.external.name
            ? InspectionExportDirectoryMode.external
            : InspectionExportDirectoryMode.internal;
    final folderName = _normalizeFolderName(folderRaw ?? _defaultFolderName);

    return InspectionExportDirectorySettings(
      mode: mode,
      folderName: folderName,
      usingExternalBase: false,
    );
  }

  Future<InspectionExportDirectorySettings> resolveEffectiveSettings() async {
    final configured = await loadDirectorySettings();
    final usingExternalBase =
        configured.mode == InspectionExportDirectoryMode.external &&
        await _resolveExternalBaseDirectory() != null;

    return InspectionExportDirectorySettings(
      mode: configured.mode,
      folderName: configured.folderName,
      usingExternalBase: usingExternalBase,
    );
  }

  Future<Directory> _resolveExportDirectory() async {
    final settings = await loadDirectorySettings();
    final normalizedFolder = _normalizeFolderName(settings.folderName);

    Directory? base;
    if (settings.mode == InspectionExportDirectoryMode.external) {
      base = await _resolveExternalBaseDirectory();
    }
    base ??= await _appDocumentsDirectoryResolver();

    return Directory('${base.path}/$normalizedFolder');
  }

  Future<Directory?> _resolveExternalBaseDirectory() async {
    try {
      return await _externalStorageDirectoryResolver();
    } catch (_) {
      return null;
    }
  }

  String _normalizeFolderName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return _defaultFolderName;
    final normalized = trimmed.replaceAll('\\', '/');
    final segments =
        normalized
            .split('/')
            .map((segment) => segment.trim())
            .where(
              (segment) =>
                  segment.isNotEmpty && segment != '.' && segment != '..',
            )
            .toList();

    if (segments.isEmpty) return _defaultFolderName;
    return segments.join('/');
  }

  Future<Map<String, dynamic>?> loadLatestPayloadForJob(String jobId) async {
    final file = await _findLatestExportFileForJob(jobId);
    if (file == null) return null;

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((key, value) => MapEntry('$key', value)),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<File?> _findLatestExportFileForJob(String jobId) async {
    final directory = await _resolveExportDirectory();
    if (!await directory.exists()) return null;

    final expectedPrefix = 'vistoria_${jobId}_';
    final candidates = <File>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final fileName =
          entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
      final normalized = Uri.decodeComponent(fileName);
      if (!normalized.startsWith(expectedPrefix) ||
          !normalized.endsWith('.json')) {
        continue;
      }
      candidates.add(entity);
    }

    if (candidates.isEmpty) return null;

    File? latest;
    DateTime? latestModified;

    for (final file in candidates) {
      DateTime modified;
      try {
        modified = await file.lastModified();
      } catch (_) {
        continue;
      }
      if (latest == null ||
          latestModified == null ||
          modified.isAfter(latestModified)) {
        latest = file;
        latestModified = modified;
      }
    }

    return latest ?? candidates.first;
  }

  // ── Retention policy ───────────────────────────────────────────────────────

  Future<void> configureRetentionDays(int days) async {
    await _preferencesRepository.setString(
      _retentionDaysKey,
      days.clamp(0, 3650).toString(),
    );
  }

  Future<int> loadRetentionDays() async {
    final raw = await _preferencesRepository.getString(_retentionDaysKey);
    if (raw == null) return _defaultRetentionDays;
    return int.tryParse(raw) ?? _defaultRetentionDays;
  }

  /// Deletes export JSON files older than [retentionDays] days.
  /// Pass [retentionDays] = 0 to skip (never purge).
  /// Returns the number of files deleted.
  Future<int> purgeOldExports({int? retentionDays}) async {
    final days = retentionDays ?? await loadRetentionDays();
    if (days <= 0) return 0;

    final directory = await _resolveExportDirectory();
    if (!await directory.exists()) return 0;

    final cutoff = DateTime.now().subtract(Duration(days: days));
    int deleted = 0;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final fileName =
          entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
      final normalized = Uri.decodeComponent(fileName);
      if (!normalized.startsWith('vistoria_') ||
          !normalized.endsWith('.json')) {
        continue;
      }
      try {
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
          deleted++;
        }
      } catch (_) {
        // skip files that cannot be read or deleted
      }
    }

    return deleted;
  }
}
