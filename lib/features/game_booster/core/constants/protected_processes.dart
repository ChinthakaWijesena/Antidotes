/// List of protected Windows operating system and critical security processes.
/// Safety Rule: Never kill or terminate these processes under any circumstance.
const Set<String> kProtectedProcesses = {
  // Core Windows NT Kernel & Session
  'system',
  'system idle process',
  'smss.exe',
  'csrss.exe',
  'wininit.exe',
  'winlogon.exe',
  'services.exe',
  'lsass.exe',
  'svchost.exe',
  'fontdrvhost.exe',
  'dwm.exe',
  'sihost.exe',
  'taskhostw.exe',
  'explorer.exe',
  'audiodg.exe',
  'registry',
  'runtimebroker.exe',
  'shellexperiencehost.exe',
  'searchhost.exe',
  'startmenuexperiencehost.exe',
  'ctfmon.exe',

  // Windows Defender & Security
  'msmpeng.exe',
  'nissrv.exe',
  'securityhealthservice.exe',
  'securityhealthsystray.exe',
  'smartscreen.exe',

  // Antidotes Application & Flutter Host
  'antidotes.exe',
  'dart.exe',
  'flutter.exe',
};

/// Checks if a process name or executable name is in the protected list.
/// Case-insensitive, automatically handles with or without `.exe`.
bool isProtectedProcess(String? processName) {
  if (processName == null || processName.trim().isEmpty) return true;
  final name = processName.trim().toLowerCase();
  final withExe = name.endsWith('.exe') ? name : '$name.exe';
  final withoutExe = name.endsWith('.exe') ? name.substring(0, name.length - 4) : name;

  return kProtectedProcesses.contains(name) ||
      kProtectedProcesses.contains(withExe) ||
      kProtectedProcesses.contains(withoutExe);
}
