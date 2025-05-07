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

 int? get id; String get date; String get packageName; String get appName; int get usageTimeInMillis; String? get appIconPath;
/// Create a copy of AppUsageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUsageModelCopyWith<AppUsageModel> get copyWith => _$AppUsageModelCopyWithImpl<AppUsageModel>(this as AppUsageModel, _$identity);

  /// Serializes this AppUsageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUsageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.usageTimeInMillis, usageTimeInMillis) || other.usageTimeInMillis == usageTimeInMillis)&&(identical(other.appIconPath, appIconPath) || other.appIconPath == appIconPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,packageName,appName,usageTimeInMillis,appIconPath);

@override
String toString() {
  return 'AppUsageModel(id: $id, date: $date, packageName: $packageName, appName: $appName, usageTimeInMillis: $usageTimeInMillis, appIconPath: $appIconPath)';
}


}

/// @nodoc
abstract mixin class $AppUsageModelCopyWith<$Res>  {
  factory $AppUsageModelCopyWith(AppUsageModel value, $Res Function(AppUsageModel) _then) = _$AppUsageModelCopyWithImpl;
@useResult
$Res call({
 int? id, String date, String packageName, String appName, int usageTimeInMillis, String? appIconPath
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? date = null,Object? packageName = null,Object? appName = null,Object? usageTimeInMillis = null,Object? appIconPath = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,usageTimeInMillis: null == usageTimeInMillis ? _self.usageTimeInMillis : usageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,appIconPath: freezed == appIconPath ? _self.appIconPath : appIconPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AppUsageModel implements AppUsageModel {
  const _AppUsageModel({this.id, required this.date, required this.packageName, required this.appName, required this.usageTimeInMillis, this.appIconPath});
  factory _AppUsageModel.fromJson(Map<String, dynamic> json) => _$AppUsageModelFromJson(json);

@override final  int? id;
@override final  String date;
@override final  String packageName;
@override final  String appName;
@override final  int usageTimeInMillis;
@override final  String? appIconPath;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUsageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.usageTimeInMillis, usageTimeInMillis) || other.usageTimeInMillis == usageTimeInMillis)&&(identical(other.appIconPath, appIconPath) || other.appIconPath == appIconPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,packageName,appName,usageTimeInMillis,appIconPath);

@override
String toString() {
  return 'AppUsageModel(id: $id, date: $date, packageName: $packageName, appName: $appName, usageTimeInMillis: $usageTimeInMillis, appIconPath: $appIconPath)';
}


}

/// @nodoc
abstract mixin class _$AppUsageModelCopyWith<$Res> implements $AppUsageModelCopyWith<$Res> {
  factory _$AppUsageModelCopyWith(_AppUsageModel value, $Res Function(_AppUsageModel) _then) = __$AppUsageModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String date, String packageName, String appName, int usageTimeInMillis, String? appIconPath
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? date = null,Object? packageName = null,Object? appName = null,Object? usageTimeInMillis = null,Object? appIconPath = freezed,}) {
  return _then(_AppUsageModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,usageTimeInMillis: null == usageTimeInMillis ? _self.usageTimeInMillis : usageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,appIconPath: freezed == appIconPath ? _self.appIconPath : appIconPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppUsageSummary {

 String get date; int get totalUsageTimeInMillis; List<AppUsageModel> get topApps;
/// Create a copy of AppUsageSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUsageSummaryCopyWith<AppUsageSummary> get copyWith => _$AppUsageSummaryCopyWithImpl<AppUsageSummary>(this as AppUsageSummary, _$identity);

  /// Serializes this AppUsageSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUsageSummary&&(identical(other.date, date) || other.date == date)&&(identical(other.totalUsageTimeInMillis, totalUsageTimeInMillis) || other.totalUsageTimeInMillis == totalUsageTimeInMillis)&&const DeepCollectionEquality().equals(other.topApps, topApps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,totalUsageTimeInMillis,const DeepCollectionEquality().hash(topApps));

@override
String toString() {
  return 'AppUsageSummary(date: $date, totalUsageTimeInMillis: $totalUsageTimeInMillis, topApps: $topApps)';
}


}

/// @nodoc
abstract mixin class $AppUsageSummaryCopyWith<$Res>  {
  factory $AppUsageSummaryCopyWith(AppUsageSummary value, $Res Function(AppUsageSummary) _then) = _$AppUsageSummaryCopyWithImpl;
@useResult
$Res call({
 String date, int totalUsageTimeInMillis, List<AppUsageModel> topApps
});




}
/// @nodoc
class _$AppUsageSummaryCopyWithImpl<$Res>
    implements $AppUsageSummaryCopyWith<$Res> {
  _$AppUsageSummaryCopyWithImpl(this._self, this._then);

  final AppUsageSummary _self;
  final $Res Function(AppUsageSummary) _then;

/// Create a copy of AppUsageSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? totalUsageTimeInMillis = null,Object? topApps = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,totalUsageTimeInMillis: null == totalUsageTimeInMillis ? _self.totalUsageTimeInMillis : totalUsageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,topApps: null == topApps ? _self.topApps : topApps // ignore: cast_nullable_to_non_nullable
as List<AppUsageModel>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AppUsageSummary implements AppUsageSummary {
  const _AppUsageSummary({required this.date, required this.totalUsageTimeInMillis, required final  List<AppUsageModel> topApps}): _topApps = topApps;
  factory _AppUsageSummary.fromJson(Map<String, dynamic> json) => _$AppUsageSummaryFromJson(json);

@override final  String date;
@override final  int totalUsageTimeInMillis;
 final  List<AppUsageModel> _topApps;
@override List<AppUsageModel> get topApps {
  if (_topApps is EqualUnmodifiableListView) return _topApps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topApps);
}


/// Create a copy of AppUsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUsageSummaryCopyWith<_AppUsageSummary> get copyWith => __$AppUsageSummaryCopyWithImpl<_AppUsageSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUsageSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUsageSummary&&(identical(other.date, date) || other.date == date)&&(identical(other.totalUsageTimeInMillis, totalUsageTimeInMillis) || other.totalUsageTimeInMillis == totalUsageTimeInMillis)&&const DeepCollectionEquality().equals(other._topApps, _topApps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,totalUsageTimeInMillis,const DeepCollectionEquality().hash(_topApps));

@override
String toString() {
  return 'AppUsageSummary(date: $date, totalUsageTimeInMillis: $totalUsageTimeInMillis, topApps: $topApps)';
}


}

/// @nodoc
abstract mixin class _$AppUsageSummaryCopyWith<$Res> implements $AppUsageSummaryCopyWith<$Res> {
  factory _$AppUsageSummaryCopyWith(_AppUsageSummary value, $Res Function(_AppUsageSummary) _then) = __$AppUsageSummaryCopyWithImpl;
@override @useResult
$Res call({
 String date, int totalUsageTimeInMillis, List<AppUsageModel> topApps
});




}
/// @nodoc
class __$AppUsageSummaryCopyWithImpl<$Res>
    implements _$AppUsageSummaryCopyWith<$Res> {
  __$AppUsageSummaryCopyWithImpl(this._self, this._then);

  final _AppUsageSummary _self;
  final $Res Function(_AppUsageSummary) _then;

/// Create a copy of AppUsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? totalUsageTimeInMillis = null,Object? topApps = null,}) {
  return _then(_AppUsageSummary(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,totalUsageTimeInMillis: null == totalUsageTimeInMillis ? _self.totalUsageTimeInMillis : totalUsageTimeInMillis // ignore: cast_nullable_to_non_nullable
as int,topApps: null == topApps ? _self._topApps : topApps // ignore: cast_nullable_to_non_nullable
as List<AppUsageModel>,
  ));
}


}

// dart format on
