import '../../data/models/running_process_model.dart';

/// Supported process priority levels for Game Booster.
/// Safety Rule: Realtime is prohibited to prevent Windows system starvation.
enum ProcessPriority {
  normal(0x00000020, 'Normal'),
  aboveNormal(0x00008000, 'Above Normal'),
  high(0x00000080, 'High');

  final int win32Value;
  final String label;
  const ProcessPriority(this.win32Value, this.label);
}

/// Abstract contract for interacting with Windows processes.
/// Keeps boost actions testable with mocks without invoking real system processes.
abstract class ProcessPlatformService {
  /// Fetches a list of running user processes, excluding protected system processes.
  Future<List<RunningProcess>> getRunningProcesses();

  /// Sets the execution priority of a process by its PID.
  /// Allowed priorities: Normal, Above Normal, High (never Realtime).
  Future<bool> setProcessPriority(int pid, ProcessPriority priority);

  /// Closes a process gracefully (or force-kills if allowed).
  Future<bool> closeProcess(int pid, {bool force = false});

  /// Launches an application or game from its executable path.
  Future<bool> launchProcess(String exePath);

  /// Looks up the running process ID for a given executable name or path.
  Future<int?> findProcessIdByNameOrPath(String exeNameOrPath);
}
