import 'dart:convert';

import 'package:appmobile/services/inspection_menu_document_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads asset and developer documents through injected sources', () async {
    const loader = InspectionMenuDocumentLoader(
      assetLoader: _fakeAssetLoader,
    );

    final result = await loader.load(
      assetPath: 'ignored.json',
      loadDeveloperDocument:
          () async => <String, dynamic>{'camera': <String, dynamic>{'v': 2}},
    );

    expect(result.assetDocument, <String, dynamic>{
      'camera': <String, dynamic>{'v': 1},
    });
    expect(result.developerDocument, <String, dynamic>{
      'camera': <String, dynamic>{'v': 2},
    });
  });

  test('returns null documents when sources fail', () async {
    const loader = InspectionMenuDocumentLoader(
      assetLoader: _failingAssetLoader,
    );

    final result = await loader.load(
      assetPath: 'ignored.json',
      loadDeveloperDocument: () async => throw Exception('boom'),
    );

    expect(result.assetDocument, isNull);
    expect(result.developerDocument, isNull);
  });
}

Future<String> _fakeAssetLoader(String _) async {
  return jsonEncode(<String, dynamic>{
    'camera': <String, dynamic>{'v': 1},
  });
}

Future<String> _failingAssetLoader(String _) async {
  throw Exception('boom');
}
