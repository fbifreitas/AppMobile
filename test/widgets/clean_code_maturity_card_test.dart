import 'package:appmobile/models/clean_code_maturity_item.dart';
import 'package:appmobile/widgets/clean_code_maturity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders maturity card title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanCodeMaturityCard(
            items: const [
              CleanCodeMaturityItem(
                id: 'a',
                title: 'Teste',
                currentLevel: 'Bom',
                targetLevel: 'Ótimo',
                action: 'Executar revisão',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Plano para chegar perto de 9/10'), findsOneWidget);
    expect(find.text('Teste'), findsOneWidget);
  });
}
