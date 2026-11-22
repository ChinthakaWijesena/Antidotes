import 'package:flutter/material.dart';
import 'software_category.dart';

enum InstallStatus {
  notInstalled,
  installing,
  installed,
  failed,
}

class SoftwareAppItem {
  final String id;
  final String name;
  final String publisher;
  final String description;
  final SoftwareCategory category;
  final IconData icon;
  final Color brandColor;
  final String packageId; // winget package id
  final bool isPopular;

  bool isInstalled;
  bool isSelected;
  InstallStatus status;
  String statusMessage;

  SoftwareAppItem({
    required this.id,
    required this.name,
    required this.publisher,
    required this.description,
    required this.category,
    required this.icon,
    required this.brandColor,
    required this.packageId,
    this.isPopular = false,
    this.isInstalled = false,
    this.isSelected = false,
    this.status = InstallStatus.notInstalled,
    this.statusMessage = '',
  });

  SoftwareAppItem copyWith({
    bool? isInstalled,
    bool? isSelected,
    InstallStatus? status,
    String? statusMessage,
  }) {
    return SoftwareAppItem(
      id: id,
      name: name,
      publisher: publisher,
      description: description,
      category: category,
      icon: icon,
      brandColor: brandColor,
      packageId: packageId,
      isPopular: isPopular,
      isInstalled: isInstalled ?? this.isInstalled,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
