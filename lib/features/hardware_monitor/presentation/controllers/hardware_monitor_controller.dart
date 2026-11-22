import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:antidotes/features/hardware_monitor/data/models/battery_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/cpu_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/gpu_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/hardware_snapshot.dart';
import 'package:antidotes/features/hardware_monitor/data/models/network_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/ram_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/storage_info.dart';
import 'package:antidotes/features/hardware_monitor/data/services/hardware_monitor_service.dart';

class HardwareMonitorController extends ChangeNotifier {
  final HardwareMonitorService _service;
  Timer? _timer;

  HardwareSnapshot? _currentSnapshot;
  final List<double> _cpuHistory = [];
  final List<double> _ramHistory = [];
  bool _isLive = true;

  static const int maxHistoryPoints = 20;

  HardwareMonitorController({HardwareMonitorService? service})
      : _service = service ?? HardwareMonitorService();

  HardwareSnapshot? get currentSnapshot => _currentSnapshot;
  CpuInfo? get cpu => _currentSnapshot?.cpu;
  RamInfo? get ram => _currentSnapshot?.ram;
  GpuInfo? get gpu => _currentSnapshot?.gpu;
  StorageInfo? get storage => _currentSnapshot?.storage;
  BatteryInfo? get battery => _currentSnapshot?.battery;
  NetworkInfo? get network => _currentSnapshot?.network;

  List<double> get cpuHistory => List.unmodifiable(_cpuHistory);
  List<double> get ramHistory => List.unmodifiable(_ramHistory);
  bool get isLive => _isLive;

  Future<void> start() async {
    await _service.initialize();
    await _tick();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isLive) {
        _tick();
      }
    });
  }

  void toggleLive() {
    _isLive = !_isLive;
    notifyListeners();
  }

  Future<void> _tick() async {
    final snapshot = await _service.takeSnapshot();

    _cpuHistory.add(snapshot.cpu.currentUsagePercent);
    if (_cpuHistory.length > maxHistoryPoints) {
      _cpuHistory.removeAt(0);
    }

    _ramHistory.add(snapshot.ram.usagePercent);
    if (_ramHistory.length > maxHistoryPoints) {
      _ramHistory.removeAt(0);
    }

    _currentSnapshot = snapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
