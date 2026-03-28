import 'package:appmobile/widgets/home/startup_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StartupStatusCard renders loading and counters', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StartupStatusCard(
            isLoadingJobs: false,
            jobsCount: 3,
            jobsLoadError: null,
          ),
        ),
      ),
    );

    expect(find.text('Status do startup'), findsOneWidget);
    expect(find.text('isLoadingJobs: false'), findsOneWidget);
    expect(find.text('jobs carregados: 3'), findsOneWidget);
    expect(find.text('jobsLoadError: nenhum'), findsOneWidget);
  });
}
