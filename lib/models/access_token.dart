import 'package:json_annotation/json_annotation.dart';
part 'accessToken.g.dart';

@JsonSerializable()
class AccessToken{

  AccessToken({
    this.accessToken,
    this.expiresIn,
  });

  String? accessToken;
  int? expiresIn;

  factory AccessToken.fromJson(Map<String,dynamic> json) => _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}
