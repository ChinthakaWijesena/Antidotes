import 'package:flutter/foundation.dart';
import '../../data/models/shred_models.dart';
import '../../data/services/file_shredder_service.dart';

enum ShredState { idle, shredding, done }

class FileShredderController extends ChangeNotifier {
  final FileShredderService _service = FileShredderService();

  List<String> _queue = [];
  List<String> get queue => _queue;

  ShredAlgorithm _algorithm = ShredAlgorithm.dod;
  ShredAlgorithm get algorithm => _algorithm;

  ShredState _state = ShredState.idle;
  ShredState get state => _state;

  /// Currently shredding file (name only).
  String _currentFile = '';
  String get currentFile => _currentFile;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  ShredResult? _lastResult;
  ShredResult? get lastResult => _lastResult;

  void setAlgorithm(ShredAlgorithm algo) {
    _algorithm = algo;
    notifyListeners();
  }

  Future<void> addFilesFromPicker() async {
    final picked = await _service.pickFiles();
    for (final p in picked) {
      if (!_queue.contains(p)) _queue.add(p);
    }
    notifyListeners();
  }

  void removeFromQueue(String path) {
    _queue.remove(path);
    notifyListeners();
  }

  void clearQueue() {
    _queue = [];
    notifyListeners();
  }

  Future<void> shredAll() async {
    if (_queue.isEmpty || _state == ShredState.shredding) return;
    _state = ShredState.shredding;
    _lastResult = null;
    _currentFile = '';
    _currentIndex = 0;
    notifyListeners();

    final result = await _service.shred(
      filePaths: List.of(_queue),
      algorithm: _algorithm,
      onFileStart: (path, idx, total) {
        _currentFile  = path.split(RegExp(r'[/\\]')).last;
        _currentIndex = idx + 1;
        notifyListeners();
      },
      onFileFinish: (r) {
        notifyListeners();
      },
    );

    _lastResult = result;
    _state = ShredState.done;
    // Remove successfully shredded files from queue
    for (final r in result.fileResults) {
      if (r.success) _queue.remove(r.path);
    }
    _currentFile = '';
    notifyListeners();

    // Auto-reset to idle after 5 s
    await Future.delayed(const Duration(seconds: 5));
    if (_state == ShredState.done) {
      _state = ShredState.idle;
      _lastResult = null;
      notifyListeners();
    }
  }
}
