import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/services/app_navigation_coordinator.dart';
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

class _FakeAppNavigationCoordinator extends AppNavigationCoordinator {
  String? lastOperationalHubItemId;

  @override
  void openAppIntegrationCenter(BuildContext context) {}

  @override
  void openAppShortcut(BuildContext context, {required String routeKey}) {}

  @override
  void openNotifications(BuildContext context) {}

  @override
  void openOperationalHub(BuildContext context) {}

  @override
  void openOperationalHubItem(BuildContext context, {required String itemId}) {
    lastOperationalHubItemId = itemId;
  }

  @override
  void openSettings(BuildContext context) {}
}

void main() {
  testWidgets('OperationalHubScreen renders title', (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(_ImmediateJobRepository()),
        child: const MaterialApp(home: OperationalHubScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Hub operacional'), findsOneWidget);
    expect(find.text('Centrais integradas'), findsOneWidget);
  });

  testWidgets('OperationalHubScreen delegates item navigation to coordinator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final navigationCoordinator = _FakeAppNavigationCoordinator();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(_ImmediateJobRepository()),
        child: MaterialApp(
          home: OperationalHubScreen(
            navigationCoordinator: navigationCoordinator,
          ),
        ),
      ),
    );

    await tester.pump();

    final checkinCard = find.text('Check-in', skipOffstage: false).first;
    await tester.scrollUntilVisible(
      checkinCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(checkinCard);
    await tester.pumpAndSettle();

    expect(navigationCoordinator.lastOperationalHubItemId, 'checkin');
  });
}
