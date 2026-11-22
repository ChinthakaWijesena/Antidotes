import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';

class DnsProviderCard extends StatelessWidget {
  final DnsProviderItem provider;
  final bool isActive;
  final bool isApplying;
  final VoidCallback onApply;

  const DnsProviderCard({
    super.key,
    required this.provider,
    required this.isActive,
    required this.isApplying,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? provider.brandColor : AppColors.surfaceBorder,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: provider.brandColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Brand Icon & Name & Tag
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: provider.brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(provider.icon, color: provider.brandColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.tag,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: provider.brandColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Latency Pill (if measured)
              if (provider.latencyMs != null) _buildLatencyPill(provider.latencyMs!),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            provider.description,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // IP Addresses Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary',
                        style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                      ),
                      Text(
                        provider.primaryIpv4,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: AppColors.surfaceBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secondary',
                        style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                      ),
                      Text(
                        provider.secondaryIpv4,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'Consolas',
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 34,
            child: isActive
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            'ACTIVE DNS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: isApplying ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.brandColor.withValues(alpha: 0.15),
                      foregroundColor: provider.brandColor,
                      elevation: 0,
                      side: BorderSide(color: provider.brandColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      provider.isDefaultDhcp ? 'Reset to Default' : 'Apply DNS',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyPill(int ms) {
    Color color = Colors.green;
    if (ms > 70) {
      color = const Color(0xFFF57C00);
    }
    if (ms > 150) {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$ms ms',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Consolas',
            ),
          ),
        ],
      ),
    );
  }
}
