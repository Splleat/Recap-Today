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

extension LocationModelExt on LocationModel {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static LocationModel fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}
