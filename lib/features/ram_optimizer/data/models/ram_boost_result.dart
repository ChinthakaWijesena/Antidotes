import 'ram_optimize_options.dart';

/// Result returned after a RAM optimisation boost operation.
class RamBoostResult {
  /// Total physical RAM in MB.
  final int totalRamMb;

  /// RAM used before the boost (MB).
  final int usedBeforeMb;

  /// RAM used after the boost (MB). 0 when optimisation did not complete.
  final int usedAfterMb;

  /// MB freed by the boost.
  int get freedMb => (usedBeforeMb - usedAfterMb).clamp(0, usedBeforeMb);

  /// True when the boost run completed without error.
  final bool success;

  /// Human-readable error message if [success] is false.
  final String? errorMessage;

  /// Per-operation result details: operation → result message.
  final Map<RamOperation, String> operationResults;

  const RamBoostResult({
    required this.totalRamMb,
    required this.usedBeforeMb,
    required this.usedAfterMb,
    required this.success,
    this.errorMessage,
    this.operationResults = const {},
  });

  /// Convenience factory for a failed result.
  factory RamBoostResult.failed({
    required int totalRamMb,
    required int usedBeforeMb,
    required String errorMessage,
  }) {
    return RamBoostResult(
      totalRamMb: totalRamMb,
      usedBeforeMb: usedBeforeMb,
      usedAfterMb: usedBeforeMb,
      success: false,
      errorMessage: errorMessage,
    );
  }
}
