import 'package:flutter/foundation.dart';
import 'package:antidotes/features/software_installer/data/models/software_app_item.dart';
import 'package:antidotes/features/software_installer/data/models/software_category.dart';
import 'package:antidotes/features/software_installer/data/services/software_installer_service.dart';

class SoftwareInstallerController extends ChangeNotifier {
  final SoftwareInstallerService _service;

  List<SoftwareAppItem> _apps = [];
  SoftwareCategory _selectedCategory = SoftwareCategory.all;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isBatchInstalling = false;
  String _currentOperationText = '';

  SoftwareInstallerController({SoftwareInstallerService? service})
      : _service = service ?? SoftwareInstallerService();

  List<SoftwareAppItem> get apps => _apps;
  SoftwareCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isBatchInstalling => _isBatchInstalling;
  String get currentOperationText => _currentOperationText;

  List<SoftwareAppItem> get filteredApps {
    return _apps.where((app) {
      final matchesCategory = _selectedCategory == SoftwareCategory.all ||
          app.category == _selectedCategory;

      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          app.name.toLowerCase().contains(q) ||
          app.publisher.toLowerCase().contains(q) ||
          app.description.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get selectedCount => _apps.where((a) => a.isSelected && !a.isInstalled).length;
  int get installedCount => _apps.where((a) => a.isInstalled).length;

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    final catalog = _service.getCatalog();
    _apps = await _service.scanInstalledStatus(catalog);

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(SoftwareCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSelectApp(String id) {
    for (final app in _apps) {
      if (app.id == id && !app.isInstalled) {
        app.isSelected = !app.isSelected;
        notifyListeners();
        return;
      }
    }
  }

  void selectAllUninstalled(bool select) {
    for (final app in _apps) {
      if (!app.isInstalled) {
        app.isSelected = select;
      }
    }
    notifyListeners();
  }

  /// Installs a single app with real-time UI updates
  Future<SoftwareInstallResult> installApp(SoftwareAppItem app) async {
    app.status = InstallStatus.installing;
    app.statusMessage = 'Installing...';
    notifyListeners();

    final result = await _service.installApp(
      app,
      onProgress: (msg) {
        app.statusMessage = msg;
        notifyListeners();
      },
    );

    if (result.isSuccess) {
      app.status = InstallStatus.installed;
      app.isInstalled = true;
      app.isSelected = false;
      app.statusMessage = 'Installed';
    } else {
      app.status = InstallStatus.failed;
      app.statusMessage = result.message;
    }

    notifyListeners();
    return result;
  }

  /// Installs all currently selected apps one after another
  Future<void> installSelectedApps({
    void Function(String msg)? onStatusUpdate,
  }) async {
    final toInstall = _apps.where((a) => a.isSelected && !a.isInstalled).toList();
    if (toInstall.isEmpty) return;

    _isBatchInstalling = true;
    notifyListeners();

    for (int i = 0; i < toInstall.length; i++) {
      final app = toInstall[i];
      _currentOperationText =
          'Installing ${app.name} (${i + 1} of ${toInstall.length})...';
      onStatusUpdate?.call(_currentOperationText);
      notifyListeners();

      await installApp(app);
    }

    _isBatchInstalling = false;
    _currentOperationText = '';
    notifyListeners();
  }
}
