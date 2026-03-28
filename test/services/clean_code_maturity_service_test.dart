import 'package:appmobile/services/clean_code_maturity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maturity service returns roadmap items', () {
    final items = const CleanCodeMaturityService().items();
    expect(items, isNotEmpty);
    expect(items.length, greaterThanOrEqualTo(5));
  });
}
