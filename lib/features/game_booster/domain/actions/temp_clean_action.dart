import 'dart:io';
import 'boost_action.dart';

/// Cleans residual temporary files in `%TEMP%` to eliminate disk I/O bottlenecks.
/// Architectural rule: This is irreversible and optional.
class TempCleanAction implements BoostAction {
  @override
  String get name => 'Clean Temporary Files';

  @override
  Future<void> apply(BoostContext context) async {
    if (!context.game.cleanTemp) return;

    try {
      final tempPath = Directory.systemTemp.path;
      final tempDir = Directory(tempPath);
      if (await tempDir.exists()) {
        final now = DateTime.now();
        // 24-hour safety guard from Antidotes safety rules
        await for (final entity in tempDir.list(followLinks: false)) {
          try {
            final stat = await entity.stat();
            if (now.difference(stat.modified).inHours >= 24) {
              await entity.delete(recursive: true);
            }
          } catch (_) {
            // Locked or in-use files safely skipped
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> revert(BoostContext context) async {
    // Temp cleaning is permanent and cannot be reverted.
  }
}
