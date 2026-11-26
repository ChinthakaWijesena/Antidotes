import 'package:flutter/foundation.dart';
import '../../data/models/cleaner_safety_options.dart';
import '../../data/models/junk_category.dart';
import '../../data/models/junk_item.dart';
import '../../data/services/junk_cleaner_service.dart';

enum CleanerState { idle, scanning, scanCompleted, cleaning, cleanCompleted }

class JunkCleanerController extends ChangeNotifier {
  final JunkCleanerService _service;
  CleanerSafetyOptions _safetyOptions = CleanerSafetyOptions();

  JunkCleanerController({JunkCleanerService? service})
      : _service = service ?? JunkCleanerService() {
    _categories = _service.getCategories();
  }

  CleanerState _state = CleanerState.idle;
  List<JunkCategory> _categories = [];
  String _currentProcessingPath = '';
  CleanupResult? _lastCleanupResult;

  CleanerState get state => _state;
  List<JunkCategory> get categories => _categories;
  CleanerSafetyOptions get safetyOptions => _safetyOptions;
  String get currentProcessingPath => _currentProcessingPath;
  CleanupResult? get lastCleanupResult => _lastCleanupResult;

  bool get isScanning => _state == CleanerState.scanning;
  bool get isCleaning => _state == CleanerState.cleaning;
  bool get hasScanned =>
      _state == CleanerState.scanCompleted || _state == CleanerState.cleanCompleted;

  int get totalJunkBytes {
    return _categories.fold(0, (sum, cat) => sum + cat.totalBytes);
  }

  int get totalJunkFiles {
    return _categories.fold(0, (sum, cat) => sum + cat.fileCount);
  }

  int get selectedJunkBytes {
    var total = 0;
    for (final cat in _categories) {
      if (!cat.isSelected) continue;
      if (cat.isSpecialCategory) {
        total += cat.totalBytes;
      } else {
        total += cat.items
            .where((i) => i.isSelected)
            .fold(0, (sum, i) => sum + i.sizeInBytes);
      }
    }
    return total;
  }

  int get selectedJunkFiles {
    var total = 0;
    for (final cat in _categories) {
      if (!cat.isSelected) continue;
      if (cat.isSpecialCategory) {
        total += cat.fileCount;
      } else {
        total += cat.items.where((i) => i.isSelected).length;
      }
    }
    return total;
  }

  bool get allSelected => _categories.every((cat) => cat.isSelected);

  void updateSafetyOptions(CleanerSafetyOptions newOptions) {
    _safetyOptions = newOptions;
    notifyListeners();
  }

  void toggleCategory(String id) {
    final catIndex = _categories.indexWhere((c) => c.id == id);
    if (catIndex != -1) {
      _categories[catIndex].isSelected = !_categories[catIndex].isSelected;
      notifyListeners();
    }
  }

  void toggleItemSelection(JunkCategory category, JunkItem item) {
    item.isSelected = !item.isSelected;
    notifyListeners();
  }

  void toggleSelectAll(bool select) {
    for (final cat in _categories) {
      cat.isSelected = select;
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (isScanning || isCleaning) return;

    _state = CleanerState.scanning;
    _currentProcessingPath = 'Initializing safe scan...';
    notifyListeners();

    for (final category in _categories) {
      category.reset();
    }

    for (final category in _categories) {
      final uiThrottle = Stopwatch()..start();
      await _service.scanCategory(
        category,
        _safetyOptions,
        onProgress: (path) {
          _currentProcessingPath = path;
          if (uiThrottle.elapsedMilliseconds >= 100) {
            uiThrottle.reset();
            notifyListeners();
          }
        },
      );
      notifyListeners();
    }

    _state = CleanerState.scanCompleted;
    _currentProcessingPath = '';
    notifyListeners();
  }

  Future<void> startClean() async {
    if (isScanning || isCleaning || (selectedJunkBytes == 0 && selectedJunkFiles == 0)) return;

    _state = CleanerState.cleaning;
    _currentProcessingPath = 'Starting cleanup process...';
    notifyListeners();

    final uiThrottle = Stopwatch()..start();
    _lastCleanupResult = await _service.cleanCategories(
      _categories,
      _safetyOptions,
      onProgress: (currentFile, filesDeleted, bytesFreed) {
        _currentProcessingPath = currentFile;
        if (uiThrottle.elapsedMilliseconds >= 100) {
          uiThrottle.reset();
          notifyListeners();
        }
      },
    );

    _state = CleanerState.cleanCompleted;
    _currentProcessingPath = '';
    notifyListeners();
  }
}
