import 'dart:convert';
import 'dart:io';
import '../../core/constants/protected_processes.dart';
import '../../core/platform/process_platform_service.dart';
import '../models/running_process_model.dart';

/// Real Windows implementation of [ProcessPlatformService] using native Windows commands and PowerShell.
class WindowsProcessService implements ProcessPlatformService {
  @override
  Future<List<RunningProcess>> getRunningProcesses() async {
    try {
      // Use PowerShell to retrieve process list with memory and executable paths
      const script = r'''
$cacheDir = "$env:LOCALAPPDATA\Antidotes\IconCache"
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction SilentlyContinue | Out-Null
}
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

Get-Process | Where-Object { $_.MainWindowTitle -or ($_.WorkingSet64 -gt 15MB) } | ForEach-Object {
    $procName = $_.ProcessName
    $pidNum = $_.Id
    $ws = [Math]::Round($_.WorkingSet64 / 1MB)
    $iconPath = ""
    try {
        if ($_.Path -and (Test-Path $_.Path)) {
            $hash = [Math]::Abs($_.Path.ToLower().GetHashCode())
            $outPng = "$cacheDir\$hash.png"
            if (Test-Path $outPng) {
                $iconPath = $outPng
            } else {
                $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($_.Path)
                if ($ico) {
                    $ico.ToBitmap().Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
                    $ico.Dispose()
                    $iconPath = $outPng
                }
            }
        }
    } catch {}

    [PSCustomObject]@{
        Id = $pidNum
        Name = "$procName.exe"
        MemoryMb = $ws
        IconCache = $iconPath
    }
} | ConvertTo-Json -Compress
''';

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      if (res.exitCode != 0) return [];

      final out = res.stdout.toString().trim();
      if (out.isEmpty) return [];

      final dynamic decoded = jsonDecode(out);
      final List<dynamic> list = decoded is List ? decoded : [decoded];

      final results = <RunningProcess>[];
      for (final item in list) {
        if (item is Map) {
          final name = item['Name']?.toString() ?? '';
          final pid = (item['Id'] as num?)?.toInt() ?? 0;
          final mem = (item['MemoryMb'] as num?)?.toInt() ?? 0;
          final icon = item['IconCache']?.toString();

          if (pid <= 4) continue;

          final isProt = isProtectedProcess(name);
          results.add(RunningProcess(
            pid: pid,
            name: name,
            memoryMb: mem,
            isProtected: isProt,
            iconCachePath: icon != null && icon.isNotEmpty ? icon : null,
          ));
        }
      }

      // Sort by memory usage descending
      results.sort((a, b) => b.memoryMb.compareTo(a.memoryMb));
      return results;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> setProcessPriority(int pid, ProcessPriority priority) async {
    try {
      // Map enum to PowerShell priority string: Normal, AboveNormal, High (never Realtime)
      String psPriority;
      switch (priority) {
        case ProcessPriority.aboveNormal:
          psPriority = 'AboveNormal';
          break;
        case ProcessPriority.high:
          psPriority = 'High';
          break;
        case ProcessPriority.normal:
          psPriority = 'Normal';
          break;
      }

      final script =
          '\$p = Get-Process -Id $pid -ErrorAction SilentlyContinue; if (\$p) { \$p.PriorityClass = "$psPriority"; \$true } else { \$false }';

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      return res.stdout.toString().trim().toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> closeProcess(int pid, {bool force = false}) async {
    try {
      // Safety rule 1: Never kill protected processes
      // We check if this PID belongs to a protected process first
      final checkRes = await Process.run('tasklist', [
        '/FI',
        'PID eq $pid',
        '/FO',
        'CSV',
        '/NH',
      ]);
      final checkOut = checkRes.stdout.toString().toLowerCase();
      for (final prot in kProtectedProcesses) {
        if (checkOut.contains(prot)) {
          // Refuse to terminate protected process
          return false;
        }
      }

      // Try graceful close first (no /F)
      final args = <String>['/PID', pid.toString()];
      if (force) {
        args.add('/F');
      }

      final res = await Process.run('taskkill', args);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> launchProcess(String exePath) async {
    try {
      final file = File(exePath);
      if (!await file.exists()) return false;

      await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.detached,
        workingDirectory: file.parent.path,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> findProcessIdByNameOrPath(String exeNameOrPath) async {
    try {
      final filename = exeNameOrPath.contains(r'\') || exeNameOrPath.contains('/')
          ? exeNameOrPath.split(RegExp(r'[\\/]')).last
          : exeNameOrPath;

      final res = await Process.run('tasklist', [
        '/FI',
        'IMAGENAME eq $filename',
        '/FO',
        'CSV',
        '/NH',
      ]);

      final out = res.stdout.toString().trim();
      if (out.isEmpty || out.startsWith('INFO:')) return null;

      final lines = out.split('\n');
      for (final line in lines) {
        final parts = line.split('","');
        if (parts.length >= 2) {
          final pidStr = parts[1].replaceAll('"', '').trim();
          final pid = int.tryParse(pidStr);
          if (pid != null && pid > 4) {
            return pid;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
