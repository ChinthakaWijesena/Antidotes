import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/hardware_monitor/data/models/battery_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/cpu_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/fan_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/gpu_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/network_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/ram_info.dart';
import 'package:antidotes/features/hardware_monitor/data/models/storage_info.dart';
import 'package:antidotes/features/hardware_monitor/data/services/hardware_monitor_service.dart';
import 'package:antidotes/features/hardware_monitor/presentation/controllers/hardware_monitor_controller.dart';

void main() {
  group('Hardware Monitoring Models Tests', () {
    test('CpuInfo properties calculate and copy accurately', () {
      const cpu = CpuInfo(
        modelName: 'AMD Ryzen 7 7445HS',
        physicalCores: 6,
        logicalProcessors: 12,
        maxClockGhz: 3.2,
        currentUsagePercent: 18.5,
        temperatureCelsius: 48.0,
      );

      expect(cpu.modelName, 'AMD Ryzen 7 7445HS');
      expect(cpu.physicalCores, 6);
      expect(cpu.logicalProcessors, 12);
      expect(cpu.temperatureCelsius, 48.0);

      final updated = cpu.copyWith(currentUsagePercent: 25.0);
      expect(updated.currentUsagePercent, 25.0);
      expect(updated.physicalCores, 6);
    });

    test('RamInfo calculations convert bytes to GB accurately', () {
      const ram = RamInfo(
        totalBytes: 16 * 1024 * 1024 * 1024,
        usedBytes: 8 * 1024 * 1024 * 1024,
        freeBytes: 8 * 1024 * 1024 * 1024,
        usagePercent: 50.0,
      );

      expect(ram.totalGb, 16.0);
      expect(ram.usedGb, 8.0);
      expect(ram.freeGb, 8.0);
      expect(ram.usagePercent, 50.0);
    });

    test('StorageInfo calculates multi-drive usage percent accurately', () {
      const driveC = DriveInfo(
        letter: 'C:',
        label: 'System Disk',
        fileSystem: 'NTFS',
        totalBytes: 500 * 1024 * 1024 * 1024,
        freeBytes: 250 * 1024 * 1024 * 1024,
      );

      expect(driveC.usagePercent, 50.0);
      expect(driveC.usedGb, 250.0);

      const storage = StorageInfo(drives: [driveC]);
      expect(storage.overallUsagePercent, 50.0);
    });

    test('BatteryInfo formats runtime and state label properly', () {
      const battery = BatteryInfo(
        hasBattery: true,
        chargePercent: 80,
        state: BatteryPowerState.discharging,
        isAcConnected: false,
        estimatedRemainingSeconds: 7200, // 2 hours
        healthPercent: 98.0,
        temperatureCelsius: 32.0,
        designCapacityMWh: 56000,
        fullChargeCapacityMWh: 55000,
      );

      expect(battery.stateLabel, 'On Battery');
      expect(battery.remainingTimeFormatted, '2h 0m remaining');

      const desktopPower = BatteryInfo(
        hasBattery: false,
        chargePercent: 100,
        state: BatteryPowerState.noBattery,
        isAcConnected: true,
        estimatedRemainingSeconds: 0,
        healthPercent: 100.0,
        temperatureCelsius: 30.0,
        designCapacityMWh: 0,
        fullChargeCapacityMWh: 0,
      );

      expect(desktopPower.stateLabel, 'Desktop PC (AC Power)');
    });

    test('GpuInfo and NetworkInfo contain accurate properties', () {
      const gpu = GpuInfo(
        name: 'AMD Radeon 740M',
        driverVersion: '32.0.32029.2010',
        totalVramBytes: 1024 * 1024 * 1024,
        usedVramBytes: 512 * 1024 * 1024,
        usagePercent: 30.0,
        temperatureCelsius: 42.0,
      );
      expect(gpu.totalVramMb, 1024.0);
      expect(gpu.usedVramMb, 512.0);

      const net = NetworkInfo(
        isConnected: true,
        adapterName: 'Realtek 8852BE',
        description: 'WiFi 6 NIC',
        connectionType: 'Wi-Fi',
        linkSpeed: '270 Mbps',
        ipAddress: '192.168.1.100',
        signalPercent: 95,
      );
      expect(net.isConnected, isTrue);
      expect(net.linkSpeed, '270 Mbps');
    });

    test('FanInfo properties calculate average RPM and copy properly', () {
      const fan = FanInfo(
        cpuFanRpm: 2800,
        gpuFanRpm: 2600,
        speedPercent: 55.0,
        mode: 'Balanced',
        fanCount: 2,
        isRunning: true,
      );

      expect(fan.cpuFanRpm, 2800);
      expect(fan.gpuFanRpm, 2600);
      expect(fan.averageRpm, 2700);
      expect(fan.speedPercent, 55.0);
      expect(fan.mode, 'Balanced');
      expect(fan.fanCount, 2);
      expect(fan.isRunning, isTrue);

      final updated = fan.copyWith(mode: 'Turbo', speedPercent: 95.0);
      expect(updated.mode, 'Turbo');
      expect(updated.speedPercent, 95.0);
      expect(updated.cpuFanRpm, 2800);
    });
  });

  group('HardwareMonitorService & Controller Tests', () {
    test('HardwareMonitorService takes a live hardware snapshot including fan', () async {
      final service = HardwareMonitorService();
      await service.initialize();

      final snapshot = await service.takeSnapshot();
      expect(snapshot, isNotNull);
      expect(snapshot.cpu.modelName.isNotEmpty, isTrue);
      expect(snapshot.cpu.physicalCores, greaterThan(0));
      expect(snapshot.ram.totalBytes, greaterThan(0));
      expect(snapshot.fan.cpuFanRpm, greaterThan(0));
      expect(snapshot.fan.gpuFanRpm, greaterThan(0));
      expect(snapshot.fan.averageRpm, greaterThan(0));
      expect(snapshot.fan.mode.isNotEmpty, isTrue);
      expect(snapshot.storage.drives.isNotEmpty, isTrue);
      expect(snapshot.network.ipAddress.isNotEmpty, isTrue);
    });

    test('HardwareMonitorController starts, ticks and updates history points', () async {
      final controller = HardwareMonitorController();
      await controller.start();

      expect(controller.currentSnapshot, isNotNull);
      expect(controller.cpuHistory.isNotEmpty, isTrue);
      expect(controller.ramHistory.isNotEmpty, isTrue);
      expect(controller.fanHistory.isNotEmpty, isTrue);
      expect(controller.fan, isNotNull);
      expect(controller.fan!.isRunning, isTrue);

      expect(controller.isLive, isTrue);
      controller.toggleLive();
      expect(controller.isLive, isFalse);

      controller.dispose();
    });
  });
}
