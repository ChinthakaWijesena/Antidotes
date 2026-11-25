import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/update_info.dart';
import '../../data/services/auto_updater_service.dart';

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  downloading,
  readyToInstall,
  error,
}

class AutoUpdaterController extends ChangeNotifier {
  final AutoUpdaterService _service;

  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _updateInfo;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  File? _downloadedFile;
  StreamSubscription<double>? _downloadSub;

  String? _dismissedVersion;

  AutoUpdaterController({AutoUpdaterService? service})
      : _service = service ?? AutoUpdaterService();

  UpdateStatus get status => _status;
  UpdateInfo? get updateInfo => _updateInfo;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isDownloading => _status == UpdateStatus.downloading;
  bool get hasUpdate => _updateInfo?.hasUpdate ?? false;
  File? get downloadedFile => _downloadedFile;

  /// Mark a version as dismissed for this session so it won't auto-pop up repeatedly
  void dismissVersion(String version) {
    _dismissedVersion = version;
    _status = UpdateStatus.idle;
    notifyListeners();
  }

  /// Checks for available update.
  /// If [silent] is true, doesn't set status to upToDate on failure (quiet background check).
  Future<bool> checkForUpdates({bool silent = false, String? customUrl}) async {
    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _service.checkForUpdate(customUrl: customUrl);
      _updateInfo = info;

      if (info != null && info.hasUpdate) {
        if (silent && info.latestVersion == _dismissedVersion) {
          _status = UpdateStatus.idle;
          notifyListeners();
          return false;
        }
        _status = UpdateStatus.updateAvailable;
        notifyListeners();
        return true;
      } else {
        _status = silent ? UpdateStatus.idle : UpdateStatus.upToDate;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = silent ? UpdateStatus.idle : UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Downloads the installer to Temp and executes it
  Future<void> startDownloadAndInstall() async {
    if (_updateInfo == null || _updateInfo!.downloadUrl.isEmpty) {
      _errorMessage = 'No valid download URL available.';
      _status = UpdateStatus.error;
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetFile = _service.getTempInstallerFile(_updateInfo!.latestVersion);
      _downloadedFile = targetFile;

      final stream = _service.downloadInstaller(
        downloadUrl: _updateInfo!.downloadUrl,
        destinationFile: targetFile,
      );

      _downloadSub = stream.listen(
        (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
        onError: (err) {
          _errorMessage = err.toString();
          _status = UpdateStatus.error;
          notifyListeners();
        },
        onDone: () async {
          _downloadProgress = 1.0;
          _status = UpdateStatus.readyToInstall;
          notifyListeners();

          // Launch installer automatically once download finishes
          await _service.launchInstallerAndExit(targetFile);
        },
        cancelOnError: true,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = UpdateStatus.error;
      notifyListeners();
    }
  }

  void cancelDownload() {
    _downloadSub?.cancel();
    _downloadSub = null;
    _status = UpdateStatus.idle;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }
}
