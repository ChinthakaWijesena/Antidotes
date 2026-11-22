import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/speed_test_result.dart';

/// Card showing IP, ISP details, and real-world network capability ratings.
class ConnectionInfoCard extends StatelessWidget {
  final NetworkMetaInfo meta;
  final SpeedTestResult? lastResult;
  final List<SpeedTestResult> history;

  const ConnectionInfoCard({
    super.key,
    required this.meta,
    required this.lastResult,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.public_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Network Connection & ISP Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details Row
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Internet Service Provider',
                  value: meta.isp,
                  icon: Icons.business_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InfoPill(
                  label: 'Public IP Address',
                  value: meta.ip,
                  icon: Icons.lan_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InfoPill(
                  label: 'Server Location',
                  value: '${meta.city}, ${meta.countryCode}',
                  icon: Icons.location_on_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Connection Quality Ratings
          Text(
            'Performance Suitability',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _QualityBadge(
                  title: 'Online Gaming',
                  rating: lastResult?.gamingQuality ?? 'Run test to measure',
                  icon: Icons.sports_esports_rounded,
                  isTested: lastResult != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QualityBadge(
                  title: '4K / HD Video',
                  rating: lastResult?.streamingQuality ?? 'Run test to measure',
                  icon: Icons.live_tv_rounded,
                  isTested: lastResult != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QualityBadge(
                  title: 'Video Conferencing',
                  rating: lastResult?.callQuality ?? 'Run test to measure',
                  icon: Icons.video_call_rounded,
                  isTested: lastResult != null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final String title;
  final String rating;
  final IconData icon;
  final bool isTested;

  const _QualityBadge({
    required this.title,
    required this.rating,
    required this.icon,
    required this.isTested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTested
            ? const Color(0xFF00E676).withValues(alpha: 0.08)
            : AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTested
              ? const Color(0xFF00E676).withValues(alpha: 0.25)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isTested ? const Color(0xFF00E676) : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  rating,
                  style: TextStyle(
                    color: isTested
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
