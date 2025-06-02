// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_usage_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
  const _AppUsageSummary({required this.date, required this.totalUsageTimeInMillis, final  List<AppUsageModel> topApps = const []}): _topApps = topApps;
  factory _AppUsageSummary.fromJson(Map<String, dynamic> json) => _$AppUsageSummaryFromJson(json);

@override final  String date;
@override final  int totalUsageTimeInMillis;
 final  List<AppUsageModel> _topApps;
@override@JsonKey() List<AppUsageModel> get topApps {
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
