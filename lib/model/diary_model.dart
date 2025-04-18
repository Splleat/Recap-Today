// diary_model.dart
/// 일기 모델 클래스
class DiaryModel {
  /// 일기의 고유 ID (null이면 새로운 일기)
  final int? id;

  /// 일기의 날짜 (YYYY-MM-DD 형식)
  final String date;

  /// 일기의 제목 (필수)
  final String title;

  /// 일기의 내용 (선택)
  final String content;

  /// 일기의 사진 경로 리스트 (선택)
  final List<String> photoPaths;

  /// Diary 생성자
  DiaryModel({
    this.id,
    required this.date,
    required this.title,
    this.content = '',
    this.photoPaths = const [],
  });

  /// Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {'id': id, 'date': date, 'title': title, 'content': content};
  }

  /// Map으로부터 Diary 객체 생성
  static DiaryModel fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      id: map['id'],
      date: map['date'],
      title: map['title'],
      content: map['content'],
    );
  }
}
