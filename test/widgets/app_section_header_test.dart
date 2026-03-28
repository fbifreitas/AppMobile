import 'package:appmobile/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSectionHeader(
            title: 'Título',
            subtitle: 'Subtítulo',
          ),
        ),
      ),
    );

    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Subtítulo'), findsOneWidget);
  });
}
