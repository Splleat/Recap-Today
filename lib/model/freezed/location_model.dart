import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

@freezed
abstract class LocationModel with _$LocationModel {
  const factory LocationModel({
    required String id,
    required String userId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    @Default(false) bool isSynced,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
}

extension LocationModelX on LocationModel {
  /// LocationModel 객체를 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static LocationModel fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

@freezed
abstract class DailyLocationData with _$DailyLocationData {
  const factory DailyLocationData({
    required String date,
    required List<LocationModel> locations,
    required String userId,
    @Default(false) bool isSynced,
  }) = _DailyLocationData;

  factory DailyLocationData.fromJson(Map<String, dynamic> json) =>
      _$DailyLocationDataFromJson(json);
}

extension DailyLocationDataX on DailyLocationData {
  /// DailyLocationData 객체를 JSON으로 변환
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
      // locations would need to be stored separately
    };
  }

  static DailyLocationData fromMap(Map<String, dynamic> map, List<LocationModel> locations) {
    return DailyLocationData(
      date: map['date'] as String,
      locations: locations,
      userId: map['user_id'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
