import 'package:recap_today/model/sync_status.dart'; // Added import

class EmotionRecord {
  final String?
  id; // Changed to String to support UUID or other string-based IDs if needed, and nullable for new records
  final String? serverId; // Added for synchronization
  final String date; // YYYY-MM-DD format
  final int hour; // 0-23
  final String emotionType; // e.g., "Happy", "Sad", "Neutral"
  final String? notes; // Optional notes for the emotion
  DateTime? lastSynced;
  bool isDeleted;
  SyncStatus?
  syncStatus; // Allowed values: 'synced', 'created', 'updated', 'deleted' // Changed to SyncStatus enum
  DateTime? updatedAt; // Tracks local modification time for sync comparison

  EmotionRecord({
    this.id,
    this.serverId, // Added serverId
    required this.date,
    required this.hour,
    required this.emotionType,
    this.notes,
    this.lastSynced,
    this.isDeleted = false,
    this.syncStatus, // Default to null, implying new or unknown
    this.updatedAt,
  });

  // Method to convert EmotionRecord to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serverId': serverId, // Added serverId
      'date': date,
      'hour': hour,
      'emotionType': emotionType,
      'notes': notes,
      'lastSynced': lastSynced?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'syncStatus': syncStatus?.name, // Store enum name as string
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Method to create an EmotionRecord from a Map (from database)
  factory EmotionRecord.fromMap(Map<String, dynamic> map) {
    return EmotionRecord(
      id: map['id'] as String?,
      serverId: map['serverId'] as String?, // Added serverId
      date: map['date'] as String,
      hour: map['hour'] as int,
      emotionType: map['emotionType'] as String,
      notes: map['notes'] as String?,
      lastSynced:
          map['lastSynced'] == null
              ? null
              : DateTime.tryParse(map['lastSynced'] as String),
      isDeleted: map['isDeleted'] == null ? false : (map['isDeleted'] == 1),
      syncStatus:
          map['syncStatus'] == null
              ? null
              : SyncStatus.values.firstWhere(
                (e) => e.name == map['syncStatus'],
                orElse: () => SyncStatus.created,
              ), // Parse string to enum, changed pending to created
      updatedAt:
          map['updatedAt'] == null
              ? null
              : DateTime.tryParse(map['updatedAt'] as String),
    );
  }

  EmotionRecord copyWith({
    String? id,
    String? serverId, // Added serverId
    String? date,
    int? hour,
    String? emotionType,
    String? notes,
    DateTime? lastSynced,
    bool? isDeleted,
    SyncStatus? syncStatus, // Changed to SyncStatus enum
    DateTime? updatedAt,
    bool clearId = false, // ID를 명시적으로 null로 설정
    bool clearNotes = false, // Notes를 명시적으로 null로 설정
    bool clearLastSynced = false,
    bool clearSyncStatus = false,
    bool clearUpdatedAt = false,
  }) {
    return EmotionRecord(
      id: clearId ? null : (id ?? this.id),
      serverId: serverId ?? this.serverId, // Added serverId
      date: date ?? this.date,
      hour: hour ?? this.hour,
      emotionType: emotionType ?? this.emotionType,
      notes: clearNotes ? null : (notes ?? this.notes),
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }

  Map<String, dynamic> toSyncMap() {
    return {
      'id': id, // Or clientTempId if that's preferred for initial sync
      'serverId':
          serverId, // Assuming id is serverId after first sync, or map explicitly
      'date': date,
      'hour': hour,
      'emotionType': emotionType,
      'notes': notes,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus?.name,
      'updatedAt': updatedAt?.toIso8601String(),
      // 'lastSynced' could be an alias for 'updatedAt' in this context
    };
  }
}
