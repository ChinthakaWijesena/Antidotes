import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:antidotes/features/windows_settings/data/models/env_variable_item.dart';
import 'package:antidotes/features/windows_settings/data/models/performance_preset.dart';
import 'package:antidotes/features/windows_settings/data/models/power_scheme_item.dart';
import 'package:antidotes/features/windows_settings/data/models/virtual_memory_config.dart';

final class _MemoryStatusEx extends Struct {
  @Uint32()
  external int dwLength;
  @Uint32()
  external int dwMemoryLoad;
  @Uint64()
  external int ullTotalPhys;
  @Uint64()
  external int ullAvailPhys;
  @Uint64()
  external int ullTotalPageFile;
  @Uint64()
  external int ullAvailPageFile;
  @Uint64()
  external int ullTotalVirtual;
  @Uint64()
  external int ullAvailVirtual;
  @Uint64()
  external int ullAvailExtendedVirtual;
}

typedef _GlobalMemoryStatusExNative = Int32 Function(Pointer<_MemoryStatusEx> lpBuffer);
typedef _GlobalMemoryStatusExDart = int Function(Pointer<_MemoryStatusEx> lpBuffer);

class WindowsSettingsService {
  _GlobalMemoryStatusExDart? _globalMemoryStatusEx;

  WindowsSettingsService() {
    if (Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        _globalMemoryStatusEx = kernel32
            .lookupFunction<_GlobalMemoryStatusExNative, _GlobalMemoryStatusExDart>(
                'GlobalMemoryStatusEx');
      } catch (_) {}
    }
  }

  // ===================== 1. THEME MODE =====================

  Future<bool> getWindowsThemeIsLight() async {
    if (!Platform.isWindows) return false;

    try {
      final res = await Process.run('reg.exe', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        '/v',
        'AppsUseLightTheme',
      ]);

      if (res.exitCode == 0) {
        final out = res.stdout.toString();
        return out.contains('0x1');
      }
    } catch (_) {}
    return false;
  }

  Future<bool> setWindowsThemeIsLight(bool isLight) async {
    if (!Platform.isWindows) return true;

    final val = isLight ? '1' : '0';
    try {
      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        '/v',
        'AppsUseLightTheme',
        '/t',
        'REG_DWORD',
        '/d',
        val,
        '/f',
      ]);

      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        '/v',
        'SystemUsesLightTheme',
        '/t',
        'REG_DWORD',
        '/d',
        val,
        '/f',
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===================== 2. PERFORMANCE OPTIONS =====================

  Future<PerformancePreset> getVisualEffectsPreset() async {
    if (!Platform.isWindows) return PerformancePreset.letWindowsChoose;

    try {
      final res = await Process.run('reg.exe', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects',
        '/v',
        'VisualFXSetting',
      ]);

      if (res.exitCode == 0) {
        final out = res.stdout.toString();
        if (out.contains('0x1')) return PerformancePreset.bestAppearance;
        if (out.contains('0x2')) return PerformancePreset.bestPerformance;
        if (out.contains('0x3')) return PerformancePreset.custom;
      }
    } catch (_) {}
    return PerformancePreset.letWindowsChoose;
  }

  Future<bool> setVisualEffectsPreset(PerformancePreset preset) async {
    if (!Platform.isWindows) return true;

    try {
      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects',
        '/v',
        'VisualFXSetting',
        '/t',
        'REG_DWORD',
        '/d',
        preset.regValue.toString(),
        '/f',
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNativePerformanceOptions() async {
    if (!Platform.isWindows) return;
    try {
      await Process.start('SystemPropertiesPerformance.exe', []);
    } catch (_) {
      try {
        await Process.start('SystemPropertiesAdvanced.exe', []);
      } catch (_) {}
    }
  }

  // ===================== 3. POWER MODES =====================

  Future<List<PowerSchemeItem>> getPowerSchemes() async {
    if (!Platform.isWindows) return _getMockPowerSchemes();

    try {
      final res = await Process.run('powercfg.exe', ['/list']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        final items = <PowerSchemeItem>[];

        final regex = RegExp(r'GUID:\s*([a-f0-9\-]+)\s*\(([^)]+)\)(\s*\*)?', caseSensitive: false);
        for (final line in lines) {
          final m = regex.firstMatch(line);
          if (m != null) {
            final guid = m.group(1) ?? '';
            final name = m.group(2) ?? '';
            final isActive = m.group(3) != null;
            items.add(PowerSchemeItem(guid: guid, name: name, isActive: isActive));
          }
        }

        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return _getMockPowerSchemes();
  }

  Future<bool> setActivePowerScheme(String guid) async {
    if (!Platform.isWindows) return true;

    try {
      final res = await Process.run('powercfg.exe', ['/setactive', guid]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNativePowerOptions() async {
    if (!Platform.isWindows) return;
    try {
      await Process.start('control.exe', ['powercfg.cpl']);
    } catch (_) {}
  }

  // ===================== 4. ENVIRONMENT VARIABLES =====================

  Future<List<EnvVariableItem>> getEnvironmentVariables() async {
    if (!Platform.isWindows) return _getMockEnvVariables();

    final list = <EnvVariableItem>[];

    // Read User Environment Variables
    try {
      final resUser = await Process.run('reg.exe', ['query', r'HKCU\Environment']);
      if (resUser.exitCode == 0) {
        final lines = resUser.stdout.toString().split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split(RegExp(r'\s{4,}|\t+'));
          if (parts.length >= 3) {
            list.add(EnvVariableItem(
              name: parts[0],
              value: parts[2],
              isSystem: false,
            ));
          }
        }
      }
    } catch (_) {}

    // Read System Environment Variables
    try {
      final resSys = await Process.run('reg.exe', [
        'query',
        r'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      ]);
      if (resSys.exitCode == 0) {
        final lines = resSys.stdout.toString().split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split(RegExp(r'\s{4,}|\t+'));
          if (parts.length >= 3) {
            list.add(EnvVariableItem(
              name: parts[0],
              value: parts[2],
              isSystem: true,
            ));
          }
        }
      }
    } catch (_) {}

    if (list.isNotEmpty) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    }

    return _getMockEnvVariables();
  }

  Future<bool> setEnvironmentVariable(EnvVariableItem item) async {
    if (!Platform.isWindows) return true;

    try {
      final target = item.isSystem ? 'Machine' : 'User';
      final sanitizedVal = item.value.replaceAll("'", "''");
      final sanitizedName = item.name.replaceAll("'", "''");

      final script =
          "[Environment]::SetEnvironmentVariable('$sanitizedName', '$sanitizedVal', '$target')";

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteEnvironmentVariable(String name, bool isSystem) async {
    if (!Platform.isWindows) return true;

    try {
      final target = isSystem ? 'Machine' : 'User';
      final sanitizedName = name.replaceAll("'", "''");
      final script = "[Environment]::SetEnvironmentVariable('$sanitizedName', \$null, '$target')";

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNativeEnvironmentVariablesDialog() async {
    if (!Platform.isWindows) return;
    try {
      await Process.start('rundll32.exe', ['sysdm.cpl,EditEnvironmentVariables']);
    } catch (_) {}
  }

  // ===================== 5. VIRTUAL MEMORY =====================

  Future<VirtualMemoryConfig> getVirtualMemoryConfig() async {
    int totalRamMb = 16384; // 16 GB default
    int allocatedPageFileMb = 8192;
    bool isAuto = true;
    int initialMb = 0;
    int maxMb = 0;

    if (Platform.isWindows && _globalMemoryStatusEx != null) {
      final memPtr = calloc<_MemoryStatusEx>();
      memPtr.ref.dwLength = sizeOf<_MemoryStatusEx>();
      if (_globalMemoryStatusEx!(memPtr) != 0) {
        totalRamMb = (memPtr.ref.ullTotalPhys / (1024 * 1024)).round();
        final totalPageFile = (memPtr.ref.ullTotalPageFile / (1024 * 1024)).round();
        allocatedPageFileMb = (totalPageFile - totalRamMb).clamp(1024, 65536);
      }
      calloc.free(memPtr);
    }

    if (Platform.isWindows) {
      try {
        final res = await Process.run('reg.exe', [
          'query',
          r'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          '/v',
          'PagingFiles',
        ]);

        if (res.exitCode == 0) {
          final out = res.stdout.toString();
          if (out.contains(r'?:') || out.contains('?')) {
            isAuto = true;
          } else {
            // e.g. C:\pagefile.sys 8192 16384
            final regex = RegExp(r'([A-Za-z]:\\pagefile\.sys)\s+(\d+)\s+(\d+)', caseSensitive: false);
            final m = regex.firstMatch(out);
            if (m != null) {
              isAuto = false;
              initialMb = int.tryParse(m.group(2) ?? '0') ?? 0;
              maxMb = int.tryParse(m.group(3) ?? '0') ?? 0;
            }
          }
        }
      } catch (_) {}
    }

    return VirtualMemoryConfig(
      totalPhysicalRamMb: totalRamMb,
      currentAllocatedMb: allocatedPageFileMb,
      isAutomaticallyManaged: isAuto,
      initialSizeMb: initialMb > 0 ? initialMb : (totalRamMb * 1.5).round(),
      maximumSizeMb: maxMb > 0 ? maxMb : (totalRamMb * 3.0).round(),
    );
  }

  Future<bool> setVirtualMemoryConfig(VirtualMemoryConfig config) async {
    if (!Platform.isWindows) return true;

    try {
      if (config.isAutomaticallyManaged) {
        // Set registry to ?: \pagefile.sys
        await Process.run('reg.exe', [
          'add',
          r'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          '/v',
          'PagingFiles',
          '/t',
          'REG_MULTI_SZ',
          '/d',
          r'?:\\pagefile.sys',
          '/f',
        ]);
      } else {
        final entry = '${config.driveLetter}\\pagefile.sys ${config.initialSizeMb} ${config.maximumSizeMb}';
        await Process.run('reg.exe', [
          'add',
          r'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          '/v',
          'PagingFiles',
          '/t',
          'REG_MULTI_SZ',
          '/d',
          entry,
          '/f',
        ]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNativeVirtualMemoryDialog() async {
    if (!Platform.isWindows) return;
    try {
      await Process.start('SystemPropertiesAdvanced.exe', []);
    } catch (_) {
      try {
        await Process.start('control.exe', ['sysdm.cpl,,3']);
      } catch (_) {}
    }
  }

  // Fallbacks
  List<PowerSchemeItem> _getMockPowerSchemes() {
    return const [
      PowerSchemeItem(
        guid: '381b4222-f694-41f0-9685-ff5bb260df2e',
        name: 'Balanced',
        isActive: true,
      ),
      PowerSchemeItem(
        guid: '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c',
        name: 'High Performance',
        isActive: false,
      ),
      PowerSchemeItem(
        guid: 'a1841308-3541-4fab-bc81-f71556f20b4a',
        name: 'Power Saver',
        isActive: false,
      ),
      PowerSchemeItem(
        guid: 'e9a42b02-d5df-448d-aa00-03f14749eb61',
        name: 'Ultimate Performance',
        isActive: false,
      ),
    ];
  }

  List<EnvVariableItem> _getMockEnvVariables() {
    return const [
      EnvVariableItem(name: 'Path', value: r'C:\Windows\system32;C:\Windows', isSystem: true),
      EnvVariableItem(name: 'JAVA_HOME', value: r'C:\Program Files\Java\jdk-21', isSystem: true),
      EnvVariableItem(name: 'TEMP', value: r'C:\Users\User\AppData\Local\Temp', isSystem: false),
      EnvVariableItem(name: 'TMP', value: r'C:\Users\User\AppData\Local\Temp', isSystem: false),
      EnvVariableItem(name: 'OS', value: 'Windows_NT', isSystem: true),
    ];
  }
}
