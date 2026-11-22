import 'package:flutter/material.dart';
import 'package:antidotes/core/utils/file_size_formatter.dart';

class InstalledAppItem {
  final String id;
  final String name;
  final String publisher;
  final String version;
  final String installDate;
  final int sizeInBytes;
  final String uninstallString;
  final String installLocation;
  final String iconPath;
  final bool is64Bit;

  const InstalledAppItem({
    required this.id,
    required this.name,
    this.publisher = '',
    this.version = '',
    this.installDate = '',
    this.sizeInBytes = 0,
    required this.uninstallString,
    this.installLocation = '',
    this.iconPath = '',
    this.is64Bit = true,
  });

  String get formattedSize {
    if (sizeInBytes <= 0) return 'Not measured';
    return FileSizeFormatter.format(sizeInBytes);
  }

  String get displayPublisher {
    if (publisher.trim().isEmpty) return 'Unknown Publisher';
    return publisher;
  }

  String get displayVersion {
    if (version.trim().isEmpty) return '1.0';
    return version;
  }

  String get displayDate {
    if (installDate.trim().isEmpty) return 'Unknown';
    if (installDate.length == 8 && int.tryParse(installDate) != null) {
      // YYYYMMDD to MM/DD/YYYY
      final y = installDate.substring(0, 4);
      final m = installDate.substring(4, 6);
      final d = installDate.substring(6, 8);
      return '$m/$d/$y';
    }
    return installDate;
  }

  IconData get defaultIcon {
    final lower = name.toLowerCase();
    if (lower.contains('vlc') || lower.contains('media') || lower.contains('player')) {
      return Icons.play_circle_filled_rounded;
    }
    if (lower.contains('code') || lower.contains('studio') || lower.contains('git') || lower.contains('python')) {
      return Icons.code_rounded;
    }
    if (lower.contains('chrome') || lower.contains('firefox') || lower.contains('edge') || lower.contains('browser')) {
      return Icons.language_rounded;
    }
    if (lower.contains('discord') || lower.contains('teams') || lower.contains('slack') || lower.contains('chat')) {
      return Icons.chat_bubble_rounded;
    }
    if (lower.contains('steam') || lower.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    if (lower.contains('zip') || lower.contains('rar') || lower.contains('archive')) {
      return Icons.folder_zip_rounded;
    }
    return Icons.widgets_rounded;
  }

  InstalledAppItem copyWith({
    String? id,
    String? name,
    String? publisher,
    String? version,
    String? installDate,
    int? sizeInBytes,
    String? uninstallString,
    String? installLocation,
    String? iconPath,
    bool? is64Bit,
  }) {
    return InstalledAppItem(
      id: id ?? this.id,
      name: name ?? this.name,
      publisher: publisher ?? this.publisher,
      version: version ?? this.version,
      installDate: installDate ?? this.installDate,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      uninstallString: uninstallString ?? this.uninstallString,
      installLocation: installLocation ?? this.installLocation,
      iconPath: iconPath ?? this.iconPath,
      is64Bit: is64Bit ?? this.is64Bit,
    );
  }
}
