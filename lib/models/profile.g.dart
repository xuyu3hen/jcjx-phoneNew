// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      data: json['data'] == null
          ? null
          : AccessToken.fromJson(json['data'] as Map<String, dynamic>),
      permissions: json['permissions'] == null
          ? null
          : Permissions.fromJson(json['permissions'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String?,
      theme: json['theme'] as int?,
      cache: json['cache'] == null
          ? null
          : CacheConfig.fromJson(json['cache'] as Map<String, dynamic>),
      lastLogin: json['lastLogin'] as String?,
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'data': instance.data,
      'permissions': instance.permissions,
      'access_token': instance.accessToken,
      'theme': instance.theme,
      'cache': instance.cache,
      'lastLogin': instance.lastLogin,
    };
