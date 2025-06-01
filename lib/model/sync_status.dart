enum SyncStatus {
  synced, // Data is synced with the server
  created, // Data is newly created locally, not yet on server
  updated, // Data is updated locally, needs to be synced
  deleted, // Data is deleted locally, needs to be marked as deleted on server
}

extension SyncStatusExtension on SyncStatus {
  static SyncStatus fromString(String status) {
    return SyncStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
      orElse:
          () =>
              SyncStatus
                  .created, // Default to created if status is not recognized
    );
  }
}
