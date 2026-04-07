import 'package:appmobile/services/inspection_menu_document_merge_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = InspectionMenuDocumentMergeResolver.instance;

  test('merges nested base and override documents recursively', () {
    final result = resolver.merge(
      base: <String, dynamic>{
        'camera': <String, dynamic>{
          'byTipo': <String, dynamic>{
            'urbano': <String, dynamic>{'levels': <String>['macroLocal']},
          },
        },
        'flags': <String, dynamic>{'a': true},
      },
      override: <String, dynamic>{
        'camera': <String, dynamic>{
          'byTipo': <String, dynamic>{
            'urbano': <String, dynamic>{'levels': <String>['ambiente']},
          },
        },
        'flags': <String, dynamic>{'b': true},
      },
    );

    expect(result, <String, dynamic>{
      'camera': <String, dynamic>{
        'byTipo': <String, dynamic>{
          'urbano': <String, dynamic>{'levels': <String>['ambiente']},
        },
      },
      'flags': <String, dynamic>{'a': true, 'b': true},
    });
  });

  test('returns whichever side exists when one document is missing', () {
    expect(
      resolver.merge(base: <String, dynamic>{'a': 1}, override: null),
      <String, dynamic>{'a': 1},
    );
    expect(
      resolver.merge(base: null, override: <String, dynamic>{'b': 2}),
      <String, dynamic>{'b': 2},
    );
  });
}
