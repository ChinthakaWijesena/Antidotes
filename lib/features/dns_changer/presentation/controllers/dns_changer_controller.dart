import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
import 'package:antidotes/features/dns_changer/data/models/family_shield_test_result.dart';
import 'package:antidotes/features/dns_changer/data/models/network_interface_item.dart';
import 'package:antidotes/features/dns_changer/data/services/dns_changer_service.dart';

class DnsChangerController extends ChangeNotifier {
  final DnsChangerService _service;

  List<DnsProviderItem> _providers = [];
  List<NetworkInterfaceItem> _adapters = [];
  NetworkInterfaceItem? _selectedAdapter;
  bool _isLoading = false;
  bool _isApplying = false;
  bool _isTestingLatency = false;
  bool _isBenchmarkRunning = false;
  bool _isTestingShield = false;
  String _statusMessage = '';
  Timer? _autoLatencyTimer;
  bool _isDisposed = false;

  bool _isBrowserDohBlocked = false;
  bool _isSafeSearchEnforced = false;
  bool _preventIpv6Leak = true;
  FamilyShieldTestResult? _testResult;

  DnsChangerController({DnsChangerService? service})
      : _service = service ?? DnsChangerService();

  DnsChangerService get service => _service;
  List<DnsProviderItem> get providers => _providers;
  List<NetworkInterfaceItem> get adapters => _adapters;
  NetworkInterfaceItem? get selectedAdapter => _selectedAdapter;
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  bool get isTestingLatency => _isTestingLatency;
  bool get isTestingShield => _isTestingShield;
  String get statusMessage => _statusMessage;

  bool get isBrowserDohBlocked => _isBrowserDohBlocked;
  bool get isSafeSearchEnforced => _isSafeSearchEnforced;
  bool get preventIpv6Leak => _preventIpv6Leak;
  FamilyShieldTestResult? get testResult => _testResult;

  /// Returns whether a Family-Safe DNS is currently active on the selected adapter
  bool get isFamilyShieldActive {
    final active = activeProvider;
    return active != null && active.isFamilySafe;
  }

  DnsProviderItem? get activeProvider {
    final id = activeProviderId;
    if (id == null) return null;
    return _providers.where((p) => p.id == id).firstOrNull;
  }

  String? get activeProviderId {
    if (_selectedAdapter == null) return null;
    final currentDns = _selectedAdapter!.currentDnsServers;

    if (_selectedAdapter!.isDhcp &&
        (currentDns.isEmpty ||
            currentDns.any((d) => d.startsWith('192.168.') || d.startsWith('10.') || d.startsWith('172.')))) {
      return 'dhcp';
    }

    for (final p in _providers) {
      if (p.isDefaultDhcp) continue;
      if (currentDns.contains(p.primaryIpv4)) {
        return p.id;
      }
    }
    return null;
  }

  List<DnsProviderItem> get familySafeProviders {
    return _providers.where((p) => p.isFamilySafe).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _providers = _service.getDnsCatalog();
    _adapters = await _service.getNetworkAdapters();

    if (_adapters.isNotEmpty) {
      _selectedAdapter = _adapters.firstWhere(
        (a) => a.isConnected,
        orElse: () => _adapters.first,
      );
    }

    _isBrowserDohBlocked = await _service.isBrowserDohBypassPrevented();
    _isSafeSearchEnforced = await _service.isSafeSearchEnforced();

    _isLoading = false;
    notifyListeners();
  }

  void selectAdapter(NetworkInterfaceItem adapter) {
    _selectedAdapter = adapter;
    notifyListeners();
  }

  Future<bool> applyProvider(DnsProviderItem provider) async {
    if (_selectedAdapter == null) return false;

    _isApplying = true;
    _statusMessage = 'Applying ${provider.name}...';
    notifyListeners();

    bool success = false;
    if (provider.isDefaultDhcp) {
      success = await _service.resetDnsToDhcp(_selectedAdapter!.name);
    } else {
      success = await _service.applyDnsToAdapter(
        adapterName: _selectedAdapter!.name,
        primaryDns: provider.primaryIpv4,
        secondaryDns: provider.secondaryIpv4,
        primaryIpv6: provider.primaryIpv6,
        secondaryIpv6: provider.secondaryIpv6,
        isFamilySafe: provider.isFamilySafe,
        preventIpv6Leak: _preventIpv6Leak,
      );

      // If the family provider recommends SafeSearch, automatically ensure SafeSearch is active
      if (provider.enforcesSafeSearch && !_isSafeSearchEnforced) {
        await toggleSafeSearch(true);
      }
    }

    if (success) {
      _adapters = await _service.getNetworkAdapters();
      _selectedAdapter = _adapters.firstWhere(
        (a) => a.name == _selectedAdapter!.name,
        orElse: () => _selectedAdapter!,
      );
    }

    _isApplying = false;
    _statusMessage = '';
    notifyListeners();
    return success;
  }

  Future<bool> applyCustomDns({
    required String primaryDns,
    String? secondaryDns,
  }) async {
    if (_selectedAdapter == null) return false;

    _isApplying = true;
    _statusMessage = 'Applying custom DNS ($primaryDns)...';
    notifyListeners();

    final success = await _service.applyDnsToAdapter(
      adapterName: _selectedAdapter!.name,
      primaryDns: primaryDns,
      secondaryDns: secondaryDns,
    );

    if (success) {
      _adapters = await _service.getNetworkAdapters();
      _selectedAdapter = _adapters.firstWhere(
        (a) => a.name == _selectedAdapter!.name,
        orElse: () => _selectedAdapter!,
      );
    }

    _isApplying = false;
    _statusMessage = '';
    notifyListeners();
    return success;
  }

  Future<bool> resetToDhcp() async {
    if (_selectedAdapter == null) return false;

    _isApplying = true;
    _statusMessage = 'Resetting DNS to Automatic (DHCP)...';
    notifyListeners();

    final success = await _service.resetDnsToDhcp(_selectedAdapter!.name);

    if (success) {
      _adapters = await _service.getNetworkAdapters();
      _selectedAdapter = _adapters.firstWhere(
        (a) => a.name == _selectedAdapter!.name,
        orElse: () => _selectedAdapter!,
      );
    }

    _isApplying = false;
    _statusMessage = '';
    notifyListeners();
    return success;
  }

  Future<bool> toggleBrowserDoh(bool prevent) async {
    final ok = await _service.setBrowserDohBypassPrevented(prevent);
    if (ok) {
      _isBrowserDohBlocked = prevent;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> toggleSafeSearch(bool enable) async {
    final ok = await _service.setSafeSearchEnforced(enable);
    if (ok) {
      _isSafeSearchEnforced = enable;
      notifyListeners();
    }
    return ok;
  }

  void togglePreventIpv6Leak(bool val) {
    _preventIpv6Leak = val;
    notifyListeners();
  }

  Future<FamilyShieldTestResult> runShieldTest() async {
    _isTestingShield = true;
    notifyListeners();

    _testResult = await _service.testFamilyShieldProtection();

    _isTestingShield = false;
    notifyListeners();
    return _testResult!;
  }

  Future<bool> flushDnsCache() async {
    final success = await _service.flushDnsCache();
    notifyListeners();
    return success;
  }

  /// Starts automatic parallel latency benchmarking immediately and repeats every 10 seconds.
  void startAutoLatencyRefresh() {
    _autoLatencyTimer?.cancel();
    if (_providers.isNotEmpty) {
      benchmarkAllLatencies(silent: true);
    }
    _autoLatencyTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isDisposed || _providers.isEmpty) return;
      benchmarkAllLatencies(silent: true);
    });
  }

  /// Stops the periodic auto-latency timer.
  void stopAutoLatencyRefresh() {
    _autoLatencyTimer?.cancel();
    _autoLatencyTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoLatencyTimer?.cancel();
    super.dispose();
  }

  Future<void> benchmarkAllLatencies({bool silent = false}) async {
    if (_isBenchmarkRunning || _isDisposed) return;
    _isBenchmarkRunning = true;

    if (!silent) {
      _isTestingLatency = true;
      notifyListeners();
    }

    try {
      final updated = await Future.wait(
        _providers.map((p) async {
          if (p.isDefaultDhcp) return p;
          final latency = await _service.testLatency(p.primaryIpv4);
          return p.copyWith(latencyMs: latency);
        }),
      );

      if (!_isDisposed) {
        _providers = updated;
      }
    } finally {
      _isBenchmarkRunning = false;
      _isTestingLatency = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
}
