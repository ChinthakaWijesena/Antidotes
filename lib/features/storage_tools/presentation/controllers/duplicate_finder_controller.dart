import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/duplicate_group.dart';
import '../../data/services/duplicate_finder_service.dart';

enum DupScanState { idle, scanning, done }

class DuplicateFinderController extends ChangeNotifier {
  final DuplicateFinderService _service = DuplicateFinderService();

  String _rootPath = '';
  String get rootPath => _rootPath;

  DupScanState _state = DupScanState.idle;
  DupScanState get state => _state;

  String _currentPath = '';
  String get currentPath => _currentPath;

  int _filesHashed = 0;
  int get filesHashed => _filesHashed;

  int _totalFiles = 0;
  int get totalFiles => _totalFiles;

  List<DuplicateGroup> _groups = [];
  List<DuplicateGroup> get groups => _groups;

  final Set<String> _selectedForDelete = {};
  Set<String> get selectedForDelete => _selectedForDelete;

  bool _cancelled = false;

  int get totalWastedBytes =>
      _groups.fold(0, (s, g) => s + g.wastedBytes);

  void setRootPath(String path) {
    _rootPath = path;
    notifyListeners();
  }

  Future<void> pickFolder() async {
    final path = await _service.pickFolder();
    if (path != null) setRootPath(path);
  }

  Future<void> startScan() async {
    if (_rootPath.isEmpty) return;
    _cancelled = false;
    _state = DupScanState.scanning;
    _groups = [];
    _selectedForDelete.clear();
    _filesHashed = 0;
    _totalFiles = 0;
    _currentPath = '';
    notifyListeners();

    final res = await _service.scan(
      rootPath: _rootPath,
      onProgress: (p) {
        _currentPath = p.currentPath;
        _filesHashed = p.filesHashed;
        _totalFiles  = p.totalFiles;
        notifyListeners();
      },
      isCancelled: () => _cancelled,
    );

    _groups = res;
    _state  = _cancelled ? DupScanState.idle : DupScanState.done;
    _currentPath = '';
    // Auto-select duplicates (all except first per group)
    for (final g in _groups) {
      for (int i = 1; i < g.paths.length; i++) {
        _selectedForDelete.add(g.paths[i]);
      }
    }
    notifyListeners();
  }

  void cancelScan() => _cancelled = true;

  void toggleSelect(String path) {
    if (_selectedForDelete.contains(path)) {
      _selectedForDelete.remove(path);
    } else {
      _selectedForDelete.add(path);
    }
    notifyListeners();
  }

  Future<int> deleteSelected() async {
    int deleted = 0;
    for (final path in List.of(_selectedForDelete)) {
      try {
        File(path).deleteSync();
        deleted++;
        _selectedForDelete.remove(path);
        for (final g in _groups) {
          g.paths.remove(path);
        }
      } catch (e) {
        debugPrint('DuplicateFinderController.deleteSelected error [$path]: $e');
      }
    }
    _groups.removeWhere((g) => g.paths.length < 2);
    notifyListeners();
    return deleted;
  }
}
