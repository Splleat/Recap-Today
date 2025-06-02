import 'package:freezed_annotation/freezed_annotation.dart';
import 'location_model.dart';

part 'daily_location_model.freezed.dart';
part 'daily_location_model.g.dart';

@freezed
abstract class DailyLocationData with _$DailyLocationData {
  const factory DailyLocationData({
    required String date,
    required List<LocationModel> locations,
  }) = _DailyLocationData;

  factory DailyLocationData.fromJson(Map<String, dynamic> json) =>
      _$DailyLocationDataFromJson(json);
}

extension DailyLocationDataExt on DailyLocationData {
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'locations': locations.map((loc) => loc.toMap()).toList(),
    };
  }

  static DailyLocationData fromMap(Map<String, dynamic> map) {
    return DailyLocationData(
      date: map['date'] as String,
      locations: (map['locations'] as List)
          .map((loc) => LocationModelExt.fromMap(loc as Map<String, dynamic>))
          .toList(),
    );
  }
}