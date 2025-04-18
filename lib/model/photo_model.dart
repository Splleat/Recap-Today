// photo_model.dart
/// 사진 모델 클래스
class Photo {
  /// 사진의 고유 ID
  final int? id;

  /// 사진이 속한 일기의 ID
  final int diaryId;

  /// 사진 파일 경로
  final String path;

  /// Photo 생성자
  Photo({this.id, required this.diaryId, required this.path});

  /// Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {'id': id, 'diary_id': diaryId, 'path': path};
  }

  /// Map으로부터 Photo 객체 생성
  static Photo fromMap(Map<String, dynamic> map) {
    return Photo(id: map['id'], diaryId: map['diary_id'], path: map['path']);
  }
}
