import 'package:recap_today/model/sync_status.dart';
import 'package:uuid/uuid.dart';

class WeatherData {
  final int? id; // Local DB ID
  final String clientTempId; // Unique client-generated ID
  String? serverId; // Server-generated ID
  final DateTime date;
  final String city;
  final String country;
  final double temperatureCelcius;
  final String condition;
  final String iconUrl;
  final double windSpeedKph;
  final int humidityPercent;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  DateTime? lastSynced;

  WeatherData({
    this.id,
    String? clientTempId,
    this.serverId,
    required this.date,
    required this.city,
    required this.country,
    required this.temperatureCelcius,
    required this.condition,
    required this.iconUrl,
    required this.windSpeedKph,
    required this.humidityPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.created,
    this.lastSynced,
  }) : clientTempId = clientTempId ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'serverId': serverId,
      'date': date.toIso8601String(),
      'city': city,
      'country': country,
      'temperatureCelcius': temperatureCelcius,
      'condition': condition,
      'iconUrl': iconUrl,
      'windSpeedKph': windSpeedKph,
      'humidityPercent': humidityPercent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'],
      clientTempId: map['clientTempId'],
      serverId: map['serverId'],
      date: DateTime.parse(map['date']),
      city: map['city'],
      country: map['country'],
      temperatureCelcius: map['temperatureCelcius']?.toDouble(),
      condition: map['condition'],
      iconUrl: map['iconUrl'],
      windSpeedKph: map['windSpeedKph']?.toDouble(),
      humidityPercent: map['humidityPercent'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.created,
      ),
      lastSynced:
          map['lastSynced'] != null ? DateTime.parse(map['lastSynced']) : null,
    );
  }

  WeatherData copyWith({
    int? id,
    String? clientTempId,
    String? serverId,
    DateTime? date,
    String? city,
    String? country,
    double? temperatureCelcius,
    String? condition,
    String? iconUrl,
    double? windSpeedKph,
    int? humidityPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSynced,
    bool setLastSyncedToNull = false,
  }) {
    return WeatherData(
      id: id ?? this.id,
      clientTempId: clientTempId ?? this.clientTempId,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      city: city ?? this.city,
      country: country ?? this.country,
      temperatureCelcius: temperatureCelcius ?? this.temperatureCelcius,
      condition: condition ?? this.condition,
      iconUrl: iconUrl ?? this.iconUrl,
      windSpeedKph: windSpeedKph ?? this.windSpeedKph,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: setLastSyncedToNull ? null : (lastSynced ?? this.lastSynced),
    );
  }

  Map<String, dynamic> toSyncMap() {
    return {
      'clientTempId': clientTempId,
      if (serverId != null) 'serverId': serverId,
      'date': date.toIso8601String(),
      'city': city,
      'country': country,
      'temperatureCelcius': temperatureCelcius,
      'condition': condition,
      'iconUrl': iconUrl,
      'windSpeedKph': windSpeedKph,
      'humidityPercent': humidityPercent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
