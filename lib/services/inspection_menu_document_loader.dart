import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class InspectionMenuDocumentSet {
  final Map<String, dynamic>? assetDocument;
  final Map<String, dynamic>? developerDocument;

  const InspectionMenuDocumentSet({
    required this.assetDocument,
    required this.developerDocument,
  });
}

class InspectionMenuDocumentLoader {
  const InspectionMenuDocumentLoader({
    Future<String> Function(String assetPath)? assetLoader,
  }) : _assetLoader = assetLoader;

  static const InspectionMenuDocumentLoader instance =
      InspectionMenuDocumentLoader();

  final Future<String> Function(String assetPath)? _assetLoader;

  Future<InspectionMenuDocumentSet> load({
    required String assetPath,
    required Future<Map<String, dynamic>?> Function() loadDeveloperDocument,
  }) async {
    Map<String, dynamic>? assetDocument;
    Map<String, dynamic>? developerDocument;

    try {
      final raw = await (_assetLoader ?? rootBundle.loadString)(assetPath);
      assetDocument = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      assetDocument = null;
    }

    try {
      developerDocument = await loadDeveloperDocument();
    } catch (_) {
      developerDocument = null;
    }

    return InspectionMenuDocumentSet(
      assetDocument: assetDocument,
      developerDocument: developerDocument,
    );
  }
}
