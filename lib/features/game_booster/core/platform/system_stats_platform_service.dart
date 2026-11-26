import '../../data/models/boost_stats_model.dart';

/// Abstract contract for reading real-time system performance statistics (CPU, RAM, GPU).
abstract class SystemStatsPlatformService {
  /// Reads a current snapshot of CPU %, RAM %, and GPU % (if available).
  Future<BoostStats> getLiveStats();
}
