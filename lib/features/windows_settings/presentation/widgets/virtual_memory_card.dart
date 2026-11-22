import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/windows_settings/data/models/virtual_memory_config.dart';

class VirtualMemoryCard extends StatefulWidget {
  final VirtualMemoryConfig? config;
  final ValueChanged<VirtualMemoryConfig> onConfigSave;
  final VoidCallback onOpenNativeVirtualMemory;

  const VirtualMemoryCard({
    super.key,
    required this.config,
    required this.onConfigSave,
    required this.onOpenNativeVirtualMemory,
  });

  @override
  State<VirtualMemoryCard> createState() => _VirtualMemoryCardState();
}

class _VirtualMemoryCardState extends State<VirtualMemoryCard> {
  late bool _isAuto;
  late final TextEditingController _initialController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _isAuto = widget.config?.isAutomaticallyManaged ?? true;
    final initial = widget.config?.initialSizeMb ?? 8192;
    final max = widget.config?.maximumSizeMb ?? 16384;
    _initialController = TextEditingController(text: initial.toString());
    _maxController = TextEditingController(text: max.toString());
  }

  @override
  void didUpdateWidget(covariant VirtualMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config && widget.config != null) {
      _isAuto = widget.config!.isAutomaticallyManaged;
      _initialController.text = widget.config!.initialSizeMb.toString();
      _maxController.text = widget.config!.maximumSizeMb.toString();
    }
  }

  @override
  void dispose() {
    _initialController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyRecommendation() {
    if (widget.config == null) return;
    setState(() {
      _isAuto = false;
      _initialController.text = widget.config!.recommendedInitialMb.toString();
      _maxController.text = widget.config!.recommendedMaximumMb.toString();
    });
  }

  void _saveSettings() {
    if (widget.config == null) return;
    final initMb = int.tryParse(_initialController.text.trim()) ?? widget.config!.recommendedInitialMb;
    final maxMb = int.tryParse(_maxController.text.trim()) ?? widget.config!.recommendedMaximumMb;

    final updated = widget.config!.copyWith(
      isAutomaticallyManaged: _isAuto,
      initialSizeMb: initMb,
      maximumSizeMb: maxMb,
    );

    widget.onConfigSave(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAuto
              ? 'Virtual memory set to Automatically Managed.'
              : 'Virtual memory set to ${initMb}MB initial / ${maxMb}MB maximum.',
        ),
        backgroundColor: Colors.green.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config ??
        const VirtualMemoryConfig(
          totalPhysicalRamMb: 16384,
          currentAllocatedMb: 8192,
        );

    final ramGb = (cfg.totalPhysicalRamMb / 1024).toStringAsFixed(1);
    final pageGb = (cfg.currentAllocatedMb / 1024).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.memory_rounded, color: Color(0xFF00897B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Virtual Memory (Paging File) Optimizer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Custom secondary disk paging allocation with Microsoft recommended ratios',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenNativeVirtualMemory,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('System Memory Dialog'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // RAM vs Virtual Memory metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricMini(
                  title: 'Installed Physical RAM',
                  value: '$ramGb GB (${cfg.totalPhysicalRamMb} MB)',
                  icon: Icons.memory_rounded,
                  color: const Color(0xFF0288D1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricMini(
                  title: 'Currently Allocated Pagefile',
                  value: '$pageGb GB (${cfg.currentAllocatedMb} MB)',
                  icon: Icons.storage_rounded,
                  color: const Color(0xFF7CB342),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recommendation Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF00897B), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expert Virtual Memory Recommendation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Initial Size: 1.5 × Physical RAM = ${cfg.recommendedInitialMb} MB\n'
                        '• Maximum Size: 3.0 × Physical RAM = ${cfg.recommendedMaximumMb} MB\n'
                        'This ratio prevents paging file fragmentation and avoids Out-Of-Memory crashes during heavy multitasking & gaming.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _applyRecommendation,
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                        label: const Text('Fill Recommended Values'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Automatic Toggle
          Row(
            children: [
              Checkbox(
                value: _isAuto,
                onChanged: (val) {
                  setState(() {
                    _isAuto = val ?? false;
                  });
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAuto = !_isAuto;
                  });
                },
                child: Text(
                  'Automatically manage paging file size for all drives',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // Custom Size Inputs (when not auto)
          if (!_isAuto) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initial Size (MB)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: TextField(
                          controller: _initialController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontFamily: 'Consolas'),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum Size (MB)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: TextField(
                          controller: _maxController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontFamily: 'Consolas'),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save Paging Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMini({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
