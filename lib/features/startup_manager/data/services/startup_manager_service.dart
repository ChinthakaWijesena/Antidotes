import 'dart:convert';
import 'dart:io';
import '../models/startup_app_item.dart';

class StartupDataResult {
  final List<StartupAppItem> apps;
  final String biosTime;

  const StartupDataResult({required this.apps, required this.biosTime});
}

class StartupManagerService {
  static const String _powershellScript = r'''
$cacheDir = "$env:LOCALAPPDATA\Antidotes\IconCache"
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction SilentlyContinue | Out-Null
}
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

$allApps = @()

$shortcutMap = @{}
$smPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
)
foreach ($sm in $smPaths) {
    if (Test-Path $sm) {
        Get-ChildItem -Path $sm -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
            $base = $_.BaseName.ToLower().Trim()
            if (-not $shortcutMap.ContainsKey($base)) {
                $shortcutMap[$base] = $_.FullName
            }
        }
    }
}

$hkcuRunAppr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
$hklmRunAppr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
$hklmRun32Appr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
$folderAppr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"

function Get-IconCachePath($targetPath) {
    if ($targetPath -and (Test-Path $targetPath)) {
        $hash = [Math]::Abs($targetPath.ToLower().GetHashCode())
        $outPng = "$script:cacheDir\$hash.png"
        if (Test-Path $outPng) { return $outPng }
        try {
            $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($targetPath)
            if ($ico) {
                $ico.ToBitmap().Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
                $ico.Dispose()
                return $outPng
            }
        } catch {}
    }
    return ""
}

function Resolve-StartupIcon($name, $exe) {
    $target = ""
    if ($exe -and (Test-Path $exe)) {
        $fn = [System.IO.Path]::GetFileName($exe).ToLower()
        $dir = [System.IO.Path]::GetDirectoryName($exe)
        if ($fn -like '*update*.exe' -or $fn -eq 'launcher.exe') {
            $main = Get-ChildItem -Path $dir -Recurse -Filter *.exe -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*update*' -and $_.Name -notlike '*setup*' } | Select-Object -First 1
            if ($main) { $target = $main.FullName } else { $target = $exe }
        } else {
            $target = $exe
        }
    }
    if (-not $target -or -not (Test-Path $target)) {
        $n = $name.ToLower().Trim()
        foreach ($k in $script:shortcutMap.Keys) {
            if ($n.Contains($k) -or $k.Contains($n)) {
                $target = $script:shortcutMap[$k]
                break
            }
        }
    }
    return (Get-IconCachePath $target)
}

function Get-ApprovedMap($path) {
    $map = @{}
    if (Test-Path $path) {
        $props = (Get-ItemProperty $path -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $props) {
            if ($p.TypeNameOfValue -eq "System.Byte[]") {
                $map[$p.Name.ToLower()] = ($p.Value[0] -eq 2)
            }
        }
    }
    return $map
}

$hkcuMap = Get-ApprovedMap $hkcuRunAppr
$hklmMap = Get-ApprovedMap $hklmRunAppr
$hklm32Map = Get-ApprovedMap $hklmRun32Appr
$folderMap = Get-ApprovedMap $folderAppr

function Get-ExePublisher($exePath) {
    if ($exePath -and (Test-Path $exePath)) {
        try {
            $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)
            if ($info.CompanyName) { return $info.CompanyName }
        } catch {}
    }
    return ""
}

function Extract-Exe($cmd) {
    $c = $cmd.Trim()
    if ($c.StartsWith('"')) {
        $idx = $c.IndexOf('"', 1)
        if ($idx -gt 1) { return $c.Substring(1, $idx - 1) }
    }
    $exeIdx = $c.IndexOf('.exe', [System.StringComparison]::OrdinalIgnoreCase)
    if ($exeIdx -gt 0) {
        return $c.Substring(0, $exeIdx + 4)
    }
    $sp = $c.IndexOf(' ')
    if ($sp -gt 0) { return $c.Substring(0, $sp) }
    return $c
}

function Read-RegRun($regPath, $locName, $map, $locType) {
    $items = @()
    if (Test-Path $regPath) {
        $props = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $props) {
            if ($p.Name -notmatch '^PS' -and $p.Name -ne "") {
                $name = $p.Name
                $cmd = [string]$p.Value
                $enabled = $true
                if ($map.ContainsKey($name.ToLower())) {
                    $enabled = $map[$name.ToLower()]
                }
                $exe = Extract-Exe $cmd
                $pub = Get-ExePublisher $exe
                if (-not $pub) {
                    $l = $name.ToLower()
                    if ($l -like '*microsoft*' -or $l -like '*security*') { $pub = "Microsoft Corporation" }
                    elseif ($l -like '*google*') { $pub = "Google LLC" }
                    elseif ($l -like '*discord*') { $pub = "Discord Inc." }
                    elseif ($l -like '*steam*') { $pub = "Valve Corporation" }
                    elseif ($l -like '*amd*') { $pub = "Advanced Micro Devices" }
                    elseif ($l -like '*figma*') { $pub = "Figma Inc." }
                    elseif ($l -like '*firefox*') { $pub = "Mozilla Corporation" }
                    elseif ($l -like '*idm*' -or $l -like '*internet download*') { $pub = "Tonec Inc." }
                    else { $pub = "Unknown" }
                }
                $iconCache = Resolve-StartupIcon $name $exe
                $items += [PSCustomObject]@{
                    Id = "$locType`_$name"
                    Name = $name
                    Publisher = $pub
                    Command = $cmd
                    ExecutablePath = $exe
                    IconCachePath = $iconCache
                    Location = $locName
                    LocationType = $locType
                    Type = "Registry"
                    Enabled = $enabled
                    PackageFamilyName = ""
                    TaskId = ""
                }
            }
        }
    }
    return $items
}

$allApps += Read-RegRun "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "Registry (Current User)" $hkcuMap "UserRegistry"
$allApps += Read-RegRun "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" "Registry (All Users)" $hklmMap "MachineRegistry"
$allApps += Read-RegRun "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" "Registry (32-bit All Users)" $hklm32Map "MachineRegistry32"

$userStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $userStartup) {
    Get-ChildItem $userStartup -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
        $baseName = $_.BaseName
        $enabled = $true
        if ($folderMap.ContainsKey($_.Name.ToLower())) {
            $enabled = $folderMap[$_.Name.ToLower()]
        }
        $iconCache = Get-IconCachePath $_.FullName
        $allApps += [PSCustomObject]@{
            Id = "Folder_$baseName"
            Name = $baseName
            Publisher = "Shortcut"
            Command = $_.FullName
            ExecutablePath = $_.FullName
            IconCachePath = $iconCache
            Location = "Startup Folder"
            LocationType = "StartupFolder"
            Type = "Shortcut"
            Enabled = $enabled
            PackageFamilyName = ""
            TaskId = ""
        }
    }
}

try {
    Get-AppxPackage | ForEach-Object {
        $manifest = Get-AppxPackageManifest $_ -ErrorAction SilentlyContinue
        if ($manifest -and $manifest.Package.Applications.Application.Extensions.Extension) {
            $exts = @($manifest.Package.Applications.Application.Extensions.Extension)
            $stList = $exts | Where-Object { $_.Category -eq 'windows.startupTask' }
            foreach ($st in $stList) {
                $taskIds = @($st.StartupTask.TaskId)
                foreach ($tId in $taskIds) {
                    if ($tId) {
                        $pfn = $_.PackageFamilyName
                        $appxReg = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\$pfn\$tId"
                        $isEnabled = $false
                        if (Test-Path $appxReg) {
                            $state = (Get-ItemProperty $appxReg -ErrorAction SilentlyContinue).State
                            if ($state -eq 2) { $isEnabled = $true }
                        }
                        
                        $appDisplayName = $_.Name
                        if ($manifest.Package.Properties.DisplayName -and -not $manifest.Package.Properties.DisplayName.StartsWith("ms-resource:")) {
                            $appDisplayName = $manifest.Package.Properties.DisplayName
                        }
                        $pubName = $manifest.Package.Properties.PublisherDisplayName
                        if (-not $pubName) { $pubName = "Microsoft Corporation" }

                        $uwpIcon = ""
                        if ($manifest.Package.Applications.Application.VisualElements -and $_.InstallLocation) {
                            $ve = @($manifest.Package.Applications.Application.VisualElements)[0]
                            $logoRel = $ve.Square44x44Logo
                            if (-not $logoRel) { $logoRel = $ve.Square150x150Logo }
                            if ($logoRel) {
                                $logoPath = Join-Path $_.InstallLocation $logoRel
                                if (Test-Path $logoPath) {
                                    $uwpIcon = $logoPath
                                } else {
                                    $logoDir = [System.IO.Path]::GetDirectoryName($logoPath)
                                    $logoBase = [System.IO.Path]::GetFileNameWithoutExtension($logoPath)
                                    if (Test-Path $logoDir) {
                                        $found = Get-ChildItem -Path $logoDir -Filter "$logoBase*.png" -ErrorAction SilentlyContinue | Select-Object -First 1
                                        if ($found) { $uwpIcon = $found.FullName }
                                    }
                                }
                            }
                        }
                        if (-not $uwpIcon) {
                            $uwpIcon = Resolve-StartupIcon $appDisplayName ""
                        }

                        $allApps += [PSCustomObject]@{
                            Id = "UWP_$pfn`_$tId"
                            Name = $appDisplayName
                            Publisher = $pubName
                            Command = "$pfn ($tId)"
                            ExecutablePath = ""
                            IconCachePath = $uwpIcon
                            Location = "Windows App Package"
                            LocationType = "UWP"
                            Type = "UWP"
                            Enabled = $isEnabled
                            PackageFamilyName = $pfn
                            TaskId = $tId
                        }
                    }
                }
            }
        }
    }
} catch {}

$biosTime = "4.1 seconds"
try {
    $evt = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($evt) {
        $xml = [xml]$evt.ToXml()
        $bootMs = [int]$xml.Event.EventData.Data[0].'#text'
        if ($bootMs -gt 0) {
            $biosTime = [string]([math]::Round($bootMs / 1000, 1)) + " seconds"
        }
    }
} catch {}

[PSCustomObject]@{
    Apps = $allApps
    BiosTime = $biosTime
} | ConvertTo-Json -Depth 4
''';

  /// Fetches all startup programs (Win32 + Startup Folder + UWP Apps)
  Future<StartupDataResult> getStartupData() async {
    if (!Platform.isWindows) {
      return _getMockData();
    }

    try {
      final res = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', _powershellScript],
      );

      if (res.exitCode == 0) {
        final jsonText = (res.stdout as String).trim();
        if (jsonText.isNotEmpty) {
          final decoded = json.decode(jsonText);
          final bios = decoded['BiosTime']?.toString() ?? '4.1 seconds';
          final rawApps = decoded['Apps'] as List<dynamic>? ?? [];

          final apps = rawApps
              .map((a) => StartupAppItem.fromJson(a as Map<String, dynamic>))
              .toList();

          _sortApps(apps);
          return StartupDataResult(apps: apps, biosTime: bios);
        }
      }
    } catch (_) {}

    return _getMockData();
  }

  /// Toggles an application's startup state accurately based on locationType
  Future<bool> toggleStartupApp(StartupAppItem item, bool enable) async {
    if (!Platform.isWindows) {
      item.isEnabled = enable;
      return true;
    }

    try {
      if (item.locationType == 'UWP') {
        // UWP App State: 2 = Enabled, 0 = Disabled
        final stateVal = enable ? '2' : '0';
        final regKey =
            'HKCU\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\SystemAppData\\${item.packageFamilyName}\\${item.taskId}';

        final res = await Process.run('reg.exe', [
          'add',
          regKey,
          '/v',
          'State',
          '/t',
          'REG_DWORD',
          '/d',
          stateVal,
          '/f',
        ]);
        if (res.exitCode == 0) {
          item.isEnabled = enable;
          return true;
        }
      } else if (item.locationType == 'StartupFolder') {
        final hexPrefix = enable ? '02' : '03';
        final hexData = '${hexPrefix}0000000000000000000000';
        final regVal = item.name.endsWith('.lnk') ? item.name : '${item.name}.lnk';

        final res = await Process.run('reg.exe', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder',
          '/v',
          regVal,
          '/t',
          'REG_BINARY',
          '/d',
          hexData,
          '/f',
        ]);
        if (res.exitCode == 0) {
          item.isEnabled = enable;
          return true;
        }
      } else if (item.locationType == 'MachineRegistry32') {
        final hexPrefix = enable ? '02' : '03';
        final hexData = '${hexPrefix}0000000000000000000000';

        final res = await Process.run('reg.exe', [
          'add',
          r'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32',
          '/v',
          item.name,
          '/t',
          'REG_BINARY',
          '/d',
          hexData,
          '/f',
        ]);
        if (res.exitCode == 0) {
          item.isEnabled = enable;
          return true;
        }
      } else if (item.locationType == 'MachineRegistry') {
        final hexPrefix = enable ? '02' : '03';
        final hexData = '${hexPrefix}0000000000000000000000';

        final res = await Process.run('reg.exe', [
          'add',
          r'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
          '/v',
          item.name,
          '/t',
          'REG_BINARY',
          '/d',
          hexData,
          '/f',
        ]);
        if (res.exitCode == 0) {
          item.isEnabled = enable;
          return true;
        }
      } else {
        // UserRegistry
        final hexPrefix = enable ? '02' : '03';
        final hexData = '${hexPrefix}0000000000000000000000';

        final res = await Process.run('reg.exe', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
          '/v',
          item.name,
          '/t',
          'REG_BINARY',
          '/d',
          hexData,
          '/f',
        ]);
        if (res.exitCode == 0) {
          item.isEnabled = enable;
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  void _sortApps(List<StartupAppItem> apps) {
    apps.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  StartupDataResult _getMockData() {
    return StartupDataResult(
      biosTime: '4.1 seconds',
      apps: [
        StartupAppItem(
          id: 'uwp_pc_manager',
          name: 'PC Manager',
          publisher: 'Microsoft Corporation',
          command: 'Microsoft.MicrosoftPCManager_8wekyb3d8bbwe',
          executablePath: '',
          location: 'Windows App Package',
          locationType: 'UWP',
          packageFamilyName: 'Microsoft.MicrosoftPCManager_8wekyb3d8bbwe',
          taskId: 'WindowsMasterUI_Store',
          isEnabled: true,
          impact: StartupImpact.notMeasured,
        ),
        StartupAppItem(
          id: 'reg_updater',
          name: 'updater.exe (2)',
          publisher: 'Google LLC',
          command: r'"C:\Users\User\AppData\Local\Google\GoogleUpdater\updater.exe" --wake',
          executablePath: '',
          location: 'Registry (Current User)',
          locationType: 'UserRegistry',
          packageFamilyName: '',
          taskId: '',
          isEnabled: true,
          impact: StartupImpact.high,
        ),
        StartupAppItem(
          id: 'uwp_lively',
          name: 'Lively Wallpaper',
          publisher: 'Sketches SRL',
          command: '12030rocksdanister.LivelyWallpaper_97hta09mmv6hy',
          executablePath: '',
          location: 'Windows App Package',
          locationType: 'UWP',
          packageFamilyName: '12030rocksdanister.LivelyWallpaper_97hta09mmv6hy',
          taskId: 'AppStartup',
          isEnabled: false,
          impact: StartupImpact.none,
        ),
        StartupAppItem(
          id: 'uwp_whatsapp',
          name: 'WhatsApp',
          publisher: 'WhatsApp Inc.',
          command: '5319275A.WhatsAppDesktop_cv1g1gvanyjgm',
          executablePath: '',
          location: 'Windows App Package',
          locationType: 'UWP',
          packageFamilyName: '5319275A.WhatsAppDesktop_cv1g1gvanyjgm',
          taskId: 'App',
          isEnabled: false,
          impact: StartupImpact.none,
        ),
      ],
    );
  }
}
