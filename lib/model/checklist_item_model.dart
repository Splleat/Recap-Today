import './sync_status.dart'; // Import SyncStatus

class ChecklistItem {
  String?
  id; // Nullable if server-generated, non-nullable if client-generated before sync
  String checklistId;
  String content;
  bool isCompleted;
  String clientGeneratedId; // Ensures client-side ID before sync
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;

  ChecklistItem({
    this.id,
    required this.checklistId,
    required this.content,
    this.isCompleted = false,
    required this.clientGeneratedId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.created, // Corrected default status
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      checklistId: map['checklistId'],
      content: map['content'],
      isCompleted: map['isCompleted'] == 1,
      clientGeneratedId: map['clientGeneratedId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      syncStatus: SyncStatusExtension.fromString(
        map['syncStatus'] ?? 'created',
      ), // Use fromString and provide default
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checklistId': checklistId,
      'content': content,
      'isCompleted': isCompleted ? 1 : 0,
      'clientGeneratedId': clientGeneratedId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus':
          syncStatus.toString().split('.').last, // Store string representation
    };
  }
}

// Assuming SyncStatus enum is defined elsewhere, e.g., in lib/model/sync_status.dart
// enum SyncStatus { synced, unsynced, syncing }
// For now, I\'ll add a placeholder here if it\'s not globally available.
// If it\'s in lib/model/sync_status.dart, ensure that file is imported where ChecklistItem is used.

// enum SyncStatus {
//   synced,
//   unsynced,
//   syncing,
// }
