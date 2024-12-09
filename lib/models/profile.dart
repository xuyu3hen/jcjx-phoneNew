import 'package:json_annotation/json_annotation.dart';
import 'package:jcjx_phone/models/accessToken.dart';
import 'index.dart';
part 'profile.g.dart';

@JsonSerializable()
class Profile {

  Profile({
    this.code,
    this.msg,
    this.data,
    // this.roleList,
    this.permissions,
    this.access_token,
    this.theme,
    this.cache,
    this.lastLogin,
  });

  int? code;
  String? msg;
  AccessToken? data;
  // List<RoleList>? roleList;
  Permissions? permissions;
  String? access_token;
  late int? theme;
  CacheConfig? cache;
  String? lastLogin;

  factory Profile.fromJson(Map<String,dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
