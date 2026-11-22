import 'dart:io';
import 'package:flutter/material.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
import 'package:antidotes/features/dns_changer/data/models/network_interface_item.dart';

class DnsChangerService {
  /// Curated catalog of the world's fastest, most reputable and popular free DNS providers
  List<DnsProviderItem> getDnsCatalog() {
    return const [
      DnsProviderItem(
        id: 'cloudflare',
        name: 'Cloudflare (1.1.1.1)',
        tag: 'Fastest & Privacy',
        primaryIpv4: '1.1.1.1',
        secondaryIpv4: '1.0.0.1',
        description: 'World\'s fastest public DNS with strict privacy and zero user tracking.',
        brandColor: Color(0xFFF57C00),
        icon: Icons.flash_on_rounded,
      ),
      DnsProviderItem(
        id: 'google',
        name: 'Google Public DNS',
        tag: 'High Reliability',
        primaryIpv4: '8.8.8.8',
        secondaryIpv4: '8.8.4.4',
        description: 'Global Anycast network with 99.99% uptime and immense global capacity.',
        brandColor: Color(0xFF4285F4),
        icon: Icons.language_rounded,
      ),
      DnsProviderItem(
        id: 'quad9',
        name: 'Quad9 (Security)',
        tag: 'Malware & Threat Shield',
        primaryIpv4: '9.9.9.9',
        secondaryIpv4: '149.112.112.112',
        description: 'Swiss non-profit DNS that automatically blocks malicious domains and botnets.',
        brandColor: Color(0xFFC2185B),
        icon: Icons.shield_rounded,
      ),
      DnsProviderItem(
        id: 'cloudflare_family_adult',
        name: 'Cloudflare Family (1.1.1.3)',
        tag: 'Adult Content + Malware Block',
        primaryIpv4: '1.1.1.3',
        secondaryIpv4: '1.0.0.3',
        description: 'Blocks adult, explicit & pornographic websites and malware using Cloudflare\'s fastest network.',
        brandColor: Color(0xFFE65100),
        icon: Icons.family_restroom_rounded,
      ),
      DnsProviderItem(
        id: 'cleanbrowsing_family',
        name: 'CleanBrowsing Family Filter',
        tag: 'Adult Block + SafeSearch',
        primaryIpv4: '185.228.168.168',
        secondaryIpv4: '185.228.169.168',
        description: 'Blocks adult content and pornography system-wide, and forces Google and YouTube SafeSearch.',
        brandColor: Color(0xFF1565C0),
        icon: Icons.child_care_rounded,
      ),
      DnsProviderItem(
        id: 'opendns_familyshield',
        name: 'OpenDNS FamilyShield (Cisco)',
        tag: 'Pre-configured Adult Filter',
        primaryIpv4: '208.67.222.123',
        secondaryIpv4: '208.67.220.123',
        description: 'Cisco pre-configured DNS that automatically blocks adult and explicit content 24/7.',
        brandColor: Color(0xFF00897B),
        icon: Icons.shield_rounded,
      ),
      DnsProviderItem(
        id: 'adguard_family',
        name: 'AdGuard Family Protection',
        tag: 'Adult Block + AdBlock',
        primaryIpv4: '94.140.14.15',
        secondaryIpv4: '94.140.15.16',
        description: 'Blocks adult content, disables ads & trackers, and enforces SafeSearch on all search engines.',
        brandColor: Color(0xFF2E7D32),
        icon: Icons.verified_user_rounded,
      ),
      DnsProviderItem(
        id: 'adguard',
        name: 'AdGuard DNS',
        tag: 'Ad & Tracker Blocker',
        primaryIpv4: '94.140.14.14',
        secondaryIpv4: '94.140.15.15',
        description: 'Blocks banner ads, popups, web trackers, and telemetry system-wide.',
        brandColor: Color(0xFF43A047),
        icon: Icons.block_rounded,
      ),
      DnsProviderItem(
        id: 'cloudflare_family',
        name: 'Cloudflare Malware Block',
        tag: '1.1.1.2 Security',
        primaryIpv4: '1.1.1.2',
        secondaryIpv4: '1.0.0.2',
        description: 'Cloudflare\'s ultra-fast speeds with automatic malware domain blocking.',
        brandColor: Color(0xFFFB8C00),
        icon: Icons.security_rounded,
      ),
      DnsProviderItem(
        id: 'opendns',
        name: 'OpenDNS Home (Cisco)',
        tag: 'Web Safety & Filter',
        primaryIpv4: '208.67.222.222',
        secondaryIpv4: '208.67.220.220',
        description: 'Enterprise-grade Anycast network by Cisco with advanced anti-phishing.',
        brandColor: Color(0xFF009688),
        icon: Icons.verified_user_rounded,
      ),
      DnsProviderItem(
        id: 'controld',
        name: 'Control D',
        tag: 'Modern Fast Anycast',
        primaryIpv4: '76.76.2.2',
        secondaryIpv4: '76.76.10.2',
        description: 'Next-generation high performance DNS with built-in ad and threat filters.',
        brandColor: Color(0xFF7C4DFF),
        icon: Icons.wifi_protected_setup_rounded,
      ),
      DnsProviderItem(
        id: 'cleanbrowsing',
        name: 'CleanBrowsing Security',
        tag: 'Safe Surfing',
        primaryIpv4: '185.228.168.9',
        secondaryIpv4: '185.228.169.9',
        description: 'Security filter blocking malicious websites, phishing, and infected hosts.',
        brandColor: Color(0xFF0288D1),
        icon: Icons.health_and_safety_rounded,
      ),
      DnsProviderItem(
        id: 'dhcp',
        name: 'Automatic (DHCP / ISP)',
        tag: 'Default Network Gateway',
        primaryIpv4: 'Automatic (Router/ISP)',
        secondaryIpv4: 'Automatic',
        description: 'Reverts your DNS back to default Wi-Fi router and ISP dynamic assignment.',
        brandColor: Color(0xFF607D8B),
        icon: Icons.settings_backup_restore_rounded,
        isDefaultDhcp: true,
      ),
    ];
  }

  /// Discovers network adapters and their current DNS configuration
  Future<List<NetworkInterfaceItem>> getNetworkAdapters() async {
    if (!Platform.isWindows) {
      return _getMockAdapters();
    }

    final adapters = <NetworkInterfaceItem>[];

    // Read direct interface DNS configurations from netsh
    final dnsMap = <String, ({bool isDhcp, List<String> servers})>{};
    try {
      final resDns = await Process.run('netsh', ['interface', 'ipv4', 'show', 'dnsservers']);
      if (resDns.exitCode == 0) {
        final rawText = resDns.stdout.toString();
        final sections = rawText.split(RegExp(r'\r?\n\r?\n(?=Configuration for interface)'));
        for (final sec in sections) {
          final mName = RegExp(r'interface "([^"]+)"').firstMatch(sec);
          if (mName == null) continue;
          final ifName = mName.group(1)!;
          final isDhcp = sec.contains('configured through DHCP');
          final servers = <String>[];
          final ipMatches = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b').allMatches(sec);
          for (final m in ipMatches) {
            final ip = m.group(0)!;
            if (!servers.contains(ip)) servers.add(ip);
          }
          dnsMap[ifName] = (isDhcp: isDhcp, servers: servers);
        }
      }
    } catch (_) {}

    try {
      final res = await Process.run('ipconfig', ['/all']);
      if (res.exitCode == 0) {
        final text = res.stdout.toString();
        final sections = text.split(RegExp(r'\r?\n\r?\n(?=[A-Za-z0-9].*?adapter)'));

        for (final section in sections) {
          final lines = section.split('\n');
          if (lines.isEmpty) continue;

          final header = lines.first.trim();
          final match = RegExp(r'adapter\s+(.*?):', caseSensitive: false).firstMatch(header);
          if (match == null) continue;

          final name = match.group(1)?.trim() ?? '';
          if (name.isEmpty || name.contains('Loopback') || name.contains('VirtualBox')) {
            continue;
          }

          String desc = '';
          String ip = '';
          bool isDhcp = true;
          bool isConnected = !section.toLowerCase().contains('media disconnected');
          final dnsServers = <String>[];

          bool readingDns = false;

          for (final line in lines) {
            final l = line.trim();

            if (l.startsWith('Description')) {
              desc = l.split(':').last.trim();
            } else if (l.startsWith('IPv4 Address') || l.startsWith('Autoconfiguration IPv4')) {
              final ipRaw = l.split(':').last.trim();
              ip = ipRaw.replaceAll(RegExp(r'\(.*?\)'), '').trim();
            } else if (l.startsWith('DHCP Enabled')) {
              isDhcp = l.toLowerCase().contains('yes');
            } else if (l.startsWith('DNS Servers')) {
              readingDns = true;
              final dnsRaw = l.split(':').last.trim();
              if (dnsRaw.isNotEmpty && !dnsRaw.contains('None')) {
                final cleaned = dnsRaw.replaceAll(RegExp(r'\(.*?\)'), '').trim();
                if (cleaned.isNotEmpty && !cleaned.contains(':')) dnsServers.add(cleaned);
              }
            } else if (readingDns) {
              if (l.contains(':') && !l.startsWith('fe80') && !l.startsWith('2001') && !l.startsWith('2606')) {
                readingDns = false;
              } else if (l.isNotEmpty) {
                final cleaned = l.replaceAll(RegExp(r'\(.*?\)'), '').trim();
                if (cleaned.isNotEmpty && !cleaned.contains('None') && !cleaned.contains(':') && !dnsServers.contains(cleaned)) {
                  dnsServers.add(cleaned);
                }
              }
            }
          }

          final dnsInfo = dnsMap[name];
          final effectiveDns = (dnsInfo != null && dnsInfo.servers.isNotEmpty) ? dnsInfo.servers : dnsServers;
          final effectiveDhcp = dnsInfo != null ? dnsInfo.isDhcp : isDhcp;

          if (isConnected || name.contains('Wi-Fi') || name.contains('Ethernet')) {
            adapters.add(NetworkInterfaceItem(
              name: name,
              description: desc,
              ipAddress: ip,
              currentDnsServers: effectiveDns,
              isDhcp: effectiveDhcp,
              isConnected: isConnected,
            ));
          }
        }
      }
    } catch (_) {}

    if (adapters.isNotEmpty) {
      // Put connected adapters first (e.g. active Wi-Fi / Ethernet)
      adapters.sort((a, b) {
        if (a.isConnected && !b.isConnected) return -1;
        if (!a.isConnected && b.isConnected) return 1;
        return a.name.compareTo(b.name);
      });
      return adapters;
    }

    return _getMockAdapters();
  }

  /// Applies primary and secondary DNS to the specified adapter
  Future<bool> applyDnsToAdapter({
    required String adapterName,
    required String primaryDns,
    String? secondaryDns,
  }) async {
    if (!Platform.isWindows) return true;

    try {
      // Step 1: Attempt direct netsh execution (succeeds if running as admin)
      final res1 = await Process.run('netsh', [
        'interface',
        'ipv4',
        'set',
        'dnsservers',
        'name=$adapterName',
        'source=static',
        'address=$primaryDns',
        'register=none',
        'validate=no',
      ]);

      if (res1.exitCode == 0) {
        if (secondaryDns != null && secondaryDns.trim().isNotEmpty) {
          await Process.run('netsh', [
            'interface',
            'ipv4',
            'add',
            'dnsservers',
            'name=$adapterName',
            'address=${secondaryDns.trim()}',
            'index=2',
            'validate=no',
          ]);
        }
        await flushDnsCache();
        return true;
      }

      // If user permission / UAC elevation is required
      return await _elevatedApplyDns(adapterName, primaryDns, secondaryDns);
    } catch (_) {
      return await _elevatedApplyDns(adapterName, primaryDns, secondaryDns);
    }
  }

  /// Resets the adapter's DNS configuration to Automatic (DHCP / Router default)
  Future<bool> resetDnsToDhcp(String adapterName) async {
    if (!Platform.isWindows) return true;

    try {
      final res = await Process.run('netsh', [
        'interface',
        'ipv4',
        'set',
        'dnsservers',
        'name=$adapterName',
        'source=dhcp',
      ]);

      if (res.exitCode == 0) {
        await flushDnsCache();
        return true;
      }

      return await _elevatedResetDhcp(adapterName);
    } catch (_) {
      return await _elevatedResetDhcp(adapterName);
    }
  }

  /// Flushes Windows DNS client resolver cache (ipconfig /flushdns)
  Future<bool> flushDnsCache() async {
    if (!Platform.isWindows) return true;

    try {
      final res = await Process.run('ipconfig', ['/flushdns']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Measures live TCP DNS connection latency to port 53 in milliseconds
  Future<int?> testLatency(String ipAddress) async {
    if (ipAddress.toLowerCase().contains('auto')) return null;

    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        ipAddress,
        53,
        timeout: const Duration(milliseconds: 1500),
      );
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _elevatedApplyDns(String adapter, String primary, String? secondary) async {
    final tempDir = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptFile = File('$tempDir\\apply_dns_$timestamp.cmd');
    final doneFile = File('$tempDir\\apply_dns_done_$timestamp.txt');

    try {
      final buffer = StringBuffer();
      buffer.writeln('@echo off');
      buffer.writeln('netsh interface ipv4 set dnsservers name="$adapter" source=static address=$primary register=none validate=no');
      if (secondary != null && secondary.trim().isNotEmpty) {
        buffer.writeln('netsh interface ipv4 add dnsservers name="$adapter" address=${secondary.trim()} index=2 validate=no');
      }
      buffer.writeln('ipconfig /flushdns >nul 2>&1');
      buffer.writeln('echo SUCCESS > "${doneFile.path}"');

      await scriptFile.writeAsString(buffer.toString());

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process -FilePath "${scriptFile.path}" -Verb RunAs -Wait -WindowStyle Hidden',
      ]);

      if (!doneFile.existsSync()) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return doneFile.existsSync() || res.exitCode == 0;
    } catch (_) {
      return false;
    } finally {
      try {
        if (scriptFile.existsSync()) scriptFile.deleteSync();
        if (doneFile.existsSync()) doneFile.deleteSync();
      } catch (_) {}
    }
  }

  Future<bool> _elevatedResetDhcp(String adapter) async {
    final tempDir = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptFile = File('$tempDir\\reset_dns_$timestamp.cmd');
    final doneFile = File('$tempDir\\reset_dns_done_$timestamp.txt');

    try {
      final buffer = StringBuffer();
      buffer.writeln('@echo off');
      buffer.writeln('netsh interface ipv4 set dnsservers name="$adapter" source=dhcp');
      buffer.writeln('ipconfig /flushdns >nul 2>&1');
      buffer.writeln('echo SUCCESS > "${doneFile.path}"');

      await scriptFile.writeAsString(buffer.toString());

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process -FilePath "${scriptFile.path}" -Verb RunAs -Wait -WindowStyle Hidden',
      ]);

      if (!doneFile.existsSync()) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return doneFile.existsSync() || res.exitCode == 0;
    } catch (_) {
      return false;
    } finally {
      try {
        if (scriptFile.existsSync()) scriptFile.deleteSync();
        if (doneFile.existsSync()) doneFile.deleteSync();
      } catch (_) {}
    }
  }

  List<NetworkInterfaceItem> _getMockAdapters() {
    return const [
      NetworkInterfaceItem(
        name: 'Wi-Fi',
        description: 'Realtek 8852BE Wireless LAN WiFi 6 PCI-E NIC',
        ipAddress: '192.168.1.10',
        currentDnsServers: ['192.168.1.1'],
        isDhcp: true,
        isConnected: true,
      ),
      NetworkInterfaceItem(
        name: 'Ethernet',
        description: 'Realtek PCIe GbE Family Controller',
        ipAddress: '',
        currentDnsServers: [],
        isDhcp: true,
        isConnected: false,
      ),
    ];
  }
}
