; Inno Setup Script for Antidotes - PC Optimizer
; Official Flutter Windows installer script template

#define MyAppName "Antidotes"
#define MyAppVersion "1.0.8"
#define MyAppPublisher "Antidotes"
#define MyAppURL "https://antidotes-df58c.web.app/"
#define MyAppExeName "antidotes.exe"

[Setup]
; Basic Application Info
AppId={{E6F7A985-2CED-4951-901B-3A8DF7AA546C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Version & Metadata Info (helps Windows identify publisher & details)
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Antidotes - PC Cleaner & Optimizer Installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}.0
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}

; Output Configuration
OutputDir=..\build\installer
OutputBaseFilename=Antidotes-Setup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; Elevation & Privileges (System Optimizer requires Administrator privileges)
PrivilegesRequired=admin
CloseApplications=force

; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Appearance
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startwithwindows"; Description: "Start Antidotes automatically when Windows starts"; GroupDescription: "Windows Integration"; Flags: checkedonce

[Files]
; All release output files and subdirectories
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu Shortcut
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
; Desktop Shortcut
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Registry]
; Run on Windows startup (automatically placed in System Tray Overflow Menu)
Root: HKCU; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Antidotes"; ValueData: """{app}\{#MyAppExeName}"" --minimized"; Tasks: startwithwindows; Flags: uninsdeletevalue

[Run]
; Option to launch the application immediately after install (shellexec prevents CreateProcess 740 elevation error)
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec nowait postinstall skipifsilent

[Code]
// Force-close any running or System-Tray instances of Antidotes before replacing files
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM antidotes.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(600);
  Result := '';
end;

function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM antidotes.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
  Result := True;
end;
