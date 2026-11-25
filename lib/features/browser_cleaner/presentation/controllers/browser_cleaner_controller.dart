import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:antidotes/features/browser_cleaner/data/models/browser_profile_group.dart';
import 'package:antidotes/features/browser_cleaner/data/models/browser_type.dart';
import 'package:antidotes/features/browser_cleaner/data/services/browser_cleaner_service.dart';

class BrowserCleanerController extends ChangeNotifier {
  final BrowserCleanerService _service;

  List<BrowserProfileGroup> _browserGroups = [];
  bool _isLoading = false;
  bool _isCleaning = false;
  String _currentProcessingPath = '';
  BrowserCleanResult? _lastResult;
  bool _showInstalledOnly = true;

  BrowserCleanerController({BrowserCleanerService? service})
      : _service = service ?? BrowserCleanerService();

  List<BrowserProfileGroup> get browserGroups => _browserGroups;
  bool get isLoading => _isLoading;
  bool get isCleaning => _isCleaning;
  String get currentProcessingPath => _currentProcessingPath;
  BrowserCleanResult? get lastResult => _lastResult;
  bool get showInstalledOnly => _showInstalledOnly;

  List<BrowserProfileGroup> get visibleGroups {
    if (_showInstalledOnly) {
      return _browserGroups.where((g) => g.isInstalled).toList();
    }
    return _browserGroups;
  }

  int get totalJunkBytes =>
      _browserGroups.fold(0, (sum, g) => sum + g.totalSizeBytes);
  int get selectedJunkBytes =>
      _browserGroups.fold(0, (sum, g) => sum + g.selectedSizeBytes);

  int get totalFilesDetected =>
      _browserGroups.fold(0, (sum, g) => sum + g.totalFiles);
  int get selectedFilesCount =>
      _browserGroups.fold(0, (sum, g) => sum + g.selectedFiles);

  int get runningBrowsersCount =>
      _browserGroups.where((g) => g.isInstalled && g.isRunning).length;

  Future<void> scan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _browserGroups = await _service.scanInstalledBrowsers();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void toggleItem(String itemId) {
    for (final group in _browserGroups) {
      for (final item in group.items) {
        if (item.id == itemId) {
          item.isSelected = !item.isSelected;
          notifyListeners();
          return;
        }
      }
    }
  }

  void toggleGroup(BrowserType type, bool selectAll) {
    for (final group in _browserGroups) {
      if (group.type == type) {
        for (final item in group.items) {
          item.isSelected = selectAll;
        }
        notifyListeners();
        return;
      }
    }
  }

  void selectAll(bool select) {
    for (final group in _browserGroups) {
      for (final item in group.items) {
        item.isSelected = select;
      }
    }
    notifyListeners();
  }

  void toggleShowInstalledOnly(bool value) {
    _showInstalledOnly = value;
    notifyListeners();
  }

  Future<void> closeBrowserProcess(BrowserProfileGroup group) async {
    if (!Platform.isWindows || !group.isRunning) return;
    try {
      await Process.run('taskkill', ['/F', '/IM', group.type.processName]);
      await scan();
    } catch (_) {}
  }

  Future<BrowserCleanResult?> startClean() async {
    if (_isCleaning || selectedJunkBytes == 0) return null;

    _isCleaning = true;
    _currentProcessingPath = 'Initializing safe browser cleanup...';
    notifyListeners();

    try {
      final uiThrottle = Stopwatch()..start();
      _lastResult = await _service.cleanSelected(
        _browserGroups,
        onProgress: (path) {
          _currentProcessingPath = path;
          if (uiThrottle.elapsedMilliseconds >= 100) {
            uiThrottle.reset();
            notifyListeners();
          }
        },
      );
    } catch (_) {}

    _isCleaning = false;
    _currentProcessingPath = '';

    // Re-scan to update remaining sizes
    await scan();

    notifyListeners();
    return _lastResult;
  }
}
