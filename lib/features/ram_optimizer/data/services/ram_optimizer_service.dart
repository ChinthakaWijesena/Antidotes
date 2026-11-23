import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ram_snapshot.dart';
import '../models/ram_boost_result.dart';
import '../models/ram_optimize_options.dart';

/// Windows RAM Optimizer service.
///
/// Implements all five operations from Sordum Reduce Memory v1.8:
///   1. Process Working Sets  – EmptyWorkingSet on user apps (no admin)
///   2. System Memory Cache   – SetSystemFileCacheSize reset (no admin)
///   3. Services & Background – EmptyWorkingSet on system/service processes (admin)
///   4. Modified Page List    – NtSetSystemInformation command 3 (admin)
///   5. Standby List          – NtSetSystemInformation command 4 (admin)
class RamOptimizerService {
  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads current RAM statistics without making any changes.
  Future<RamSnapshot> snapshot() async {
    if (!Platform.isWindows) {
      return RamSnapshot(totalMb: 0, usedMb: 0, standbyMb: 0, freeMb: 0, timestamp: DateTime.now());
    }
    return _readSnapshot();
  }

  /// Runs the selected RAM-cleaning operations.
  ///
  /// Non-admin operations run first without UAC.
  /// If any admin operation is selected, an elevated UAC process is also launched.
  Future<RamBoostResult> boost(RamOptimizeOptions options) async {
    if (!Platform.isWindows) {
      return RamBoostResult.failed(
        totalRamMb: 0,
        usedBeforeMb: 0,
        errorMessage: 'RAM Optimizer is only supported on Windows.',
      );
    }

    if (options.selected.isEmpty) {
      return RamBoostResult.failed(
        totalRamMb: 0,
        usedBeforeMb: 0,
        errorMessage: 'No operations selected.',
      );
    }

    final before = await _readSnapshot();
    final Map<RamOperation, String> opResults = {};

    // ── Step 1: Run non-admin operations directly ─────────────────────────
    final nonAdminOps = options.selected.where((o) => !o.requiresAdmin).toSet();
    if (nonAdminOps.isNotEmpty) {
      final directResults = await _runScript(
        _buildScript(nonAdminOps, resultFile: null),
        elevated: false,
      );
      opResults.addAll(directResults);
    }

    // ── Step 2: Run all selected operations elevated (if admin ops needed) ─
    bool elevatedRan = false;
    if (options.requiresAdmin) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final tempDir = Directory.systemTemp.path;
      final scriptPath = '$tempDir\\antidotes_ram_$ts.ps1';
      final resultPath = '$tempDir\\antidotes_ram_${ts}_out.txt';

      final script = _buildScript(options.selected, resultFile: resultPath);
      try {
        await File(scriptPath).writeAsString(script);
        await Process.run(
          'powershell.exe',
          [
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
            'Start-Process powershell.exe -Verb RunAs -Wait -WindowStyle Hidden '
                '-ArgumentList \'-NoProfile -ExecutionPolicy Bypass -File "$scriptPath"\'',
          ],
          runInShell: false,
        );
        try { await File(scriptPath).delete(); } catch (_) {}

        final f = File(resultPath);
        if (await f.exists()) {
          final content = (await f.readAsString()).trim();
          try { await f.delete(); } catch (_) {}
          final parsed = _parseResults(content);
          opResults.addAll(parsed);
          elevatedRan = true;
        }
      } catch (e) {
        debugPrint('RamOptimizerService.boost elevated error: $e');
        try { await File(scriptPath).delete(); } catch (_) {}
        try { await File(resultPath).delete(); } catch (_) {}
      }

      if (!elevatedRan) {
        // UAC was cancelled or failed
        final after = await _readSnapshot();
        return RamBoostResult(
          totalRamMb: after.totalMb,
          usedBeforeMb: before.usedMb,
          usedAfterMb: after.usedMb,
          success: opResults.isNotEmpty,
          operationResults: opResults,
          errorMessage: opResults.isEmpty
              ? 'Administrator permission was not granted (UAC cancelled).'
              : null,
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    final after = await _readSnapshot();

    return RamBoostResult(
      totalRamMb: after.totalMb,
      usedBeforeMb: before.usedMb,
      usedAfterMb: after.usedMb,
      success: opResults.isNotEmpty,
      operationResults: opResults,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Script builder
  // ──────────────────────────────────────────────────────────────────────────

  /// Builds the PowerShell script for the given set of operations.
  /// If [resultFile] is non-null the script writes its result map there;
  /// otherwise it writes to stdout.
  String _buildScript(Set<RamOperation> ops, {required String? resultFile}) {
    final doWs       = ops.contains(RamOperation.processWorkingSets);
    final doCache    = ops.contains(RamOperation.systemCache);
    final doSvc      = ops.contains(RamOperation.serviceWorkingSets);
    final doModList  = ops.contains(RamOperation.modifiedPageList);
    final doStandby  = ops.contains(RamOperation.standbyList);

    final script = StringBuffer();
    script.writeln(r'$ErrorActionPreference = "Continue"');

    // ── C# helper class ────────────────────────────────────────────────────
    script.writeln(r'''
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public class RamUtil {
    [DllImport("ntdll.dll")]
    public static extern int NtSetSystemInformation(int infoClass, IntPtr info, int length);

    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);

    [DllImport("kernel32.dll")]
    public static extern bool SetSystemFileCacheSize(IntPtr min, IntPtr max, uint flags);

    /// Trim working sets. If includeSystem is true, attempts all processes (requires admin).
    public static string TrimWorkingSets(bool includeSystem) {
        int trimmed = 0, skipped = 0;
        foreach (var proc in Process.GetProcesses()) {
            try {
                if (!includeSystem) {
                    // Skip system/service processes by checking session ID
                    if (proc.SessionId == 0) { skipped++; continue; }
                }
                if (EmptyWorkingSet(proc.Handle)) trimmed++;
                else skipped++;
            } catch { skipped++; }
        }
        return trimmed + " trimmed, " + skipped + " skipped";
    }

    /// Clear file-system cache by resetting cache size limits.
    public static string ClearSystemCache() {
        try {
            bool ok = SetSystemFileCacheSize((IntPtr)(-1), (IntPtr)(-1), 0);
            return ok ? "Cache reset OK" : "Cache reset returned false";
        } catch (Exception ex) { return "Error: " + ex.Message; }
    }

    /// Flush modified page list (command 3). Requires admin.
    public static string FlushModifiedList() {
        try {
            IntPtr buf = Marshal.AllocHGlobal(4);
            Marshal.WriteInt32(buf, 3);
            int r = NtSetSystemInformation(80, buf, 4);
            Marshal.FreeHGlobal(buf);
            return r == 0 ? "Flushed OK" : "NTSTATUS 0x" + r.ToString("X");
        } catch (Exception ex) { return "Error: " + ex.Message; }
    }

    /// Purge standby list (command 4). Requires admin.
    public static string PurgeStandbyList() {
        try {
            IntPtr buf = Marshal.AllocHGlobal(4);
            Marshal.WriteInt32(buf, 4);
            int r = NtSetSystemInformation(80, buf, 4);
            Marshal.FreeHGlobal(buf);
            return r == 0 ? "Purged OK" : "NTSTATUS 0x" + r.ToString("X");
        } catch (Exception ex) { return "Error: " + ex.Message; }
    }
}
"@ -ErrorAction SilentlyContinue
''');

    // ── Collect results ────────────────────────────────────────────────────
    script.writeln(r'$lines = @()');

    if (doWs) {
      script.writeln(r'try { $r = [RamUtil]::TrimWorkingSets($false); $lines += "processWorkingSets:$r" } catch { $lines += "processWorkingSets:Error:$($_.Exception.Message)" }');
    }
    if (doCache) {
      script.writeln(r'try { $r = [RamUtil]::ClearSystemCache(); $lines += "systemCache:$r" } catch { $lines += "systemCache:Error:$($_.Exception.Message)" }');
    }
    if (doSvc) {
      script.writeln(r'try { $r = [RamUtil]::TrimWorkingSets($true); $lines += "serviceWorkingSets:$r" } catch { $lines += "serviceWorkingSets:Error:$($_.Exception.Message)" }');
    }
    if (doModList) {
      script.writeln(r'try { $r = [RamUtil]::FlushModifiedList(); $lines += "modifiedPageList:$r" } catch { $lines += "modifiedPageList:Error:$($_.Exception.Message)" }');
    }
    if (doStandby) {
      script.writeln(r'try { $r = [RamUtil]::PurgeStandbyList(); $lines += "standbyList:$r" } catch { $lines += "standbyList:Error:$($_.Exception.Message)" }');
    }

    script.writeln(r'$output = "SUCCESS`n" + ($lines -join "`n")');

    if (resultFile != null) {
      script.writeln('[IO.File]::WriteAllText(\'$resultFile\', \$output)');
    } else {
      script.writeln(r'Write-Output $output');
    }

    return script.toString();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Script executor (direct / in-process PowerShell)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<RamOperation, String>> _runScript(
    String script, {
    required bool elevated,
  }) async {
    try {
      final r = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
        runInShell: false,
      );
      return _parseResults(r.stdout.toString());
    } catch (e) {
      debugPrint('RamOptimizerService._runScript error: $e');
      return {};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Result parser
  // ──────────────────────────────────────────────────────────────────────────

  Map<RamOperation, String> _parseResults(String raw) {
    final result = <RamOperation, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed == 'SUCCESS') continue;
      final idx = trimmed.indexOf(':');
      if (idx < 0) continue;
      final key = trimmed.substring(0, idx);
      final val = trimmed.substring(idx + 1);
      final op = _keyToOp(key);
      if (op != null) result[op] = val;
    }
    return result;
  }

  RamOperation? _keyToOp(String key) => switch (key) {
        'processWorkingSets' => RamOperation.processWorkingSets,
        'systemCache'        => RamOperation.systemCache,
        'serviceWorkingSets' => RamOperation.serviceWorkingSets,
        'modifiedPageList'   => RamOperation.modifiedPageList,
        'standbyList'        => RamOperation.standbyList,
        _                    => null,
      };

  // ──────────────────────────────────────────────────────────────────────────
  // RAM snapshot
  // ──────────────────────────────────────────────────────────────────────────

  static const String _snapshotPs = r'''
$os = Get-CimInstance Win32_OperatingSystem
$total = [math]::Round($os.TotalVisibleMemorySize / 1024)
$free  = [math]::Round($os.FreePhysicalMemory  / 1024)
$standby = 0
try {
  $pf = Get-CimInstance -Namespace root\cimv2 -ClassName Win32_PerfFormattedData_PerfOS_Memory
  $standby = [math]::Round($pf.StandbyCacheNormalPriorityBytes / 1MB)
} catch {}
$used = $total - $free
Write-Output "$total,$used,$standby,$free"
''';

  Future<RamSnapshot> _readSnapshot() async {
    try {
      final r = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', _snapshotPs],
        runInShell: false,
      );
      final out = r.stdout.toString().trim();
      final parts = out.split(',');
      if (parts.length == 4) {
        return RamSnapshot(
          totalMb:   int.tryParse(parts[0]) ?? 0,
          usedMb:    int.tryParse(parts[1]) ?? 0,
          standbyMb: int.tryParse(parts[2]) ?? 0,
          freeMb:    int.tryParse(parts[3]) ?? 0,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('RamOptimizerService._readSnapshot error: $e');
    }
    return RamSnapshot(totalMb: 0, usedMb: 0, standbyMb: 0, freeMb: 0, timestamp: DateTime.now());
  }
}
