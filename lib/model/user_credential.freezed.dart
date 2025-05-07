// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCredential {

 String get accessToken; User get user;
/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCredentialCopyWith<UserCredential> get copyWith => _$UserCredentialCopyWithImpl<UserCredential>(this as UserCredential, _$identity);

  /// Serializes this UserCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCredential&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,user);

@override
String toString() {
  return 'UserCredential(accessToken: $accessToken, user: $user)';
}


}

/// @nodoc
abstract mixin class $UserCredentialCopyWith<$Res>  {
  factory $UserCredentialCopyWith(UserCredential value, $Res Function(UserCredential) _then) = _$UserCredentialCopyWithImpl;
@useResult
$Res call({
 String accessToken, User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserCredentialCopyWithImpl<$Res>
    implements $UserCredentialCopyWith<$Res> {
  _$UserCredentialCopyWithImpl(this._self, this._then);

  final UserCredential _self;
  final $Res Function(UserCredential) _then;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? user = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}
/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _UserCredential implements UserCredential {
  const _UserCredential({required this.accessToken, required this.user});
  factory _UserCredential.fromJson(Map<String, dynamic> json) => _$UserCredentialFromJson(json);

@override final  String accessToken;
@override final  User user;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCredentialCopyWith<_UserCredential> get copyWith => __$UserCredentialCopyWithImpl<_UserCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCredential&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,user);

@override
String toString() {
  return 'UserCredential(accessToken: $accessToken, user: $user)';
}


}

/// @nodoc
abstract mixin class _$UserCredentialCopyWith<$Res> implements $UserCredentialCopyWith<$Res> {
  factory _$UserCredentialCopyWith(_UserCredential value, $Res Function(_UserCredential) _then) = __$UserCredentialCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, User user
});


@override $UserCopyWith<$Res> get user;

}
/// @nodoc
class __$UserCredentialCopyWithImpl<$Res>
    implements _$UserCredentialCopyWith<$Res> {
  __$UserCredentialCopyWithImpl(this._self, this._then);

  final _UserCredential _self;
  final $Res Function(_UserCredential) _then;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? user = null,}) {
  return _then(_UserCredential(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
