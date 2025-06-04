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
mixin _$DiaryModel {

 int? get id; String get date; String get title; String get content; List<String> get photoPaths; String get userId; bool get isSynced;
/// Create a copy of DiaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryModelCopyWith<DiaryModel> get copyWith => _$DiaryModelCopyWithImpl<DiaryModel>(this as DiaryModel, _$identity);

  /// Serializes this DiaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.photoPaths, photoPaths)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,title,content,const DeepCollectionEquality().hash(photoPaths),userId,isSynced);

@override
String toString() {
  return 'DiaryModel(id: $id, date: $date, title: $title, content: $content, photoPaths: $photoPaths, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $DiaryModelCopyWith<$Res>  {
  factory $DiaryModelCopyWith(DiaryModel value, $Res Function(DiaryModel) _then) = _$DiaryModelCopyWithImpl;
@useResult
$Res call({
 int? id, String date, String title, String content, List<String> photoPaths, String userId, bool isSynced
});




}
/// @nodoc
class _$DiaryModelCopyWithImpl<$Res>
    implements $DiaryModelCopyWith<$Res> {
  _$DiaryModelCopyWithImpl(this._self, this._then);

  final DiaryModel _self;
  final $Res Function(DiaryModel) _then;

/// Create a copy of DiaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? date = null,Object? title = null,Object? content = null,Object? photoPaths = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,photoPaths: null == photoPaths ? _self.photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DiaryModel implements DiaryModel {
  const _DiaryModel({this.id, required this.date, required this.title, this.content = '', final  List<String> photoPaths = const [], required this.userId, this.isSynced = false}): _photoPaths = photoPaths;
  factory _DiaryModel.fromJson(Map<String, dynamic> json) => _$DiaryModelFromJson(json);

@override final  int? id;
@override final  String date;
@override final  String title;
@override@JsonKey() final  String content;
 final  List<String> _photoPaths;
@override@JsonKey() List<String> get photoPaths {
  if (_photoPaths is EqualUnmodifiableListView) return _photoPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoPaths);
}

@override final  String userId;
@override@JsonKey() final  bool isSynced;

/// Create a copy of DiaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryModelCopyWith<_DiaryModel> get copyWith => __$DiaryModelCopyWithImpl<_DiaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._photoPaths, _photoPaths)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,title,content,const DeepCollectionEquality().hash(_photoPaths),userId,isSynced);

@override
String toString() {
  return 'DiaryModel(id: $id, date: $date, title: $title, content: $content, photoPaths: $photoPaths, userId: $userId, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$DiaryModelCopyWith<$Res> implements $DiaryModelCopyWith<$Res> {
  factory _$DiaryModelCopyWith(_DiaryModel value, $Res Function(_DiaryModel) _then) = __$DiaryModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String date, String title, String content, List<String> photoPaths, String userId, bool isSynced
});




}
/// @nodoc
class __$DiaryModelCopyWithImpl<$Res>
    implements _$DiaryModelCopyWith<$Res> {
  __$DiaryModelCopyWithImpl(this._self, this._then);

  final _DiaryModel _self;
  final $Res Function(_DiaryModel) _then;

/// Create a copy of DiaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? date = null,Object? title = null,Object? content = null,Object? photoPaths = null,Object? userId = null,Object? isSynced = null,}) {
  return _then(_DiaryModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,photoPaths: null == photoPaths ? _self._photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
