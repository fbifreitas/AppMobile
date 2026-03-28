import 'package:appmobile/widgets/home/location_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LocationStatusCard renders empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationStatusCard(
            loading: false,
            errorMessage: null,
            lastSyncAt: null,
            latitude: null,
            longitude: null,
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Localização operacional'), findsOneWidget);
    expect(find.text('Nenhuma localização capturada ainda.'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
  });
}
