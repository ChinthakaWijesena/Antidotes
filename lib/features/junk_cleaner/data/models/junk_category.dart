import 'package:flutter/material.dart';
import 'junk_item.dart';

enum JunkCategoryType {
  userTemp,
  systemTemp,
  inetCache,
  crashDumps,
  thumbnailCache,
  shaderCache,
  recycleBin,
  browserCache,
  windowsUpdate,
  windowsLogs,
  prefetch,
  dnsCache,
  clipboard,
  muiCache,
}

class JunkCategory {
  final JunkCategoryType type;
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> paths;
  final bool isCareful;
  final bool isRecycleBin;
  bool isSelected;
  int totalBytes;
  int fileCount;
  List<JunkItem> items;
  bool isScanning;
  bool isCleaned;

  bool get isSpecialCategory =>
      isRecycleBin ||
      type == JunkCategoryType.dnsCache ||
      type == JunkCategoryType.clipboard ||
      type == JunkCategoryType.muiCache;

  JunkCategory({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.paths,
    this.isCareful = false,
    this.isRecycleBin = false,
    this.isSelected = true,
    this.totalBytes = 0,
    this.fileCount = 0,
    List<JunkItem>? items,
    this.isScanning = false,
    this.isCleaned = false,
  }) : items = items ?? [];

  void reset() {
    totalBytes = 0;
    fileCount = 0;
    items.clear();
    isScanning = false;
    isCleaned = false;
  }
}
