import 'package:flutter/foundation.dart';
import '../../data/models/large_file_item.dart';
import '../../data/services/large_file_service.dart';

enum ScanState { idle, scanning, done }

class LargeFileController extends ChangeNotifier {
  final LargeFileService _service = LargeFileService();

  String _rootPath = 'C:\\';
  String get rootPath => _rootPath;

  int _minSizeMb = 100;
  int get minSizeMb => _minSizeMb;

  ScanState _state = ScanState.idle;
  ScanState get state => _state;

  String _currentPath = '';
  String get currentPath => _currentPath;

  int _filesScanned = 0;
  int get filesScanned => _filesScanned;

  List<LargeFileItem> _results = [];
  List<LargeFileItem> get results => _results;

  bool _cancelled = false;

  void setRootPath(String path) {
    _rootPath = path;
    notifyListeners();
  }

  void setMinSizeMb(int mb) {
    _minSizeMb = mb;
    notifyListeners();
  }

  Future<void> pickFolder() async {
    final path = await _service.pickFolder();
    if (path != null) setRootPath(path);
  }

  Future<void> startScan() async {
    _cancelled = false;
    _state = ScanState.scanning;
    _results = [];
    _filesScanned = 0;
    _currentPath = '';
    notifyListeners();

    final res = await _service.scan(
      rootPath: _rootPath,
      minSizeMb: _minSizeMb,
      onProgress: (p) {
        _currentPath = p.currentPath;
        _filesScanned = p.filesScanned;
        notifyListeners();
      },
      isCancelled: () => _cancelled,
    );

    _results = res;
    _state = _cancelled ? ScanState.idle : ScanState.done;
    _currentPath = '';
    notifyListeners();
  }

  void cancelScan() {
    _cancelled = true;
  }

  Future<void> openFileLocation(String path) =>
      _service.openFileLocation(path);

  Future<bool> deleteFile(String path) async {
    final ok = await _service.deleteFile(path);
    if (ok) {
      _results.removeWhere((f) => f.path == path);
      notifyListeners();
    }
    return ok;
  }
}
