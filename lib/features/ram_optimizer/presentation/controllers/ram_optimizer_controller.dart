import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/ram_snapshot.dart';
import '../../data/models/ram_boost_result.dart';
import '../../data/models/ram_optimize_options.dart';
import '../../data/services/ram_optimizer_service.dart';

enum RamBoostState { idle, boosting, done }

class RamOptimizerController extends ChangeNotifier {
  final RamOptimizerService _service = RamOptimizerService();

  // ── Live snapshot ────────────────────────────────────────────────────────
  RamSnapshot? _snapshot;
  RamSnapshot? get snapshot => _snapshot;

  // ── Options ──────────────────────────────────────────────────────────────
  RamOptimizeOptions _options = RamOptimizeOptions.allEnabled();
  RamOptimizeOptions get options => _options;

  void toggleOperation(RamOperation op) {
    _options = _options.copyWithToggled(op);
    notifyListeners();
  }

  // ── Boost state ──────────────────────────────────────────────────────────
  RamBoostState _boostState = RamBoostState.idle;
  RamBoostState get boostState => _boostState;

  RamBoostResult? _lastResult;
  RamBoostResult? get lastResult => _lastResult;

  // ── Live polling ─────────────────────────────────────────────────────────
  Timer? _pollTimer;

  void startMonitoring() {
    _fetchSnapshot();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_boostState != RamBoostState.boosting) _fetchSnapshot();
    });
  }

  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Boost ─────────────────────────────────────────────────────────────────
  Future<void> runBoost() async {
    if (_boostState == RamBoostState.boosting) return;
    if (_options.selected.isEmpty) return;

    _boostState = RamBoostState.boosting;
    _lastResult = null;
    notifyListeners();

    final result = await _service.boost(_options);

    _lastResult = result;
    _boostState = RamBoostState.done;
    notifyListeners();

    await _fetchSnapshot();

    // Auto-reset to idle after 8 s
    await Future.delayed(const Duration(seconds: 8));
    if (_boostState == RamBoostState.done) {
      _boostState = RamBoostState.idle;
      notifyListeners();
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────
  Future<void> _fetchSnapshot() async {
    final s = await _service.snapshot();
    _snapshot = s;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
