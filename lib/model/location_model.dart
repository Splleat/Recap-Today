/// 위치 정보를 담는 모델 클래스
class LocationModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// JSON에서 LocationModel 객체 생성
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// LocationModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 데이터베이스에서 LocationModel 객체 생성
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// LocationModel 객체를 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 하루 동안의 위치 데이터를 담는 클래스
class DailyLocationData {
  final String date;
  final List<LocationModel> locations;

  DailyLocationData({required this.date, required this.locations});

  /// JSON에서 DailyLocationData 객체 생성
  factory DailyLocationData.fromJson(Map<String, dynamic> json) {
    final locationsList = json['locations'] as List;
    final locations =
        locationsList
            .map((locationJson) => LocationModel.fromJson(locationJson))
            .toList();

    return DailyLocationData(
      date: json['date'] as String,
      locations: locations,
    );
  }

  /// DailyLocationData 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'locations': locations.map((location) => location.toJson()).toList(),
    };
  }
}
