import 'package:flutter/material.dart';
import './sync_status.dart' as model_sync_status;

/// 체크리스트 항목을 표현하는 모델 클래스
class ChecklistItem {
  final String id;
  final String checklistId; // Added: ID of the parent checklist
  String text;
  String? subtext;
  bool isChecked;
  DateTime? dueDate;
  DateTime? completedDate; // 항목이 완료된 날짜 및 시간
  DateTime lastSynced; // Ensure this is non-nullable and consistently used
  String? serverId;
  bool isDeleted;
  String? clientTempId; // Added for optimistic UI and sync matching
  model_sync_status.SyncStatus
  syncStatus; // Updated to use aliased global SyncStatus

  ChecklistItem({
    required this.id,
    required this.checklistId, // Added
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.subtext,
    this.completedDate,
    DateTime? lastSynced, // Allow nullable in constructor for easier init
    this.serverId,
    this.isDeleted = false,
    this.clientTempId,
    this.syncStatus =
        model_sync_status.SyncStatus.created, // Default to created
  }) : this.lastSynced = lastSynced ?? DateTime.now();

  ChecklistItem copyWith({
    String? id,
    String? checklistId, // Added
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    String? subtext,
    DateTime? completedDate,
    DateTime? lastSynced,
    String? serverId,
    bool? isDeleted,
    String? clientTempId,
    model_sync_status.SyncStatus?
    syncStatus, // Updated to use aliased global SyncStatus
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId, // Added
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      lastSynced: lastSynced ?? this.lastSynced,
      serverId: serverId ?? this.serverId,
      isDeleted: isDeleted ?? this.isDeleted,
      clientTempId: clientTempId ?? this.clientTempId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// SQLite 데이터베이스를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checklistId': checklistId, // Added
      'text': text.trim(),
      'subtext': subtext?.trim(),
      'isChecked': isChecked ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(), // Stays as TEXT
      'completedDate': completedDate?.toIso8601String(), // Stays as TEXT
      'lastSynced': lastSynced.millisecondsSinceEpoch, // Changed to INTEGER
      'serverId': serverId,
      'isDeleted': isDeleted ? 1 : 0,
      'clientTempId': clientTempId,
      'syncStatus': syncStatus.name, // Store enum as string
    };
  }

  static DateTime _parseLastSyncedTimestamp(dynamic value) {
    if (value == null)
      return DateTime.fromMillisecondsSinceEpoch(0); // Default for null
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      // Try parsing as int (epoch milliseconds) first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
      // Try parsing as ISO 8601 date string
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Fallback if parsing fails
        debugPrint('Error parsing lastSynced string "$value": $e');
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    // Fallback for unexpected types
    debugPrint('Unexpected type for lastSynced: ${value.runtimeType}');
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// SQLite 데이터베이스로부터 객체 생성
  /// [map]은 데이터베이스에서 조회한 원시 데이터
  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    try {
      return ChecklistItem(
        id: map['id'] as String,
        checklistId:
            map['checklistId'] as String? ??
            '', // Added, provide default if null
        text: (map['text'] as String?) ?? '',
        subtext: map['subtext'] as String?,
        isChecked: (map['isChecked'] as int?) == 1,
        dueDate:
            map['dueDate'] != null
                ? DateTime.parse(map['dueDate'] as String)
                : null,
        completedDate:
            map['completedDate'] != null
                ? DateTime.parse(map['completedDate'] as String)
                : null,
        lastSynced: _parseLastSyncedTimestamp(
          map['lastSynced'] ?? map['lastModified'], // Prioritize lastSynced
        ),
        serverId: map['serverId'] as String?,
        isDeleted: (map['isDeleted'] as int?) == 1,
        clientTempId: map['clientTempId'] as String?,
        syncStatus:
            map['syncStatus'] != null
                ? model_sync_status.SyncStatusExtension.fromString(
                  map['syncStatus']
                      as String, // Ensure it's a string before parsing
                )
                : model_sync_status.SyncStatus.created,
      );
    } catch (e) {
      debugPrint('ChecklistItem.fromMap 파싱 중 오류 발생: $e. Map: $map');
      return ChecklistItem(
        id: map['id'] as String? ?? UniqueKey().toString(),
        checklistId:
            map['checklistId'] as String? ??
            'unknown_checklist_id', // Added default
        text: (map['text'] as String?) ?? '항목',
        isChecked: false,
        isDeleted: false,
        lastSynced: DateTime.fromMillisecondsSinceEpoch(0),
        syncStatus: model_sync_status.SyncStatus.created, // Default to created
      );
    }
  }

  /// 오늘 완료 여부 확인
  bool get isCompletedToday {
    if (completedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDay = DateTime(
      completedDate!.year,
      completedDate!.month,
      completedDate!.day,
    );

    return completedDay.isAtSameMomentAs(today);
  }

  @override
  String toString() =>
      'ChecklistItem(id: $id, checklistId: $checklistId, text: $text, isChecked: $isChecked, '
      'dueDate: ${dueDate?.toIso8601String() ?? "null"}, '
      'completedDate: ${completedDate?.toIso8601String() ?? "null"}, '
      'lastSynced: ${lastSynced.toIso8601String()}, '
      'serverId: $serverId, isDeleted: $isDeleted, clientTempId: $clientTempId, syncStatus: ${syncStatus.name})';

  Map<String, dynamic> toSyncMap() {
    return {
      'clientTempId': clientTempId ?? id, // Ensure clientTempId is prioritized
      'serverId': serverId,
      'checklistId': checklistId, // Added
      'text': text,
      'subtext': subtext,
      'isChecked': isChecked,
      'dueDate': dueDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.name,
      'lastModified':
          lastSynced.toIso8601String(), // Use lastSynced for lastModified
    };
  }
}
