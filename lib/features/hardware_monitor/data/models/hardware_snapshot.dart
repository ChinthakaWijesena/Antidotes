import 'battery_info.dart';
import 'cpu_info.dart';
import 'fan_info.dart';
import 'gpu_info.dart';
import 'network_info.dart';
import 'ram_info.dart';
import 'storage_info.dart';

class HardwareSnapshot {
  final CpuInfo cpu;
  final RamInfo ram;
  final GpuInfo gpu;
  final FanInfo fan;
  final StorageInfo storage;
  final BatteryInfo battery;
  final NetworkInfo network;
  final DateTime timestamp;

  const HardwareSnapshot({
    required this.cpu,
    required this.ram,
    required this.gpu,
    required this.fan,
    required this.storage,
    required this.battery,
    required this.network,
    required this.timestamp,
  });
}
