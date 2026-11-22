import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/navigation/data/models/nav_topic.dart';
import 'package:antidotes/features/navigation/presentation/widgets/app_sidebar.dart';

void main() {
  group('Navigation Models & Hierarchy Tests', () {
    test('Default topics contains 4 structured categories with 8 subtopics', () {
      final topics = NavTopic.defaultTopics;
      expect(topics.length, 4);

      expect(topics[0].id, 'optimization');
      expect(topics[0].title, 'OPTIMIZATION');
      expect(topics[0].items.length, 3);
      expect(topics[0].items.map((i) => i.index), [0, 1, 2]);

      expect(topics[1].id, 'system_hardware');
      expect(topics[1].title, 'SYSTEM & HARDWARE');
      expect(topics[1].items.length, 2);
      expect(topics[1].items.map((i) => i.index), [3, 6]);

      expect(topics[2].id, 'software_management');
      expect(topics[2].title, 'SOFTWARE MANAGER');
      expect(topics[2].items.length, 2);
      expect(topics[2].items.map((i) => i.index), [4, 5]);

      expect(topics[3].id, 'network_security');
      expect(topics[3].title, 'NETWORK & SECURITY');
      expect(topics[3].items.length, 1);
      expect(topics[3].items.map((i) => i.index), [7]);
    });

    test('All 8 subtopic indices (0-7) are uniquely covered', () {
      final allIndices = NavTopic.defaultTopics
          .expand((topic) => topic.items.map((item) => item.index))
          .toList();

      expect(allIndices.length, 8);
      expect(allIndices.toSet().length, 8);
      expect(allIndices..sort(), [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('NavTopic.forIndex resolves parent topic correctly for each subtopic', () {
      expect(NavTopic.forIndex(0)?.id, 'optimization'); // Junk Cleaner
      expect(NavTopic.forIndex(1)?.id, 'optimization'); // Startup Optimizer
      expect(NavTopic.forIndex(2)?.id, 'optimization'); // Browser Cleaner
      expect(NavTopic.forIndex(3)?.id, 'system_hardware'); // Hardware Monitor
      expect(NavTopic.forIndex(6)?.id, 'system_hardware'); // Windows Settings
      expect(NavTopic.forIndex(4)?.id, 'software_management'); // Software Installer
      expect(NavTopic.forIndex(5)?.id, 'software_management'); // Software Uninstaller
      expect(NavTopic.forIndex(7)?.id, 'network_security'); // DNS Changer
      expect(NavTopic.forIndex(99), isNull);
    });
  });

  group('AppSidebar Widget Tests', () {
    testWidgets('Renders all topics, counts and subtopic labels initially expanded',
        (tester) async {
      int selectedDestination = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSidebar(
              selectedIndex: 0,
              onDestinationSelected: (idx) {
                selectedDestination = idx;
              },
            ),
          ),
        ),
      );

      // Verify Header branding
      expect(find.text('Antidotes'), findsOneWidget);
      expect(find.text('PC OPTIMIZER'), findsOneWidget);

      // Verify Topic headers
      expect(find.text('OPTIMIZATION'), findsOneWidget);
      expect(find.text('SYSTEM & HARDWARE'), findsOneWidget);
      expect(find.text('SOFTWARE MANAGER'), findsOneWidget);
      expect(find.text('NETWORK & SECURITY'), findsOneWidget);

      // Verify Subtopics
      expect(find.text('Junk Cleaner'), findsOneWidget);
      expect(find.text('Hardware Monitor'), findsOneWidget);
      expect(find.text('Software Installer'), findsOneWidget);
      expect(find.text('DNS Changer'), findsOneWidget);

      // Tap on a subtopic item
      await tester.tap(find.text('Hardware Monitor'));
      await tester.pumpAndSettle();
      expect(selectedDestination, 3);
    });

    testWidgets('Tapping topic header collapses and expands subtopics',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSidebar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      // Initially expanded
      expect(find.text('Software Installer'), findsOneWidget);

      // Tap to collapse SOFTWARE MANAGER topic
      await tester.tap(find.text('SOFTWARE MANAGER'));
      await tester.pumpAndSettle();

      // Subtopics inside should be collapsed (hidden)
      expect(find.text('Software Installer'), findsNothing);

      // Tap again to expand
      await tester.tap(find.text('SOFTWARE MANAGER'));
      await tester.pumpAndSettle();

      expect(find.text('Software Installer'), findsOneWidget);
    });
  });
}
