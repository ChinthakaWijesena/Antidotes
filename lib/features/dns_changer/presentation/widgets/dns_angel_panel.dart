import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
import 'package:antidotes/features/dns_changer/presentation/controllers/dns_changer_controller.dart';

class DnsAngelPanel extends StatelessWidget {
  final DnsChangerController controller;
  final ValueChanged<DnsProviderItem> onApplyProvider;
  final VoidCallback onResetDefault;
  final VoidCallback onRunTest;

  const DnsAngelPanel({
    super.key,
    required this.controller,
    required this.onApplyProvider,
    required this.onResetDefault,
    required this.onRunTest,
  });

  @override
  Widget build(BuildContext context) {
    final isProtected = controller.isFamilyShieldActive;
    final active = controller.activeProvider;
    final isApplying = controller.isApplying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Big Status Hero Card (DNS Angel Style)
        _buildStatusHeroCard(context, isProtected, active),
        const SizedBox(height: 20),

        // 2. 1-Click DNS Angel Preset Buttons Grid
        Text(
          '1-Click Family Safe DNS Servers (DNS Angel Mode)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select any server below to block pornographic websites, adult domains, and dangerous threats instantly',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),

        _buildPresetsGrid(context, isApplying),
        const SizedBox(height: 24),

        // 3. Complete Protection Controls (SafeSearch, Browser DoH, IPv6 leak)
        _buildProtectionControlsCard(context),
        const SizedBox(height: 20),

        // 4. Live Shield Verification Test Card
        _buildLiveTestCard(context),
      ],
    );
  }

  Widget _buildStatusHeroCard(BuildContext context, bool isProtected, DnsProviderItem? active) {
    final statusColor = isProtected ? const Color(0xFF2E7D32) : const Color(0xFFF57C00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isProtected ? Colors.green.shade600 : AppColors.surfaceBorder,
          width: isProtected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isProtected ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield Badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Icon(
                  isProtected ? Icons.gpp_good_rounded : Icons.shield_outlined,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),

              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isProtected ? 'FAMILY PROTECTION: ACTIVE' : 'FAMILY PROTECTION: INACTIVE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isProtected ? 'Protected' : 'Unfiltered',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isProtected
                          ? 'Protected by ${active?.name ?? "Family DNS"}. Explicit websites and adult materials are automatically blocked.'
                          : 'Your PC is using standard unfiltered DNS (${active?.name ?? "Default Gateway"}). Adult websites and unfiltered Google search results are accessible.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              ),

              // Adapter info pill
              if (controller.selectedAdapter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.selectedAdapter!.name.toLowerCase().contains('wi-fi')
                            ? Icons.wifi_rounded
                            : Icons.settings_ethernet_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.selectedAdapter!.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 14),

          // Feature Badges Row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFeatureBadge(
                label: 'Adult Websites Blocked',
                isActive: isProtected,
                icon: Icons.block_rounded,
              ),
              _buildFeatureBadge(
                label: 'Google & YouTube SafeSearch',
                isActive: isProtected && controller.isSafeSearchEnforced,
                icon: Icons.search_rounded,
              ),
              _buildFeatureBadge(
                label: 'Anti-Malware Shield',
                isActive: isProtected,
                icon: Icons.security_rounded,
              ),
              _buildFeatureBadge(
                label: 'Browser Leak Shield (DoH)',
                isActive: controller.isBrowserDohBlocked,
                icon: Icons.public_off_rounded,
              ),
              _buildFeatureBadge(
                label: 'IPv6 Leak Protected',
                isActive: controller.preventIpv6Leak,
                icon: Icons.leak_remove_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({
    required String label,
    required bool isActive,
    required IconData icon,
  }) {
    final color = isActive ? Colors.green : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.12) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? Colors.green.withValues(alpha: 0.35) : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green.shade400 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid(BuildContext context, bool isApplying) {
    final familyProviders = controller.familySafeProviders;
    final activeId = controller.activeProviderId;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 750) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 175,
          ),
          itemCount: familyProviders.length + 1, // +1 for Restore Default
          itemBuilder: (context, index) {
            if (index == familyProviders.length) {
              // Restore Default Button Card
              final isDefault = activeId == 'dhcp';
              return _buildRestoreDefaultCard(isDefault, isApplying);
            }

            final provider = familyProviders[index];
            final isActive = activeId == provider.id;

            return _buildPresetCard(provider, isActive, isApplying);
          },
        );
      },
    );
  }

  Widget _buildPresetCard(DnsProviderItem provider, bool isActive, bool isApplying) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? provider.brandColor : AppColors.surfaceBorder,
          width: isActive ? 1.6 : 1,
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: provider.brandColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(provider.icon, color: provider.brandColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      provider.tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: provider.brandColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            provider.description,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'DNS: ${provider.primaryIpv4}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'Consolas',
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (provider.enforcesSafeSearch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SafeSearch',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: isActive
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.14),
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
                            'ACTIVE SHIELD',
                            style: TextStyle(
                              fontSize: 10.5,
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
                    onPressed: isApplying ? null : () => onApplyProvider(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.brandColor.withValues(alpha: 0.15),
                      foregroundColor: provider.brandColor,
                      elevation: 0,
                      side: BorderSide(color: provider.brandColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Enable Protection',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreDefaultCard(bool isDefault, bool isApplying) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDefault ? const Color(0xFF607D8B) : AppColors.surfaceBorder,
          width: isDefault ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFF607D8B), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restore Default DNS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Router / ISP Default',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF607D8B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reverts all network adapters back to default DHCP dynamic DNS from your Wi-Fi router.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            'Assignment: Dynamic DHCP',
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'Consolas',
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: isDefault
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueGrey),
                    ),
                    child: const Center(
                      child: Text(
                        'DEFAULT (DHCP)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: isApplying ? null : onResetDefault,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Turn Off Protection',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionControlsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Complete Adult Content & SafeSearch Controls',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ensure adult content cannot bypass DNS through Google Search, Chrome Secure DNS, or IPv6 routers.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          // 1. Google SafeSearch Switch
          _buildToggleTile(
            title: 'Enforce Google & YouTube SafeSearch',
            subtitle:
                'Forces Google, Bing & YouTube to permanently filter pornographic videos, images, and explicit search results.',
            icon: Icons.search_rounded,
            value: controller.isSafeSearchEnforced,
            onChanged: (val) => controller.toggleSafeSearch(val),
          ),
          const Divider(height: 20),

          // 2. Browser DoH Switch
          _buildToggleTile(
            title: 'Prevent Browser DoH Bypass (Chrome & Edge)',
            subtitle:
                'Prevents Google Chrome and Edge from using "Secure DNS" to bypass Windows Family DNS.',
            icon: Icons.public_off_rounded,
            value: controller.isBrowserDohBlocked,
            onChanged: (val) => controller.toggleBrowserDoh(val),
          ),
          const Divider(height: 20),

          // 3. IPv6 Leak Protection Switch
          _buildToggleTile(
            title: 'Block Router IPv6 DNS Leaks',
            subtitle:
                'Ensures your local router\'s IPv6 DNS does not answer queries with unfiltered adult domain addresses.',
            icon: Icons.leak_remove_rounded,
            value: controller.preventIpv6Leak,
            onChanged: (val) => controller.togglePreventIpv6Leak(val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: value ? AppColors.primary.withValues(alpha: 0.14) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: controller.isApplying ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildLiveTestCard(BuildContext context) {
    final result = controller.testResult;
    final isTesting = controller.isTestingShield;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.verified_rounded, size: 20, color: Colors.teal),
              const SizedBox(width: 10),
              Text(
                'Live Family Shield Health Test',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: isTesting ? null : onRunTest,
                icon: isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(isTesting ? 'Testing Protection...' : 'Run Protection Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tests live domain resolution against known adult sites (e.g. pornhub.com) and verifies SafeSearch status.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.isFullyProtected
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: result.isFullyProtected
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.isFullyProtected ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: result.isFullyProtected ? Colors.green : Colors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.details,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: result.isFullyProtected ? Colors.green.shade300 : Colors.amber.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
