import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/game_booster/core/constants/protected_processes.dart';
import 'package:antidotes/features/game_booster/core/platform/power_plan_platform_service.dart';
import 'package:antidotes/features/game_booster/core/platform/process_platform_service.dart';
import 'package:antidotes/features/game_booster/core/platform/system_stats_platform_service.dart';
import 'package:antidotes/features/game_booster/data/models/boost_stats_model.dart';
import 'package:antidotes/features/game_booster/data/models/game_model.dart';
import 'package:antidotes/features/game_booster/data/models/running_process_model.dart';
import 'package:antidotes/features/game_booster/data/services/game_storage_service.dart';
import 'package:antidotes/features/game_booster/domain/actions/boost_action.dart';
import 'package:antidotes/features/game_booster/domain/actions/close_background_apps_action.dart';
import 'package:antidotes/features/game_booster/domain/actions/power_plan_action.dart';
import 'package:antidotes/features/game_booster/domain/actions/process_priority_action.dart';
import 'package:antidotes/features/game_booster/domain/session/boost_session.dart';
import 'package:antidotes/features/game_booster/domain/watcher/game_watcher.dart';
import 'package:antidotes/features/game_booster/presentation/screens/game_booster_screen.dart';

// ── Mock & Fake Implementations for Safe Testing ─────────────────────────────

class FakeProcessPlatformService implements ProcessPlatformService {
  final List<RunningProcess> runningProcesses = [];
  final Map<int, ProcessPriority> priorities = {};
  final List<int> closedPids = [];
  final List<String> launchedPaths = [];
  final Map<String, int> runningGamePids = {};

  @override
  Future<List<RunningProcess>> getRunningProcesses() async => runningProcesses;

  @override
  Future<bool> setProcessPriority(int pid, ProcessPriority priority) async {
    priorities[pid] = priority;
    return true;
  }

  @override
  Future<bool> closeProcess(int pid, {bool force = false}) async {
    closedPids.add(pid);
    return true;
  }

  @override
  Future<bool> launchProcess(String exePath) async {
    launchedPaths.add(exePath);
    return true;
  }

  @override
  Future<int?> findProcessIdByNameOrPath(String exeNameOrPath) async {
    final key = exeNameOrPath.toLowerCase();
    for (final entry in runningGamePids.entries) {
      if (entry.key.toLowerCase().contains(key) || key.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}

class FakePowerPlanPlatformService implements PowerPlanPlatformService {
  String? currentGuid = PowerPlanPlatformService.balancedGuid;
  final List<String> history = [];

  @override
  Future<String?> getActivePowerPlanGuid() async => currentGuid;

  @override
  Future<bool> setActivePowerPlanGuid(String guid) async {
    history.add(guid);
    currentGuid = guid;
    return true;
  }
}

class FakeSystemStatsPlatformService implements SystemStatsPlatformService {
  BoostStats stats = const BoostStats(
    cpuUsagePercent: 24.5,
    ramUsagePercent: 42.0,
    ramUsedGb: 6.7,
    ramTotalGb: 16.0,
    gpuUsageDisplay: '35%',
  );

  @override
  Future<BoostStats> getLiveStats() async => stats;
}

class FakeGameStorageService implements GameStorageService {
  List<Game> inMemoryGames = [];

  @override
  Future<List<Game>> loadGames() async => List.from(inMemoryGames);

  @override
  Future<void> saveGames(List<Game> games) async {
    inMemoryGames = List.from(games);
  }
}

class ActionWithAudit implements BoostAction {
  @override
  final String name;
  final List<String> callLog;
  final bool failOnApply;

  ActionWithAudit(this.name, this.callLog, {this.failOnApply = false});

  @override
  Future<void> apply(BoostContext context) async {
    if (failOnApply) throw Exception('Failure on apply for $name');
    callLog.add('apply:$name');
  }

  @override
  Future<void> revert(BoostContext context) async {
    callLog.add('revert:$name');
  }
}

// ── Test Suites ──────────────────────────────────────────────────────────────

void main() {
  group('Safety Rules & Protected Processes Tests', () {
    test('Safety Rule 1: Critical Windows & security processes are protected', () {
      expect(isProtectedProcess('System'), isTrue);
      expect(isProtectedProcess('system.exe'), isTrue);
      expect(isProtectedProcess('csrss.exe'), isTrue);
      expect(isProtectedProcess('winlogon.exe'), isTrue);
      expect(isProtectedProcess('explorer.exe'), isTrue);
      expect(isProtectedProcess('audiodg.exe'), isTrue);
      expect(isProtectedProcess('MsMpEng.exe'), isTrue);
      expect(isProtectedProcess('antidotes.exe'), isTrue);
      expect(isProtectedProcess('dart.exe'), isTrue);

      // Normal non-protected game or user app
      expect(isProtectedProcess('cyberpunk2077.exe'), isFalse);
      expect(isProtectedProcess('spotify.exe'), isFalse);
      expect(isProtectedProcess('discord.exe'), isFalse);
    });
  });

  group('BoostSession & Actions Tests', () {
    late FakePowerPlanPlatformService fakePower;
    late FakeProcessPlatformService fakeProc;
    late Game testGame;

    setUp(() {
      fakePower = FakePowerPlanPlatformService();
      fakeProc = FakeProcessPlatformService();
      testGame = const Game(
        id: 'g1',
        name: 'Cyberpunk 2077',
        exePath: r'C:\Games\Cyberpunk\bin\Cyberpunk2077.exe',
        switchPowerPlan: true,
        raisePriority: true,
        closeBackgroundApps: true,
      );
    });

    test('PowerPlanAction switches to High Performance and restores previous GUID', () async {
      fakePower.currentGuid = PowerPlanPlatformService.balancedGuid;

      final context = BoostContext(
        game: testGame,
        processService: fakeProc,
        powerPlanService: fakePower,
      );

      final action = PowerPlanAction();
      await action.apply(context);

      expect(fakePower.currentGuid, PowerPlanPlatformService.highPerformanceGuid);
      expect(context.sessionState[PowerPlanAction.stateKey], PowerPlanPlatformService.balancedGuid);

      await action.revert(context);
      expect(fakePower.currentGuid, PowerPlanPlatformService.balancedGuid);
    });

    test('ProcessPriorityAction sets Above Normal and restores to Normal', () async {
      const pid = 1234;
      final context = BoostContext(
        game: testGame,
        gamePid: pid,
        processService: fakeProc,
        powerPlanService: fakePower,
      );

      final action = ProcessPriorityAction();
      await action.apply(context);

      expect(fakeProc.priorities[pid], ProcessPriority.aboveNormal);

      await action.revert(context);
      expect(fakeProc.priorities[pid], ProcessPriority.normal);
    });

    test('CloseBackgroundAppsAction closes user apps but skips protected processes', () async {
      final userApp = const RunningProcess(pid: 200, name: 'spotify.exe', memoryMb: 120, isProtected: false);
      final protApp = const RunningProcess(pid: 300, name: 'explorer.exe', memoryMb: 90, isProtected: true);

      final context = BoostContext(
        game: testGame,
        selectedAppsToClose: [userApp, protApp],
        processService: fakeProc,
        powerPlanService: fakePower,
      );

      final action = CloseBackgroundAppsAction();
      await action.apply(context);

      expect(fakeProc.closedPids, contains(200));
      expect(fakeProc.closedPids, isNot(contains(300)));
    });

    test('BoostSession reverts in REVERSE order and handles partial failure gracefully', () async {
      final callLog = <String>[];
      final action1 = ActionWithAudit('A1', callLog);
      final action2 = ActionWithAudit('A2', callLog, failOnApply: true);
      final action3 = ActionWithAudit('A3', callLog);

      final context = BoostContext(
        game: testGame,
        processService: fakeProc,
        powerPlanService: fakePower,
      );

      final session = BoostSession(game: testGame, context: context);
      await session.start([action1, action2, action3]);

      // A1 and A3 succeeded, A2 failed and was skipped
      expect(session.appliedActions.length, 2);
      expect(callLog, ['apply:A1', 'apply:A3']);

      // Revert must occur in reverse order: A3 then A1
      await session.stop();
      expect(callLog, ['apply:A1', 'apply:A3', 'revert:A3', 'revert:A1']);
      expect(session.isActive, isFalse);
    });
  });

  group('GameWatcher Tests', () {
    test('GameWatcher detects game launch and game exit correctly', () async {
      final fakeProc = FakeProcessPlatformService();
      final game = const Game(
        id: 'g1',
        name: 'Witcher 3',
        exePath: r'C:\Games\Witcher3.exe',
      );

      Game? startedGame;
      int? startedPid;
      Game? exitedGame;

      final watcher = GameWatcher(
        processService: fakeProc,
        getMonitoredGames: () => [game],
        onGameStarted: (g, pid) {
          startedGame = g;
          startedPid = pid;
        },
        onGameExited: (g, _) {
          exitedGame = g;
        },
      );

      // 1. Initial check: game is not running
      await watcher.checkProcesses();
      expect(startedGame, isNull);

      // 2. Game starts with PID 5555
      fakeProc.runningGamePids['Witcher3.exe'] = 5555;
      await watcher.checkProcesses();
      expect(startedGame?.id, 'g1');
      expect(startedPid, 5555);

      // 3. Game exits
      fakeProc.runningGamePids.remove('Witcher3.exe');
      await watcher.checkProcesses();
      expect(exitedGame?.id, 'g1');
    });
  });

  group('Game Model Serialization Tests', () {
    test('Game model serializes and deserializes cleanly', () {
      const original = Game(
        id: 'game_99',
        name: 'Doom Eternal',
        exePath: r'C:\Doom\DOOMEternal.exe',
        iconCachePath: r'C:\Cache\icon.png',
        autoBoost: true,
        switchPowerPlan: true,
        closeBackgroundApps: false,
        raisePriority: true,
        cleanTemp: false,
        targetPriority: ProcessPriority.high,
        appsToClose: ['discord.exe'],
      );

      final json = original.toJson();
      final restored = Game.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.exePath, original.exePath);
      expect(restored.iconCachePath, original.iconCachePath);
      expect(restored.targetPriority, ProcessPriority.high);
      expect(restored.appsToClose, ['discord.exe']);
    });
  });

  group('GameBooster Widget Tests', () {
    testWidgets('Renders empty state, headers, telemetry, and add game trigger', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBoosterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Booster'), findsOneWidget);
      expect(find.text('LIVE SYSTEM TELEMETRY'), findsOneWidget);
      expect(find.text('CPU USAGE'), findsOneWidget);
      expect(find.text('RAM LOAD'), findsOneWidget);
      expect(find.text('GPU ACTIVITY'), findsOneWidget);
      expect(find.text('GAME LIBRARY'), findsOneWidget);
      expect(find.text('Your Game Library is Empty'), findsOneWidget);
      expect(find.text('Add Game'), findsWidgets);
    });
  });
}
