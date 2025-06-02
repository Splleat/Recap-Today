// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Diary implements DiagnosticableTreeMixin {

 String? get id; String get userId; String get date; String get title; String? get content; List<String> get photoPaths; DateTime get createdAt; bool get isSynced;
/// Create a copy of Diary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryCopyWith<Diary> get copyWith => _$DiaryCopyWithImpl<Diary>(this as Diary, _$identity);

  /// Serializes this Diary to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Diary'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('content', content))..add(DiagnosticsProperty('photoPaths', photoPaths))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('isSynced', isSynced));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Diary&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.photoPaths, photoPaths)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,title,content,const DeepCollectionEquality().hash(photoPaths),createdAt,isSynced);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Diary(id: $id, userId: $userId, date: $date, title: $title, content: $content, photoPaths: $photoPaths, createdAt: $createdAt, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $DiaryCopyWith<$Res>  {
  factory $DiaryCopyWith(Diary value, $Res Function(Diary) _then) = _$DiaryCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, String date, String title, String? content, List<String> photoPaths, DateTime createdAt, bool isSynced
});




}
/// @nodoc
class _$DiaryCopyWithImpl<$Res>
    implements $DiaryCopyWith<$Res> {
  _$DiaryCopyWithImpl(this._self, this._then);

  final Diary _self;
  final $Res Function(Diary) _then;

/// Create a copy of Diary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? date = null,Object? title = null,Object? content = freezed,Object? photoPaths = null,Object? createdAt = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,photoPaths: null == photoPaths ? _self.photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Diary with DiagnosticableTreeMixin implements Diary {
  const _Diary({this.id, required this.userId, required this.date, required this.title, this.content, required final  List<String> photoPaths, required this.createdAt, this.isSynced = false}): _photoPaths = photoPaths;
  factory _Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  String date;
@override final  String title;
@override final  String? content;
 final  List<String> _photoPaths;
@override List<String> get photoPaths {
  if (_photoPaths is EqualUnmodifiableListView) return _photoPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoPaths);
}

@override final  DateTime createdAt;
@override@JsonKey() final  bool isSynced;

/// Create a copy of Diary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryCopyWith<_Diary> get copyWith => __$DiaryCopyWithImpl<_Diary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Diary'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('content', content))..add(DiagnosticsProperty('photoPaths', photoPaths))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('isSynced', isSynced));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Diary&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._photoPaths, _photoPaths)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,date,title,content,const DeepCollectionEquality().hash(_photoPaths),createdAt,isSynced);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Diary(id: $id, userId: $userId, date: $date, title: $title, content: $content, photoPaths: $photoPaths, createdAt: $createdAt, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$DiaryCopyWith<$Res> implements $DiaryCopyWith<$Res> {
  factory _$DiaryCopyWith(_Diary value, $Res Function(_Diary) _then) = __$DiaryCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, String date, String title, String? content, List<String> photoPaths, DateTime createdAt, bool isSynced
});




}
/// @nodoc
class __$DiaryCopyWithImpl<$Res>
    implements _$DiaryCopyWith<$Res> {
  __$DiaryCopyWithImpl(this._self, this._then);

  final _Diary _self;
  final $Res Function(_Diary) _then;

/// Create a copy of Diary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? date = null,Object? title = null,Object? content = freezed,Object? photoPaths = null,Object? createdAt = null,Object? isSynced = null,}) {
  return _then(_Diary(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,photoPaths: null == photoPaths ? _self._photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
