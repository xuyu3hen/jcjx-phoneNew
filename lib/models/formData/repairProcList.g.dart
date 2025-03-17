// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_proc_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairProcList _$RepairProcListFromJson(Map<String, dynamic> json) =>
    RepairProcList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => RepairProc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RepairProcListToJson(RepairProcList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

RepairProc _$RepairProcFromJson(Map<String, dynamic> json) => RepairProc(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairSysCode: json['repairSysCode'] as String?,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$RepairProcToJson(RepairProc instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'repairSysCode': instance.repairSysCode,
      'remark': instance.remark,
    };
