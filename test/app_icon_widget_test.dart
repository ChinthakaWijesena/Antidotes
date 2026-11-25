import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/widgets/app_icon_widget.dart';

void main() {
  group('AppIconWidget Tests', () {
    testWidgets('renders Spotify brand painter for Spotify', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconWidget(
              name: 'Spotify',
              packageId: 'Spotify.Spotify',
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(AppIconWidget),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('renders Chrome brand painter for Google Chrome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconWidget(
              name: 'Google Chrome',
              packageId: 'Google.Chrome',
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(AppIconWidget),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('renders fallback icon when provided for unknown app', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconWidget(
              name: 'Custom Utility App',
              fallbackIcon: Icons.build_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.build_rounded), findsOneWidget);
    });

    testWidgets('renders initial letter when no icon is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconWidget(
              name: 'Zebra Tool',
            ),
          ),
        ),
      );

      expect(find.text('Z'), findsOneWidget);
    });
  });
}
