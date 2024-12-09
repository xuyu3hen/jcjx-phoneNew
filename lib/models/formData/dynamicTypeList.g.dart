// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dynamicTypeList.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DynamicTypeList _$DynamicTypeListFromJson(Map<String, dynamic> json) =>
    DynamicTypeList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => DynamicType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DynamicTypeListToJson(DynamicTypeList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

DynamicType _$DynamicTypeFromJson(Map<String, dynamic> json) => DynamicType(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      nodeCode: json['nodeCode'] as String?,
      jcTypeList: json['jcTypeList'] as String?,
    );

Map<String, dynamic> _$DynamicTypeToJson(DynamicType instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'nodeCode': instance.nodeCode,
      'jcTypeList': instance.jcTypeList,
    };
