# AGENTS.md — Development Guidelines for Antidotes

Welcome to **Antidotes**! This document provides instructions, architectural context, best practices, and release protocols for AI coding agents (and human contributors) working in this repository.

---

## 1. Project Overview & Tech Stack

- **Application**: Antidotes — Windows PC Cleaner, System Optimizer & Utility Suite.
- **Framework**: Flutter Desktop (`windows-x64`), Dart (`sdk: ^3.13.5`).
- **Native Interop**: Native Windows Win32 APIs, WMI/CIM, PowerShell automation, Registry inspection, Shell FFI.
- **Packaging & Distribution**: Inno Setup 7 (`installer/antidotes_setup.iss`).
- **Backend / Deployment**: Firebase Hosting (`antidotes-df58c.web.app`) for updates manifest (`version.json`) and landing page.
- **CI / CD**: GitHub Actions (`.github/workflows/build-release.yml`) for automated building, testing, and release asset publishing.

---

## 2. Repository Structure

```
Antidotes/
├── .github/workflows/           # CI/CD workflows (build-release.yml)
├── installer/
│   └── antidotes_setup.iss      # Inno Setup 7 installer configuration
├── lib/
│   ├── core/                    # Cross-cutting utilities, theme, and base widgets
│   │   ├── constants/           # App-wide constants
│   │   ├── services/            # Win32 shell, restore point, startup services
│   │   ├── theme/               # Dark/Light system theme configuration
│   │   ├── utils/               # AdminHelper, FileSizeFormatter, etc.
│   │   └── widgets/             # AppIconWidget, reusable UI components
│   ├── features/                # Feature modules (Feature-first architecture)
│   │   ├── app_settings/        # App theme, preferences & about info
│   │   ├── auth/                # Optional user authentication
│   │   ├── auto_updater/        # In-app updater checking version.json
│   │   ├── browser_cleaner/     # Caches, cookies, history cleaner (Chromium, Gecko)
│   │   ├── disk_health/         # S.M.A.R.T. disk diagnostics & temperatures
│   │   ├── dns_changer/         # Fast DNS switcher & latency benchmark
│   │   ├── game_booster/        # Game library, process watcher, power plan & boost session
│   │   ├── hardware_monitor/    # Real-time CPU, GPU, RAM, temperature monitor
│   │   ├── junk_cleaner/        # Temp & log purge with 24h safety guard
│   │   ├── navigation/          # App sidebar & responsive shell
│   │   ├── profile/             # Profile management
│   │   ├── ram_optimizer/       # Working set trimmer & standby list purge
│   │   ├── software_installer/  # Winget silent app installer
│   │   ├── software_uninstaller/# Revo-style deep uninstaller with trace purge
│   │   ├── speed_test/          # Internet download & upload speed test
│   │   ├── startup_manager/     # Startup apps inspector & impact analyzer
│   │   ├── storage_tools/       # Large/Duplicate file finder & file shredder
│   │   └── windows_settings/    # Quick Windows system settings shortcuts
│   └── main.dart                # Application entrypoint
├── public/                      # Static assets for Firebase Hosting (version.json, etc.)
├── test/                        # Comprehensive unit and widget tests
├── pubspec.yaml                 # Dependencies and application metadata
└── README.md                    # Public documentation
```

---

## 3. Core Architectural Rules & Constraints

### 3.1 Strict Safety & System Integrity
- **Junk Cleaner**: Must always enforce whitelist validation, pattern risk scoring, and the **24-hour recent-file safety guard**. Never delete recently modified files that may be locked or active.
- **Recycle Bin**: When deleting files from cleaners or storage tools, prefer sending to Windows Recycle Bin via Shell API (`win32_shell_service.dart`) unless secure shredding is explicitly requested.
- **Elevated Permissions**: System operations (e.g. Memory cache clearing, System Restore point creation, Service stopping) require administrator rights. Always check `AdminHelper.isRunningAsAdmin()` and guide the user if elevation is needed.

### 3.2 Authentic Windows Icons (Strict Rule)
- **NO CustomPainter Fake Brand Logos**: Never write custom code-drawn vector logos (e.g., custom SVG painters) for software titles.
- **Genuine Icon Extraction**: In `software_uninstaller` and `startup_manager`, extract authentic icons from:
  1. Registry `DisplayIcon` path.
  2. Executable `.exe` path using Win32 / PowerShell extraction.
  3. Start Menu `.lnk` shortcuts.
  4. UWP / AppX application manifest assets.
- If an authentic icon cannot be resolved or extracted, **always fall back to a clean standard Material icon** (`AppIconWidget`).

### 3.3 Threading & Asynchronous Work (Zero UI Freezes)
- Any heavy I/O operations (scanning directories, calculating file hashes, uninstaller registry scans, disk health polling) **must run in a background Dart `Isolate`** or non-blocking async process.
- The UI thread must stay responsive at 60/120 FPS at all times.

### 3.4 Game Booster Architectural & Safety Rules
- **Never Kill Protected Processes**: System and security processes (`System`, `csrss`, `wininit`, `winlogon`, `services`, `lsass`, `svchost`, `dwm`, `explorer`, `audiodg`, Windows Defender, `antidotes.exe`) are strictly safeguarded in `protected_processes.dart`.
- **Reversible Sessions**: `BoostSession` must revert all applied actions in **reverse order** (LIFO) when the game exits or the user clicks restore.
- **Process Priority Safety**: Maximum allowed priority is `High` (default is `Above Normal`). `Realtime` priority is strictly prohibited.
- **Graceful Termination**: Background apps selected by the user are closed gracefully via `taskkill /PID` first before considering force termination.
- **Zero Anti-Cheat Interference**: No DLL injection, memory hooking, or overlay injection. Games with BattlEye, Easy Anti-Cheat, and Vanguard must remain intact.

---

## 4. Development Commands (PowerShell)

> **Important**: On Windows PowerShell, chain dependent commands with `;` (or `&&` only in modern PowerShell 7+; prefer `;` for cross-version reliability).

### Run Static Analysis
```powershell
flutter analyze --no-fatal-infos
```

### Run All Unit & Widget Tests
```powershell
flutter test --no-pub
```

### Build Windows Release Executable
```powershell
flutter build windows --release
```
Output: `build\windows\x64\runner\Release\antidotes.exe`

### Compile Inno Setup Installer
```powershell
& "C:\Program Files\Inno Setup 7\ISCC.exe" "installer\antidotes_setup.iss"
```
Output: `build\installer\Antidotes-Setup-vX.Y.Z.exe`

---

## 5. Version Bumping & Release Workflow

When bumping the version to a new release (e.g., `X.Y.Z`):

1. **Update Version Across All Relevant Files**:
   - `pubspec.yaml`: `version: X.Y.Z+<build_number>`
   - `installer/antidotes_setup.iss`: `#define MyAppVersion "X.Y.Z"`
   - `lib/features/auto_updater/data/services/auto_updater_service.dart`: `defaultAppVersion = 'X.Y.Z'`
   - `lib/features/auto_updater/presentation/widgets/app_update_card.dart`: fallback version `'X.Y.Z'`
   - `lib/features/app_settings/presentation/screens/app_settings_screen.dart`: displayed badge `'vX.Y.Z'`
   - `public/version.json`: `"latest_version": "X.Y.Z"` and update `changelog`
   - `antidotes-landing.html`: download links and badge version
   - `test/app_settings_test.dart` & `test/auto_updater_test.dart`: update test expectations to `'vX.Y.Z'`

2. **Run Analysis & Test Suite**:
   ```powershell
   flutter analyze --no-fatal-infos ; flutter test --no-pub
   ```

3. **Deploy to Firebase Hosting**:
   ```powershell
   firebase deploy --only hosting
   ```
   Verify at: `https://antidotes-df58c.web.app/version.json`

4. **Commit, Tag & Push to GitHub**:
   ```powershell
   git add .
   git commit -m "chore(release): bump version to X.Y.Z and publish release"
   git push origin main
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
   Pushing a tag `v*` triggers the GitHub Actions workflow to automatically build the release and upload the installer to GitHub Releases via `softprops/action-gh-release@v2`.

---

## 6. Guidelines for AI Agents

1. **Maintain Consistency**: Follow existing patterns in `lib/features/` (Controller/Notifier -> Service -> Presentation).
2. **Never Break Tests**: Always run `flutter test --no-pub` after making changes to core logic or UI text.
3. **Cross-Platform Paths in Workflows**: In GitHub Actions workflow files (`.github/workflows/*.yml`), always use forward slashes `/` for file patterns (e.g., `build/installer/Antidotes-Setup-*.exe`), as glob libraries treat `\` as an escape character.
4. **Commits & Pull Requests**: Use Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore(release):`).
