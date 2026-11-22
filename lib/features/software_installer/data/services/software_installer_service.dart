import 'dart:io';
import 'package:flutter/material.dart';
import '../models/software_app_item.dart';
import '../models/software_category.dart';

class SoftwareInstallResult {
  final bool isSuccess;
  final String message;

  const SoftwareInstallResult({required this.isSuccess, required this.message});
}

class SoftwareInstallerService {
  List<SoftwareAppItem> getCatalog() {
    return [
      // --- Browsers ---
      SoftwareAppItem(
        id: 'chrome',
        name: 'Google Chrome',
        publisher: 'Google LLC',
        description: 'Fast, secure, and customizable web browser built for modern web.',
        category: SoftwareCategory.browsers,
        icon: Icons.language_rounded,
        brandColor: const Color(0xFF4285F4),
        packageId: 'Google.Chrome',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'firefox',
        name: 'Mozilla Firefox',
        publisher: 'Mozilla Corporation',
        description: 'Privacy-focused independent browser with enhanced tracking protection.',
        category: SoftwareCategory.browsers,
        icon: Icons.local_fire_department_rounded,
        brandColor: const Color(0xFFFF7139),
        packageId: 'Mozilla.Firefox',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'brave',
        name: 'Brave Browser',
        publisher: 'Brave Software Inc.',
        description: 'Ultra-fast privacy browser with built-in ad and tracker blocker.',
        category: SoftwareCategory.browsers,
        icon: Icons.shield_rounded,
        brandColor: const Color(0xFFFF5000),
        packageId: 'Brave.Brave',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'operagx',
        name: 'Opera GX',
        publisher: 'Opera Norway AS',
        description: 'The gaming browser with CPU, RAM, and network limiters.',
        category: SoftwareCategory.browsers,
        icon: Icons.sports_esports_rounded,
        brandColor: const Color(0xFFFA1E4E),
        packageId: 'Opera.OperaGX',
      ),

      // --- Developer Tools ---
      SoftwareAppItem(
        id: 'vscode',
        name: 'Visual Studio Code',
        publisher: 'Microsoft Corporation',
        description: 'Code editor redefined and optimized for building modern web and cloud applications.',
        category: SoftwareCategory.devTools,
        icon: Icons.code_rounded,
        brandColor: const Color(0xFF007ACC),
        packageId: 'Microsoft.VisualStudioCode',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'git',
        name: 'Git for Windows',
        publisher: 'Software Freedom Conservancy',
        description: 'Fast, scalable, distributed revision control system with Git Bash.',
        category: SoftwareCategory.devTools,
        icon: Icons.merge_type_rounded,
        brandColor: const Color(0xFFF05032),
        packageId: 'Git.Git',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'nodejs',
        name: 'Node.js (LTS)',
        publisher: 'OpenJS Foundation',
        description: 'JavaScript runtime built on Chrome\'s V8 JavaScript engine with npm.',
        category: SoftwareCategory.devTools,
        icon: Icons.terminal_rounded,
        brandColor: const Color(0xFF68A063),
        packageId: 'OpenJS.NodeJS.LTS',
      ),
      SoftwareAppItem(
        id: 'python',
        name: 'Python 3',
        publisher: 'Python Software Foundation',
        description: 'Powerful interpreted programming language with vast library ecosystem.',
        category: SoftwareCategory.devTools,
        icon: Icons.integration_instructions_rounded,
        brandColor: const Color(0xFF3776AB),
        packageId: 'Python.Python.3.12',
      ),

      // --- Utilities & System Tools ---
      SoftwareAppItem(
        id: '7zip',
        name: '7-Zip',
        publisher: 'Igor Pavlov',
        description: 'High compression ratio file archiver with open architecture.',
        category: SoftwareCategory.utilities,
        icon: Icons.folder_zip_rounded,
        brandColor: const Color(0xFF2C5E8A),
        packageId: '7zip.7zip',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'notepadplusplus',
        name: 'Notepad++',
        publisher: 'Don Ho',
        description: 'Free source code editor and Notepad replacement supporting many languages.',
        category: SoftwareCategory.utilities,
        icon: Icons.edit_note_rounded,
        brandColor: const Color(0xFF90C53F),
        packageId: 'Notepad++.Notepad++',
      ),
      SoftwareAppItem(
        id: 'powertoys',
        name: 'Microsoft PowerToys',
        publisher: 'Microsoft Corporation',
        description: 'System utilities for power users to tune and streamline Windows experience.',
        category: SoftwareCategory.utilities,
        icon: Icons.tune_rounded,
        brandColor: const Color(0xFF0078D7),
        packageId: 'Microsoft.PowerToys',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'everything',
        name: 'Everything Search',
        publisher: 'voidtools',
        description: 'Instant filename search engine that locates files and folders in real-time.',
        category: SoftwareCategory.utilities,
        icon: Icons.search_rounded,
        brandColor: const Color(0xFFFFA000),
        packageId: 'voidtools.Everything',
      ),
      SoftwareAppItem(
        id: 'winrar',
        name: 'WinRAR',
        publisher: 'win.rar GmbH',
        description: 'Popular compression tool supporting RAR, ZIP, and other archive formats.',
        category: SoftwareCategory.utilities,
        icon: Icons.inventory_2_rounded,
        brandColor: const Color(0xFF2196F3),
        packageId: 'RARLab.WinRAR',
      ),

      // --- Media & Players ---
      SoftwareAppItem(
        id: 'vlc',
        name: 'VLC Media Player',
        publisher: 'VideoLAN',
        description: 'Free, open source cross-platform multimedia player for all video formats.',
        category: SoftwareCategory.media,
        icon: Icons.play_circle_filled_rounded,
        brandColor: const Color(0xFFFF8800),
        packageId: 'VideoLAN.VLC',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'spotify',
        name: 'Spotify',
        publisher: 'Spotify AB',
        description: 'Digital music and podcast service giving access to millions of songs.',
        category: SoftwareCategory.media,
        icon: Icons.music_note_rounded,
        brandColor: const Color(0xFF1DB954),
        packageId: 'Spotify.Spotify',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'obs',
        name: 'OBS Studio',
        publisher: 'OBS Project',
        description: 'Free and open source software for video recording and live streaming.',
        category: SoftwareCategory.media,
        icon: Icons.videocam_rounded,
        brandColor: const Color(0xFF302E31),
        packageId: 'OBSProject.OBSStudio',
      ),

      // --- Social & Communication ---
      SoftwareAppItem(
        id: 'discord',
        name: 'Discord',
        publisher: 'Discord Inc.',
        description: 'Voice, video and text communication service used by over a hundred million people.',
        category: SoftwareCategory.social,
        icon: Icons.chat_bubble_rounded,
        brandColor: const Color(0xFF5865F2),
        packageId: 'Discord.Discord',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'telegram',
        name: 'Telegram Desktop',
        publisher: 'Telegram FZ-LLC',
        description: 'Fast and secure desktop messaging app synced with your phone.',
        category: SoftwareCategory.social,
        icon: Icons.send_rounded,
        brandColor: const Color(0xFF229ED9),
        packageId: 'Telegram.TelegramDesktop',
      ),
      SoftwareAppItem(
        id: 'whatsapp',
        name: 'WhatsApp',
        publisher: 'WhatsApp Inc.',
        description: 'Simple, reliable, private messaging and calling for your desktop.',
        category: SoftwareCategory.social,
        icon: Icons.phone_in_talk_rounded,
        brandColor: const Color(0xFF25D366),
        packageId: 'WhatsApp.WhatsApp',
      ),

      // --- Gaming ---
      SoftwareAppItem(
        id: 'steam',
        name: 'Steam',
        publisher: 'Valve Corporation',
        description: 'Ultimate online game platform to play, discuss, and create games.',
        category: SoftwareCategory.gaming,
        icon: Icons.sports_esports_rounded,
        brandColor: const Color(0xFF171A21),
        packageId: 'Valve.Steam',
        isPopular: true,
      ),
      SoftwareAppItem(
        id: 'epicgames',
        name: 'Epic Games Launcher',
        publisher: 'Epic Games Inc.',
        description: 'Store and launcher for Unreal Engine, Fortnite, and PC gaming library.',
        category: SoftwareCategory.gaming,
        icon: Icons.gamepad_rounded,
        brandColor: const Color(0xFF313131),
        packageId: 'EpicGames.EpicGamesLauncher',
      ),
    ];
  }

  /// Scans Windows to detect which of the catalog apps are already installed
  Future<List<SoftwareAppItem>> scanInstalledStatus(
      List<SoftwareAppItem> catalog) async {
    if (!Platform.isWindows) return catalog;

    final installedNames = <String>{};

    try {
      // Query winget list in quick non-blocking format
      final res = await Process.run('winget.exe', [
        'list',
        '--source',
        'winget',
        '--accept-source-agreements',
      ]);

      if (res.exitCode == 0) {
        final out = res.stdout.toString().toLowerCase();
        for (final app in catalog) {
          final pid = app.packageId.toLowerCase();
          final name = app.name.toLowerCase();
          if (out.contains(pid) || out.contains(name)) {
            installedNames.add(app.id);
          }
        }
      }
    } catch (_) {}

    // Fallback registry / local check for common paths
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final programFiles = Platform.environment['ProgramFiles'] ?? '';
    final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? '';

    for (final app in catalog) {
      if (installedNames.contains(app.id)) continue;

      if (app.id == 'chrome') {
        if (File('$localAppData\\Google\\Chrome\\Application\\chrome.exe').existsSync() ||
            File('$programFiles\\Google\\Chrome\\Application\\chrome.exe').existsSync() ||
            File('$programFilesX86\\Google\\Chrome\\Application\\chrome.exe').existsSync()) {
          installedNames.add(app.id);
        }
      } else if (app.id == 'vscode') {
        if (File('$localAppData\\Programs\\Microsoft VS Code\\Code.exe').existsSync() ||
            File('$programFiles\\Microsoft VS Code\\Code.exe').existsSync()) {
          installedNames.add(app.id);
        }
      } else if (app.id == 'discord') {
        if (Directory('$localAppData\\Discord').existsSync()) {
          installedNames.add(app.id);
        }
      } else if (app.id == 'steam') {
        if (File('$programFilesX86\\Steam\\steam.exe').existsSync() ||
            File('$programFiles\\Steam\\steam.exe').existsSync()) {
          installedNames.add(app.id);
        }
      } else if (app.id == 'vlc') {
        if (File('$programFiles\\VideoLAN\\VLC\\vlc.exe').existsSync() ||
            File('$programFilesX86\\VideoLAN\\VLC\\vlc.exe').existsSync()) {
          installedNames.add(app.id);
        }
      } else if (app.id == '7zip') {
        if (File('$programFiles\\7-Zip\\7z.exe').existsSync() ||
            File('$programFilesX86\\7-Zip\\7z.exe').existsSync()) {
          installedNames.add(app.id);
        }
      }
    }

    return catalog.map((app) {
      final isInst = installedNames.contains(app.id);
      return app.copyWith(
        isInstalled: isInst,
        status: isInst ? InstallStatus.installed : InstallStatus.notInstalled,
        statusMessage: isInst ? 'Installed' : '',
      );
    }).toList();
  }

  /// Installs an app silently via Windows Package Manager (winget)
  Future<SoftwareInstallResult> installApp(
    SoftwareAppItem app, {
    void Function(String msg)? onProgress,
  }) async {
    if (!Platform.isWindows) {
      return const SoftwareInstallResult(
        isSuccess: false,
        message: 'Winget installation is only supported on Windows.',
      );
    }

    onProgress?.call('Starting download for ${app.name}...');

    try {
      final proc = await Process.start('winget.exe', [
        'install',
        '--id',
        app.packageId,
        '--exact',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity',
      ]);

      proc.stdout.transform(const SystemEncoding().decoder).listen((data) {
        if (data.contains('Found') || data.contains('Downloading')) {
          onProgress?.call('Downloading ${app.name}...');
        } else if (data.contains('Installing') || data.contains('Verifying')) {
          onProgress?.call('Installing ${app.name}...');
        }
      });

      final exitCode = await proc.exitCode;
      if (exitCode == 0 || exitCode == 2316632065) {
        return SoftwareInstallResult(
          isSuccess: true,
          message: '${app.name} was installed successfully.',
        );
      } else if (exitCode == 0x8A150024) {
        return SoftwareInstallResult(
          isSuccess: true,
          message: '${app.name} is already installed.',
        );
      } else {
        return SoftwareInstallResult(
          isSuccess: false,
          message: 'Installation failed with exit code $exitCode.',
        );
      }
    } catch (e) {
      return SoftwareInstallResult(
        isSuccess: false,
        message: 'Failed to launch installer: $e',
      );
    }
  }
}
