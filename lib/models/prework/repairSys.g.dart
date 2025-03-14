// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_sys.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairSysResponse _$RepairSysResponseFromJson(Map<String, dynamic> json) =>
    RepairSysResponse(
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => RepairSys.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
    );

Map<String, dynamic> _$RepairSysResponseToJson(RepairSysResponse instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

RepairSys _$RepairSysFromJson(Map<String, dynamic> json) => RepairSys(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      dynamicCode: json['dynamicCode'] as String?,
      remark: json['remark'] as String?,
      repairProcList: json['repairProcList'] as String?,
    );

Map<String, dynamic> _$RepairSysToJson(RepairSys instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'dynamicCode': instance.dynamicCode,
      'remark': instance.remark,
      'repairProcList': instance.repairProcList,
    };
