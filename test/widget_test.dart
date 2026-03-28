import 'package:flutter_test/flutter_test.dart';
import 'package:appmobile/main.dart';

void main() {
  testWidgets('app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
