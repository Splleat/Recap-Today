// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocationModel {

 String get id; String get userId; double get latitude; double get longitude; DateTime get timestamp; bool get isSynced;
/// Create a copy of LocationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationModelCopyWith<LocationModel> get copyWith => _$LocationModelCopyWithImpl<LocationModel>(this as LocationModel, _$identity);

  /// Serializes this LocationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,latitude,longitude,timestamp,isSynced);

@override
String toString() {
  return 'LocationModel(id: $id, userId: $userId, latitude: $latitude, longitude: $longitude, timestamp: $timestamp, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $LocationModelCopyWith<$Res>  {
  factory $LocationModelCopyWith(LocationModel value, $Res Function(LocationModel) _then) = _$LocationModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, double latitude, double longitude, DateTime timestamp, bool isSynced
});




}
/// @nodoc
class _$LocationModelCopyWithImpl<$Res>
    implements $LocationModelCopyWith<$Res> {
  _$LocationModelCopyWithImpl(this._self, this._then);

  final LocationModel _self;
  final $Res Function(LocationModel) _then;

/// Create a copy of LocationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? latitude = null,Object? longitude = null,Object? timestamp = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _LocationModel implements LocationModel {
  const _LocationModel({required this.id, required this.userId, required this.latitude, required this.longitude, required this.timestamp, this.isSynced = false});
  factory _LocationModel.fromJson(Map<String, dynamic> json) => _$LocationModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  double latitude;
@override final  double longitude;
@override final  DateTime timestamp;
@override@JsonKey() final  bool isSynced;

/// Create a copy of LocationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationModelCopyWith<_LocationModel> get copyWith => __$LocationModelCopyWithImpl<_LocationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,latitude,longitude,timestamp,isSynced);

@override
String toString() {
  return 'LocationModel(id: $id, userId: $userId, latitude: $latitude, longitude: $longitude, timestamp: $timestamp, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$LocationModelCopyWith<$Res> implements $LocationModelCopyWith<$Res> {
  factory _$LocationModelCopyWith(_LocationModel value, $Res Function(_LocationModel) _then) = __$LocationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, double latitude, double longitude, DateTime timestamp, bool isSynced
});




}
/// @nodoc
class __$LocationModelCopyWithImpl<$Res>
    implements _$LocationModelCopyWith<$Res> {
  __$LocationModelCopyWithImpl(this._self, this._then);

  final _LocationModel _self;
  final $Res Function(_LocationModel) _then;

/// Create a copy of LocationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? latitude = null,Object? longitude = null,Object? timestamp = null,Object? isSynced = null,}) {
  return _then(_LocationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DailyLocationData {

 String get date; List<LocationModel> get locations; String get userId; bool get isSynced;
/// Create a copy of DailyLocationData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyLocationDataCopyWith<DailyLocationData> get copyWith => _$DailyLocationDataCopyWithImpl<DailyLocationData>(this as DailyLocationData, _$identity);

  /// Serializes this DailyLocationData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyLocationData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.locations, locations)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(locations),userId,isSynced);

@override
String toString() {
  return 'DailyLocationData(date: $date, locations: $locations, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $DailyLocationDataCopyWith<$Res>  {
  factory $DailyLocationDataCopyWith(DailyLocationData value, $Res Function(DailyLocationData) _then) = _$DailyLocationDataCopyWithImpl;
@useResult
$Res call({
 String date, List<LocationModel> locations, String userId, bool isSynced
});




}
/// @nodoc
class _$DailyLocationDataCopyWithImpl<$Res>
    implements $DailyLocationDataCopyWith<$Res> {
  _$DailyLocationDataCopyWithImpl(this._self, this._then);

  final DailyLocationData _self;
  final $Res Function(DailyLocationData) _then;

/// Create a copy of DailyLocationData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? locations = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,locations: null == locations ? _self.locations : locations // ignore: cast_nullable_to_non_nullable
as List<LocationModel>,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DailyLocationData implements DailyLocationData {
  const _DailyLocationData({required this.date, required final  List<LocationModel> locations, required this.userId, this.isSynced = false}): _locations = locations;
  factory _DailyLocationData.fromJson(Map<String, dynamic> json) => _$DailyLocationDataFromJson(json);

@override final  String date;
 final  List<LocationModel> _locations;
@override List<LocationModel> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

@override final  String userId;
@override@JsonKey() final  bool isSynced;

/// Create a copy of DailyLocationData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyLocationDataCopyWith<_DailyLocationData> get copyWith => __$DailyLocationDataCopyWithImpl<_DailyLocationData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyLocationDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyLocationData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._locations, _locations)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_locations),userId,isSynced);

@override
String toString() {
  return 'DailyLocationData(date: $date, locations: $locations, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$DailyLocationDataCopyWith<$Res> implements $DailyLocationDataCopyWith<$Res> {
  factory _$DailyLocationDataCopyWith(_DailyLocationData value, $Res Function(_DailyLocationData) _then) = __$DailyLocationDataCopyWithImpl;
@override @useResult
$Res call({
 String date, List<LocationModel> locations, String userId, bool isSynced
});




}
/// @nodoc
class __$DailyLocationDataCopyWithImpl<$Res>
    implements _$DailyLocationDataCopyWith<$Res> {
  __$DailyLocationDataCopyWithImpl(this._self, this._then);

  final _DailyLocationData _self;
  final $Res Function(_DailyLocationData) _then;

/// Create a copy of DailyLocationData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? locations = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_DailyLocationData(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<LocationModel>,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
