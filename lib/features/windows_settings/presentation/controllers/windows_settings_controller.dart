import 'package:flutter/foundation.dart';
import 'package:antidotes/features/windows_settings/data/models/env_variable_item.dart';
import 'package:antidotes/features/windows_settings/data/models/performance_preset.dart';
import 'package:antidotes/features/windows_settings/data/models/power_scheme_item.dart';
import 'package:antidotes/features/windows_settings/data/models/virtual_memory_config.dart';
import 'package:antidotes/features/windows_settings/data/services/windows_settings_service.dart';

class WindowsSettingsController extends ChangeNotifier {
  final WindowsSettingsService _service;

  bool _isLoading = false;
  bool _isLightMode = false;
  PerformancePreset _performancePreset = PerformancePreset.letWindowsChoose;
  List<PowerSchemeItem> _powerSchemes = [];
  List<EnvVariableItem> _envVariables = [];
  VirtualMemoryConfig? _virtualMemoryConfig;
  String _envSearchQuery = '';
  int _envFilterTab = 0; // 0 = All, 1 = User, 2 = System

  WindowsSettingsController({WindowsSettingsService? service})
      : _service = service ?? WindowsSettingsService();

  WindowsSettingsService get service => _service;
  bool get isLoading => _isLoading;
  bool get isLightMode => _isLightMode;
  PerformancePreset get performancePreset => _performancePreset;
  List<PowerSchemeItem> get powerSchemes => _powerSchemes;
  VirtualMemoryConfig? get virtualMemoryConfig => _virtualMemoryConfig;
  String get envSearchQuery => _envSearchQuery;
  int get envFilterTab => _envFilterTab;

  List<EnvVariableItem> get filteredEnvVariables {
    final q = _envSearchQuery.toLowerCase().trim();
    return _envVariables.where((item) {
      if (_envFilterTab == 1 && item.isSystem) return false;
      if (_envFilterTab == 2 && !item.isSystem) return false;
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) || item.value.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadAllSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLightMode = await _service.getWindowsThemeIsLight();
      _performancePreset = await _service.getVisualEffectsPreset();
      _powerSchemes = await _service.getPowerSchemes();
      _envVariables = await _service.getEnvironmentVariables();
      _virtualMemoryConfig = await _service.getVirtualMemoryConfig();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleThemeMode(bool isLight) async {
    _isLightMode = isLight;
    notifyListeners();
    await _service.setWindowsThemeIsLight(isLight);
  }

  Future<void> setPerformancePreset(PerformancePreset preset) async {
    _performancePreset = preset;
    notifyListeners();
    await _service.setVisualEffectsPreset(preset);
  }

  Future<void> setActivePowerScheme(String guid) async {
    _powerSchemes = _powerSchemes.map((p) => p.copyWith(isActive: p.guid == guid)).toList();
    notifyListeners();
    await _service.setActivePowerScheme(guid);
  }

  void setEnvSearchQuery(String query) {
    _envSearchQuery = query;
    notifyListeners();
  }

  void setEnvFilterTab(int tab) {
    _envFilterTab = tab;
    notifyListeners();
  }

  Future<void> saveEnvVariable(EnvVariableItem item) async {
    final idx = _envVariables.indexWhere((e) => e.name == item.name && e.isSystem == item.isSystem);
    if (idx >= 0) {
      _envVariables[idx] = item;
    } else {
      _envVariables.add(item);
    }
    notifyListeners();
    await _service.setEnvironmentVariable(item);
  }

  Future<void> deleteEnvVariable(String name, bool isSystem) async {
    _envVariables.removeWhere((e) => e.name == name && e.isSystem == isSystem);
    notifyListeners();
    await _service.deleteEnvironmentVariable(name, isSystem);
  }

  Future<void> updateVirtualMemory(VirtualMemoryConfig config) async {
    _virtualMemoryConfig = config;
    notifyListeners();
    await _service.setVirtualMemoryConfig(config);
  }
}

