import 'package:recap_today/model/sync_status.dart';
import 'package:uuid/uuid.dart';

class PedometerData {
  final int? id; // Local DB ID
  final String clientTempId; // Unique client-generated ID
  String? serverId; // Server-generated ID
  final DateTime date;
  final int steps;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  DateTime? lastSynced;

  PedometerData({
    this.id,
    String? clientTempId,
    this.serverId,
    required this.date,
    required this.steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.created,
    this.lastSynced,
  }) : clientTempId = clientTempId ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'serverId': serverId,
      'date': date.toIso8601String(),
      'steps': steps,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }

  factory PedometerData.fromMap(Map<String, dynamic> map) {
    return PedometerData(
      id: map['id'],
      clientTempId: map['clientTempId'],
      serverId: map['serverId'],
      date: DateTime.parse(map['date']),
      steps: map['steps'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.created, // Default if parsing fails
      ),
      lastSynced:
          map['lastSynced'] != null ? DateTime.parse(map['lastSynced']) : null,
    );
  }

  PedometerData copyWith({
    int? id,
    String? clientTempId,
    String? serverId,
    DateTime? date,
    int? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSynced,
    bool setLastSyncedToNull = false,
  }) {
    return PedometerData(
      id: id ?? this.id,
      clientTempId: clientTempId ?? this.clientTempId,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: setLastSyncedToNull ? null : (lastSynced ?? this.lastSynced),
    );
  }

  // For sending to server, might exclude local id or adjust fields
  Map<String, dynamic> toSyncMap() {
    return {
      'clientTempId': clientTempId,
      if (serverId != null) 'serverId': serverId,
      'date': date.toIso8601String(),
      'steps': steps,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // syncStatus is managed by the sync process, not usually sent directly unless for specific cases
    };
  }
}
