import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:recap_today/model/sync_status.dart'; // Import existing SyncStatus

class ScheduleItem {
  final String id;
  String text; // 일정 이름
  String? subText; // 일정의 세부 정보
  int? dayOfWeek; // 요일
  DateTime? selectedDate; // 날짜
  bool isRoutine; // 루틴 일정 / 사용자 일정 (반복 / 일회성)
  TimeOfDay startTime; // 시작 시간
  TimeOfDay endTime; // 종료 시간
  Color? color; // 일정 색상
  bool? hasAlarm; // 알림 설정 여부
  Duration? alarmOffset; // 알림 시간 간격

  // Fields for database storage and server synchronization
  DateTime? lastModified;
  bool isSynced;
  String? serverId;

  // New sync-related fields
  String? clientTempId; // To track items created offline before first sync
  SyncStatus syncStatus; // More detailed sync status
  DateTime?
  updatedAt; // Tracks the last update time, crucial for conflict resolution
  DateTime? createdAt; // Tracks the creation time
  DateTime? lastSynced; // Tracks the last sync time with server

  /// 신규 일정 생성 시 사용하는 생성자
  /// ID는 자동 생성됩니다
  ScheduleItem.create({
    required this.text,
    this.subText,
    this.dayOfWeek,
    this.selectedDate,
    required this.isRoutine,
    required this.startTime,
    required this.endTime,
    this.color = Colors.lightBlueAccent,
    this.hasAlarm = false,
    this.alarmOffset = const Duration(hours: 1),
    this.lastModified, // Will be deprecated
    this.isSynced = false, // Will be deprecated by syncStatus
    this.serverId,
    this.syncStatus = SyncStatus.created, // Default for new items
    this.lastSynced,
  }) : id = const Uuid().v4(),
       clientTempId = const Uuid().v4(),
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  /// 기존 일정을 위한 생성자
  ScheduleItem({
    required this.id,
    required this.text,
    this.subText,
    this.dayOfWeek,
    this.selectedDate,
    required this.isRoutine,
    required this.startTime,
    required this.endTime,
    this.color = Colors.lightBlueAccent,
    this.hasAlarm = false,
    this.alarmOffset = const Duration(hours: 1),
    this.lastModified, // Will be deprecated by updatedAt
    this.isSynced = false, // Will be deprecated by syncStatus
    this.serverId,
    this.clientTempId,
    this.syncStatus =
        SyncStatus
            .synced, // Default for existing items from DB (assume synced if no status)
    this.updatedAt,
    this.createdAt,
    this.lastSynced,
  });

  ScheduleItem copyWith({
    String? id,
    String? text,
    String? subText,
    int? dayOfWeek,
    DateTime? date, // Changed from selectedDate to date to match usage
    bool? isRoutine,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
    bool? hasAlarm,
    Duration? alarmOffset,
    DateTime? lastModified, // Will be deprecated
    bool? isSynced, // Will be deprecated
    String? serverId,
    String? clientTempId,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? lastSynced,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      selectedDate: date ?? this.selectedDate,
      isRoutine: isRoutine ?? this.isRoutine,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmOffset: alarmOffset ?? this.alarmOffset,
      lastModified: lastModified ?? this.lastModified, // Keep for now
      isSynced: isSynced ?? this.isSynced, // Keep for now
      serverId: serverId ?? this.serverId,
      clientTempId: clientTempId ?? this.clientTempId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  // SQLite를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'subText': subText,
      'dayOfWeek': dayOfWeek,
      'selectedDate': selectedDate?.toIso8601String(),
      'isRoutine': isRoutine ? 1 : 0,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'colorValue': color?.value,
      'hasAlarm': hasAlarm == true ? 1 : 0,
      'alarmOffsetInMinutes': alarmOffset?.inMinutes,
      'lastModified': updatedAt?.toIso8601String(), // Use updatedAt
      'isSynced': syncStatus == SyncStatus.synced ? 1 : 0, // Reflect syncStatus
      'serverId': serverId,
      'clientTempId': clientTempId,
      'syncStatus': syncStatus.name, // Store enum name
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }

  // Map에서 객체 생성을 위한 팩토리 메서드
  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    DateTime? date;
    if (map['selectedDate'] != null) {
      try {
        date = DateTime.parse(map['selectedDate']);
      } catch (e) {
        // Handle or log parsing error if necessary
        if (kDebugMode) {
          print('Error parsing selectedDate: ${map['selectedDate']}');
        }
        date = null;
      }
    }

    DateTime? lastModifiedDate;
    // Prioritize 'updatedAt' over 'lastModified' for backward compatibility
    String? dateStringForUpdate = map['updatedAt'] ?? map['lastModified'];
    if (dateStringForUpdate != null) {
      try {
        lastModifiedDate = DateTime.parse(dateStringForUpdate);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing updatedAt/lastModified: $dateStringForUpdate');
        }
        lastModifiedDate = null;
      }
    }

    DateTime? createdTimestamp;
    if (map['createdAt'] != null) {
      try {
        createdTimestamp = DateTime.parse(map['createdAt']);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing createdAt: ${map['createdAt']}');
        }
        createdTimestamp = null;
      }
    }

    DateTime? lastSyncTimestamp;
    if (map['lastSynced'] != null) {
      try {
        lastSyncTimestamp = DateTime.parse(map['lastSynced']);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing lastSynced: ${map['lastSynced']}');
        }
        lastSyncTimestamp = null;
      }
    }

    SyncStatus currentSyncStatus;
    if (map['syncStatus'] != null &&
        SyncStatus.values.any((e) => e.name == map['syncStatus'])) {
      currentSyncStatus = SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
      );
    } else {
      // Fallback for older records or if syncStatus is missing/invalid
      currentSyncStatus =
          (map['isSynced'] != null && (map['isSynced'] as int) == 1)
              ? SyncStatus.synced
              : SyncStatus
                  .created; // Or .modified if appropriate based on other fields
    }

    return ScheduleItem(
      id: map['id'] as String,
      text: map['text'] as String,
      subText: map['subText'] as String?,
      dayOfWeek: map['dayOfWeek'] as int?,
      selectedDate: date,
      isRoutine: (map['isRoutine'] as int) == 1,
      startTime: TimeOfDay(
        hour: map['startTimeHour'] as int,
        minute: map['startTimeMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] as int,
        minute: map['endTimeMinute'] as int,
      ),
      color: map['colorValue'] != null ? Color(map['colorValue'] as int) : null,
      hasAlarm: map['hasAlarm'] != null ? (map['hasAlarm'] as int) == 1 : false,
      alarmOffset:
          map['alarmOffsetInMinutes'] != null
              ? Duration(minutes: map['alarmOffsetInMinutes'] as int)
              : null,
      lastModified:
          lastModifiedDate, // Keep for backward compatibility if needed by other parts
      isSynced: currentSyncStatus == SyncStatus.synced, // Reflect syncStatus
      serverId: map['serverId'] as String?,
      clientTempId: map['clientTempId'] as String?,
      syncStatus: currentSyncStatus,
      updatedAt: lastModifiedDate, // Use the parsed date for updatedAt
      createdAt: createdTimestamp,
      lastSynced: lastSyncTimestamp,
    );
  }

  /// For data synchronization payload
  Map<String, dynamic> toSyncMap() {
    return {
      'clientTempId': clientTempId ?? id, // Ensure clientTempId is present
      'serverId': serverId,
      'text': text,
      'subText': subText,
      'dayOfWeek': dayOfWeek,
      'selectedDate': selectedDate?.toIso8601String(),
      'isRoutine': isRoutine,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'colorValue': color?.value,
      'hasAlarm': hasAlarm,
      'alarmOffsetInMinutes': alarmOffset?.inMinutes,
      'syncStatus': syncStatus.name,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      // 'isDeleted' will be handled by syncStatus = SyncStatus.deleted
    };
  }

  // Factory method to create from sync payload (from server)
  factory ScheduleItem.fromSyncMap(Map<String, dynamic> map) {
    DateTime? date;
    if (map['selectedDate'] != null) {
      try {
        date = DateTime.parse(map['selectedDate']);
      } catch (e) {
        if (kDebugMode) {
          print(
            'Error parsing selectedDate fromSyncMap: ${map['selectedDate']}',
          );
        }
        date = null;
      }
    }
    DateTime? updatedTimestamp;
    if (map['updatedAt'] != null) {
      try {
        updatedTimestamp = DateTime.parse(map['updatedAt']);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing updatedAt fromSyncMap: ${map['updatedAt']}');
        }
        updatedTimestamp = null;
      }
    }

    DateTime? createdTimestamp;
    if (map['createdAt'] != null) {
      try {
        createdTimestamp = DateTime.parse(map['createdAt']);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing createdAt fromSyncMap: ${map['createdAt']}');
        }
        createdTimestamp = null;
      }
    }

    DateTime? lastSyncTimestamp;
    if (map['lastSynced'] != null) {
      try {
        lastSyncTimestamp = DateTime.parse(map['lastSynced']);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing lastSynced fromSyncMap: ${map['lastSynced']}');
        }
        lastSyncTimestamp = null;
      }
    }

    SyncStatus status = SyncStatus.values.firstWhere(
      (e) => e.name == map['syncStatus'],
      orElse:
          () =>
              SyncStatus
                  .created, // Default if status string is invalid (changed to created as failed/unknown not defined)
    );

    // If serverId is present, it's the definitive ID.
    // clientTempId from server helps match with local item if it was newly created offline.
    String localId =
        map['clientTempId'] ??
        const Uuid().v4(); // Fallback if clientTempId is missing

    return ScheduleItem(
      id: map['serverId'] ?? localId, // Prioritize serverId for the main ID
      clientTempId:
          map['clientTempId'] as String?, // Store server's view of clientTempId
      serverId: map['serverId'] as String?,
      text: map['text'] as String,
      subText: map['subText'] as String?,
      dayOfWeek: map['dayOfWeek'] as int?,
      selectedDate: date,
      isRoutine: map['isRoutine'] as bool? ?? false,
      startTime: TimeOfDay(
        hour: map['startTimeHour'] as int? ?? 0,
        minute: map['startTimeMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] as int? ?? 0,
        minute: map['endTimeMinute'] as int? ?? 0,
      ),
      color: map['colorValue'] != null ? Color(map['colorValue'] as int) : null,
      hasAlarm: map['hasAlarm'] as bool? ?? false,
      alarmOffset:
          map['alarmOffsetInMinutes'] != null
              ? Duration(minutes: map['alarmOffsetInMinutes'] as int)
              : null,
      syncStatus: status,
      updatedAt: updatedTimestamp ?? DateTime.now(), // Fallback for updatedAt
      createdAt: createdTimestamp ?? DateTime.now(), // Fallback for createdAt
      lastSynced: lastSyncTimestamp,
      // lastModified and isSynced are not directly used from syncMap, derived from syncStatus/updatedAt
    );
  }

  /// 시작 시간을 24시간 형식의 double 값으로 변환 (정렬용)
  double get startTimeValue => startTime.hour + (startTime.minute / 60.0);

  /// 종료 시간을 24시간 형식의 double 값으로 변환 (정렬용)
  double get endTimeValue => endTime.hour + (endTime.minute / 60.0);

  /// 일정 시간이 서로 겹치는지 확인
  bool overlapsWith(ScheduleItem other) {
    // 요일이나 날짜가 다르면 겹치지 않음
    if (isRoutine && other.isRoutine) {
      if (dayOfWeek != other.dayOfWeek) return false;
    } else if (!isRoutine && !other.isRoutine) {
      if (selectedDate?.year != other.selectedDate?.year ||
          selectedDate?.month != other.selectedDate?.month ||
          selectedDate?.day != other.selectedDate?.day) {
        return false;
      }
    } else {
      // 하나는 루틴이고 하나는 일회성이면 비교 불가
      return false;
    }

    // 시간 비교: [a시작, a종료]와 [b시작, b종료]가 겹치는지 확인
    return (startTimeValue <= other.endTimeValue) &&
        (endTimeValue >= other.startTimeValue);
  }
}
