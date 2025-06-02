// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_usage_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUsageModel {

 String get id; String get userId; String get date; String get packageName; String get appName; int get usageTimeInMillis; String? get appIconPath; bool get isSynced;
/// Create a copy of AppUsageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUsageModelCopyWith<AppUsageModel> get copyWith => _$AppUsageModelCopyWithImpl<AppUsageModel>(this as AppUsageModel, _$identity);

  /// Serializes this AppUsageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUsageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.usageTimeInMillis, usageTimeInMillis) || other.usageTimeInMillis == usageTimeInMillis)&&(identical(other.appIconPath, appIconPath) || other.appIconPath == appIconPath)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,packageName,appName,usageTimeInMillis,appIconPath,isSynced);

@override
String toString() {
  return 'AppUsageModel(id: $id, userId: $userId, date: $date, packageName: $packageName, appName: $appName, usageTimeInMillis: $usageTimeInMillis, appIconPath: $appIconPath, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $AppUsageModelCopyWith<$Res>  {
  factory $AppUsageModelCopyWith(AppUsageModel value, $Res Function(AppUsageModel) _then) = _$AppUsageModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String date, String packageName, String appName, int usageTimeInMillis, String? appIconPath, bool isSynced
});




}
/// @nodoc
class _$AppUsageModelCopyWithImpl<$Res>
    implements $AppUsageModelCopyWith<$Res> {
  _$AppUsageModelCopyWithImpl(this._self, this._then);

  final AppUsageModel _self;
  final $Res Function(AppUsageModel) _then;

/// Create a copy of AppUsageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? date = null,Object? packageName = null,Object? appName = null,Object? usageTimeInMillis = null,Object? appIconPath = freezed,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,usageTimeInMillis: null == usageTimeInMillis ? _self.usageTimeInMillis : usageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,appIconPath: freezed == appIconPath ? _self.appIconPath : appIconPath // ignore: cast_nullable_to_non_nullable
as String?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AppUsageModel implements AppUsageModel {
  const _AppUsageModel({required this.id, required this.userId, required this.date, required this.packageName, required this.appName, required this.usageTimeInMillis, this.appIconPath, this.isSynced = false});
  factory _AppUsageModel.fromJson(Map<String, dynamic> json) => _$AppUsageModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String date;
@override final  String packageName;
@override final  String appName;
@override final  int usageTimeInMillis;
@override final  String? appIconPath;
@override@JsonKey() final  bool isSynced;

/// Create a copy of AppUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUsageModelCopyWith<_AppUsageModel> get copyWith => __$AppUsageModelCopyWithImpl<_AppUsageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUsageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUsageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.usageTimeInMillis, usageTimeInMillis) || other.usageTimeInMillis == usageTimeInMillis)&&(identical(other.appIconPath, appIconPath) || other.appIconPath == appIconPath)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,packageName,appName,usageTimeInMillis,appIconPath,isSynced);

@override
String toString() {
  return 'AppUsageModel(id: $id, userId: $userId, date: $date, packageName: $packageName, appName: $appName, usageTimeInMillis: $usageTimeInMillis, appIconPath: $appIconPath, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$AppUsageModelCopyWith<$Res> implements $AppUsageModelCopyWith<$Res> {
  factory _$AppUsageModelCopyWith(_AppUsageModel value, $Res Function(_AppUsageModel) _then) = __$AppUsageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String date, String packageName, String appName, int usageTimeInMillis, String? appIconPath, bool isSynced
});




}
/// @nodoc
class __$AppUsageModelCopyWithImpl<$Res>
    implements _$AppUsageModelCopyWith<$Res> {
  __$AppUsageModelCopyWithImpl(this._self, this._then);

  final _AppUsageModel _self;
  final $Res Function(_AppUsageModel) _then;

/// Create a copy of AppUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? date = null,Object? packageName = null,Object? appName = null,Object? usageTimeInMillis = null,Object? appIconPath = freezed,Object? isSynced = null,}) {
  return _then(_AppUsageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,usageTimeInMillis: null == usageTimeInMillis ? _self.usageTimeInMillis : usageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,appIconPath: freezed == appIconPath ? _self.appIconPath : appIconPath // ignore: cast_nullable_to_non_nullable
as String?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
