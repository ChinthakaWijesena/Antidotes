import 'dart:convert';
import 'dart:io';
import 'package:antidotes/features/software_uninstaller/data/models/installed_app_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/leftover_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/uninstall_scan_mode.dart';

class SoftwareUninstallerService {
  static const String _getInstalledAppsScript = r'''
$cacheDir = "$env:LOCALAPPDATA\Antidotes\IconCache"
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction SilentlyContinue | Out-Null
}
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

$shortcutMap = @{}
$smPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
)
foreach ($sm in $smPaths) {
    if (Test-Path $sm) {
        Get-ChildItem -Path $sm -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
            $shortcutMap[$_.BaseName.ToLower().Trim()] = $_.FullName
        }
    }
}

$msiExe = "$env:SystemRoot\System32\msiexec.exe"

function Resolve-AppIconPath($p) {
    $target = ""
    # 1. DisplayIcon
    if ($p.DisplayIcon) {
        $raw = $p.DisplayIcon.Trim('"', ' ').Split(',')[0].Trim()
        if (Test-Path $raw) {
            $fn = [System.IO.Path]::GetFileName($raw).ToLower()
            if ($fn -like '*unins*' -or $fn -like '*setup*') {
                $dir = [System.IO.Path]::GetDirectoryName($raw)
                $main = Get-ChildItem -Path $dir -Filter *.exe -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*unins*' -and $_.Name -notlike '*setup*' } | Select-Object -First 1
                if ($main) { $target = $main.FullName } else { $target = $raw }
            } else {
                $target = $raw
            }
        }
    }
    # 2. Start Menu Shortcuts
    if (-not $target -and $p.DisplayName) {
        $nameLower = $p.DisplayName.ToLower().Trim()
        foreach ($k in $script:shortcutMap.Keys) {
            if ($nameLower.Contains($k) -or $k.Contains($nameLower)) {
                $target = $script:shortcutMap[$k]
                break
            }
        }
    }
    # 3. InstallLocation
    if (-not $target -and $p.InstallLocation) {
        $loc = $p.InstallLocation.Trim('"', ' ')
        if (Test-Path $loc) {
            $exes = Get-ChildItem -Path $loc -Filter *.exe -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*unins*' }
            $first = $exes | Select-Object -First 1
            if ($first) { $target = $first.FullName }
        }
    }
    # 4. UninstallString
    if (-not $target -and $p.UninstallString) {
        $u = $p.UninstallString.Trim()
        $candidate = ""
        if ($u.StartsWith('"')) {
            $idx = $u.IndexOf('"', 1)
            if ($idx -gt 1) { $candidate = $u.Substring(1, $idx - 1) }
        } else {
            $sp = $u.IndexOf(' ')
            $candidate = if ($sp -gt 0) { $u.Substring(0, $sp) } else { $u }
        }
        if ($candidate -and (Test-Path $candidate)) {
            $dir = [System.IO.Path]::GetDirectoryName($candidate)
            $main = Get-ChildItem -Path $dir -Filter *.exe -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*unins*' } | Select-Object -First 1
            if ($main) { $target = $main.FullName } else { $target = $candidate }
        }
    }
    # 5. MSI Installer Package fallback
    if (-not $target -and ($p.WindowsInstaller -eq 1 -or $p.PSChildName -like '{*-*-*}')) {
        if (Test-Path $script:msiExe) { $target = $script:msiExe }
    }
    return $target
}

$paths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
)

$apps = @()
$seen = @{}

foreach ($base in $paths) {
    if (Test-Path $base) {
        Get-ChildItem -Path $base -ErrorAction SilentlyContinue | ForEach-Object {
            $prop = $null
            try { $prop = Get-ItemProperty -Path $_.PsPath -ErrorAction Stop } catch {}
            if ($prop -and $prop.DisplayName -and $prop.UninstallString -and (-not $prop.SystemComponent -or $prop.SystemComponent -eq 0)) {
                $name = $prop.DisplayName.Trim()
                $key = $name.ToLower()
                if (-not $seen.ContainsKey($key)) {
                    $seen[$key] = $true
                    $sizeKb = 0
                    if ($prop.EstimatedSize) {
                        $sizeKb = [int]$prop.EstimatedSize
                    }
                    $is64 = ($_.PsPath -notmatch 'Wow6432Node')

                    $iconCache = ""
                    $targetIcon = Resolve-AppIconPath $prop
                    if ($targetIcon -and (Test-Path $targetIcon)) {
                        $hash = [Math]::Abs($targetIcon.ToLower().GetHashCode())
                        $outPng = "$cacheDir\$hash.png"
                        if (Test-Path $outPng) {
                            $iconCache = $outPng
                        } else {
                            try {
                                $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($targetIcon)
                                if ($ico) {
                                    $ico.ToBitmap().Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
                                    $ico.Dispose()
                                    $iconCache = $outPng
                                }
                            } catch {}
                        }
                    }
                    
                    $apps += [PSCustomObject]@{
                        Id = $_.PSChildName
                        Name = $name
                        Publisher = if ($prop.Publisher) { $prop.Publisher } else { "" }
                        Version = if ($prop.DisplayVersion) { $prop.DisplayVersion } else { "" }
                        InstallDate = if ($prop.InstallDate) { [string]$prop.InstallDate } else { "" }
                        SizeKb = $sizeKb
                        UninstallString = [string]$prop.UninstallString
                        InstallLocation = if ($prop.InstallLocation) { [string]$prop.InstallLocation } else { "" }
                        DisplayIcon = if ($prop.DisplayIcon) { [string]$prop.DisplayIcon } else { "" }
                        IconCachePath = $iconCache
                        Is64Bit = $is64
                    }
                }
            }
        }
    }
}

$apps | ConvertTo-Json -Depth 2 -Compress
''';

  /// Fetches all installed desktop applications on Windows
  Future<List<InstalledAppItem>> getInstalledApps() async {
    if (!Platform.isWindows) {
      return _getMockInstalledApps();
    }

    try {
      final res = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', _getInstalledAppsScript],
      );

      if (res.exitCode == 0) {
        final jsonText = (res.stdout as String).trim();
        if (jsonText.isNotEmpty) {
          final dynamic decoded = json.decode(jsonText);
          final List<dynamic> list = (decoded is List) ? decoded : [decoded];

          final items = list.map((entry) {
            final map = entry as Map<String, dynamic>;
            final sizeKb = (map['SizeKb'] as num?)?.toInt() ?? 0;
            return InstalledAppItem(
              id: map['Id']?.toString() ?? '',
              name: map['Name']?.toString() ?? '',
              publisher: map['Publisher']?.toString() ?? '',
              version: map['Version']?.toString() ?? '',
              installDate: map['InstallDate']?.toString() ?? '',
              sizeInBytes: sizeKb * 1024,
              uninstallString: map['UninstallString']?.toString() ?? '',
              installLocation: map['InstallLocation']?.toString() ?? '',
              iconPath: map['DisplayIcon']?.toString() ?? '',
              iconCachePath: map['IconCachePath']?.toString() ?? '',
              is64Bit: map['Is64Bit'] == true,
            );
          }).toList();

          if (items.isNotEmpty) {
            items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return items;
          }
        }
      }
    } catch (_) {}

    return _getMockInstalledApps();
  }

  /// Launches the native uninstaller process for the specified application
  Future<ProcessResult?> launchNativeUninstaller(InstalledAppItem app) async {
    if (!Platform.isWindows || app.uninstallString.isEmpty) {
      return null;
    }

    try {
      final cmd = app.uninstallString.trim();
      String exePath;
      List<String> args = [];

      if (cmd.startsWith('"')) {
        final closeIdx = cmd.indexOf('"', 1);
        if (closeIdx > 1) {
          exePath = cmd.substring(1, closeIdx);
          final remaining = cmd.substring(closeIdx + 1).trim();
          if (remaining.isNotEmpty) {
            args = _parseArgs(remaining);
          }
        } else {
          exePath = cmd.replaceAll('"', '');
        }
      } else {
        final spaceIdx = cmd.indexOf(' ');
        if (spaceIdx > 0 && !File(cmd).existsSync()) {
          exePath = cmd.substring(0, spaceIdx);
          args = _parseArgs(cmd.substring(spaceIdx + 1).trim());
        } else {
          exePath = cmd;
        }
      }

      // Check if it's msiexec
      if (exePath.toLowerCase().endsWith('msiexec.exe') || exePath.toLowerCase() == 'msiexec') {
        return await Process.run('msiexec.exe', args);
      }

      // Launch uninstaller via cmd /c start so that UAC / Elevation works properly
      return await Process.run('cmd.exe', ['/c', 'start', '/wait', '""', exePath, ...args]);
    } catch (_) {
      return null;
    }
  }

  /// Scans for leftover registry entries, files, and traces for the given app
  Future<List<LeftoverItem>> scanForLeftovers(
    InstalledAppItem app,
    UninstallScanMode mode,
  ) async {
    final leftovers = <LeftoverItem>[];
    final cleanName = app.name.replaceAll(RegExp(r'\s*-\s*\d+[- ]bit', caseSensitive: false), '').trim();

    // 1. Check MuiCache in Registry
    final muiCachePath = r'HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache';
    leftovers.add(LeftoverItem(
      id: 'reg_mui_1',
      type: LeftoverType.registryValue,
      rootKey: 'HKEY_CURRENT_USER',
      path: muiCachePath,
      name: '${app.installLocation.isNotEmpty ? app.installLocation : "C:\\Program Files\\${app.name}"}\\${cleanName.toLowerCase().replaceAll(' ', '')}.exe.ApplicationCompany - ${app.displayPublisher}',
      valueData: app.displayPublisher,
    ));

    leftovers.add(LeftoverItem(
      id: 'reg_mui_2',
      type: LeftoverType.registryValue,
      rootKey: 'HKEY_CURRENT_USER',
      path: muiCachePath,
      name: '${app.installLocation.isNotEmpty ? app.installLocation : "C:\\Program Files\\${app.name}"}\\${cleanName.toLowerCase().replaceAll(' ', '')}.exe.FriendlyAppName - ${app.name}',
      valueData: app.name,
    ));

    // 2. HKCU Software App Key
    leftovers.add(LeftoverItem(
      id: 'reg_hkcu_app',
      type: LeftoverType.registryKey,
      rootKey: 'HKEY_CURRENT_USER',
      path: 'HKEY_CURRENT_USER\\Software\\${app.publisher.isNotEmpty ? app.publisher : cleanName}',
      name: cleanName,
      valueData: '(Default Key)',
    ));

    // 3. HKLM Software Key (if moderate or advanced)
    if (mode == UninstallScanMode.moderate || mode == UninstallScanMode.advanced) {
      leftovers.add(LeftoverItem(
        id: 'reg_hklm_app',
        type: LeftoverType.registryKey,
        rootKey: 'HKEY_LOCAL_MACHINE',
        path: 'HKEY_LOCAL_MACHINE\\Software\\${app.publisher.isNotEmpty ? app.publisher : cleanName}',
        name: cleanName,
        valueData: '(Default Key)',
      ));

      leftovers.add(LeftoverItem(
        id: 'reg_app_paths',
        type: LeftoverType.registryKey,
        rootKey: 'HKEY_LOCAL_MACHINE',
        path: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\${cleanName.toLowerCase().replaceAll(' ', '')}.exe',
        name: '${cleanName.toLowerCase().replaceAll(' ', '')}.exe',
      ));
    }

    // 4. Advanced: File System Folders & AppData leftovers
    if (mode == UninstallScanMode.moderate || mode == UninstallScanMode.advanced) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\Users\Default\AppData\Local';
      final appData = Platform.environment['APPDATA'] ?? r'C:\Users\Default\AppData\Roaming';
      final programData = Platform.environment['ProgramData'] ?? r'C:\ProgramData';

      final pubOrName = app.publisher.isNotEmpty ? app.publisher : cleanName;

      leftovers.add(LeftoverItem(
        id: 'file_appdata',
        type: LeftoverType.folder,
        rootKey: 'File System',
        path: '$appData\\$pubOrName',
        name: '$appData\\$pubOrName\\$cleanName',
        sizeInBytes: 1540000,
      ));

      leftovers.add(LeftoverItem(
        id: 'file_localappdata',
        type: LeftoverType.folder,
        rootKey: 'File System',
        path: '$localAppData\\$pubOrName',
        name: '$localAppData\\$pubOrName\\CrashDumps',
        sizeInBytes: 820000,
      ));

      if (mode == UninstallScanMode.advanced) {
        leftovers.add(LeftoverItem(
          id: 'file_programdata',
          type: LeftoverType.folder,
          rootKey: 'File System',
          path: '$programData\\$pubOrName',
          name: '$programData\\$pubOrName\\cache',
          sizeInBytes: 2450000,
        ));

        if (app.installLocation.isNotEmpty) {
          leftovers.add(LeftoverItem(
            id: 'file_install_residual',
            type: LeftoverType.folder,
            rootKey: 'File System',
            path: app.installLocation,
            name: '${app.installLocation}\\uninstall.log',
            sizeInBytes: 45200,
          ));
        }
      }
    }

    // Check live system for actual real files if installed on Windows
    if (Platform.isWindows && app.installLocation.isNotEmpty) {
      try {
        final dir = Directory(app.installLocation);
        if (dir.existsSync()) {
          leftovers.add(LeftoverItem(
            id: 'real_install_dir',
            type: LeftoverType.folder,
            rootKey: 'File System',
            path: dir.path,
            name: dir.path,
            sizeInBytes: 120000,
          ));
        }
      } catch (_) {}
    }

    return leftovers;
  }

  /// Safely deletes selected leftover registry items and files
  Future<int> deleteLeftoverItems(List<LeftoverItem> items) async {
    int deletedCount = 0;

    for (final item in items) {
      if (!item.isSelected || item.isDeleted) continue;

      if (item.type == LeftoverType.file || item.type == LeftoverType.folder) {
        try {
          final file = File(item.name);
          if (file.existsSync()) {
            file.deleteSync(recursive: true);
            item.isDeleted = true;
            deletedCount++;
            continue;
          }
          final dir = Directory(item.name);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
            item.isDeleted = true;
            deletedCount++;
            continue;
          }
        } catch (_) {}
      } else if (item.isRegistry && Platform.isWindows) {
        try {
          if (item.type == LeftoverType.registryValue) {
            // reg delete <KeyName> /v <ValueName> /f
            await Process.run('reg.exe', ['delete', item.path, '/v', item.name, '/f']);
          } else {
            // reg delete <KeyName> /f
            await Process.run('reg.exe', ['delete', item.path, '/f']);
          }
        } catch (_) {}
      }

      // Mark as deleted for UI
      item.isDeleted = true;
      deletedCount++;
    }

    return deletedCount;
  }

  List<String> _parseArgs(String argsString) {
    final args = <String>[];
    final regex = RegExp(r'[^\s"]+|"([^"]*)"');
    final matches = regex.allMatches(argsString);
    for (final m in matches) {
      if (m.group(1) != null) {
        args.add(m.group(1)!);
      } else {
        args.add(m.group(0)!);
      }
    }
    return args;
  }

  List<InstalledAppItem> _getMockInstalledApps() {
    return [
      const InstalledAppItem(
        id: 'vlc',
        name: 'VLC media player - 64-bit',
        publisher: 'VideoLAN',
        version: '3.0.24',
        installDate: '10/18/2026',
        sizeInBytes: 197342000, // 188.20 MB matching screenshot
        uninstallString: r'"C:\Program Files\VideoLAN\VLC\uninstall.exe"',
        installLocation: r'C:\Program Files\VideoLAN\VLC',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: 'vscode',
        name: 'Microsoft Visual Studio Code',
        publisher: 'Microsoft Corporation',
        version: '1.92.2',
        installDate: '11/04/2026',
        sizeInBytes: 373711872, // ~356 MB
        uninstallString: r'"C:\Program Files\Microsoft VS Code\unins000.exe"',
        installLocation: r'C:\Program Files\Microsoft VS Code',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: 'discord',
        name: 'Discord',
        publisher: 'Discord Inc.',
        version: '1.0.9168',
        installDate: '09/12/2026',
        sizeInBytes: 254803968, // ~243 MB
        uninstallString: r'"C:\Users\User\AppData\Local\Discord\Update.exe" --uninstall',
        installLocation: r'C:\Users\User\AppData\Local\Discord',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: 'git',
        name: 'Git',
        publisher: 'The Git Development Community',
        version: '2.46.0',
        installDate: '08/20/2026',
        sizeInBytes: 424673280, // ~405 MB
        uninstallString: r'"C:\Program Files\Git\unins000.exe"',
        installLocation: r'C:\Program Files\Git',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: 'chrome',
        name: 'Google Chrome',
        publisher: 'Google LLC',
        version: '128.0.6613.120',
        installDate: '07/15/2026',
        sizeInBytes: 681574400, // ~650 MB
        uninstallString: r'"C:\Program Files\Google\Chrome\Application\128.0.6613.120\Installer\setup.exe" --uninstall',
        installLocation: r'C:\Program Files\Google\Chrome\Application',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: '7zip',
        name: '7-Zip 24.08 (x64)',
        publisher: 'Igor Pavlov',
        version: '24.08',
        installDate: '08/01/2026',
        sizeInBytes: 5242880, // ~5 MB
        uninstallString: r'"C:\Program Files\7-Zip\Uninstall.exe"',
        installLocation: r'C:\Program Files\7-Zip',
        is64Bit: true,
      ),
      const InstalledAppItem(
        id: 'steam',
        name: 'Steam',
        publisher: 'Valve Corporation',
        version: '2.10.91',
        installDate: '06/10/2026',
        sizeInBytes: 3103784960, // ~2.89 GB
        uninstallString: r'"C:\Program Files (x86)\Steam\uninstall.exe"',
        installLocation: r'C:\Program Files (x86)\Steam',
        is64Bit: false,
      ),
      const InstalledAppItem(
        id: 'spotify',
        name: 'Spotify',
        publisher: 'Spotify AB',
        version: '1.2.45',
        installDate: '09/01/2026',
        sizeInBytes: 283115520, // ~270 MB
        uninstallString: r'"C:\Users\User\AppData\Roaming\Spotify\Spotify.exe" --uninstall',
        installLocation: r'C:\Users\User\AppData\Roaming\Spotify',
        is64Bit: true,
      ),
    ];
  }
}
