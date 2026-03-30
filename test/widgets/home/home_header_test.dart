import 'package:appmobile/widgets/home/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeHeader renders greeting and action icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            firstName: 'Felipe',
            unreadMessages: 3,
            photoPath: null,
            onNotificationsTap: () {},
            onSettingsTap: () {},
            onHubTap: () {},
            showHubButton: true,
          ),
        ),
      ),
    );

    expect(find.text('Olá, Felipe!'), findsOneWidget);
    expect(find.text('Seu painel operacional de hoje'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_customize_outlined), findsOneWidget);
  });

  testWidgets('HomeHeader hides hub button when developer mode is disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            firstName: 'Felipe',
            unreadMessages: 0,
            photoPath: null,
            onNotificationsTap: () {},
            onSettingsTap: () {},
            onHubTap: () {},
            showHubButton: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_customize_outlined), findsNothing);
  });
}
