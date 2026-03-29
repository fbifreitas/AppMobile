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
}
