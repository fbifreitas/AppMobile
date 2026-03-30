import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class InspectionExportService {
  const InspectionExportService();

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

  Future<Directory> _resolveExportDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/inspection_exports');
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
      final fileName = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
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
      if (latest == null || latestModified == null || modified.isAfter(latestModified)) {
        latest = file;
        latestModified = modified;
      }
    }

    return latest ?? candidates.first;
  }
}
