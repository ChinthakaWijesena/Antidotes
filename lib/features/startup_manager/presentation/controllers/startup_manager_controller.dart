import 'package:flutter/foundation.dart';
import '../../data/models/startup_app_item.dart';
import '../../data/services/startup_manager_service.dart';

enum StartupSortField { name, publisher, status, impact }

class StartupManagerController extends ChangeNotifier {
  final StartupManagerService _service;

  StartupManagerController({StartupManagerService? service})
      : _service = service ?? StartupManagerService();

  bool _isLoading = false;
  List<StartupAppItem> _apps = [];
  String _biosTime = '4.1 seconds';
  String _searchQuery = '';
  StartupAppItem? _selectedItem;

  // Default sort order: Name A-Z (same as Windows Task Manager)
  StartupSortField _sortField = StartupSortField.name;
  bool _sortAscending = true;

  bool get isLoading => _isLoading;
  String get biosTime => _biosTime;
  String get searchQuery => _searchQuery;
  StartupAppItem? get selectedItem => _selectedItem;
  StartupSortField get sortField => _sortField;
  bool get sortAscending => _sortAscending;

  List<StartupAppItem> get filteredApps {
    final list = _apps.where((app) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = app.name.toLowerCase().contains(query);
        final matchPublisher = app.publisher.toLowerCase().contains(query);
        final matchCmd = app.command.toLowerCase().contains(query);
        return matchName || matchPublisher || matchCmd;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case StartupSortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case StartupSortField.publisher:
          cmp = a.publisher.toLowerCase().compareTo(b.publisher.toLowerCase());
          if (cmp == 0) {
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          break;
        case StartupSortField.status:
          if (a.isEnabled == b.isEnabled) {
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          } else {
            cmp = a.isEnabled ? -1 : 1;
          }
          break;
        case StartupSortField.impact:
          cmp = a.impact.index.compareTo(b.impact.index);
          if (cmp == 0) {
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  int get totalApps => _apps.length;
  int get enabledApps => _apps.where((a) => a.isEnabled).length;
  int get disabledApps => _apps.where((a) => !a.isEnabled).length;

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.getStartupData();
    _apps = result.apps;
    _biosTime = result.biosTime;
    _selectedItem = null;

    _isLoading = false;
    notifyListeners();
  }

  void selectItem(StartupAppItem? item) {
    if (item == null) {
      _selectedItem = null;
    } else {
      // Find the authoritative reference in _apps
      _selectedItem = _apps.firstWhere(
        (a) => a.id == item.id,
        orElse: () => item,
      );
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void sortBy(StartupSortField field) {
    if (_sortField == field) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = field;
      _sortAscending = true;
    }
    notifyListeners();
  }

  Future<bool> toggleApp(StartupAppItem item, bool enable) async {
    // Look up exact item in list by unique ID to prevent any index mismatches
    final target = _apps.firstWhere(
      (a) => a.id == item.id,
      orElse: () => item,
    );

    // Optimistic UI update: instantly update state and notify listeners so Switch animates with 0ms latency
    final previousState = target.isEnabled;
    target.isEnabled = enable;
    if (_selectedItem?.id == target.id) {
      _selectedItem = target;
    }
    notifyListeners();

    final ok = await _service.toggleStartupApp(target, enable);
    if (!ok) {
      // Revert if system operation failed
      target.isEnabled = previousState;
      if (_selectedItem?.id == target.id) {
        _selectedItem = target;
      }
      notifyListeners();
    }
    return ok;
  }

  Future<bool> toggleSelectedItem(bool enable) async {
    if (_selectedItem == null) return false;
    return toggleApp(_selectedItem!, enable);
  }
}
