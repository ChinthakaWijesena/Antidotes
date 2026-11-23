import 'package:flutter/foundation.dart';
import '../../../../core/utils/admin_helper.dart';
import '../../data/models/disk_health_model.dart';
import '../../data/services/disk_health_service.dart';

enum DiskHealthLoadState { idle, loading, loaded, error }

class DiskHealthController extends ChangeNotifier {
  DiskHealthController() {
    refresh();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  DiskHealthLoadState _state = DiskHealthLoadState.idle;
  List<DiskDrive> _drives = [];
  String _errorMessage = '';
  DateTime? _lastRefreshed;
  bool _isAdmin = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  DiskHealthLoadState get state => _state;
  List<DiskDrive> get drives => List.unmodifiable(_drives);
  String get errorMessage => _errorMessage;
  DateTime? get lastRefreshed => _lastRefreshed;
  bool get isAdmin => _isAdmin;

  bool get isLoading => _state == DiskHealthLoadState.loading;
  bool get hasData => _drives.isNotEmpty;

  int get healthyCount =>
      _drives.where((d) => d.healthStatus == DiskHealthStatus.healthy).length;
  int get warningCount =>
      _drives.where((d) => d.healthStatus == DiskHealthStatus.warning).length;
  int get criticalCount =>
      _drives
          .where((d) =>
              d.healthStatus == DiskHealthStatus.unhealthy || d.predictFailure)
          .length;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (_state == DiskHealthLoadState.loading) return;

    _state = DiskHealthLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _isAdmin = await AdminHelper.isRunningAsAdmin();
      final result = await DiskHealthService.instance.fetchAllDrives();
      _drives = result;
      _lastRefreshed = DateTime.now();
      _state = DiskHealthLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DiskHealthLoadState.error;
    }

    notifyListeners();
  }
}
