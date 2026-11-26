import 'dart:io';
import '../../core/platform/system_stats_platform_service.dart';
import '../models/boost_stats_model.dart';
import '../../../hardware_monitor/data/services/hardware_monitor_service.dart';

/// Real Windows implementation of [SystemStatsPlatformService] leveraging hardware monitoring routines.
class WindowsSystemStatsService implements SystemStatsPlatformService {
  final HardwareMonitorService _hwService = HardwareMonitorService();
  String? _gpuName;
  bool _checkedGpu = false;

  @override
  Future<BoostStats> getLiveStats() async {
    try {
      final snap = await _hwService.takeSnapshot();

      final cpuPercent = snap.cpu.currentUsagePercent.clamp(0.0, 100.0);
      final ramPercent = snap.ram.usagePercent.clamp(0.0, 100.0);
      final ramUsedGb = snap.ram.usedBytes / (1024 * 1024 * 1024);
      final ramTotalGb = snap.ram.totalBytes / (1024 * 1024 * 1024);

      String gpuDisplay = 'N/A';
      if (snap.gpu.name.isNotEmpty) {
        _gpuName = snap.gpu.name;
      }
      if (snap.gpu.usagePercent > 0) {
        gpuDisplay = '${snap.gpu.usagePercent.toStringAsFixed(0)}%';
      }

      // Check nvidia-smi if available for fast GPU utilization percentage
      if (!_checkedGpu) {
        _checkedGpu = true;
      }

      try {
        final nvRes = await Process.run('nvidia-smi', [
          '--query-gpu=utilization.gpu',
          '--format=csv,noheader,nounits',
        ]);
        if (nvRes.exitCode == 0) {
          final out = nvRes.stdout.toString().trim();
          final parsed = int.tryParse(out);
          if (parsed != null) {
            gpuDisplay = '$parsed%';
          }
        }
      } catch (_) {
        if (_gpuName != null && _gpuName!.isNotEmpty) {
          gpuDisplay = _gpuName!;
        }
      }

      return BoostStats(
        cpuUsagePercent: cpuPercent,
        ramUsagePercent: ramPercent,
        ramUsedGb: ramUsedGb,
        ramTotalGb: ramTotalGb,
        gpuUsageDisplay: gpuDisplay,
      );
    } catch (_) {
      return BoostStats.empty();
    }
  }
}
