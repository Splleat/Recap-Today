import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
abstract class Photo with _$Photo {
  const factory Photo({
    required String diaryId,
    required String path,
    @Default(false) bool isSynced,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}

extension PhotoExt on Photo {
  Map<String, dynamic> toMap() {
    return {
      'diaryId': diaryId,
      'path': path,
      'isSynced': isSynced ? 1 : 0,
    };  
  }

  static Photo fromMap(Map<String, dynamic> map) {
    return Photo(
      diaryId: map['diaryId'] as String,
      path: map['path'] as String,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}