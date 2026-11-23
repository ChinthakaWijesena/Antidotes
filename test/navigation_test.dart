import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/navigation/data/models/nav_topic.dart';
import 'package:antidotes/features/navigation/presentation/widgets/app_sidebar.dart';

void main() {
  group('Navigation Models & Hierarchy Tests', () {
    test('Default topics contains 5 structured categories with 13 subtopics', () {
      final topics = NavTopic.defaultTopics;
      expect(topics.length, 5);

      expect(topics[0].id, 'optimization');
      expect(topics[0].title, 'OPTIMIZATION');
      expect(topics[0].items.length, 4); // Junk Cleaner, Startup Optimizer, Browser Cleaner, RAM Optimizer
      expect(topics[0].items.map((i) => i.index), [0, 1, 2, 9]);

      expect(topics[1].id, 'system_hardware');
      expect(topics[1].title, 'SYSTEM & HARDWARE');
      expect(topics[1].items.length, 2);
      expect(topics[1].items.map((i) => i.index), [3, 6]);

      expect(topics[2].id, 'software_management');
      expect(topics[2].title, 'SOFTWARE MANAGER');
      expect(topics[2].items.length, 2);
      expect(topics[2].items.map((i) => i.index), [4, 5]);

      expect(topics[3].id, 'network_tools');
      expect(topics[3].title, 'NETWORK & TOOLS');
      expect(topics[3].items.length, 2);
      expect(topics[3].items.map((i) => i.index), [7, 8]);

      expect(topics[4].id, 'storage_files');
      expect(topics[4].title, 'STORAGE & FILES');
      expect(topics[4].items.length, 3);
      expect(topics[4].items.map((i) => i.index), [10, 11, 12]);
    });

    test('All 13 subtopic indices (0-12) are uniquely covered', () {
      final allIndices = NavTopic.defaultTopics
          .expand((topic) => topic.items.map((item) => item.index))
          .toList();

      expect(allIndices.length, 13);
      expect(allIndices.toSet().length, 13);
      expect(allIndices..sort(), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    });

    test('NavTopic.forIndex resolves parent topic correctly for each subtopic', () {
      expect(NavTopic.forIndex(0)?.id, 'optimization'); // Junk Cleaner
      expect(NavTopic.forIndex(1)?.id, 'optimization'); // Startup Optimizer
      expect(NavTopic.forIndex(2)?.id, 'optimization'); // Browser Cleaner
      expect(NavTopic.forIndex(9)?.id, 'optimization'); // RAM Optimizer
      expect(NavTopic.forIndex(3)?.id, 'system_hardware'); // Hardware Monitor
      expect(NavTopic.forIndex(6)?.id, 'system_hardware'); // Windows Settings
      expect(NavTopic.forIndex(4)?.id, 'software_management'); // Software Installer
      expect(NavTopic.forIndex(5)?.id, 'software_management'); // Software Uninstaller
      expect(NavTopic.forIndex(7)?.id, 'network_tools'); // DNS Changer
      expect(NavTopic.forIndex(8)?.id, 'network_tools'); // Speed Test
      expect(NavTopic.forIndex(10)?.id, 'storage_files'); // Large File Finder
      expect(NavTopic.forIndex(11)?.id, 'storage_files'); // Duplicate Finder
      expect(NavTopic.forIndex(12)?.id, 'storage_files'); // File Shredder
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
      expect(find.text('NETWORK & TOOLS'), findsOneWidget);

      // Verify Subtopics
      expect(find.text('Junk Cleaner'), findsOneWidget);
      expect(find.text('Hardware Monitor'), findsOneWidget);
      expect(find.text('Software Installer'), findsOneWidget);
      expect(find.text('DNS Changer'), findsOneWidget);
      expect(find.text('Speed Test'), findsOneWidget);
      expect(find.text('RAM Optimizer'), findsOneWidget);
      expect(find.text('Large File Finder'), findsOneWidget);

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
