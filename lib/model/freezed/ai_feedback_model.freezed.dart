// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_feedback_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiFeedbackModel {

 int? get id; String get date; String get feedback_text; String get userId; bool get isSynced;
/// Create a copy of AiFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiFeedbackModelCopyWith<AiFeedbackModel> get copyWith => _$AiFeedbackModelCopyWithImpl<AiFeedbackModel>(this as AiFeedbackModel, _$identity);

  /// Serializes this AiFeedbackModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiFeedbackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.feedback_text, feedback_text) || other.feedback_text == feedback_text)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,feedback_text,userId,isSynced);

@override
String toString() {
  return 'AiFeedbackModel(id: $id, date: $date, feedback_text: $feedback_text, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $AiFeedbackModelCopyWith<$Res>  {
  factory $AiFeedbackModelCopyWith(AiFeedbackModel value, $Res Function(AiFeedbackModel) _then) = _$AiFeedbackModelCopyWithImpl;
@useResult
$Res call({
 int? id, String date, String feedback_text, String userId, bool isSynced
});




}
/// @nodoc
class _$AiFeedbackModelCopyWithImpl<$Res>
    implements $AiFeedbackModelCopyWith<$Res> {
  _$AiFeedbackModelCopyWithImpl(this._self, this._then);

  final AiFeedbackModel _self;
  final $Res Function(AiFeedbackModel) _then;

/// Create a copy of AiFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? date = null,Object? feedback_text = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,feedback_text: null == feedback_text ? _self.feedback_text : feedback_text // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AiFeedbackModel implements AiFeedbackModel {
  const _AiFeedbackModel({this.id, required this.date, required this.feedback_text, required this.userId, this.isSynced = false});
  factory _AiFeedbackModel.fromJson(Map<String, dynamic> json) => _$AiFeedbackModelFromJson(json);

@override final  int? id;
@override final  String date;
@override final  String feedback_text;
@override final  String userId;
@override@JsonKey() final  bool isSynced;

/// Create a copy of AiFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiFeedbackModelCopyWith<_AiFeedbackModel> get copyWith => __$AiFeedbackModelCopyWithImpl<_AiFeedbackModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiFeedbackModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiFeedbackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.feedback_text, feedback_text) || other.feedback_text == feedback_text)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,feedback_text,userId,isSynced);

@override
String toString() {
  return 'AiFeedbackModel(id: $id, date: $date, feedback_text: $feedback_text, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$AiFeedbackModelCopyWith<$Res> implements $AiFeedbackModelCopyWith<$Res> {
  factory _$AiFeedbackModelCopyWith(_AiFeedbackModel value, $Res Function(_AiFeedbackModel) _then) = __$AiFeedbackModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String date, String feedback_text, String userId, bool isSynced
});




}
/// @nodoc
class __$AiFeedbackModelCopyWithImpl<$Res>
    implements _$AiFeedbackModelCopyWith<$Res> {
  __$AiFeedbackModelCopyWithImpl(this._self, this._then);

  final _AiFeedbackModel _self;
  final $Res Function(_AiFeedbackModel) _then;

/// Create a copy of AiFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? date = null,Object? feedback_text = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_AiFeedbackModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,feedback_text: null == feedback_text ? _self.feedback_text : feedback_text // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
