// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'step_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StepModel {

 String get date; int get stepCount; String get userId; bool get isSynced;
/// Create a copy of StepModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepModelCopyWith<StepModel> get copyWith => _$StepModelCopyWithImpl<StepModel>(this as StepModel, _$identity);

  /// Serializes this StepModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepModel&&(identical(other.date, date) || other.date == date)&&(identical(other.stepCount, stepCount) || other.stepCount == stepCount)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,stepCount,userId,isSynced);

@override
String toString() {
  return 'StepModel(date: $date, stepCount: $stepCount, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $StepModelCopyWith<$Res>  {
  factory $StepModelCopyWith(StepModel value, $Res Function(StepModel) _then) = _$StepModelCopyWithImpl;
@useResult
$Res call({
 String date, int stepCount, String userId, bool isSynced
});




}
/// @nodoc
class _$StepModelCopyWithImpl<$Res>
    implements $StepModelCopyWith<$Res> {
  _$StepModelCopyWithImpl(this._self, this._then);

  final StepModel _self;
  final $Res Function(StepModel) _then;

/// Create a copy of StepModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? stepCount = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,stepCount: null == stepCount ? _self.stepCount : stepCount // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _StepModel implements StepModel {
  const _StepModel({required this.date, required this.stepCount, required this.userId, this.isSynced = false});
  factory _StepModel.fromJson(Map<String, dynamic> json) => _$StepModelFromJson(json);

@override final  String date;
@override final  int stepCount;
@override final  String userId;
@override@JsonKey() final  bool isSynced;

/// Create a copy of StepModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StepModelCopyWith<_StepModel> get copyWith => __$StepModelCopyWithImpl<_StepModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StepModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StepModel&&(identical(other.date, date) || other.date == date)&&(identical(other.stepCount, stepCount) || other.stepCount == stepCount)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,stepCount,userId,isSynced);

@override
String toString() {
  return 'StepModel(date: $date, stepCount: $stepCount, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$StepModelCopyWith<$Res> implements $StepModelCopyWith<$Res> {
  factory _$StepModelCopyWith(_StepModel value, $Res Function(_StepModel) _then) = __$StepModelCopyWithImpl;
@override @useResult
$Res call({
 String date, int stepCount, String userId, bool isSynced
});




}
/// @nodoc
class __$StepModelCopyWithImpl<$Res>
    implements _$StepModelCopyWith<$Res> {
  __$StepModelCopyWithImpl(this._self, this._then);

  final _StepModel _self;
  final $Res Function(_StepModel) _then;

/// Create a copy of StepModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? stepCount = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_StepModel(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,stepCount: null == stepCount ? _self.stepCount : stepCount // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
