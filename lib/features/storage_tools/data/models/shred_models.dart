/// Shred algorithm / pass count options.
enum ShredAlgorithm {
  single,   // 1-pass random (fast)
  standard, // 3-pass (zeros, ones, random)
  dod,      // 7-pass DoD 5220.22-M
  gutmann,  // 35-pass Gutmann
}

extension ShredAlgorithmExt on ShredAlgorithm {
  String get displayName => switch (this) {
        ShredAlgorithm.single   => '1-Pass  (Fast)',
        ShredAlgorithm.standard => '3-Pass  (Standard)',
        ShredAlgorithm.dod      => '7-Pass  (DoD 5220.22-M)',
        ShredAlgorithm.gutmann  => '35-Pass (Gutmann)',
      };

  int get passes => switch (this) {
        ShredAlgorithm.single   => 1,
        ShredAlgorithm.standard => 3,
        ShredAlgorithm.dod      => 7,
        ShredAlgorithm.gutmann  => 35,
      };

  String get description => switch (this) {
        ShredAlgorithm.single   => 'Random data overwrite — good for SSDs',
        ShredAlgorithm.standard => 'Zeros, ones, random — suitable for most uses',
        ShredAlgorithm.dod      => 'US Department of Defense standard',
        ShredAlgorithm.gutmann  => 'Maximum security — 35-pass overwrite',
      };
}

/// Result for a single shredded file.
class ShredFileResult {
  final String path;
  final bool success;
  final String? errorMessage;
  final int passes;
  const ShredFileResult({
    required this.path,
    required this.success,
    required this.passes,
    this.errorMessage,
  });
}

/// Overall shred session result.
class ShredResult {
  final List<ShredFileResult> fileResults;
  int get successCount => fileResults.where((r) => r.success).length;
  int get failCount    => fileResults.where((r) => !r.success).length;
  const ShredResult({required this.fileResults});
}
