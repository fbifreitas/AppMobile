import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appmobile/screens/operational_hub_screen.dart';

void main() {
  testWidgets('OperationalHubScreen renders title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OperationalHubScreen(),
      ),
    );

    expect(find.text('Hub operacional'), findsOneWidget);
    expect(find.text('Centrais integradas'), findsOneWidget);
  });
}
