// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'myapkversion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyApkVersion _$MyApkVersionFromJson(Map<String, dynamic> json) => MyApkVersion(
      name: json['name'] as String?,
      version: json['version'] as String?,
      url: json['url'] as String?,
      dec: json['dec'] as String?,
      id: json['id'] as String?,
      createTime: json['createTime'] as String?,
    );

Map<String, dynamic> _$MyApkVersionToJson(MyApkVersion instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'url': instance.url,
      'dec': instance.dec,
      'id': instance.id,
      'createTime': instance.createTime,
    };

SysMessageVO _$SysMessageVOFromJson(Map<String, dynamic> json) => SysMessageVO(
      sysMessageVO: (json['sysMessageVO'] as List<dynamic>?)
          ?.map((e) => MessageInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SysMessageVOToJson(SysMessageVO instance) =>
    <String, dynamic>{
      'sysMessageVO': instance.sysMessageVO,
      'count': instance.count,
    };

MessageInfo _$MessageInfoFromJson(Map<String, dynamic> json) => MessageInfo(
      number1: (json['number1'] as num?)?.toInt(),
      model: json['model'] as String?,
      number2: (json['number2'] as num?)?.toInt(),
      status: json['status'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$MessageInfoToJson(MessageInfo instance) =>
    <String, dynamic>{
      'number1': instance.number1,
      'model': instance.model,
      'number2': instance.number2,
      'status': instance.status,
      'url': instance.url,
    };
