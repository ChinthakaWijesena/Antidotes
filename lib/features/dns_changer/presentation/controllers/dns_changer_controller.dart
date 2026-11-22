import 'package:flutter/foundation.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
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
  String _statusMessage = '';

  DnsChangerController({DnsChangerService? service})
      : _service = service ?? DnsChangerService();

  DnsChangerService get service => _service;
  List<DnsProviderItem> get providers => _providers;
  List<NetworkInterfaceItem> get adapters => _adapters;
  NetworkInterfaceItem? get selectedAdapter => _selectedAdapter;
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  bool get isTestingLatency => _isTestingLatency;
  String get statusMessage => _statusMessage;

  String? get activeProviderId {
    if (_selectedAdapter == null) return null;
    final currentDns = _selectedAdapter!.currentDnsServers;

    if (_selectedAdapter!.isDhcp && (currentDns.isEmpty || currentDns.any((d) => d.startsWith('192.168.') || d.startsWith('10.') || d.startsWith('172.')))) {
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

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _providers = _service.getDnsCatalog();
    _adapters = await _service.getNetworkAdapters();

    if (_adapters.isNotEmpty) {
      // Pick first connected adapter, prefer Wi-Fi or Ethernet
      _selectedAdapter = _adapters.firstWhere(
        (a) => a.isConnected,
        orElse: () => _adapters.first,
      );
    }

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
      );
    }

    if (success) {
      // Refresh adapter status
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

  Future<bool> flushDnsCache() async {
    final success = await _service.flushDnsCache();
    notifyListeners();
    return success;
  }

  Future<void> benchmarkAllLatencies() async {
    _isTestingLatency = true;
    notifyListeners();

    final updated = <DnsProviderItem>[];
    for (final p in _providers) {
      if (p.isDefaultDhcp) {
        updated.add(p);
        continue;
      }

      final latency = await _service.testLatency(p.primaryIpv4);
      updated.add(p.copyWith(latencyMs: latency));
    }

    _providers = updated;
    _isTestingLatency = false;
    notifyListeners();
  }
}
