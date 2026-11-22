import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/speed_test_result.dart';
import '../../data/services/speed_test_service.dart';

/// State controller managing real-time internet speed test phases and metrics.
class SpeedTestController extends ChangeNotifier {
  final SpeedTestService _service;

  SpeedTestPhase _phase = SpeedTestPhase.idle;
  NetworkMetaInfo _meta = const NetworkMetaInfo();
  SpeedTestResult? _lastResult;
  double _liveSpeed = 0.0;
  double _progress = 0.0;
  int _remainingSeconds = 0;
  final List<double> _speedHistory = List.filled(20, 0.0, growable: true);
  final List<SpeedTestResult> _sessionHistory = [];

  bool _isCancelled = false;

  SpeedTestController({SpeedTestService? service})
      : _service = service ?? SpeedTestService() {
    init();
  }

  SpeedTestPhase get phase => _phase;
  NetworkMetaInfo get meta => _meta;
  SpeedTestResult? get lastResult => _lastResult;
  double get liveSpeed => _liveSpeed;
  double get progress => _progress;
  int get remainingSeconds => _remainingSeconds;
  List<double> get speedHistory => List.unmodifiable(_speedHistory);
  List<SpeedTestResult> get sessionHistory => List.unmodifiable(_sessionHistory);
  bool get isTesting =>
      _phase != SpeedTestPhase.idle &&
      _phase != SpeedTestPhase.completed &&
      _phase != SpeedTestPhase.error;

  Future<void> init() async {
    _meta = await _service.fetchNetworkMeta();
    notifyListeners();
  }

  void _pushHistory(double speed) {
    _speedHistory.removeAt(0);
    _speedHistory.add(speed);
  }

  /// Begins a sustained ~50-60 second internet speed test
  Future<void> startTest({int phaseDuration = 25}) async {
    if (isTesting) return;

    _isCancelled = false;
    _phase = SpeedTestPhase.pinging;
    _progress = 0.05;
    _liveSpeed = 0.0;
    _remainingSeconds = (phaseDuration * 2) + 5; // ~55 seconds total
    _speedHistory.fillRange(0, _speedHistory.length, 0.0);
    notifyListeners();

    try {
      // 1. Measure Ping & Jitter (~5s)
      final pingResult = await _service.measurePing();
      if (_isCancelled) return;

      int measuredPing = pingResult.ping;
      int measuredJitter = pingResult.jitter;

      _progress = 0.1;
      _remainingSeconds = phaseDuration * 2;
      notifyListeners();

      // 2. Measure Sustained Download Speed (~25s)
      _phase = SpeedTestPhase.downloading;
      notifyListeners();

      final downloadSpeed = await _service.measureDownload(
        durationSeconds: phaseDuration,
        onProgress: (mbps, pct, rem) {
          if (_isCancelled) return;
          _liveSpeed = mbps;
          _progress = 0.1 + (pct * 0.45);
          _remainingSeconds = phaseDuration + rem;
          _pushHistory(mbps);
          notifyListeners();
        },
      );
      if (_isCancelled) return;

      // 3. Measure Sustained Upload Speed (~25s)
      _phase = SpeedTestPhase.uploading;
      _liveSpeed = 0.0;
      _speedHistory.fillRange(0, _speedHistory.length, 0.0);
      notifyListeners();

      final uploadSpeed = await _service.measureUpload(
        durationSeconds: phaseDuration,
        onProgress: (mbps, pct, rem) {
          if (_isCancelled) return;
          _liveSpeed = mbps;
          _progress = 0.55 + (pct * 0.45);
          _remainingSeconds = rem;
          _pushHistory(mbps);
          notifyListeners();
        },
      );
      if (_isCancelled) return;

      // 4. Test Completed
      _phase = SpeedTestPhase.completed;
      _progress = 1.0;
      _remainingSeconds = 0;
      _liveSpeed = downloadSpeed;

      final result = SpeedTestResult(
        downloadMbps: downloadSpeed,
        uploadMbps: uploadSpeed,
        pingMs: measuredPing,
        jitterMs: measuredJitter,
        timestamp: DateTime.now(),
      );

      _lastResult = result;
      _sessionHistory.insert(0, result);
      notifyListeners();
    } catch (_) {
      if (!_isCancelled) {
        _phase = SpeedTestPhase.error;
        notifyListeners();
      }
    }
  }

  /// Cancels any currently active test run
  void cancelTest() {
    _isCancelled = true;
    _phase = SpeedTestPhase.idle;
    _liveSpeed = 0.0;
    _progress = 0.0;
    notifyListeners();
  }
}
