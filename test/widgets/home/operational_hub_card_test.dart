import 'package:appmobile/widgets/home/operational_hub_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/brand_test_helper.dart';

void main() {
  testWidgets('OperationalHubCard renders open button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      withBrand(MaterialApp(
        home: Scaffold(
          body: OperationalHubCard(
            onOpen: () {
              tapped = true;
            },
          ),
        ),
      )),
    );

    expect(find.text('Centrais integradas'), findsOneWidget);
    expect(find.text('ABRIR'), findsOneWidget);

    await tester.tap(find.text('ABRIR'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
