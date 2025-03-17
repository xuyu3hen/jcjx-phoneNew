// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jc_type_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JcTypeList _$JcTypeListFromJson(Map<String, dynamic> json) => JcTypeList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => JcType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JcTypeListToJson(JcTypeList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

JcType _$JcTypeFromJson(Map<String, dynamic> json) => JcType(
      code: json['code'] as String?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as int?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as int?,
      sort: json['sort'] as int?,
      length: json['length'] as String?,
      maxSpeed: json['maxSpeed'] as String?,
      maxAcceleration: json['maxAcceleration'] as String?,
      maxDeceleration: json['maxDeceleration'] as String?,
      standardWheel: json['standardWheel'] as String?,
      weight: json['weight'] as String?,
      label: json['label'] as String?,
      dynamicCode: json['dynamicCode'] as String?,
      deleted: json['deleted'] as bool?,
      nodeCode: json['nodeCode'] as String?,
    );

Map<String, dynamic> _$JcTypeToJson(JcType instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'sort': instance.sort,
      'length': instance.length,
      'maxSpeed': instance.maxSpeed,
      'maxAcceleration': instance.maxAcceleration,
      'maxDeceleration': instance.maxDeceleration,
      'standardWheel': instance.standardWheel,
      'weight': instance.weight,
      'label': instance.label,
      'dynamicCode': instance.dynamicCode,
      'deleted': instance.deleted,
      'nodeCode': instance.nodeCode,
    };
