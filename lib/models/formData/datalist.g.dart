// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datalist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataList _$DataListFromJson(Map<String, dynamic> json) => DataList(
      total: (json['total'] as num?)?.toInt(),
      code: (json['code'] as num?)?.toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$DataListToJson(DataList instance) => <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
    };
