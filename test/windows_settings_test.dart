import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/windows_settings/data/models/env_variable_item.dart';
import 'package:antidotes/features/windows_settings/data/models/performance_preset.dart';
import 'package:antidotes/features/windows_settings/data/models/power_scheme_item.dart';
import 'package:antidotes/features/windows_settings/data/models/virtual_memory_config.dart';
import 'package:antidotes/features/windows_settings/data/services/windows_settings_service.dart';
import 'package:antidotes/features/windows_settings/presentation/controllers/windows_settings_controller.dart';

class FakeWindowsSettingsService extends WindowsSettingsService {
  bool isLight = false;
  PerformancePreset preset = PerformancePreset.letWindowsChoose;
  String activeGuid = 'guid_balanced';
  final List<EnvVariableItem> envs = [
    const EnvVariableItem(name: 'Path', value: r'C:\Windows\System32', isSystem: true),
    const EnvVariableItem(name: 'JAVA_HOME', value: r'C:\Java\jdk-21', isSystem: true),
    const EnvVariableItem(name: 'TEMP', value: r'C:\Users\User\AppData\Local\Temp', isSystem: false),
  ];

  @override
  Future<bool> getWindowsThemeIsLight() async => isLight;

  @override
  Future<bool> setWindowsThemeIsLight(bool val) async {
    isLight = val;
    return true;
  }

  @override
  Future<PerformancePreset> getVisualEffectsPreset() async => preset;

  @override
  Future<bool> setVisualEffectsPreset(PerformancePreset p) async {
    preset = p;
    return true;
  }

  @override
  Future<List<PowerSchemeItem>> getPowerSchemes() async {
    return [
      PowerSchemeItem(guid: 'guid_balanced', name: 'Balanced', isActive: activeGuid == 'guid_balanced'),
      PowerSchemeItem(guid: 'guid_perf', name: 'High Performance', isActive: activeGuid == 'guid_perf'),
      PowerSchemeItem(guid: 'guid_saver', name: 'Power Saver', isActive: activeGuid == 'guid_saver'),
    ];
  }

  @override
  Future<bool> setActivePowerScheme(String guid) async {
    activeGuid = guid;
    return true;
  }

  @override
  Future<List<EnvVariableItem>> getEnvironmentVariables() async => List.of(envs);

  @override
  Future<bool> setEnvironmentVariable(EnvVariableItem item) async {
    final idx = envs.indexWhere((e) => e.name == item.name && e.isSystem == item.isSystem);
    if (idx >= 0) {
      envs[idx] = item;
    } else {
      envs.add(item);
    }
    return true;
  }

  @override
  Future<bool> deleteEnvironmentVariable(String name, bool isSystem) async {
    envs.removeWhere((e) => e.name == name && e.isSystem == isSystem);
    return true;
  }

  @override
  Future<VirtualMemoryConfig> getVirtualMemoryConfig() async {
    return const VirtualMemoryConfig(
      totalPhysicalRamMb: 16384,
      currentAllocatedMb: 8192,
      isAutomaticallyManaged: true,
      initialSizeMb: 24576,
      maximumSizeMb: 49152,
    );
  }

  @override
  Future<bool> setVirtualMemoryConfig(VirtualMemoryConfig config) async => true;
}

void main() {
  group('Windows Settings Models Tests', () {
    test('PerformancePreset provides expected reg values and descriptions', () {
      expect(PerformancePreset.letWindowsChoose.regValue, 0);
      expect(PerformancePreset.bestAppearance.regValue, 1);
      expect(PerformancePreset.bestPerformance.regValue, 2);
      expect(PerformancePreset.custom.regValue, 3);
      expect(PerformancePreset.bestPerformance.description, contains('Turns off unnecessary animations'));
    });

    test('PowerSchemeItem copyWith updates accurately', () {
      const scheme = PowerSchemeItem(guid: 'guid-1', name: 'Performance', isActive: false);
      final active = scheme.copyWith(isActive: true);
      expect(active.isActive, isTrue);
      expect(active.name, 'Performance');
    });

    test('VirtualMemoryConfig calculates 1.5x and 3.0x recommendations accurately', () {
      // 8 GB RAM
      const config8Gb = VirtualMemoryConfig(
        totalPhysicalRamMb: 8192,
        currentAllocatedMb: 4096,
      );
      expect(config8Gb.recommendedInitialMb, 12288); // 8192 * 1.5
      expect(config8Gb.recommendedMaximumMb, 24576); // 8192 * 3.0

      // 16 GB RAM
      const config16Gb = VirtualMemoryConfig(
        totalPhysicalRamMb: 16384,
        currentAllocatedMb: 8192,
      );
      expect(config16Gb.recommendedInitialMb, 24576); // 16384 * 1.5
      expect(config16Gb.recommendedMaximumMb, 49152); // 16384 * 3.0
    });
  });

  group('WindowsSettingsController Tests', () {
    test('loads all settings from service', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);

      await controller.loadAllSettings();

      expect(controller.isLightMode, isFalse);
      expect(controller.performancePreset, PerformancePreset.letWindowsChoose);
      expect(controller.powerSchemes.length, 3);
      expect(controller.powerSchemes.first.isActive, isTrue);
      expect(controller.virtualMemoryConfig, isNotNull);
      expect(controller.virtualMemoryConfig!.totalPhysicalRamMb, 16384);
    });

    test('toggles theme mode', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      await controller.toggleThemeMode(true);
      expect(controller.isLightMode, isTrue);
      expect(service.isLight, isTrue);

      await controller.toggleThemeMode(false);
      expect(controller.isLightMode, isFalse);
      expect(service.isLight, isFalse);
    });

    test('changes performance preset', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      await controller.setPerformancePreset(PerformancePreset.bestPerformance);
      expect(controller.performancePreset, PerformancePreset.bestPerformance);
      expect(service.preset, PerformancePreset.bestPerformance);
    });

    test('changes active power scheme', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      await controller.setActivePowerScheme('guid_perf');
      expect(controller.powerSchemes.firstWhere((p) => p.guid == 'guid_perf').isActive, isTrue);
      expect(controller.powerSchemes.firstWhere((p) => p.guid == 'guid_balanced').isActive, isFalse);
    });

    test('filters environment variables by search and tab', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      expect(controller.filteredEnvVariables.length, 3);

      controller.setEnvSearchQuery('java');
      expect(controller.filteredEnvVariables.length, 1);
      expect(controller.filteredEnvVariables.first.name, 'JAVA_HOME');

      controller.setEnvSearchQuery('');
      controller.setEnvFilterTab(1); // User only
      expect(controller.filteredEnvVariables.length, 1);
      expect(controller.filteredEnvVariables.first.name, 'TEMP');

      controller.setEnvFilterTab(2); // System only
      expect(controller.filteredEnvVariables.length, 2);
    });

    test('saves and deletes environment variables', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      await controller.saveEnvVariable(const EnvVariableItem(
        name: 'ANTIDOTES_PATH',
        value: r'C:\Tools\Antidotes',
        isSystem: false,
      ));

      controller.setEnvFilterTab(0);
      expect(controller.filteredEnvVariables.any((e) => e.name == 'ANTIDOTES_PATH'), isTrue);

      await controller.deleteEnvVariable('ANTIDOTES_PATH', false);
      expect(controller.filteredEnvVariables.any((e) => e.name == 'ANTIDOTES_PATH'), isFalse);
    });

    test('updates virtual memory configuration', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      final updated = controller.virtualMemoryConfig!.copyWith(
        isAutomaticallyManaged: false,
        initialSizeMb: 12288,
        maximumSizeMb: 24576,
      );

      await controller.updateVirtualMemory(updated);
      expect(controller.virtualMemoryConfig!.isAutomaticallyManaged, isFalse);
      expect(controller.virtualMemoryConfig!.initialSizeMb, 12288);
      expect(controller.virtualMemoryConfig!.maximumSizeMb, 24576);
    });

    test('startup state loads and notifies listeners on toggle', () async {
      final service = FakeWindowsSettingsService();
      final controller = WindowsSettingsController(service: service);
      await controller.loadAllSettings();

      expect(controller.isStartupEnabled, isA<bool>());
      bool notified = false;
      controller.addListener(() => notified = true);
      await controller.toggleStartup(controller.isStartupEnabled);
      expect(notified, isTrue);
    });
  });
}

