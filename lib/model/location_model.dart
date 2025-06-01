import 'package:recap_today/model/sync_status.dart';

/// 위치 정보를 담는 모델 클래스
class LocationRecord {
  final String? id; // Changed to nullable
  final String? clientTempId; // Added for client-side ID management
  final String? serverId; // Added for server-side ID management
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  DateTime? lastSynced; // Made non-final
  bool isDeleted; // Made non-final
  SyncStatus? syncStatus; // Changed to SyncStatus enum
  DateTime? updatedAt; // Added to track local modifications

  LocationRecord({
    this.id,
    this.clientTempId,
    this.serverId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.lastSynced,
    this.isDeleted = false,
    this.syncStatus,
    this.updatedAt,
  });

  /// JSON에서 LocationRecord 객체 생성 (주로 서버 응답 처리용)
  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      // id: json['id'] as String?, // Prefer serverId from sync operations
      clientTempId: json['clientTempId'] as String?,
      serverId: json['id'] as String?, // Server's ID is mapped to serverId
      userId: json['userId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      lastSynced:
          json['lastSynced'] == null
              ? null
              : DateTime.parse(json['lastSynced'] as String),
      isDeleted: json['isDeleted'] == null ? false : json['isDeleted'] as bool,
      syncStatus:
          json['syncStatus'] == null
              ? (json['id'] != null ? SyncStatus.synced : null)
              : SyncStatus.values.firstWhere(
                (e) => e.name == json['syncStatus'],
                orElse:
                    () => SyncStatus.created, // Default if string doesn't match
              ),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// LocationRecord 객체를 JSON으로 변환 (주로 서버 요청용)
  Map<String, dynamic> toJson() {
    return {
      'clientTempId': clientTempId,
      'id': serverId, // Send serverId as 'id' to the backend
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus?.name, // Store enum name as string
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 데이터베이스에서 LocationRecord 객체 생성
  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'] as String?,
      clientTempId: map['clientTempId'] as String?,
      serverId: map['serverId'] as String?,
      userId: map['userId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      lastSynced:
          map['lastSynced'] == null
              ? null
              : DateTime.parse(map['lastSynced'] as String),
      isDeleted: map['isDeleted'] == 1,
      syncStatus:
          map['syncStatus'] == null
              ? null
              : SyncStatus.values.firstWhere(
                (e) => e.name == map['syncStatus'],
                orElse:
                    () => SyncStatus.created, // Default if string doesn't match
              ),
      updatedAt:
          map['updatedAt'] == null
              ? null
              : DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// LocationRecord 객체를 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Local DB primary key
      'clientTempId': clientTempId,
      'serverId': serverId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'syncStatus': syncStatus?.name, // Store enum name as string
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  LocationRecord copyWith({
    String? id,
    String? clientTempId,
    String? serverId,
    String? userId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    DateTime? lastSynced,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return LocationRecord(
      id: id ?? this.id,
      clientTempId: clientTempId ?? this.clientTempId,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      lastSynced: lastSynced ?? this.lastSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toSyncMap() {
    return toJson(); // toJson is already suitable for sync
  }
}

/// 하루 동안의 위치 데이터를 담는 클래스
class DailyLocationData {
  final String date;
  final List<LocationRecord> locations;

  DailyLocationData({required this.date, required this.locations});

  /// JSON에서 DailyLocationData 객체 생성
  factory DailyLocationData.fromJson(Map<String, dynamic> json) {
    final locationsList = json['locations'] as List;
    final locations =
        locationsList
            .map((locationJson) => LocationRecord.fromJson(locationJson))
            .toList();

    return DailyLocationData(
      date: json['date'] as String,
      locations: locations,
    );
  }

  /// DailyLocationData 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'locations': locations.map((location) => location.toJson()).toList(),
    };
  }
}
