class VirtualMemoryConfig {
  final int totalPhysicalRamMb;
  final int currentAllocatedMb;
  final bool isAutomaticallyManaged;
  final int initialSizeMb;
  final int maximumSizeMb;
  final String driveLetter;

  const VirtualMemoryConfig({
    required this.totalPhysicalRamMb,
    required this.currentAllocatedMb,
    this.isAutomaticallyManaged = true,
    this.initialSizeMb = 0,
    this.maximumSizeMb = 0,
    this.driveLetter = 'C:',
  });

  /// Recommended Initial Size = 1.5 x Physical RAM
  int get recommendedInitialMb => (totalPhysicalRamMb * 1.5).round();

  /// Recommended Maximum Size = 3.0 x Physical RAM (capped at reasonable max for high RAM)
  int get recommendedMaximumMb {
    if (totalPhysicalRamMb >= 32768) {
      return (totalPhysicalRamMb * 1.5).round();
    }
    return (totalPhysicalRamMb * 3.0).round();
  }

  VirtualMemoryConfig copyWith({
    int? totalPhysicalRamMb,
    int? currentAllocatedMb,
    bool? isAutomaticallyManaged,
    int? initialSizeMb,
    int? maximumSizeMb,
    String? driveLetter,
  }) {
    return VirtualMemoryConfig(
      totalPhysicalRamMb: totalPhysicalRamMb ?? this.totalPhysicalRamMb,
      currentAllocatedMb: currentAllocatedMb ?? this.currentAllocatedMb,
      isAutomaticallyManaged: isAutomaticallyManaged ?? this.isAutomaticallyManaged,
      initialSizeMb: initialSizeMb ?? this.initialSizeMb,
      maximumSizeMb: maximumSizeMb ?? this.maximumSizeMb,
      driveLetter: driveLetter ?? this.driveLetter,
    );
  }
}

