import 'dart:convert';
import 'dart:io';
import '../models/disk_health_model.dart';

/// Queries S.M.A.R.T. disk health data via Windows PowerShell / WMI.
class DiskHealthService {
  const DiskHealthService._();
  static const DiskHealthService instance = DiskHealthService._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns S.M.A.R.T. health data for every detected physical drive.
  Future<List<DiskDrive>> fetchAllDrives() async {
    final script = _buildScript();
    final result = await _runPs(script);
    return _parseDrives(result);
  }

  // ── PowerShell Script ──────────────────────────────────────────────────────

  static String _buildScript() => r'''
$ErrorActionPreference = "SilentlyContinue"
$drives = @()

try {
  $physDisks = Get-PhysicalDisk
  foreach ($pd in $physDisks) {

    # Basic info
    $name   = $pd.FriendlyName
    $model  = $pd.FriendlyName
    $media  = $pd.MediaType.ToString()
    $health = $pd.HealthStatus.ToString()
    $opStatus = $pd.OperationalStatus.ToString()
    $size   = [long]$pd.Size
    $used   = [long]$pd.AllocatedSize

    # Map disk number for WMI queries
    $diskNum = $null
    try {
      $diskNum = ($pd | Get-Disk).Number
    } catch {}

    # S.M.A.R.T. failure prediction
    $predictFail = $false
    if ($diskNum -ne $null) {
      try {
        $preds = Get-WmiObject -Namespace root\wmi `
                   -Class MSStorageDriver_FailurePredictStatus
        foreach ($p in $preds) {
          if ($p.InstanceName -match "Disk$diskNum") {
            $predictFail = $p.PredictFailure
          }
        }
      } catch {}
    }

    # S.M.A.R.T. raw attribute data (temperature, power-on hours, life left)
    $smartAttrs = @()
    $tempVal    = $null
    $lifePct    = $null
    $powerHours = $null

    # 1. Query StorageReliabilityCounter (Works for NVMe SSDs, SATA, and all modern drives)
    try {
      $rel = $pd | Get-StorageReliabilityCounter
      if ($rel) {
        if ($rel.Temperature) {
          $tempVal = [int]$rel.Temperature
        }
        if ($rel.Wear -ne $null) {
          $lifePct = [math]::Max(0, (100 - [int]$rel.Wear))
        }
        if ($rel.PowerOnHours -ne $null) {
          $powerHours = [int]$rel.PowerOnHours
        }
        if ($rel.Temperature) {
          $smartAttrs += [PSCustomObject]@{
            Id = 194; Name = "Temperature"; Value = [int]$rel.Temperature; Worst = [int]$rel.Temperature; Threshold = 0; RawValue = [int]$rel.Temperature
          }
        }
        if ($lifePct -ne $null) {
          $smartAttrs += [PSCustomObject]@{
            Id = 231; Name = "SSD Life Left"; Value = $lifePct; Worst = $lifePct; Threshold = 0; RawValue = $lifePct
          }
        }
        if ($powerHours -ne $null) {
          $smartAttrs += [PSCustomObject]@{
            Id = 9; Name = "Power-On Hours"; Value = 100; Worst = 100; Threshold = 0; RawValue = $powerHours
          }
        }
        if ($rel.ReadErrorsTotal -ne $null) {
          $smartAttrs += [PSCustomObject]@{
            Id = 1; Name = "Read Error Rate"; Value = 100; Worst = 100; Threshold = 0; RawValue = [int]$rel.ReadErrorsTotal
          }
        }
        if ($rel.WriteErrorsTotal -ne $null) {
          $smartAttrs += [PSCustomObject]@{
            Id = 7; Name = "Write Error Rate"; Value = 100; Worst = 100; Threshold = 0; RawValue = [int]$rel.WriteErrorsTotal
          }
        }
      }
    } catch {}

    # 2. Query ATAPI S.M.A.R.T. (For SATA drives if StorageReliabilityCounter didn't provide attrs)
    if ($diskNum -ne $null -and $smartAttrs.Count -eq 0) {
      try {
        $smartData = Get-WmiObject -Namespace root\wmi `
                       -Class MSStorageDriver_ATAPISmartData
        foreach ($sd in $smartData) {
          if ($sd.InstanceName -match "Disk$diskNum") {
            $data = $sd.VendorSpecific
            # Attribute block: starts at index 2, 12 bytes each, up to 30 attrs
            for ($i = 2; $i -lt $data.Count - 11; $i += 12) {
              $attrId = $data[$i]
              if ($attrId -eq 0) { continue }
              $val   = $data[$i + 3]
              $worst = $data[$i + 4]
              $thres = 0
              $raw   = [int]($data[$i + 5]) + ([int]($data[$i + 6]) * 256) +
                       ([int]($data[$i + 7]) * 65536)

              # Known attribute names
              $attrName = switch ($attrId) {
                1   { "Read Error Rate" }
                3   { "Spin-Up Time" }
                4   { "Start/Stop Count" }
                5   { "Reallocated Sectors" }
                7   { "Seek Error Rate" }
                9   { "Power-On Hours" }
                10  { "Spin Retry Count" }
                12  { "Power Cycle Count" }
                177 { "Wear Leveling Count" }
                190 { "Airflow Temperature" }
                191 { "G-Sense Error Rate" }
                192 { "Power-Off Retract" }
                194 { "Temperature" }
                197 { "Current Pending Sectors" }
                198 { "Uncorrectable Sectors" }
                199 { "UltraDMA CRC Errors" }
                231 { "SSD Life Left" }
                233 { "NAND Writes (GB)" }
                241 { "Total LBAs Written" }
                242 { "Total LBAs Read" }
                default { "Attribute $attrId" }
              }

              # Grab temperature
              if (($attrId -eq 194 -or $attrId -eq 190) -and $tempVal -eq $null) {
                $t = $data[$i + 5]
                if ($t -gt 0 -and $t -lt 100) { $tempVal = $t }
              }

              $smartAttrs += [PSCustomObject]@{
                Id        = $attrId
                Name      = $attrName
                Value     = $val
                Worst     = $worst
                Threshold = $thres
                RawValue  = $raw
              }
            }
          }
        }
      } catch {}
    }

    $drives += [PSCustomObject]@{
      Name            = $name
      Model           = $model
      MediaType       = $media
      HealthStatus    = $health
      OperationalStatus = $opStatus
      SizeBytes       = $size
      UsedBytes       = $used
      Temperature     = $tempVal
      LifeRemaining   = $lifePct
      PowerOnHours    = $powerHours
      PredictFailure  = $predictFail
      SmartAttributes = $smartAttrs
    }
  }
} catch {
  # Fallback: list logical disks if Get-PhysicalDisk fails
  $wdisks = Get-WmiObject Win32_DiskDrive
  foreach ($d in $wdisks) {
    $drives += [PSCustomObject]@{
      Name            = $d.Caption
      Model           = $d.Model
      MediaType       = "Unspecified"
      HealthStatus    = if ($d.Status -eq "OK") { "Healthy" } else { $d.Status }
      OperationalStatus = $d.Status
      SizeBytes       = [long]$d.Size
      UsedBytes       = 0
      Temperature     = $null
      PredictFailure  = $false
      SmartAttributes = @()
    }
  }
}

$drives | ConvertTo-Json -Depth 5
''';

  // ── PowerShell Runner ──────────────────────────────────────────────────────

  Future<String> _runPs(String script) async {
    try {
      final result = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        stdoutEncoding: const Utf8Codec(allowMalformed: true),
        stderrEncoding: const Utf8Codec(allowMalformed: true),
        runInShell: false,
      );
      return result.stdout.toString().trim();
    } catch (e) {
      return '';
    }
  }

  // ── JSON Parser ────────────────────────────────────────────────────────────

  List<DiskDrive> _parseDrives(String raw) {
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(DiskDrive.fromJson)
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        // Single disk — PS returns object not array for single item
        return [DiskDrive.fromJson(decoded)];
      }
    } catch (_) {}
    return [];
  }
}
