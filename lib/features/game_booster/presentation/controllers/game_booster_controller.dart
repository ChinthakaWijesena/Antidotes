import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/protected_processes.dart';
import '../../core/platform/power_plan_platform_service.dart';
import '../../core/platform/process_platform_service.dart';
import '../../core/platform/system_stats_platform_service.dart';
import '../../data/models/boost_stats_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/running_process_model.dart';
import '../../data/services/game_storage_service.dart';
import '../../data/services/windows_power_plan_service.dart';
import '../../data/services/windows_process_service.dart';
import '../../data/services/windows_system_stats_service.dart';
import '../../domain/actions/boost_action.dart';
import '../../domain/actions/close_background_apps_action.dart';
import '../../domain/actions/power_plan_action.dart';
import '../../domain/actions/process_priority_action.dart';
import '../../domain/actions/temp_clean_action.dart';
import '../../domain/session/boost_session.dart';
import '../../domain/watcher/game_watcher.dart';

enum BoosterState { idle, boosting, boosted, reverting }

/// Presentation controller coordinating Game Booster operations, watchers, and sessions.
class GameBoosterController extends ChangeNotifier {
  final GameStorageService _storageService;
  final ProcessPlatformService _processService;
  final PowerPlanPlatformService _powerPlanService;
  final SystemStatsPlatformService _statsService;

  late final GameWatcher _gameWatcher;

  List<Game> _games = [];
  List<Game> get games => List.unmodifiable(_games);

  List<RunningProcess> _runningProcesses = [];
  List<RunningProcess> get runningProcesses => List.unmodifiable(_runningProcesses);

  // Set of selected process names (lowercase) to close
  final Set<String> _selectedAppsToClose = {};
  Set<String> get selectedAppsToClose => Set.unmodifiable(_selectedAppsToClose);

  BoostSession? _activeSession;
  BoostSession? get activeSession => _activeSession;
  bool get isBoosted => _activeSession?.isActive == true;

  BoosterState _state = BoosterState.idle;
  BoosterState get state => _state;

  BoostStats _stats = BoostStats.empty();
  BoostStats get stats => _stats;

  bool _isAutoWatcherEnabled = true;
  bool get isAutoWatcherEnabled => _isAutoWatcherEnabled;

  Timer? _statsTimer;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  GameBoosterController({
    GameStorageService? storageService,
    ProcessPlatformService? processService,
    PowerPlanPlatformService? powerPlanService,
    SystemStatsPlatformService? statsService,
  })  : _storageService = storageService ?? GameStorageService(),
        _processService = processService ?? WindowsProcessService(),
        _powerPlanService = powerPlanService ?? WindowsPowerPlanService(),
        _statsService = statsService ?? WindowsSystemStatsService() {
    _gameWatcher = GameWatcher(
      processService: _processService,
      getMonitoredGames: () => _games,
      onGameStarted: _handleGameAutoStarted,
      onGameExited: _handleGameAutoExited,
    );
  }

  /// Initializes the controller, loads saved games, fetches processes, and starts stats polling.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadGames();
    await refreshRunningProcesses();

    // Start live stats timer (refreshes every 2 seconds)
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) => _updateStats());
    await _updateStats();

    // Start auto game watcher
    if (_isAutoWatcherEnabled) {
      _gameWatcher.start();
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _gameWatcher.stop();
    // Safety: revert boost session if app is closing
    if (isBoosted) {
      _activeSession?.stop();
    }
    super.dispose();
  }

  // ── Game Library Management ────────────────────────────────────────────────

  Future<void> loadGames() async {
    _games = await _storageService.loadGames();
    notifyListeners();
  }

  Future<void> addGame(Game game) async {
    _games.add(game);
    await _storageService.saveGames(_games);
    notifyListeners();
  }

  Future<void> updateGame(Game updated) async {
    final index = _games.indexWhere((g) => g.id == updated.id);
    if (index != -1) {
      _games[index] = updated;
      await _storageService.saveGames(_games);
      notifyListeners();
    }
  }

  Future<void> removeGame(String id) async {
    _games.removeWhere((g) => g.id == id);
    await _storageService.saveGames(_games);
    notifyListeners();
  }

  // ── Running Processes Management ───────────────────────────────────────────

  Future<void> refreshRunningProcesses() async {
    final procs = await _processService.getRunningProcesses();
    // Filter out protected system processes
    _runningProcesses = procs.where((p) => !p.isProtected && !isProtectedProcess(p.name)).toList();
    notifyListeners();
  }

  void toggleAppToClose(String processName) {
    final key = processName.toLowerCase();
    if (_selectedAppsToClose.contains(key)) {
      _selectedAppsToClose.remove(key);
    } else {
      _selectedAppsToClose.add(key);
    }
    notifyListeners();
  }

  void selectAllClosableApps() {
    for (final p in _runningProcesses) {
      _selectedAppsToClose.add(p.name.toLowerCase());
    }
    notifyListeners();
  }

  void clearSelectedAppsToClose() {
    _selectedAppsToClose.clear();
    notifyListeners();
  }

  // ── Boost Operations ───────────────────────────────────────────────────────

  Future<void> manualBoost(Game game) async {
    if (isBoosted) return;
    await _startBoost(game, null);
  }

  Future<void> revertBoost() async {
    if (_activeSession == null || !_activeSession!.isActive) return;
    _state = BoosterState.reverting;
    notifyListeners();

    await _activeSession!.stop();
    _activeSession = null;
    _state = BoosterState.idle;
    notifyListeners();
  }

  Future<void> launchGame(Game game) async {
    await _processService.launchProcess(game.exePath);
    // If auto-boost is enabled, start boost immediately
    if (game.autoBoost && !isBoosted) {
      await _startBoost(game, null);
    }
  }

  Future<void> _startBoost(Game game, int? pid) async {
    _state = BoosterState.boosting;
    notifyListeners();

    // Prepare apps to close
    final appsToCloseList = <RunningProcess>[];
    for (final proc in _runningProcesses) {
      if (_selectedAppsToClose.contains(proc.name.toLowerCase()) ||
          game.appsToClose.any((name) => name.toLowerCase() == proc.name.toLowerCase())) {
        appsToCloseList.add(proc);
      }
    }

    final context = BoostContext(
      game: game,
      gamePid: pid,
      selectedAppsToClose: appsToCloseList,
      processService: _processService,
      powerPlanService: _powerPlanService,
    );

    final session = BoostSession(game: game, context: context);

    // Build configured actions
    final actions = <BoostAction>[];
    if (game.switchPowerPlan) actions.add(PowerPlanAction());
    if (game.closeBackgroundApps && appsToCloseList.isNotEmpty) {
      actions.add(CloseBackgroundAppsAction());
    }
    if (game.raisePriority) actions.add(ProcessPriorityAction());
    if (game.cleanTemp) actions.add(TempCleanAction());

    await session.start(actions);

    _activeSession = session;
    _state = BoosterState.boosted;
    notifyListeners();
  }

  void toggleAutoWatcher(bool enabled) {
    _isAutoWatcherEnabled = enabled;
    if (enabled) {
      _gameWatcher.start();
    } else {
      _gameWatcher.stop();
    }
    notifyListeners();
  }

  void _handleGameAutoStarted(Game game, int? pid) {
    if (!isBoosted && game.autoBoost) {
      _startBoost(game, pid);
    }
  }

  void _handleGameAutoExited(Game game, int? _) {
    if (isBoosted && _activeSession?.game.id == game.id) {
      revertBoost();
    }
  }

  Future<void> _updateStats() async {
    try {
      _stats = await _statsService.getLiveStats();
      notifyListeners();
    } catch (_) {}
  }

  /// Native Windows OpenFileDialog for choosing game executable and resolving its authentic icon.
  Future<Map<String, String>?> pickGameExecutable() async {
    try {
      const script = r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title = "Select Game Executable"
$dlg.Filter = "Game Executable (*.exe)|*.exe|All Files (*.*)|*.*"
if ($dlg.ShowDialog() -eq "OK") {
    $path = $dlg.FileName
    $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $cacheDir = "$env:LOCALAPPDATA\Antidotes\IconCache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction SilentlyContinue | Out-Null
    }
    $iconPath = ""
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
        $hash = [Math]::Abs($path.ToLower().GetHashCode())
        $outPng = "$cacheDir\$hash.png"
        if (Test-Path $outPng) {
            $iconPath = $outPng
        } else {
            $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
            if ($ico) {
                $ico.ToBitmap().Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
                $ico.Dispose()
                $iconPath = $outPng
            }
        }
    } catch {}

    Write-Output "$name|$path|$iconPath"
}
''';

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      final out = res.stdout.toString().trim();
      if (out.isNotEmpty && out.contains('|')) {
        final parts = out.split('|');
        return {
          'name': parts[0].trim(),
          'exePath': parts[1].trim(),
          'iconCachePath': parts.length > 2 ? parts[2].trim() : '',
        };
      }
    } catch (_) {}
    return null;
  }
}
