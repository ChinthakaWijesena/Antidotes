import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/dns_changer/presentation/controllers/dns_changer_controller.dart';
import 'package:antidotes/features/dns_changer/data/models/dns_provider_item.dart';
import 'package:antidotes/features/dns_changer/presentation/widgets/active_dns_status_card.dart';
import 'package:antidotes/features/dns_changer/presentation/widgets/custom_dns_modal.dart';
import 'package:antidotes/features/dns_changer/presentation/widgets/dns_angel_panel.dart';
import 'package:antidotes/features/dns_changer/presentation/widgets/dns_provider_card.dart';

class DnsChangerScreen extends StatefulWidget {
  final DnsChangerController? controller;

  const DnsChangerScreen({super.key, this.controller});

  @override
  State<DnsChangerScreen> createState() => _DnsChangerScreenState();
}

class _DnsChangerScreenState extends State<DnsChangerScreen> {
  late final DnsChangerController _controller;
  int _activeTab = 0; // 0 = Family Shield (DNS Angel), 1 = All DNS Servers
  int _categoryFilter = 0; // 0 = All, 1 = Adult Block & Family, 2 = Fast & Privacy, 3 = Security & AdBlock

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DnsChangerController();
    _controller.addListener(_onControllerUpdate);
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _openCustomDnsModal() {
    if (_controller.selectedAdapter == null) return;

    showDialog(
      context: context,
      builder: (ctx) => CustomDnsModal(
        adapterName: _controller.selectedAdapter!.name,
        onApply: (primary, secondary) async {
          final success = await _controller.applyCustomDns(
            primaryDns: primary,
            secondaryDns: secondary,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Custom DNS ($primary) applied successfully!'
                      : 'Failed to apply custom DNS. Check permissions.',
                ),
                backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
              ),
            );
          }
        },
      ),
    );
  }

  void _onFlushDns() async {
    final success = await _controller.flushDnsCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Windows DNS Cache successfully flushed!' : 'Could not flush DNS cache.',
          ),
          backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
        ),
      );
    }
  }

  void _onRunShieldTest() async {
    final res = await _controller.runShieldTest();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.isFullyProtected
                ? 'Protection Verified: Adult sites & leaks are 100% blocked!'
                : 'Protection Alert: Some layers need attention (${res.details})',
          ),
          backgroundColor: res.isFullyProtected ? Colors.green.shade800 : Colors.amber.shade900,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeId = _controller.activeProviderId;
    final activeProvider = _controller.providers.where((p) => p.id == activeId).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Mode Switcher (DNS Angel / All Servers)
                  _buildModeSwitcher(),
                  const SizedBox(height: 20),

                  // Tab 0: Family Shield (DNS Angel)
                  if (_activeTab == 0)
                    DnsAngelPanel(
                      controller: _controller,
                      onApplyProvider: (provider) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await _controller.applyProvider(provider);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '${provider.name} activated! Adult websites & threats are blocked.'
                                  : 'Failed to activate ${provider.name}.',
                            ),
                            backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        );
                      },
                      onResetDefault: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await _controller.resetToDhcp();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Protection turned off. Reverted to Default DHCP.' : 'Failed to reset DNS.',
                            ),
                            backgroundColor: ok ? Colors.blueGrey.shade800 : Colors.red.shade800,
                          ),
                        );
                      },
                      onRunTest: _onRunShieldTest,
                    ),

                  // Tab 1: All DNS Servers & Latency Benchmarks
                  if (_activeTab == 1) ...[
                    ActiveDnsStatusCard(
                      adapters: _controller.adapters,
                      selectedAdapter: _controller.selectedAdapter,
                      activeProviderName: activeProvider?.name,
                      isTestingLatency: _controller.isTestingLatency,
                      onAdapterSelected: _controller.selectAdapter,
                      onFlushDns: _onFlushDns,
                      onTestSpeeds: _controller.benchmarkAllLatencies,
                      onOpenCustomDns: _openCustomDnsModal,
                    ),
                    const SizedBox(height: 24),

                    // Section Title & Category Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Popular & Fast Free DNS Servers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select any provider to switch your DNS instantly and optimize latency, gaming, and web privacy',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        if (_controller.isApplying)
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _controller.statusMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips
                    _buildCategoryFilters(),
                    const SizedBox(height: 16),

                    // Provider Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 750) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 1100) {
                          crossAxisCount = 2;
                        }

                        final displayed = _filteredProviders;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 220,
                          ),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            final provider = displayed[index];
                            final isActive = activeId == provider.id;

                            return DnsProviderCard(
                              provider: provider,
                              isActive: isActive,
                              isApplying: _controller.isApplying,
                              onApply: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await _controller.applyProvider(provider);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? '${provider.name} applied successfully!'
                                          : 'Failed to apply ${provider.name}.',
                                    ),
                                    backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DNS Manager & Angel Shield',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'DNS Angel Mode',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Switch between the world\'s fastest DNS providers, block adult content, and protect your family from explicit websites',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _controller.loadData,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Network Adapters',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            index: 0,
            icon: Icons.family_restroom_rounded,
            label: 'Family Shield (DNS Angel)',
            badge: _controller.isFamilyShieldActive ? 'PROTECTED' : null,
            badgeColor: Colors.green,
          ),
          const SizedBox(width: 4),
          _buildModeButton(
            index: 1,
            icon: Icons.dns_rounded,
            label: 'All DNS Servers & Latency',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required int index,
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _activeTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.green).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (badgeColor ?? Colors.green).withValues(alpha: 0.4)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<DnsProviderItem> get _filteredProviders {
    final all = _controller.providers;
    switch (_categoryFilter) {
      case 1: // Adult Block & Family
        return all.where((p) => p.isFamilySafe).toList();
      case 2: // Fast & Privacy
        return all.where((p) => [
          'cloudflare',
          'google',
          'controld',
          'dhcp',
        ].contains(p.id)).toList();
      case 3: // Security & AdBlock
        return all.where((p) => [
          'quad9',
          'adguard',
          'cloudflare_family',
          'opendns',
          'cleanbrowsing',
        ].contains(p.id)).toList();
      default:
        return all;
    }
  }

  Widget _buildCategoryFilters() {
    final filters = [
      {'label': 'All Servers', 'icon': Icons.apps_rounded, 'index': 0},
      {'label': '🛡️ Adult Block & Family', 'icon': Icons.family_restroom_rounded, 'index': 1},
      {'label': '⚡ Fast & Privacy', 'icon': Icons.flash_on_rounded, 'index': 2},
      {'label': '🔒 Security & AdBlock', 'icon': Icons.shield_rounded, 'index': 3},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _categoryFilter == f['index'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _categoryFilter = f['index'] as int;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 15,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
