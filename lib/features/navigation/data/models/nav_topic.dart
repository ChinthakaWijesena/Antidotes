import 'package:flutter/material.dart';
import 'nav_item.dart';

/// Represents a major category / topic group containing subtopic navigation items.
class NavTopic {
  final String id;
  final String title;
  final IconData icon;
  final List<NavItem> items;

  const NavTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });

  /// All categorized topics & subtopics for the Antidotes sidebar navigation.
  static const List<NavTopic> defaultTopics = [
    NavTopic(
      id: 'optimization',
      title: 'OPTIMIZATION',
      icon: Icons.auto_fix_high_rounded,
      items: [
        NavItem(
          index: 0,
          label: 'Junk Cleaner',
          icon: Icons.cleaning_services_rounded,
        ),
        NavItem(
          index: 1,
          label: 'Startup Optimizer',
          icon: Icons.rocket_launch_rounded,
        ),
        NavItem(
          index: 2,
          label: 'Browser Cleaner',
          icon: Icons.travel_explore_rounded,
        ),
        NavItem(
          index: 9,
          label: 'RAM Optimizer',
          icon: Icons.memory_rounded,
          badgeText: 'NEW',
        ),
      ],
    ),
    NavTopic(
      id: 'system_hardware',
      title: 'SYSTEM & HARDWARE',
      icon: Icons.memory_rounded,
      items: [
        NavItem(
          index: 3,
          label: 'Hardware Monitor',
          icon: Icons.monitor_heart_rounded,
        ),
        NavItem(
          index: 6,
          label: 'Windows Settings',
          icon: Icons.tune_rounded,
        ),
      ],
    ),
    NavTopic(
      id: 'software_management',
      title: 'SOFTWARE MANAGER',
      icon: Icons.apps_rounded,
      items: [
        NavItem(
          index: 4,
          label: 'Software Installer',
          icon: Icons.get_app_rounded,
        ),
        NavItem(
          index: 5,
          label: 'Software Uninstaller',
          icon: Icons.delete_sweep_rounded,
        ),
      ],
    ),
    NavTopic(
      id: 'network_tools',
      title: 'NETWORK & TOOLS',
      icon: Icons.wifi_tethering_rounded,
      items: [
        NavItem(
          index: 7,
          label: 'DNS Changer',
          icon: Icons.dns_rounded,
        ),
        NavItem(
          index: 8,
          label: 'Speed Test',
          icon: Icons.speed_rounded,
          badgeText: 'LIVE',
        ),
      ],
    ),
    NavTopic(
      id: 'storage_files',
      title: 'STORAGE & FILES',
      icon: Icons.folder_special_rounded,
      items: [
        NavItem(
          index: 10,
          label: 'Large File Finder',
          icon: Icons.storage_rounded,
          badgeText: 'NEW',
        ),
        NavItem(
          index: 11,
          label: 'Duplicate Finder',
          icon: Icons.copy_all_rounded,
          badgeText: 'NEW',
        ),
        NavItem(
          index: 12,
          label: 'File Shredder',
          icon: Icons.shield_rounded,
          badgeText: 'NEW',
        ),
      ],
    ),
  ];

  /// Finds which topic owns a particular item index
  static NavTopic? forIndex(int index) {
    for (final topic in defaultTopics) {
      if (topic.items.any((item) => item.index == index)) {
        return topic;
      }
    }
    return null;
  }
}
