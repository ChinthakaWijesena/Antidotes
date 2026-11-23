import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/speed_test_controller.dart';
import '../widgets/connection_info_card.dart';
import '../widgets/speed_gauge_card.dart';
import '../widgets/speed_metric_card.dart';

/// Full-page screen offering live internet bandwidth speed tests, ping and jitter analysis.
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  late final SpeedTestController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpeedTestController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (responsive)
                LayoutBuilder(
                  builder: (context, hdrConstraints) {
                    final hdrNarrow = hdrConstraints.maxWidth < 600;
                    final titleSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            Icons.speed_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Internet Speed Test',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Real-time network throughput, latency, jitter and ISP performance analysis',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final statusBadge = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _controller.isTesting
                            ? const Color(0xFFFF9100).withValues(alpha: 0.12)
                            : const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _controller.isTesting
                              ? const Color(0xFFFF9100).withValues(alpha: 0.4)
                              : const Color(0xFF00E676).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _controller.isTesting
                                  ? const Color(0xFFFF9100)
                                  : const Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _controller.isTesting ? 'TESTING...' : 'ONLINE',
                            style: TextStyle(
                              color: _controller.isTesting
                                  ? const Color(0xFFFF9100)
                                  : const Color(0xFF00E676),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (hdrNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleSection,
                          const SizedBox(height: 10),
                          statusBadge,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 12),
                        statusBadge,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Main Test Row: Gauge on Left, Metrics on Right (responsive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;

                    final gaugeCard = SpeedGaugeCard(
                      currentSpeed: _controller.liveSpeed,
                      phase: _controller.phase,
                      progress: _controller.progress,
                      remainingSeconds: _controller.remainingSeconds,
                      onStart: _controller.startTest,
                      onCancel: _controller.cancelTest,
                    );

                    final progressCard = Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Test Progress',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_controller.progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _controller.progress,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );

                    final metricsSection = Column(
                      children: [
                        SpeedMetricsGrid(
                          result: _controller.lastResult,
                          currentLiveSpeed: _controller.liveSpeed,
                          phase: _controller.phase,
                        ),
                        const SizedBox(height: 16),
                        progressCard,
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gaugeCard,
                          const SizedBox(height: 16),
                          metricsSection,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 290, child: gaugeCard),
                        const SizedBox(width: 20),
                        Expanded(child: metricsSection),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Network & ISP Capabilities Card
                ConnectionInfoCard(
                  meta: _controller.meta,
                  lastResult: _controller.lastResult,
                  history: _controller.sessionHistory,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
