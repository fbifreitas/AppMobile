import 'package:appmobile/screens/app_integration_center_screen.dart';
import 'package:appmobile/services/app_navigation_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppNavigationCoordinator extends AppNavigationCoordinator {
  String? lastShortcutRouteKey;

  @override
  void openAppIntegrationCenter(BuildContext context) {}

  @override
  void openAppShortcut(BuildContext context, {required String routeKey}) {
    lastShortcutRouteKey = routeKey;
  }

  @override
  void openNotifications(BuildContext context) {}

  @override
  void openOperationalHub(BuildContext context) {}

  @override
  void openOperationalHubItem(BuildContext context, {required String itemId}) {}

  @override
  void openSettings(BuildContext context) {}
}

void main() {
  testWidgets('AppIntegrationCenterScreen delegates shortcut navigation', (
    tester,
  ) async {
    final navigationCoordinator = _FakeAppNavigationCoordinator();

    await tester.pumpWidget(
      MaterialApp(
        home: AppIntegrationCenterScreen(
          navigationCoordinator: navigationCoordinator,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Fluxo principal'));
    await tester.pump();

    expect(navigationCoordinator.lastShortcutRouteKey, 'checkin');
  });
}
