enum DeletionStatus {
  deleted,
  recycled,
  skippedLocked,
  skippedPermission,
  failed,
}

class DeletionLogEntry {
  final DateTime timestamp;
  final String filePath;
  final int sizeInBytes;
  final DeletionStatus status;
  final String? errorMessage;

  const DeletionLogEntry({
    required this.timestamp,
    required this.filePath,
    required this.sizeInBytes,
    required this.status,
    this.errorMessage,
  });
}
