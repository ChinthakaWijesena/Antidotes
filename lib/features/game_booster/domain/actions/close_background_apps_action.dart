import '../../core/constants/protected_processes.dart';
import 'boost_action.dart';

/// Gracefully closes non-protected background apps selected by the user
/// to free up CPU cycles and RAM for the game.
class CloseBackgroundAppsAction implements BoostAction {
  static const String stateKey = 'closed_process_names';

  @override
  String get name => 'Close Background Applications';

  @override
  Future<void> apply(BoostContext context) async {
    final closed = <String>[];

    for (final app in context.selectedAppsToClose) {
      // Safety Rule 1: Never kill protected processes
      if (app.isProtected || isProtectedProcess(app.name)) {
        continue;
      }

      // Try graceful close first
      final success = await context.processService.closeProcess(app.pid, force: false);
      if (success) {
        closed.add(app.name);
      }
    }

    context.sessionState[stateKey] = closed;
  }

  @override
  Future<void> revert(BoostContext context) async {
    // Note: Terminated processes are recorded in session state for logging / audit.
    // They are not automatically restarted to prevent sudden CPU spikes after gaming.
  }
}
