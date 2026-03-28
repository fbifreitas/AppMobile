import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/operational_hub_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:appmobile/models/job.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

void main() {
  testWidgets('OperationalHubScreen renders title', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(_ImmediateJobRepository()),
        child: const MaterialApp(
          home: OperationalHubScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Hub operacional'), findsOneWidget);
    expect(find.text('Centrais integradas'), findsOneWidget);
  });
}
