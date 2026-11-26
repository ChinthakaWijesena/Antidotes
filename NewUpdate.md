# AGENTS.md — Game Booster (Flutter Desktop, Windows)

Instructions for AI coding agents working in this repo. Read this fully before making changes.

## 1. Project overview

**Game Booster** is a Flutter desktop app (Windows first) that prepares the PC for gaming. When the user launches a game through the app (or the app detects a registered game), it applies a set of reversible "boost actions". When the game exits, everything is restored.

**Core idea:** free CPU/RAM by closing apps the user picked, switch to a high-performance power plan, raise the game's priority, and show live system stats. No magic, no risky tweaks.

**Target:** Windows 10 / 11, x64. macOS / Linux are out of scope for the MVP, but all OS-specific code must sit behind interfaces (section 6) so other platforms can be added later.

## 2. Tech stack

- Framework: Flutter (stable channel), Dart 3+, Windows desktop target
- State management: `flutter_riverpod`
- Windows native access: `dart:ffi` + `win32` + `ffi` packages; `dart:io` `Process.run` for `powercfg`, `tasklist`, `taskkill`
- Window / tray: `window_manager`, `tray_manager`, `launch_at_startup`
- File picking: `file_picker` (choose game .exe)
- Charts: `fl_chart`
- Storage: JSON file in the app data folder via `path_provider` (no database in the MVP)
- Logging: `logger` (also write to a log file)
- Localization: `flutter_localizations` + `.arb` files (English first, Sinhala later)
- Lints: `flutter_lints` (or `very_good_analysis`)
- Tests: `flutter_test` + `mocktail`

## 3. Setup (one time)

- Install the Flutter SDK and add it to PATH
- Install **Visual Studio 2022** with the **"Desktop development with C++"** workload (required for Windows desktop builds)
- Turn on Windows **Developer Mode** (needed for plugin symlinks)
- Run `flutter doctor` and fix everything it reports for Windows

## 4. Commands

```bash
flutter pub get
flutter analyze
dart format .
flutter test
flutter run -d windows
flutter build windows --release
```

Always run `flutter analyze` and `flutter test` before saying a task is done.

## 5. Repo structure (feature-first)

```
game_booster/
├─ AGENTS.md
├─ pubspec.yaml
├─ analysis_options.yaml
├─ lib/
│  ├─ main.dart
│  ├─ app/                       # App widget, theme, routing, root providers
│  ├─ core/
│  │  ├─ platform/               # Abstract services + Windows implementations
│  │  │  ├─ process_service.dart        # list / close / set priority
│  │  │  ├─ power_plan_service.dart     # powercfg wrapper
│  │  │  └─ system_stats_service.dart   # CPU / RAM / GPU readers
│  │  ├─ constants/              # protected_processes.dart
│  │  └─ utils/
│  └─ features/
│     ├─ games/                  # data / domain / presentation
│     ├─ boost/                  # BoostAction, BoostSession, actions/
│     ├─ monitoring/             # dashboard + live stats
│     └─ settings/
├─ test/                         # mirrors lib/ structure
├─ windows/                      # generated runner; edit only when truly needed
└─ docs/
```

Each feature uses `data/` (storage, services), `domain/` (models, logic), `presentation/` (widgets, providers).
Rule: `domain/` must not import Flutter widgets. `presentation/` must not call `Process.run` or FFI directly; it goes through providers and services.

## 6. Features (MVP → later)

**MVP**
1. **Game library**: add/remove games (name, exe path). Launch from the app.
2. **Game watcher**: detect when a registered game process starts and exits (poll every 2–3 s).
3. **Boost session**: on game start, apply actions; on game exit (or app close/crash), revert them.
4. **Boost actions** (each user-toggleable):
   - `PowerPlanAction`: switch to High Performance, restore the previous plan after.
   - `CloseBackgroundAppsAction`: close only the apps the user selected.
   - `ProcessPriorityAction`: set the game process to `Above Normal` (never `Realtime`).
   - `TempCleanAction`: optional cleanup of the user temp folder (not reverted, needs confirmation).
5. **Live dashboard**: CPU %, RAM %, GPU % (if available), refreshed every 1–2 s.
6. **Settings**: enabled actions per game, start with Windows, minimize to tray.

**Later**
- Per-game profiles, tray quick-boost button, temperature sensors, FPS overlay, update checker, Sinhala UI.

## 7. Architecture rules

Every boost action implements:

```dart
abstract class BoostAction {
  String get name;
  Future<void> apply(BoostContext context);
  Future<void> revert(BoostContext context);
}
```

- `BoostSession` keeps a stack of successfully applied actions and reverts them **in reverse order**.
- Save the original state (previous power plan GUID, original priority) **before** changing anything.
- If an action fails, log it, skip it, continue. One failure must not break the whole session.
- Revert must also run when the app closes (`window_manager` close handler) and on uncaught errors.
- All OS calls live behind abstract services in `core/platform/`. Actions depend on the abstract class, never on `Process.run` directly. This keeps actions unit-testable with `mocktail`.
- Useful Windows facts:
  - High Performance power plan GUID: `8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`
  - Current plan: `powercfg /getactivescheme`, switch: `powercfg /setactive <GUID>`
  - Process priority: `OpenProcess` + `SetPriorityClass` via `win32` FFI
  - Process list: `CreateToolhelp32Snapshot` via FFI (or `tasklist` as a fallback)
  - Graceful close: `taskkill /PID <pid>` (no `/F`); force close only if the user allowed it
  - CPU / RAM: `GetSystemTimes` and `GlobalMemoryStatusEx` via FFI
  - GPU: `nvidia-smi` if present; otherwise show "N/A" (do not crash)

## 8. Performance rules for Flutter

- Never block the UI isolate. Polling, process listing and cleanup run in a background isolate (`Isolate.run` / `compute`) or in async calls that don't block.
- Dashboard updates use a `Stream` provider; rebuild only the widgets that show the changing value (`select`, small widgets, `const` constructors).
- Cancel timers and subscriptions in `dispose` / provider `onDispose`.
- FFI: free every allocated pointer (`calloc.free`) in a `finally` block and close every handle (`CloseHandle`).

## 9. Safety rules (hard rules, never break these)

1. **Never kill protected processes.** Keep a `protectedProcesses` list in `core/constants/`: `System`, `csrss`, `wininit`, `winlogon`, `services`, `lsass`, `svchost`, `dwm`, `explorer`, `audiodg`, `Registry`, Windows Defender / antivirus processes, and the app itself.
2. **Only close apps the user explicitly selected.** No automatic "kill everything" mode.
3. Try a graceful close first, wait a few seconds, then force-kill only if the user allowed it.
4. **Everything must be reversible** (except temp cleanup, which needs a confirmation dialog).
5. **Do not touch anti-cheat–sensitive areas.** No DLL injection, no hooking, no reading/writing game memory, no overlays injected into game processes. Games with EAC / BattlEye / Vanguard must keep working.
6. **Do not disable** Windows Defender, Windows Update, the firewall, or any security feature.
7. **No `Realtime` priority.** Max is `High`; default is `Above Normal`.
8. **No fake "RAM cleaner".** Don't call `EmptyWorkingSet` on all processes repeatedly. Real RAM gain comes from closing apps.
9. **No registry edits** in the MVP. If ever needed, back up the old value and restore it on revert.
10. The app runs as a normal user by default. Ask for admin rights only when an action truly needs it, and explain why in the UI.
11. No telemetry, no network calls, no ads, no bundled third-party software.

## 10. Coding conventions

- Follow `flutter_lints`; keep `flutter analyze` at zero issues.
- Run `dart format .` before finishing.
- Naming: `UpperCamelCase` types, `lowerCamelCase` members, `snake_case` file names.
- Prefer `const` constructors and small, single-purpose widgets. No business logic inside widgets.
- Use `async`/`await`; handle errors with `try/catch` at service boundaries and return typed results or throw typed exceptions (no silent `catch (_) {}`).
- No `print`; use the shared `logger`.
- User-facing strings go in `.arb` files, not hard-coded in widgets.
- Comments explain *why*, not *what*.

## 11. Testing

- Unit-test all `domain/` logic and every `BoostAction` using mocked platform services.
- Tests must **never** change the real system (no real `powercfg`, no real process killing).
- Required test cases:
  - `BoostSession` reverts in reverse order after a partial failure.
  - Protected processes never appear in the "closable apps" list.
  - The original power plan is restored even if the game crashes.
  - Game watcher detects start and exit correctly (using a fake process service).
- Widget tests for the games list and boost toggle screens.
- Manual checklist before release: boost → exit game → confirm power plan, priority and closed apps are as expected.

## 12. Definition of done

- [ ] `flutter analyze` reports no issues
- [ ] `dart format .` leaves no changes
- [ ] `flutter test` passes
- [ ] `flutter build windows --release` succeeds
- [ ] New logic has tests, and the revert path is implemented and tested
- [ ] No rule in section 9 is violated
- [ ] Changes are small and focused, with a short summary of what changed and why

## 13. How agents should work here

- Make the smallest change that solves the task. Don't refactor unrelated code.
- If a task is ambiguous or touches section 9, **ask before coding**.
- Don't add new packages without saying why; prefer well-maintained packages with Windows support.
- Don't hand-edit generated files (`*.g.dart`, `*.freezed.dart`, anything in `windows/flutter/`).
- Don't commit secrets, user paths, or log files.
- Update this file when architecture or rules change.