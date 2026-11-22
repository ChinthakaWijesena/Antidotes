import 'package:flutter/material.dart';

/// Represents a single subtopic navigation destination item in Antidotes.
class NavItem {
  final int index;
  final String label;
  final IconData icon;
  final String? badgeText;

  const NavItem({
    required this.index,
    required this.label,
    required this.icon,
    this.badgeText,
  });
}
