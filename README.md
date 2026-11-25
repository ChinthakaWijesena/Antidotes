# Antidotes — PC Cleaner & System Optimizer

**Antidotes** is an open-source, modern Windows desktop PC cleaner, optimizer, and system utility suite built with **Flutter**, **Dart**, and native **Win32 FFI APIs**.

## ✨ Key Features

- **Junk Cleaner**: Strict whitelist scanning, pattern-based risk assessment, 24h recent-file safety guard, background Isolate multithreading, and Recycle Bin integration.
- **Startup Optimizer**: Manage Windows startup applications and inspect startup impact.
- **Browser Cleaner**: Clean temporary caches, cookies, and session leftovers across Chrome, Edge, Firefox, Opera, Opera GX, Brave, and IE.
- **RAM Optimizer**: Trim process working sets, clear system memory cache, and purge standby memory lists.
- **Hardware Monitor**: Real-time CPU, RAM, GPU, temperature, and fan monitoring.
- **Disk Health**: S.M.A.R.T. health status, temperature, and lifespan diagnostics.
- **Software Manager**: 1-Click silent installation via `winget` and clean application uninstaller.
- **DNS Changer & Speed Test**: Fast DNS switching (including Family Shield / DNS Angel mode) and live bandwidth benchmarking.
- **Storage Tools**: Large File Finder, Duplicate File Finder, and Secure File Shredder (DoD / Gutmann).
- **Windows Settings & App Settings**: System theme sync, power plans, virtual memory tuning, environment variables, and In-App Auto-Updater.

## 🛠️ Building from Source (Windows)

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (`>= 3.13.5`)
- Visual Studio 2022 with **Desktop development with C++**
- [Inno Setup 7](https://jrsoftware.org/isinfo.php) (for building the `.exe` installer)

### Commands
```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test --no-pub
flutter build windows --release
& "C:\Program Files\Inno Setup 7\ISCC.exe" installer\antidotes_setup.iss
```

## 🔐 Code Signing Policy

Free code signing is intended to be provided by [SignPath.io](https://signpath.io/), using a certificate provided by the [SignPath Foundation](https://signpath.org/).

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
