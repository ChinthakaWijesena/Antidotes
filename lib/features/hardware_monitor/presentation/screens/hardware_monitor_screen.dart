import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../controllers/hardware_monitor_controller.dart';
import '../widgets/hardware_components_cards.dart';

class HardwareMonitorScreen extends StatefulWidget {
  const HardwareMonitorScreen({super.key});

  @override
  State<HardwareMonitorScreen> createState() => _HardwareMonitorScreenState();
}

class _HardwareMonitorScreenState extends State<HardwareMonitorScreen> {
  late final HardwareMonitorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HardwareMonitorController();
    _controller.addListener(_onUpdate);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final snapshot = _controller.currentSnapshot;

    return Scaffold(
      body: SafeArea(
        child: snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Grid of Live Cards: CPU & RAM
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CpuMonitorCard(
                            cpu: snapshot.cpu,
                            history: _controller.cpuHistory,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: RamMonitorCard(
                            ram: snapshot.ram,
                            history: _controller.ramHistory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid of Live Cards: GPU & Fan Speed (Cooling)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GpuMonitorCard(gpu: snapshot.gpu),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: FanSpeedMonitorCard(
                            fan: snapshot.fan,
                            history: _controller.fanHistory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid of Live Cards: Battery & Network
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: BatteryMonitorCard(battery: snapshot.battery),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: NetworkMonitorCard(network: snapshot.network),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Live Card: Storage Drives
                    StorageMonitorCard(storage: snapshot.storage),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.monitor_heart_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware Monitor',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live real-time telemetry: CPU, GPU, Memory, Thermals, Battery & Network',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Controls (Live Pulse & Pause/Resume)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _controller.isLive
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _controller.isLive
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.isLive
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _controller.isLive ? 'LIVE (1s)' : 'PAUSED',
                    style: TextStyle(
                      color: _controller.isLive
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: _controller.isLive ? 'Pause Live Telemetry' : 'Resume Live Telemetry',
              onPressed: () => _controller.toggleLive(),
              icon: Icon(
                _controller.isLive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
