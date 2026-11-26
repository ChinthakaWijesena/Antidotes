import 'dart:io';
import '../../core/platform/power_plan_platform_service.dart';

/// Real Windows implementation of [PowerPlanPlatformService] using `powercfg`.
class WindowsPowerPlanService implements PowerPlanPlatformService {
  @override
  Future<String?> getActivePowerPlanGuid() async {
    try {
      final res = await Process.run('powercfg', ['/getactivescheme']);
      final out = res.stdout.toString();
      // Example output: "Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)"
      final match = RegExp(r'GUID:\s*([a-fA-F0-9\-]{36})').firstMatch(out);
      if (match != null) {
        return match.group(1)?.toLowerCase();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> setActivePowerPlanGuid(String guid) async {
    try {
      final cleanGuid = guid.trim().toLowerCase();
      final res = await Process.run('powercfg', ['/setactive', cleanGuid]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
