import '../../core/platform/process_platform_service.dart';
import 'boost_action.dart';

/// Raises the target game process priority to Above Normal (or High, never Realtime)
/// to prioritize CPU core scheduling, and restores it to Normal when finished.
class ProcessPriorityAction implements BoostAction {
  static const String stateKey = 'priority_raised_pid';

  @override
  String get name => 'Optimize Game Priority';

  @override
  Future<void> apply(BoostContext context) async {
    int? pid = context.gamePid;

    // If PID was not directly known, try resolving it via processService
    pid ??= await context.processService.findProcessIdByNameOrPath(context.game.exeFileName);

    if (pid != null && pid > 4) {
      // Safety Rule 7: Realtime priority is prohibited. Default is Above Normal, max is High.
      var target = context.game.targetPriority;
      if (target != ProcessPriority.high && target != ProcessPriority.aboveNormal) {
        target = ProcessPriority.aboveNormal;
      }

      final success = await context.processService.setProcessPriority(pid, target);
      if (success) {
        context.sessionState[stateKey] = pid;
      }
    }
  }

  @override
  Future<void> revert(BoostContext context) async {
    final pid = context.sessionState[stateKey] as int?;
    if (pid != null && pid > 4) {
      await context.processService.setProcessPriority(pid, ProcessPriority.normal);
    }
  }
}
