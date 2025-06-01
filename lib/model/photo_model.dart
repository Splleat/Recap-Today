// photo_model.dart
import 'package:recap_today/model/sync_status.dart'; // Added import

/// 사진 모델 클래스
class Photo {
  /// 사진의 고유 ID
  final int? id;

  /// 클라이언트에서 생성된 임시 ID
  final String? clientTempId;

  /// 사진이 속한 일기의 ID (로컬 DB의 diary.id 참조)
  final int diaryId; // This refers to the local DB's diary.id

  /// 사진 파일 경로
  final String path;

  /// 사진 캡션
  final String? caption; // Added caption field

  /// 서버 동기화를 위한 ID
  final String? serverId;

  /// 생성 시간
  final DateTime createdAt;

  /// 수정 시간
  final DateTime updatedAt;

  /// 마지막 동기화 시간
  final DateTime? lastSynced; // Made nullable

  /// 삭제 여부
  final bool isDeleted;

  /// 동기화 상태
  final SyncStatus syncStatus;

  /// Photo 생성자
  Photo({
    this.id,
    this.clientTempId,
    required this.diaryId, // This still refers to local diary_id for local DB operations
    required this.path,
    this.caption,
    this.serverId,
    DateTime? createdAt, // Added createdAt
    DateTime? updatedAt, // Added updatedAt
    this.lastSynced, // Nullable
    this.isDeleted = false,
    this.syncStatus = SyncStatus.created, // Default to created
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// `copyWith` 메서드 추가
  Photo copyWith({
    int? id,
    String? clientTempId,
    int? diaryId,
    String? path,
    String? caption,
    String? serverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSynced,
    bool? isDeleted,
    SyncStatus? syncStatus, // Added syncStatus
  }) {
    return Photo(
      id: id ?? this.id,
      clientTempId: clientTempId ?? this.clientTempId,
      diaryId: diaryId ?? this.diaryId,
      path: path ?? this.path,
      caption: caption ?? this.caption,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSynced: lastSynced ?? this.lastSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus, // Added syncStatus
    );
  }

  /// Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_temp_id': clientTempId, // Added clientTempId
      'diary_id': diaryId,
      'path': path,
      'caption': caption,
      'server_id': serverId, // Changed from serverId
      'created_at': createdAt.millisecondsSinceEpoch, // Added createdAt
      'updated_at': updatedAt.millisecondsSinceEpoch, // Added updatedAt
      'last_synced':
          lastSynced
              ?.millisecondsSinceEpoch, // Changed from lastSynced, nullable
      'is_deleted': isDeleted ? 1 : 0, // Changed from isDeleted
      'sync_status': syncStatus.name, // Store enum name as string
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      clientTempId: map['client_temp_id'] as String?,
      diaryId: map['diary_id'] as int,
      path: map['path'] as String,
      caption: map['caption'] as String?,
      serverId: map['server_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lastSynced:
          map['last_synced'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_synced'] as int)
              : null,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      syncStatus: SyncStatusExtension.fromString(
        map['sync_status'] as String? ?? 'created',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'diaryId':
          diaryId, // Note: For server, this might need to be diaryServerId
      'path': path,
      'caption': caption,
      'serverId': serverId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.name,
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int?,
      clientTempId: json['clientTempId'] as String?,
      // diaryId is tricky for fromJson if it refers to a server diary ID
      // Assuming diaryId in JSON is the local one if present, or needs to be set post-creation
      diaryId: json['diaryId'] as int? ?? 0, // Default or handle if missing
      path: json['path'] as String,
      caption: json['caption'] as String?,
      serverId: json['serverId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSynced:
          json['lastSynced'] != null
              ? DateTime.tryParse(json['lastSynced'] as String)
              : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      syncStatus:
          json['syncStatus'] != null
              ? SyncStatusExtension.fromString(json['syncStatus'] as String)
              : SyncStatus.created,
    );
  }

  /// 서버 동기화용 Map 변환 메서드
  Map<String, dynamic> toMapForSync(int diaryId) {
    return {
      'clientTempId': clientTempId,
      'serverId': serverId,
      'path': path,
      'caption': caption,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }

  /// SyncService에서 사용하는 동기화용 Map 변환 메서드
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'serverId': serverId,
      'path': path,
      'caption': caption,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }

  /// 서버 동기화 응답으로부터 Photo 객체 생성
  static Photo fromMapForSync(Map<String, dynamic> map, int localDiaryId) {
    return Photo(
      id: null, // New photos from sync don't have local ID yet
      clientTempId: map['clientTempId'] as String?,
      diaryId: localDiaryId, // Use provided local diary ID
      path: map['path'] as String,
      caption: map['caption'] as String?,
      serverId: map['serverId'] as String?,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      lastSynced: map['lastSynced'] != null
          ? DateTime.parse(map['lastSynced'] as String)
          : null,
      isDeleted: map['isDeleted'] as bool? ?? false,
      syncStatus: map['syncStatus'] != null
          ? SyncStatusExtension.fromString(map['syncStatus'] as String)
          : SyncStatus.synced, // Default for data from server
    );
  }
}
