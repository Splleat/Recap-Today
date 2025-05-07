import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:recap_today/model/user_model.dart';

part 'user_credential.freezed.dart';
part 'user_credential.g.dart';

@freezed
abstract class UserCredential with _$UserCredential {
  const factory UserCredential({
    required String accessToken,
    required User user,
  }) = _UserCredential;

  factory UserCredential.fromJson(Map<String, dynamic> json) =>
      _$UserCredentialFromJson(json);
}
