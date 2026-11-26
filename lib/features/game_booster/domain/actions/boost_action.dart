import '../../core/platform/power_plan_platform_service.dart';
import '../../core/platform/process_platform_service.dart';
import '../../data/models/game_model.dart';
import '../../data/models/running_process_model.dart';

/// Context passed to each [BoostAction] during application and reverting.
class BoostContext {
  final Game game;
  final int? gamePid;
  final List<RunningProcess> selectedAppsToClose;
  final ProcessPlatformService processService;
  final PowerPlanPlatformService powerPlanService;

  /// Holds state saved before applying actions so they can be reverted reliably.
  final Map<String, dynamic> sessionState;

  BoostContext({
    required this.game,
    this.gamePid,
    this.selectedAppsToClose = const [],
    required this.processService,
    required this.powerPlanService,
    Map<String, dynamic>? sessionState,
  }) : sessionState = sessionState ?? <String, dynamic>{};
}

/// Abstract contract for reversible boost actions.
/// Architectural rule: Every action must be fully reversible.
abstract class BoostAction {
  /// Display name of the action.
  String get name;

  /// Applies the boost action and saves necessary revert data to [context.sessionState].
  Future<void> apply(BoostContext context);

  /// Reverts the action back to its prior system state using saved data in [context.sessionState].
  Future<void> revert(BoostContext context);
}
