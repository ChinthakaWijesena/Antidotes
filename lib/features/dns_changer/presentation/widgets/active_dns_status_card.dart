import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/dns_changer/data/models/network_interface_item.dart';

class ActiveDnsStatusCard extends StatelessWidget {
  final List<NetworkInterfaceItem> adapters;
  final NetworkInterfaceItem? selectedAdapter;
  final String? activeProviderName;
  final bool isTestingLatency;
  final ValueChanged<NetworkInterfaceItem> onAdapterSelected;
  final VoidCallback onFlushDns;
  final VoidCallback onTestSpeeds;
  final VoidCallback onOpenCustomDns;

  const ActiveDnsStatusCard({
    super.key,
    required this.adapters,
    required this.selectedAdapter,
    required this.activeProviderName,
    required this.isTestingLatency,
    required this.onAdapterSelected,
    required this.onFlushDns,
    required this.onTestSpeeds,
    required this.onOpenCustomDns,
  });

  @override
  Widget build(BuildContext context) {
    final adapter = selectedAdapter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              // Title & Adapter Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Current Active DNS Configuration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (activeProviderName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  activeProviderName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Changes apply to your network adapter with zero system restart required',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Adapter Selector Dropdown
              if (adapters.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<NetworkInterfaceItem>(
                      value: adapter,
                      dropdownColor: AppColors.surface,
                      items: adapters.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                a.name.toLowerCase().contains('wi-fi')
                                    ? Icons.wifi_rounded
                                    : Icons.settings_ethernet_rounded,
                                size: 16,
                                color: a.isConnected ? Colors.green : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                a.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) onAdapterSelected(val);
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Adapter Details Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned DNS Server(s)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        adapter?.formattedCurrentDns ?? 'Detecting...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Consolas',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adapter IP Address',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        adapter?.ipAddress.isNotEmpty == true ? adapter!.ipAddress : 'Disconnected',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'Consolas',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignment Type',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        adapter?.isDhcp == true ? 'Dynamic (DHCP)' : 'Static (Manual DNS)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: adapter?.isDhcp == true ? const Color(0xFF0288D1) : const Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Bar
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: isTestingLatency ? null : onTestSpeeds,
                icon: isTestingLatency
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.speed_rounded, size: 16),
                label: Text(isTestingLatency ? 'Benchmarking...' : 'Test DNS Latency / Speeds'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onFlushDns,
                icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                label: const Text('Flush DNS Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onOpenCustomDns,
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Custom DNS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
