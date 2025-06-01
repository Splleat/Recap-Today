import 'package:recap_today/model/sync_status.dart';

class ChecklistModel {
  String? id;
  String? clientGeneratedId;
  String title;
  DateTime date;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  bool isDeleted;

  ChecklistModel({
    this.id,
    this.clientGeneratedId,
    required this.title,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.created,
    this.isDeleted = false,
  });

  factory ChecklistModel.fromMap(Map<String, dynamic> map) {
    return ChecklistModel(
      id: map['id'],
      clientGeneratedId: map['clientGeneratedId'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      syncStatus: SyncStatusExtension.fromString(
        map['syncStatus'] ?? 'created',
      ),
      isDeleted: map['isDeleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientGeneratedId': clientGeneratedId,
      'title': title,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toString().split('.').last,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  ChecklistModel copyWith({
    String? id,
    String? clientGeneratedId,
    String? title,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return ChecklistModel(
      id: id ?? this.id,
      clientGeneratedId: clientGeneratedId ?? this.clientGeneratedId,
      title: title ?? this.title,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
