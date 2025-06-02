// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emotion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmotionRecord {

 String get id; String get userId; String get date; int get hour; String get emotionType; String? get notes; bool get isSynced;
/// Create a copy of EmotionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmotionRecordCopyWith<EmotionRecord> get copyWith => _$EmotionRecordCopyWithImpl<EmotionRecord>(this as EmotionRecord, _$identity);

  /// Serializes this EmotionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmotionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.emotionType, emotionType) || other.emotionType == emotionType)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,hour,emotionType,notes,isSynced);

@override
String toString() {
  return 'EmotionRecord(id: $id, userId: $userId, date: $date, hour: $hour, emotionType: $emotionType, notes: $notes, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $EmotionRecordCopyWith<$Res>  {
  factory $EmotionRecordCopyWith(EmotionRecord value, $Res Function(EmotionRecord) _then) = _$EmotionRecordCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String date, int hour, String emotionType, String? notes, bool isSynced
});




}
/// @nodoc
class _$EmotionRecordCopyWithImpl<$Res>
    implements $EmotionRecordCopyWith<$Res> {
  _$EmotionRecordCopyWithImpl(this._self, this._then);

  final EmotionRecord _self;
  final $Res Function(EmotionRecord) _then;

/// Create a copy of EmotionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? date = null,Object? hour = null,Object? emotionType = null,Object? notes = freezed,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,emotionType: null == emotionType ? _self.emotionType : emotionType // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _EmotionRecord implements EmotionRecord {
  const _EmotionRecord({required this.id, required this.userId, required this.date, required this.hour, required this.emotionType, this.notes, this.isSynced = false});
  factory _EmotionRecord.fromJson(Map<String, dynamic> json) => _$EmotionRecordFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String date;
@override final  int hour;
@override final  String emotionType;
@override final  String? notes;
@override@JsonKey() final  bool isSynced;

/// Create a copy of EmotionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmotionRecordCopyWith<_EmotionRecord> get copyWith => __$EmotionRecordCopyWithImpl<_EmotionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmotionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmotionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.emotionType, emotionType) || other.emotionType == emotionType)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,hour,emotionType,notes,isSynced);

@override
String toString() {
  return 'EmotionRecord(id: $id, userId: $userId, date: $date, hour: $hour, emotionType: $emotionType, notes: $notes, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$EmotionRecordCopyWith<$Res> implements $EmotionRecordCopyWith<$Res> {
  factory _$EmotionRecordCopyWith(_EmotionRecord value, $Res Function(_EmotionRecord) _then) = __$EmotionRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String date, int hour, String emotionType, String? notes, bool isSynced
});




}
/// @nodoc
class __$EmotionRecordCopyWithImpl<$Res>
    implements _$EmotionRecordCopyWith<$Res> {
  __$EmotionRecordCopyWithImpl(this._self, this._then);

  final _EmotionRecord _self;
  final $Res Function(_EmotionRecord) _then;

/// Create a copy of EmotionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? date = null,Object? hour = null,Object? emotionType = null,Object? notes = freezed,Object? isSynced = null,}) {
  return _then(_EmotionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,emotionType: null == emotionType ? _self.emotionType : emotionType // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
