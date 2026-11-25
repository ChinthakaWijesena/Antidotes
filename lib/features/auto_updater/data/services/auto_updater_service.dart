import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/update_info.dart';

/// Service responsible for:
/// 1. Querying remote version.json for updates
/// 2. Streaming the installer download to %TEMP%
/// 3. Executing the downloaded installer and cleanly closing the app
class AutoUpdaterService {
  /// Default endpoint on Firebase Hosting. Can be overridden in constructor or settings.
  final String updateManifestUrl;
  final String currentAppVersion;

  static const String defaultManifestUrl = 'https://antidotes-df58c.web.app/version.json';
  static const String defaultAppVersion = '1.0.3';

  final HttpClient _client;

  AutoUpdaterService({
    String? updateManifestUrl,
    String? currentAppVersion,
    HttpClient? client,
  })  : updateManifestUrl = updateManifestUrl ?? defaultManifestUrl,
        currentAppVersion = currentAppVersion ?? defaultAppVersion,
        _client = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 8));

  /// Checks for available update online
  Future<UpdateInfo?> checkForUpdate({String? customUrl}) async {
    final targetUrl = customUrl ?? updateManifestUrl;
    try {
      final uri = Uri.parse(targetUrl);
      final req = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
      req.headers.set('User-Agent', 'Antidotes-AutoUpdater/$currentAppVersion');
      final resp = await req.close().timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        return null;
      }

      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      return UpdateInfo.fromJson(data, currentVersion: currentAppVersion);
    } catch (_) {
      // Offline, network error or invalid JSON - return null gracefully
      return null;
    }
  }

  /// Downloads the installer to the local Windows Temp folder with progress updates (0.0 to 1.0)
  Stream<double> downloadInstaller({
    required String downloadUrl,
    required File destinationFile,
  }) async* {
    if (await destinationFile.exists()) {
      try {
        await destinationFile.delete();
      } catch (_) {}
    }

    final uri = Uri.parse(downloadUrl);
    final req = await _client.getUrl(uri);
    final resp = await req.close();

    if (resp.statusCode != 200) {
      throw HttpException('Failed to download update file. Server returned HTTP ${resp.statusCode}');
    }

    final totalBytes = resp.contentLength;
    int receivedBytes = 0;

    final sink = destinationFile.openWrite();
    try {
      await for (final chunk in resp) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          yield receivedBytes / totalBytes;
        } else {
          yield 0.5; // indeterminate
        }
      }
      await sink.flush();
      yield 1.0;
    } finally {
      await sink.close();
    }
  }

  /// Returns the recommended local temp path for downloaded setup
  File getTempInstallerFile(String version) {
    final tempDir = Directory.systemTemp.path;
    final fileName = 'Antidotes-Setup-v$version.exe';
    return File(p.join(tempDir, fileName));
  }

  /// Executes the downloaded setup and terminates this app process
  Future<void> launchInstallerAndExit(File installerFile) async {
    if (!await installerFile.exists()) {
      throw FileNotFoundException('Installer file not found at ${installerFile.path}');
    }

    // Launch Inno Setup installer.
    // Inno Setup flags:
    // /RESTARTAPPLICATIONS - prompts Windows Restart Manager to handle processes
    // standard user prompt so user can see installation progress
    await Process.start(
      installerFile.path,
      ['/RESTARTAPPLICATIONS'],
      mode: ProcessStartMode.detached,
    );

    // Give installer 500ms to initialize and take over
    await Future.delayed(const Duration(milliseconds: 500));

    // Gracefully exit this application to avoid DLL/file lock conflicts
    exit(0);
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => message;
}
