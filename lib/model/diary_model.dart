// diary_model.dart
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/sync_status.dart'; // Added import

/// 일기 모델 클래스
class DiaryModel {
  /// 일기의 고유 ID (null이면 새로운 일기)
  final int? id;

  /// 클라이언트에서 생성된 임시 ID (서버와 동기화 전까지 사용)
  final String? clientTempId;

  /// 일기의 날짜 (YYYY-MM-DD 형식)
  final String date;

  /// 일기의 제목 (필수)
  final String title;

  /// 일기의 내용 (선택)
  final String content;

  /// 일기의 사진 경로 리스트 (선택)
  final List<String> photoPaths;

  /// 사진 모델 리스트 (선택)
  final List<Photo>? photos;

  /// 서버 동기화를 위한 ID
  final String? serverId;

  /// 마지막 동기화 시간
  final DateTime? lastSynced; // Changed to nullable

  /// 삭제 여부
  final bool isDeleted;

  /// 동기화 상태
  final SyncStatus? syncStatus; // Changed to nullable SyncStatus

  /// Diary 생성자
  DiaryModel({
    this.id,
    this.clientTempId,
    required this.date,
    required this.title,
    this.content = '',
    this.photoPaths = const [],
    this.photos,
    this.serverId,
    this.lastSynced,
    this.isDeleted = false,
    this.syncStatus,
  });

  factory DiaryModel.fromLocalMap(Map<String, dynamic> map) {
    return DiaryModel(
      id: map['id'] as int?,
      clientTempId: map['clientTempId'] as String?,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      // photoPaths are not stored directly in the diary table, they are derived from photos
      photos: [], // Photos should be loaded separately by DAO
      serverId: map['serverId'] as String?,
      lastSynced:
          map['lastSynced'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastSynced'] as int)
              : null,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      syncStatus:
          map['syncStatus'] != null
              ? SyncStatusExtension.fromString(map['syncStatus'] as String)
              : SyncStatus.created, // Default to created
    );
  }

  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      id: json['id'] as int?,
      clientTempId: json['clientTempId'] as String?,
      date: json['date'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      photoPaths:
          json['photoPaths'] != null
              ? List<String>.from(json['photoPaths'] as List<dynamic>)
              : [],
      photos:
          json['photos'] != null
              ? (json['photos'] as List<dynamic>)
                  .map(
                    (photoJson) =>
                        Photo.fromJson(photoJson as Map<String, dynamic>),
                  )
                  .toList()
              : null,
      serverId: json['serverId'] as String?,
      lastSynced:
          json['lastSynced'] != null
              ? DateTime.tryParse(json['lastSynced'] as String)
              : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      syncStatus:
          json['syncStatus'] != null
              ? SyncStatusExtension.fromString(json['syncStatus'] as String)
              : null, // If syncStatus is not in json, it might be null or default to created based on context
    );
  }

  /// `copyWith` 메서드 추가
  DiaryModel copyWith({
    int? id,
    String? clientTempId,
    String? date,
    String? title,
    String? content,
    List<String>? photoPaths,
    List<Photo>? photos,
    String? serverId,
    DateTime? lastSynced,
    bool? isDeleted,
    SyncStatus? syncStatus,
    bool clearClientTempId = false,
    bool clearServerId = false,
    bool clearLastSynced = false,
    bool clearSyncStatus = false,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      clientTempId:
          clearClientTempId ? null : (clientTempId ?? this.clientTempId),
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      photoPaths: photoPaths ?? this.photoPaths,
      photos: photos ?? this.photos,
      serverId: clearServerId ? null : (serverId ?? this.serverId),
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
    );
  }

  /// Map으로 변환 (데이터베이스 저장용 - 사진 경로 제외)
  Map<String, dynamic> toMapWithoutPhotos() {
    return {
      'id': id,
      'clientTempId': clientTempId, // Added clientTempId
      'date': date,
      'title': title,
      'content': content,
      'serverId': serverId,
      'lastSynced': lastSynced?.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'syncStatus': syncStatus?.name, // Added syncStatus
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'date': date,
      'title': title,
      'content': content,
      'photoPaths': photoPaths,
      'photos': photos?.map((p) => p.toJson()).toList(),
      'serverId': serverId,
      'lastSynced': lastSynced?.toIso8601String(),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus?.name,
    };
  }

  /// Map으로 변환 (데이터베이스 저장용 - 기존 toMap은 toMapWithoutPhotos로 변경)
  Map<String, dynamic> toMap() {
    // In the future, if photoPaths are stored in a separate table linked by diaryId,
    // this method might be adjusted. For now, it mirrors toMapWithoutPhotos.
    return toMapWithoutPhotos();
  }

  /// Map으로부터 Diary 객체 생성 (로컬 DB용)
  static DiaryModel fromMap(Map<String, dynamic> map) {
    SyncStatus? status;
    if (map['syncStatus'] != null) {
      status = SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.created, // Default if parsing fails
      );
    } else {
      // Legacy or new data handling
      if (map['isDeleted'] == 1) {
        status = SyncStatus.deleted;
      } else if (map['serverId'] != null) {
        status =
            SyncStatus
                .synced; // Assume synced if serverId exists and not deleted
      } else {
        status = SyncStatus.created; // Default for new local entries
      }
    }

    return DiaryModel(
      id: map['id'] as int?, // Ensure it's nullable
      clientTempId: map['clientTempId'] as String?,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '', // Ensure content is not null
      photoPaths: [],
      photos: [],
      serverId: map['serverId'] as String?,
      lastSynced:
          map['lastSynced'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastSynced'] as int)
              : null, // Changed to null if not present
      isDeleted: map['isDeleted'] == 1,
      syncStatus: status,
    );
  }

  /// Map으로 변환 (서버 동기화용)
  Map<String, dynamic> toSyncMap() {
    return {
      'clientTempId': clientTempId,
      'serverId': serverId,
      'date': date,
      'title': title,
      'content': content,
      'isDeleted': isDeleted,
      'photos':
          photos
              ?.map((p) => p.toMapForSync(this.id ?? 0))
              .toList() ?? // Pass diary's local id or 0 as placeholder
          [],
      'syncStatus': syncStatus?.name, // Use name for string representation
      'lastSynced':
          lastSynced?.toIso8601String(), // Added lastSynced for server
      // 'updatedAt' equivalent for server would be lastSynced or a dedicated server-side timestamp
    };
  }

  /// 서버 응답 Map으로부터 Diary 객체 생성 (동기화용)
  static DiaryModel fromMapForSync(Map<String, dynamic> map) {
    List<Photo> photoList = [];
    if (map['photos'] != null && map['photos'] is List) {
      photoList =
          (map['photos'] as List)
              .map(
                (photoMap) => Photo.fromMapForSync(
                  photoMap as Map<String, dynamic>,
                  0,
                ), // 변경됨: 두 번째 인자로 0 추가
              )
              .toList();
    }

    // Determine syncStatus from server data if available, otherwise default to synced
    SyncStatus status = SyncStatus.synced; // Default for data from server
    if (map['syncStatus'] != null && map['syncStatus'] is String) {
      try {
        status = SyncStatus.values.firstWhere(
          (e) => e.name == map['syncStatus'],
        );
      } catch (e) {
        // If parsing fails, keep default or log error
        print("Failed to parse syncStatus from server: ${map['syncStatus']}");
      }
    } else if (map['isDeleted'] == true || map['isDeleted'] == 1) {
      status = SyncStatus.deleted; // If marked deleted by server, reflect that
    }

    return DiaryModel(
      // id is local, serverId is what matters from server
      clientTempId: map['clientTempId'] as String?,
      serverId:
          map['id'] as String? ??
          map['serverId']
              as String?, // Prefer 'id' from server as serverId, fallback to 'serverId'
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      photos: photoList,
      lastSynced: // Prefer 'lastSynced', then 'updatedAt' from server
          map['lastSynced'] != null
              ? DateTime.tryParse(map['lastSynced'] as String)
              : (map['updatedAt'] != null
                  ? DateTime.tryParse(map['updatedAt'] as String)
                  : null),
      isDeleted:
          map['isDeleted'] == true ||
          map['isDeleted'] == 1, // Handle boolean or int
      syncStatus: status,
    );
  }
}
