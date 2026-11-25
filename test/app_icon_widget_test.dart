import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/widgets/app_icon_widget.dart';

void main() {
  group('AppIconWidget Tests', () {
    testWidgets('renders fallback icon when provided', (tester) async {
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

    testWidgets('renders default widget icon when no fallback is specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconWidget(
              name: 'Unknown Tool',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.widgets_rounded), findsOneWidget);
    });

    testWidgets('renders Image.file when cached icon file exists', (tester) async {
      // Create temporary test image
      final tempFile = File('${Directory.systemTemp.path}/test_app_icon.png');
      tempFile.writeAsBytesSync([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      ]);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIconWidget(
                name: 'Sample App',
                iconCachePath: tempFile.path,
              ),
            ),
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });
  });
}
