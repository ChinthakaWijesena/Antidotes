import 'dart:io';
import 'package:flutter/material.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
import 'package:antidotes/features/dns_changer/data/models/family_shield_test_result.dart';
import 'package:antidotes/features/dns_changer/data/models/network_interface_item.dart';

class DnsChangerService {
  /// Curated catalog of the world's fastest, most reputable and popular free DNS providers
  List<DnsProviderItem> getDnsCatalog() {
    return const [
      DnsProviderItem(
        id: 'cleanbrowsing_family',
        name: 'CleanBrowsing Family Filter',
        tag: 'Adult Block + SafeSearch (Recommended)',
        primaryIpv4: '185.228.168.168',
        secondaryIpv4: '185.228.169.168',
        primaryIpv6: '2a0d:2a00:1::',
        secondaryIpv6: '2a0d:2a00:2::1',
        description: 'Gold standard family filter: automatically blocks pornographic & adult websites and locks Google, Bing & YouTube to Strict SafeSearch.',
        brandColor: Color(0xFF1565C0),
        icon: Icons.family_restroom_rounded,
        isFamilySafe: true,
        enforcesSafeSearch: true,
      ),
      DnsProviderItem(
        id: 'adguard_family',
        name: 'AdGuard Family Protection',
        tag: 'Adult Block + AdBlock + SafeSearch',
        primaryIpv4: '94.140.14.15',
        secondaryIpv4: '94.140.15.16',
        primaryIpv6: '2a10:50c0::bad:filter',
        secondaryIpv6: '2a10:50c0::bad:filter',
        description: 'Blocks adult content & explicit sites, removes ads & popups, and enforces SafeSearch across all search engines.',
        brandColor: Color(0xFF2E7D32),
        icon: Icons.verified_user_rounded,
        isFamilySafe: true,
        enforcesSafeSearch: true,
      ),
      DnsProviderItem(
        id: 'cloudflare_family_adult',
        name: 'Cloudflare Family (1.1.1.3)',
        tag: 'Adult Content + Malware Shield',
        primaryIpv4: '1.1.1.3',
        secondaryIpv4: '1.0.0.3',
        primaryIpv6: '2606:4700:4700::1113',
        secondaryIpv6: '2606:4700:4700::1003',
        description: 'High-speed protection that blocks pornographic & explicit websites and malware using Cloudflare\'s global Anycast network.',
        brandColor: Color(0xFFE65100),
        icon: Icons.shield_rounded,
        isFamilySafe: true,
      ),
      DnsProviderItem(
        id: 'opendns_familyshield',
        name: 'OpenDNS FamilyShield (Cisco)',
        tag: 'Pre-configured Adult Filter',
        primaryIpv4: '208.67.222.123',
        secondaryIpv4: '208.67.220.123',
        primaryIpv6: '2620:119:35::35',
        secondaryIpv6: '2620:119:53::53',
        description: 'Cisco pre-configured DNS that automatically blocks adult and explicit content 24/7 without needing an account.',
        brandColor: Color(0xFF00897B),
        icon: Icons.health_and_safety_rounded,
        isFamilySafe: true,
      ),
      DnsProviderItem(
        id: 'neustar_family',
        name: 'Neustar Family Secure',
        tag: 'Adult & Phishing Filter',
        primaryIpv4: '156.154.70.3',
        secondaryIpv4: '156.154.71.3',
        description: 'Filters adult content, gambling, and malicious phishing sites for homes and schools.',
        brandColor: Color(0xFF6A1B9A),
        icon: Icons.child_care_rounded,
        isFamilySafe: true,
      ),
      DnsProviderItem(
        id: 'yandex_family',
        name: 'Yandex Family DNS',
        tag: 'Adult Content Protection',
        primaryIpv4: '77.88.8.7',
        secondaryIpv4: '77.88.8.3',
        description: 'Fast DNS server with automatic blocking of adult content, pornographic sites, and dangerous scripts.',
        brandColor: Color(0xFFD32F2F),
        icon: Icons.security_rounded,
        isFamilySafe: true,
      ),
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
        icon: Icons.security_rounded,
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
        icon: Icons.shield_rounded,
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

  /// Returns only family-safe providers for DNS Angel mode
  List<DnsProviderItem> getFamilySafeProviders() {
    return getDnsCatalog().where((p) => p.isFamilySafe || p.isDefaultDhcp).toList();
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
              if (l.contains(':') && !l.startsWith('fe80') && !l.startsWith('2001') && !l.startsWith('2606') && !l.startsWith('2a0d') && !l.startsWith('2a10')) {
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
      adapters.sort((a, b) {
        if (a.isConnected && !b.isConnected) return -1;
        if (!a.isConnected && b.isConnected) return 1;
        return a.name.compareTo(b.name);
      });
      return adapters;
    }

    return _getMockAdapters();
  }

  /// Applies primary and secondary DNS to the specified adapter with IPv6 leak protection
  Future<bool> applyDnsToAdapter({
    required String adapterName,
    required String primaryDns,
    String? secondaryDns,
    String? primaryIpv6,
    String? secondaryIpv6,
    bool isFamilySafe = false,
    bool preventIpv6Leak = true,
  }) async {
    if (!Platform.isWindows) return true;

    try {
      final serverList = <String>[primaryDns];
      if (secondaryDns != null && secondaryDns.trim().isNotEmpty) {
        serverList.add(secondaryDns.trim());
      }
      final serverArgs = serverList.map((s) => '"$s"').join(',');

      // Step 1: PowerShell Set-DnsClientServerAddress (robust Windows cmdlet)
      final psCmd = StringBuffer();
      psCmd.write('Set-DnsClientServerAddress -InterfaceAlias "$adapterName" -ServerAddresses @($serverArgs); ');

      // IPv6 configuration: Set family IPv6 DNS if available, or disable IPv6 DNS to prevent unblocked router DNS leaks
      if (primaryIpv6 != null && primaryIpv6.isNotEmpty) {
        psCmd.write('netsh interface ipv6 set dnsservers name="$adapterName" source=static address=$primaryIpv6 validate=no; ');
        if (secondaryIpv6 != null && secondaryIpv6.isNotEmpty) {
          psCmd.write('netsh interface ipv6 add dnsservers name="$adapterName" address=$secondaryIpv6 index=2 validate=no; ');
        }
      } else if (isFamilySafe && preventIpv6Leak) {
        // Prevent router IPv6 DNS leak (e.g. fe80::1) from returning adult domain resolutions
        psCmd.write('netsh interface ipv6 set dnsservers name="$adapterName" source=static address=none validate=no; ');
      }

      // IPv4 netsh fallback
      psCmd.write('netsh interface ipv4 set dnsservers name="$adapterName" source=static address=$primaryDns register=none validate=no; ');
      if (secondaryDns != null && secondaryDns.trim().isNotEmpty) {
        psCmd.write('netsh interface ipv4 add dnsservers name="$adapterName" address=${secondaryDns.trim()} index=2 validate=no; ');
      }
      psCmd.write('ipconfig /flushdns');

      final res1 = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        psCmd.toString(),
      ]);

      if (res1.exitCode == 0) {
        await flushDnsCache();
        return true;
      }

      // If execution requires elevation / UAC elevation
      return await _elevatedApplyDns(
        adapterName,
        primaryDns,
        secondaryDns,
        primaryIpv6: primaryIpv6,
        secondaryIpv6: secondaryIpv6,
        isFamilySafe: isFamilySafe,
        preventIpv6Leak: preventIpv6Leak,
      );
    } catch (_) {
      return await _elevatedApplyDns(
        adapterName,
        primaryDns,
        secondaryDns,
        primaryIpv6: primaryIpv6,
        secondaryIpv6: secondaryIpv6,
        isFamilySafe: isFamilySafe,
        preventIpv6Leak: preventIpv6Leak,
      );
    }
  }

  /// Resets the adapter's DNS configuration to Automatic (DHCP / Router default)
  Future<bool> resetDnsToDhcp(String adapterName) async {
    if (!Platform.isWindows) return true;

    try {
      final psCmd = StringBuffer();
      psCmd.write('Set-DnsClientServerAddress -InterfaceAlias "$adapterName" -ResetServerAddresses; ');
      psCmd.write('netsh interface ipv4 set dnsservers name="$adapterName" source=dhcp; ');
      psCmd.write('netsh interface ipv6 set dnsservers name="$adapterName" source=dhcp; ');
      psCmd.write('ipconfig /flushdns');

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        psCmd.toString(),
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

  /// Configures Browser DoH (Secure DNS) policies in Windows Registry
  /// When blocked, Chrome & Edge are prevented from bypassing Windows DNS
  Future<bool> setBrowserDohBypassPrevented(bool prevent) async {
    if (!Platform.isWindows) return true;

    try {
      final script = StringBuffer();
      if (prevent) {
        script.writeln(r'New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Force -ErrorAction SilentlyContinue | Out-Null');
        script.writeln(r'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "DnsOverHttpsMode" -Value "off" -Type String -Force');
        script.writeln(r'New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null');
        script.writeln(r'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DnsOverHttpsMode" -Value "off" -Type String -Force');
        script.writeln(r'New-Item -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Force -ErrorAction SilentlyContinue | Out-Null');
        script.writeln(r'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "DnsOverHttpsMode" -Value "off" -Type String -Force');
      } else {
        script.writeln(r'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "DnsOverHttpsMode" -Force -ErrorAction SilentlyContinue');
        script.writeln(r'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DnsOverHttpsMode" -Force -ErrorAction SilentlyContinue');
        script.writeln(r'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "DnsOverHttpsMode" -Force -ErrorAction SilentlyContinue');
      }

      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script.toString(),
      ]);

      if (res.exitCode == 0) return true;

      // Elevated retry
      return await _runElevatedPowerShell(script.toString());
    } catch (_) {
      return false;
    }
  }

  /// Checks whether Chrome / Edge DoH bypass is prevented
  Future<bool> isBrowserDohBypassPrevented() async {
    if (!Platform.isWindows) return false;

    try {
      const script = r'(Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue).DnsOverHttpsMode -eq "off" -or (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue).DnsOverHttpsMode -eq "off"';
      final res = await Process.run('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', script]);
      return res.stdout.toString().trim().toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Forces Google & YouTube Strict SafeSearch system-wide via Windows Hosts file
  Future<bool> setSafeSearchEnforced(bool enable) async {
    if (!Platform.isWindows) return true;

    try {
      final hostsFile = File(r'C:\Windows\System32\drivers\etc\hosts');
      if (!hostsFile.existsSync()) return false;

      final content = await hostsFile.readAsString();
      final hasBlock = content.contains('# BEGIN ANTIDOTES SAFESEARCH');

      if (enable && !hasBlock) {
        final buffer = StringBuffer();
        buffer.writeln(content.trimRight());
        buffer.writeln('');
        buffer.writeln('# BEGIN ANTIDOTES SAFESEARCH');
        buffer.writeln('216.239.38.120 forcesafesearch.google.com');
        buffer.writeln('216.239.38.120 www.google.com');
        buffer.writeln('216.239.38.120 google.com');
        buffer.writeln('2001:4860:4802:32::78 www.google.com');
        buffer.writeln('2001:4860:4802:32::78 google.com');
        buffer.writeln('204.79.197.220 www.bing.com');
        buffer.writeln('204.79.197.220 bing.com');
        buffer.writeln('216.239.38.119 restrict.youtube.com');
        buffer.writeln('216.239.38.119 www.youtube.com');
        buffer.writeln('# END ANTIDOTES SAFESEARCH');

        try {
          await hostsFile.writeAsString(buffer.toString());
          await flushDnsCache();
          return true;
        } catch (_) {
          return await _elevatedWriteHosts(buffer.toString());
        }
      } else if (!enable && hasBlock) {
        final cleaned = content.replaceAll(
          RegExp(r'# BEGIN ANTIDOTES SAFESEARCH[\s\S]*?# END ANTIDOTES SAFESEARCH\r?\n?'),
          '',
        );
        try {
          await hostsFile.writeAsString(cleaned);
          await flushDnsCache();
          return true;
        } catch (_) {
          return await _elevatedWriteHosts(cleaned);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if Google / YouTube SafeSearch block is present in Windows hosts
  Future<bool> isSafeSearchEnforced() async {
    if (!Platform.isWindows) return false;

    try {
      final hostsFile = File(r'C:\Windows\System32\drivers\etc\hosts');
      if (!hostsFile.existsSync()) return false;
      final content = await hostsFile.readAsString();
      return content.contains('# BEGIN ANTIDOTES SAFESEARCH');
    } catch (_) {
      return false;
    }
  }

  /// Tests live system protection against adult domains, SafeSearch, and IPv6 leak
  Future<FamilyShieldTestResult> testFamilyShieldProtection() async {
    if (!Platform.isWindows) {
      return const FamilyShieldTestResult(
        isAdultBlocked: true,
        isSafeSearchEnforced: true,
        isIpv6Protected: true,
        details: 'Mock test passed on non-Windows platform.',
      );
    }

    bool isAdultBlocked = false;
    bool isSafeSearchEnforced = false;
    bool isIpv6Protected = true;

    try {
      // 1. Test adult domain resolution (pornhub.com)
      final resAdult = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Resolve-DnsName pornhub.com -DnsOnly -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress',
      ]);
      final adultIps = resAdult.stdout.toString().trim();
      if (adultIps.isEmpty || adultIps.contains('0.0.0.0') || adultIps.contains('::')) {
        isAdultBlocked = true;
      }

      // 2. Test SafeSearch enforcement
      final resSafe = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Resolve-DnsName www.google.com -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress',
      ]);
      final googleIps = resSafe.stdout.toString();
      if (googleIps.contains('216.239.38.120') || googleIps.contains('2001:4860:4802:32::78')) {
        isSafeSearchEnforced = true;
      } else {
        // Also check CleanBrowsing DNS directly
        final hostsActive = await this.isSafeSearchEnforced();
        isSafeSearchEnforced = hostsActive;
      }

      // 3. Test IPv6 leak
      final resIpv6 = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Resolve-DnsName pornhub.com -Type AAAA -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress',
      ]);
      final ipv6Out = resIpv6.stdout.toString().trim();
      if (ipv6Out.isNotEmpty && !ipv6Out.contains('::') && !ipv6Out.contains('0.0.0.0')) {
        isIpv6Protected = false;
      }
    } catch (_) {}

    final details = isAdultBlocked && isSafeSearchEnforced && isIpv6Protected
        ? 'Full Protection Active: Adult sites blocked, SafeSearch locked, IPv6 leaks prevented.'
        : 'Adult blocked: ${isAdultBlocked ? "YES" : "NO"} | SafeSearch: ${isSafeSearchEnforced ? "YES" : "NO"} | IPv6 Protected: ${isIpv6Protected ? "YES" : "NO"}';

    return FamilyShieldTestResult(
      isAdultBlocked: isAdultBlocked,
      isSafeSearchEnforced: isSafeSearchEnforced,
      isIpv6Protected: isIpv6Protected,
      details: details,
    );
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

  Future<bool> _elevatedApplyDns(
    String adapter,
    String primary,
    String? secondary, {
    String? primaryIpv6,
    String? secondaryIpv6,
    bool isFamilySafe = false,
    bool preventIpv6Leak = true,
  }) async {
    final tempDir = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptFile = File('$tempDir\\apply_dns_$timestamp.cmd');
    final doneFile = File('$tempDir\\apply_dns_done_$timestamp.txt');

    try {
      final buffer = StringBuffer();
      buffer.writeln('@echo off');
      buffer.writeln('powershell.exe -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias \\"$adapter\\" -ServerAddresses @(\\"$primary\\"${secondary != null && secondary.trim().isNotEmpty ? ',\\"${secondary.trim()}\\"' : ''})"');
      buffer.writeln('netsh interface ipv4 set dnsservers name="$adapter" source=static address=$primary register=none validate=no');
      if (secondary != null && secondary.trim().isNotEmpty) {
        buffer.writeln('netsh interface ipv4 add dnsservers name="$adapter" address=${secondary.trim()} index=2 validate=no');
      }

      if (primaryIpv6 != null && primaryIpv6.isNotEmpty) {
        buffer.writeln('netsh interface ipv6 set dnsservers name="$adapter" source=static address=$primaryIpv6 validate=no');
        if (secondaryIpv6 != null && secondaryIpv6.isNotEmpty) {
          buffer.writeln('netsh interface ipv6 add dnsservers name="$adapter" address=$secondaryIpv6 index=2 validate=no');
        }
      } else if (isFamilySafe && preventIpv6Leak) {
        buffer.writeln('netsh interface ipv6 set dnsservers name="$adapter" source=static address=none validate=no');
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
      buffer.writeln('powershell.exe -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias \\"$adapter\\" -ResetServerAddresses"');
      buffer.writeln('netsh interface ipv4 set dnsservers name="$adapter" source=dhcp');
      buffer.writeln('netsh interface ipv6 set dnsservers name="$adapter" source=dhcp');
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

  Future<bool> _runElevatedPowerShell(String psCommands) async {
    final tempDir = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ps1File = File('$tempDir\\antidotes_elevated_$timestamp.ps1');

    try {
      await ps1File.writeAsString(psCommands);
      final res = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File \\"${ps1File.path}\\"" -Verb RunAs -Wait -WindowStyle Hidden',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    } finally {
      try {
        if (ps1File.existsSync()) ps1File.deleteSync();
      } catch (_) {}
    }
  }

  Future<bool> _elevatedWriteHosts(String content) async {
    final tempDir = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempHosts = File('$tempDir\\temp_hosts_$timestamp.txt');

    try {
      await tempHosts.writeAsString(content);
      final script = 'Copy-Item -Path "${tempHosts.path}" -Destination "C:\\Windows\\System32\\drivers\\etc\\hosts" -Force; ipconfig /flushdns';
      return await _runElevatedPowerShell(script);
    } catch (_) {
      return false;
    } finally {
      try {
        if (tempHosts.existsSync()) tempHosts.deleteSync();
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
