import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/dns_changer/data/models/family_shield_test_result.dart';
import 'package:antidotes/features/dns_changer/data/models/network_interface_item.dart';
import 'package:antidotes/features/dns_changer/data/services/dns_changer_service.dart';
import 'package:antidotes/features/dns_changer/presentation/controllers/dns_changer_controller.dart';

class FakeDnsChangerService extends DnsChangerService {
  NetworkInterfaceItem currentAdapter = const NetworkInterfaceItem(
    name: 'Wi-Fi',
    description: 'Realtek 8852BE WiFi 6',
    ipAddress: '192.168.1.10',
    currentDnsServers: ['192.168.1.1'],
    isDhcp: true,
    isConnected: true,
  );

  bool browserDohBlocked = false;
  bool safeSearchEnforced = false;

  @override
  Future<List<NetworkInterfaceItem>> getNetworkAdapters() async {
    return [currentAdapter];
  }

  @override
  Future<bool> applyDnsToAdapter({
    required String adapterName,
    required String primaryDns,
    String? secondaryDns,
    String? primaryIpv6,
    String? secondaryIpv6,
    bool isFamilySafe = false,
    bool preventIpv6Leak = true,
  }) async {
    final servers = [primaryDns];
    if (secondaryDns != null && secondaryDns.isNotEmpty) {
      servers.add(secondaryDns);
    }
    currentAdapter = currentAdapter.copyWith(
      currentDnsServers: servers,
      isDhcp: false,
    );
    return true;
  }

  @override
  Future<bool> resetDnsToDhcp(String adapterName) async {
    currentAdapter = currentAdapter.copyWith(
      currentDnsServers: ['192.168.1.1'],
      isDhcp: true,
    );
    return true;
  }

  @override
  Future<bool> flushDnsCache() async => true;

  @override
  Future<int?> testLatency(String ipAddress) async => 15;

  @override
  Future<bool> setBrowserDohBypassPrevented(bool prevent) async {
    browserDohBlocked = prevent;
    return true;
  }

  @override
  Future<bool> isBrowserDohBypassPrevented() async => browserDohBlocked;

  @override
  Future<bool> setSafeSearchEnforced(bool enable) async {
    safeSearchEnforced = enable;
    return true;
  }

  @override
  Future<bool> isSafeSearchEnforced() async => safeSearchEnforced;

  @override
  Future<FamilyShieldTestResult> testFamilyShieldProtection() async {
    return const FamilyShieldTestResult(
      isAdultBlocked: true,
      isSafeSearchEnforced: true,
      isIpv6Protected: true,
      details: 'All protection layers active and verified.',
    );
  }
}

void main() {
  group('DNS Changer Models & Catalog Tests', () {
    test('DnsChangerService catalog contains all major fast free providers', () {
      final service = DnsChangerService();
      final catalog = service.getDnsCatalog();

      expect(catalog.length, greaterThanOrEqualTo(8));

      final names = catalog.map((p) => p.name).toList();
      expect(names, contains('Cloudflare (1.1.1.1)'));
      expect(names, contains('Google Public DNS'));
      expect(names, contains('Quad9 (Security)'));
      expect(names, contains('Cloudflare Family (1.1.1.3)'));
      expect(names, contains('CleanBrowsing Family Filter'));
      expect(names, contains('OpenDNS FamilyShield (Cisco)'));
      expect(names, contains('AdGuard Family Protection'));
      expect(names, contains('AdGuard DNS'));
      expect(names, contains('OpenDNS Home (Cisco)'));
      expect(names, contains('Control D'));
      expect(names, contains('Automatic (DHCP / ISP)'));

      final cloudflare = catalog.firstWhere((p) => p.id == 'cloudflare');
      expect(cloudflare.primaryIpv4, '1.1.1.1');
      expect(cloudflare.secondaryIpv4, '1.0.0.1');

      final cloudflareFamilyAdult = catalog.firstWhere((p) => p.id == 'cloudflare_family_adult');
      expect(cloudflareFamilyAdult.primaryIpv4, '1.1.1.3');
      expect(cloudflareFamilyAdult.secondaryIpv4, '1.0.0.3');
      expect(cloudflareFamilyAdult.isFamilySafe, isTrue);

      final cleanbrowsingFamily = catalog.firstWhere((p) => p.id == 'cleanbrowsing_family');
      expect(cleanbrowsingFamily.primaryIpv4, '185.228.168.168');
      expect(cleanbrowsingFamily.secondaryIpv4, '185.228.169.168');
      expect(cleanbrowsingFamily.isFamilySafe, isTrue);
      expect(cleanbrowsingFamily.enforcesSafeSearch, isTrue);

      final google = catalog.firstWhere((p) => p.id == 'google');
      expect(google.primaryIpv4, '8.8.8.8');
      expect(google.secondaryIpv4, '8.8.4.4');

      final quad9 = catalog.firstWhere((p) => p.id == 'quad9');
      expect(quad9.primaryIpv4, '9.9.9.9');
    });

    test('DnsChangerService returns family safe providers for DNS Angel mode', () {
      final service = DnsChangerService();
      final familyList = service.getFamilySafeProviders();

      expect(familyList.isNotEmpty, isTrue);
      expect(familyList.any((p) => p.id == 'cleanbrowsing_family'), isTrue);
      expect(familyList.any((p) => p.id == 'adguard_family'), isTrue);
      expect(familyList.any((p) => p.id == 'cloudflare_family_adult'), isTrue);
      expect(familyList.any((p) => p.id == 'opendns_familyshield'), isTrue);
    });

    test('NetworkInterfaceItem formats current DNS correctly', () {
      const dhcpAdapter = NetworkInterfaceItem(
        name: 'Wi-Fi',
        currentDnsServers: [],
        isDhcp: true,
      );
      expect(dhcpAdapter.formattedCurrentDns, contains('Automatic (DHCP'));

      const staticAdapter = NetworkInterfaceItem(
        name: 'Wi-Fi',
        currentDnsServers: ['1.1.1.1', '1.0.0.1'],
        isDhcp: false,
      );
      expect(staticAdapter.formattedCurrentDns, '1.1.1.1  •  1.0.0.1');
    });
  });

  group('DnsChangerController Tests', () {
    test('loads data and accurately identifies active DNS provider', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);

      await controller.loadData();

      expect(controller.selectedAdapter, isNotNull);
      expect(controller.selectedAdapter!.name, 'Wi-Fi');
      expect(controller.activeProviderId, 'dhcp');
      expect(controller.isFamilyShieldActive, isFalse);
    });

    test('applies Cloudflare DNS and updates active provider state', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      final cloudflare = controller.providers.firstWhere((p) => p.id == 'cloudflare');
      final ok = await controller.applyProvider(cloudflare);

      expect(ok, isTrue);
      expect(controller.selectedAdapter!.currentDnsServers, ['1.1.1.1', '1.0.0.1']);
      expect(controller.activeProviderId, 'cloudflare');
      expect(controller.isFamilyShieldActive, isFalse);
    });

    test('applies CleanBrowsing Family and activates Family Shield (DNS Angel)', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      final cleanbrowsing = controller.providers.firstWhere((p) => p.id == 'cleanbrowsing_family');
      final ok = await controller.applyProvider(cleanbrowsing);

      expect(ok, isTrue);
      expect(controller.activeProviderId, 'cleanbrowsing_family');
      expect(controller.isFamilyShieldActive, isTrue);
      expect(controller.isSafeSearchEnforced, isTrue);
    });

    test('toggles Browser DoH bypass and SafeSearch', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      expect(controller.isBrowserDohBlocked, isFalse);
      final dohOk = await controller.toggleBrowserDoh(true);
      expect(dohOk, isTrue);
      expect(controller.isBrowserDohBlocked, isTrue);

      final safeOk = await controller.toggleSafeSearch(true);
      expect(safeOk, isTrue);
      expect(controller.isSafeSearchEnforced, isTrue);
    });

    test('runs live shield verification test', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      final res = await controller.runShieldTest();
      expect(res.isFullyProtected, isTrue);
      expect(res.isAdultBlocked, isTrue);
      expect(controller.testResult, isNotNull);
    });

    test('applies custom DNS servers', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      final ok = await controller.applyCustomDns(
        primaryDns: '8.8.8.8',
        secondaryDns: '8.8.4.4',
      );

      expect(ok, isTrue);
      expect(controller.selectedAdapter!.currentDnsServers, ['8.8.8.8', '8.8.4.4']);
      expect(controller.activeProviderId, 'google');
    });

    test('resets DNS to Automatic DHCP', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      // First set to Google
      await controller.applyCustomDns(primaryDns: '8.8.8.8');
      expect(controller.activeProviderId, 'google');

      // Then reset
      final ok = await controller.resetToDhcp();
      expect(ok, isTrue);
      expect(controller.selectedAdapter!.isDhcp, isTrue);
      expect(controller.activeProviderId, 'dhcp');
      expect(controller.isFamilyShieldActive, isFalse);
    });

    test('benchmarks all latencies and populates latencyMs', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      await controller.benchmarkAllLatencies();

      final cloudflare = controller.providers.firstWhere((p) => p.id == 'cloudflare');
      expect(cloudflare.latencyMs, 15);
    });

    test('startAutoLatencyRefresh immediately benchmarks and disposes cleanly', () async {
      final service = FakeDnsChangerService();
      final controller = DnsChangerController(service: service);
      await controller.loadData();

      controller.startAutoLatencyRefresh();
      await Future.delayed(const Duration(milliseconds: 50));

      final cloudflare = controller.providers.firstWhere((p) => p.id == 'cloudflare');
      expect(cloudflare.latencyMs, 15);

      controller.stopAutoLatencyRefresh();
      controller.dispose();
    });
  });
}
