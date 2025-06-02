// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_location_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyLocationData {

 String get date; List<LocationModel> get locations;
/// Create a copy of DailyLocationData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyLocationDataCopyWith<DailyLocationData> get copyWith => _$DailyLocationDataCopyWithImpl<DailyLocationData>(this as DailyLocationData, _$identity);

  /// Serializes this DailyLocationData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyLocationData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.locations, locations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(locations));

@override
String toString() {
  return 'DailyLocationData(date: $date, locations: $locations)';
}


}

/// @nodoc
abstract mixin class $DailyLocationDataCopyWith<$Res>  {
  factory $DailyLocationDataCopyWith(DailyLocationData value, $Res Function(DailyLocationData) _then) = _$DailyLocationDataCopyWithImpl;
@useResult
$Res call({
 String date, List<LocationModel> locations
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
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? locations = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,locations: null == locations ? _self.locations : locations // ignore: cast_nullable_to_non_nullable
as List<LocationModel>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DailyLocationData implements DailyLocationData {
  const _DailyLocationData({required this.date, required final  List<LocationModel> locations}): _locations = locations;
  factory _DailyLocationData.fromJson(Map<String, dynamic> json) => _$DailyLocationDataFromJson(json);

@override final  String date;
 final  List<LocationModel> _locations;
@override List<LocationModel> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyLocationData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._locations, _locations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_locations));

@override
String toString() {
  return 'DailyLocationData(date: $date, locations: $locations)';
}


}

/// @nodoc
abstract mixin class _$DailyLocationDataCopyWith<$Res> implements $DailyLocationDataCopyWith<$Res> {
  factory _$DailyLocationDataCopyWith(_DailyLocationData value, $Res Function(_DailyLocationData) _then) = __$DailyLocationDataCopyWithImpl;
@override @useResult
$Res call({
 String date, List<LocationModel> locations
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
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? locations = null,}) {
  return _then(_DailyLocationData(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<LocationModel>,
  ));
}


}

// dart format on
