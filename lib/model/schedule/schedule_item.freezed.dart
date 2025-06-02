// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleItem {

 String get id; String get userId; String get text; String? get subText; int? get dayOfWeek; DateTime? get selectedDate; bool get isRoutine;@TimeOfDayConverter() TimeOfDay get startTime;@TimeOfDayConverter() TimeOfDay get endTime;@ColorConverter() Color? get color; bool? get hasAlarm;@DurationConverter() Duration? get alarmOffset; bool get isSynced;
/// Create a copy of ScheduleItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleItemCopyWith<ScheduleItem> get copyWith => _$ScheduleItemCopyWithImpl<ScheduleItem>(this as ScheduleItem, _$identity);

  /// Serializes this ScheduleItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.text, text) || other.text == text)&&(identical(other.subText, subText) || other.subText == subText)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.isRoutine, isRoutine) || other.isRoutine == isRoutine)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.color, color) || other.color == color)&&(identical(other.hasAlarm, hasAlarm) || other.hasAlarm == hasAlarm)&&(identical(other.alarmOffset, alarmOffset) || other.alarmOffset == alarmOffset)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,text,subText,dayOfWeek,selectedDate,isRoutine,startTime,endTime,color,hasAlarm,alarmOffset,isSynced);

@override
String toString() {
  return 'ScheduleItem(id: $id, userId: $userId, text: $text, subText: $subText, dayOfWeek: $dayOfWeek, selectedDate: $selectedDate, isRoutine: $isRoutine, startTime: $startTime, endTime: $endTime, color: $color, hasAlarm: $hasAlarm, alarmOffset: $alarmOffset, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $ScheduleItemCopyWith<$Res>  {
  factory $ScheduleItemCopyWith(ScheduleItem value, $Res Function(ScheduleItem) _then) = _$ScheduleItemCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String text, String? subText, int? dayOfWeek, DateTime? selectedDate, bool isRoutine,@TimeOfDayConverter() TimeOfDay startTime,@TimeOfDayConverter() TimeOfDay endTime,@ColorConverter() Color? color, bool? hasAlarm,@DurationConverter() Duration? alarmOffset, bool isSynced
});




}
/// @nodoc
class _$ScheduleItemCopyWithImpl<$Res>
    implements $ScheduleItemCopyWith<$Res> {
  _$ScheduleItemCopyWithImpl(this._self, this._then);

  final ScheduleItem _self;
  final $Res Function(ScheduleItem) _then;

/// Create a copy of ScheduleItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? text = null,Object? subText = freezed,Object? dayOfWeek = freezed,Object? selectedDate = freezed,Object? isRoutine = null,Object? startTime = null,Object? endTime = null,Object? color = freezed,Object? hasAlarm = freezed,Object? alarmOffset = freezed,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,subText: freezed == subText ? _self.subText : subText // ignore: cast_nullable_to_non_nullable
as String?,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isRoutine: null == isRoutine ? _self.isRoutine : isRoutine // ignore: cast_nullable_to_non_nullable
as bool,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,hasAlarm: freezed == hasAlarm ? _self.hasAlarm : hasAlarm // ignore: cast_nullable_to_non_nullable
as bool?,alarmOffset: freezed == alarmOffset ? _self.alarmOffset : alarmOffset // ignore: cast_nullable_to_non_nullable
as Duration?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ScheduleItem implements ScheduleItem {
  const _ScheduleItem({required this.id, required this.userId, required this.text, this.subText, this.dayOfWeek, this.selectedDate, required this.isRoutine, @TimeOfDayConverter() required this.startTime, @TimeOfDayConverter() required this.endTime, @ColorConverter() this.color, this.hasAlarm, @DurationConverter() this.alarmOffset, this.isSynced = false});
  factory _ScheduleItem.fromJson(Map<String, dynamic> json) => _$ScheduleItemFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String text;
@override final  String? subText;
@override final  int? dayOfWeek;
@override final  DateTime? selectedDate;
@override final  bool isRoutine;
@override@TimeOfDayConverter() final  TimeOfDay startTime;
@override@TimeOfDayConverter() final  TimeOfDay endTime;
@override@ColorConverter() final  Color? color;
@override final  bool? hasAlarm;
@override@DurationConverter() final  Duration? alarmOffset;
@override@JsonKey() final  bool isSynced;

/// Create a copy of ScheduleItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleItemCopyWith<_ScheduleItem> get copyWith => __$ScheduleItemCopyWithImpl<_ScheduleItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.text, text) || other.text == text)&&(identical(other.subText, subText) || other.subText == subText)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.isRoutine, isRoutine) || other.isRoutine == isRoutine)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.color, color) || other.color == color)&&(identical(other.hasAlarm, hasAlarm) || other.hasAlarm == hasAlarm)&&(identical(other.alarmOffset, alarmOffset) || other.alarmOffset == alarmOffset)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,text,subText,dayOfWeek,selectedDate,isRoutine,startTime,endTime,color,hasAlarm,alarmOffset,isSynced);

@override
String toString() {
  return 'ScheduleItem(id: $id, userId: $userId, text: $text, subText: $subText, dayOfWeek: $dayOfWeek, selectedDate: $selectedDate, isRoutine: $isRoutine, startTime: $startTime, endTime: $endTime, color: $color, hasAlarm: $hasAlarm, alarmOffset: $alarmOffset, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$ScheduleItemCopyWith<$Res> implements $ScheduleItemCopyWith<$Res> {
  factory _$ScheduleItemCopyWith(_ScheduleItem value, $Res Function(_ScheduleItem) _then) = __$ScheduleItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String text, String? subText, int? dayOfWeek, DateTime? selectedDate, bool isRoutine,@TimeOfDayConverter() TimeOfDay startTime,@TimeOfDayConverter() TimeOfDay endTime,@ColorConverter() Color? color, bool? hasAlarm,@DurationConverter() Duration? alarmOffset, bool isSynced
});




}
/// @nodoc
class __$ScheduleItemCopyWithImpl<$Res>
    implements _$ScheduleItemCopyWith<$Res> {
  __$ScheduleItemCopyWithImpl(this._self, this._then);

  final _ScheduleItem _self;
  final $Res Function(_ScheduleItem) _then;

/// Create a copy of ScheduleItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? text = null,Object? subText = freezed,Object? dayOfWeek = freezed,Object? selectedDate = freezed,Object? isRoutine = null,Object? startTime = null,Object? endTime = null,Object? color = freezed,Object? hasAlarm = freezed,Object? alarmOffset = freezed,Object? isSynced = null,}) {
  return _then(_ScheduleItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,subText: freezed == subText ? _self.subText : subText // ignore: cast_nullable_to_non_nullable
as String?,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isRoutine: null == isRoutine ? _self.isRoutine : isRoutine // ignore: cast_nullable_to_non_nullable
as bool,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,hasAlarm: freezed == hasAlarm ? _self.hasAlarm : hasAlarm // ignore: cast_nullable_to_non_nullable
as bool?,alarmOffset: freezed == alarmOffset ? _self.alarmOffset : alarmOffset // ignore: cast_nullable_to_non_nullable
as Duration?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
