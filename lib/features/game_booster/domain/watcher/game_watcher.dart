import 'dart:async';
import '../../core/platform/process_platform_service.dart';
import '../../data/models/game_model.dart';

typedef OnGameEvent = void Function(Game game, int? pid);

/// Background watcher polling process list (every 2-3 seconds)
/// to detect when registered games start or exit.
class GameWatcher {
  final ProcessPlatformService processService;
  final List<Game> Function() getMonitoredGames;
  final OnGameEvent onGameStarted;
  final OnGameEvent onGameExited;

  Timer? _pollTimer;
  final Map<String, int> _activePids = {}; // gameId -> PID

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  GameWatcher({
    required this.processService,
    required this.getMonitoredGames,
    required this.onGameStarted,
    required this.onGameExited,
  });

  void start({Duration interval = const Duration(seconds: 2)}) {
    if (_isRunning) return;
    _isRunning = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => checkProcesses());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
  }

  Future<void> checkProcesses() async {
    final games = getMonitoredGames();
    for (final game in games) {
      if (!game.autoBoost) continue;

      final pid = await processService.findProcessIdByNameOrPath(game.exeFileName);
      final wasRunning = _activePids.containsKey(game.id);

      if (pid != null && !wasRunning) {
        // Game just started!
        _activePids[game.id] = pid;
        onGameStarted(game, pid);
      } else if (pid == null && wasRunning) {
        // Game just exited!
        _activePids.remove(game.id);
        onGameExited(game, null);
      }
    }
  }

  void clearActive(String gameId) {
    _activePids.remove(gameId);
  }
}
