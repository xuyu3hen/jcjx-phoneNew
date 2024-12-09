import 'package:json_annotation/json_annotation.dart';
part 'accessToken.g.dart';

@JsonSerializable()
class AccessToken{

  AccessToken({
    this.access_token,
    this.expires_in,
  });

  String? access_token;
  int? expires_in;

  factory AccessToken.fromJson(Map<String,dynamic> json) => _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}
