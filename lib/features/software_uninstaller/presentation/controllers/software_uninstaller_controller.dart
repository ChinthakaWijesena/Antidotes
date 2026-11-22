import 'package:flutter/foundation.dart';
import 'package:antidotes/core/utils/file_size_formatter.dart';
import 'package:antidotes/features/software_uninstaller/data/models/installed_app_item.dart';
import 'package:antidotes/features/software_uninstaller/data/services/software_uninstaller_service.dart';

class SoftwareUninstallerController extends ChangeNotifier {
  final SoftwareUninstallerService _service;

  List<InstalledAppItem> _apps = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortColumn = 'name';
  bool _isAscending = true;

  SoftwareUninstallerController({SoftwareUninstallerService? service})
      : _service = service ?? SoftwareUninstallerService();

  SoftwareUninstallerService get service => _service;
  List<InstalledAppItem> get apps => _apps;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortColumn => _sortColumn;
  bool get isAscending => _isAscending;

  int get totalCount => _apps.length;

  String get totalSizeFormatted {
    final total = _apps.fold<int>(0, (sum, a) => sum + a.sizeInBytes);
    return FileSizeFormatter.format(total);
  }

  List<InstalledAppItem> get filteredApps {
    final q = _searchQuery.toLowerCase().trim();
    var list = _apps.where((app) {
      if (q.isEmpty) return true;
      return app.name.toLowerCase().contains(q) ||
          app.publisher.toLowerCase().contains(q) ||
          app.version.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'size':
          cmp = a.sizeInBytes.compareTo(b.sizeInBytes);
          break;
        case 'date':
          cmp = a.installDate.compareTo(b.installDate);
          break;
        case 'publisher':
          cmp = a.displayPublisher.toLowerCase().compareTo(b.displayPublisher.toLowerCase());
          break;
        case 'name':
        default:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return list;
  }

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    _apps = await _service.getInstalledApps();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void sortBy(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = true;
    }
    notifyListeners();
  }

  void removeApp(String id) {
    _apps.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
