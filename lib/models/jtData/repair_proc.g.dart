// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_proc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairProcAndNode _$RepairProcAndNodeFromJson(Map<String, dynamic> json) =>
    RepairProcAndNode(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairSysCode: json['repairSysCode'] as String?,
      remark: json['remark'] as String?,
      repairMainNodeList: (json['repairMainNodeList'] as List<dynamic>?)
          ?.map((e) => RepairMainNodeList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RepairProcAndNodeToJson(RepairProcAndNode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'repairSysCode': instance.repairSysCode,
      'remark': instance.remark,
      'repairMainNodeList': instance.repairMainNodeList,
    };

RepairMainNodeList _$RepairMainNodeListFromJson(Map<String, dynamic> json) =>
    RepairMainNodeList(
      code: json['code'] as String,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairProcCode: json['repairProcCode'] as String?,
      remark: json['remark'] as String?,
      deptIds: json['deptIds'] as String?,
      sysDeptList: json['sysDeptList'],
      childList: json['childList'],
      deleted: json['deleted'] as bool?,
    );

Map<String, dynamic> _$RepairMainNodeListToJson(RepairMainNodeList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'repairProcCode': instance.repairProcCode,
      'remark': instance.remark,
      'deptIds': instance.deptIds,
      'sysDeptList': instance.sysDeptList,
      'childList': instance.childList,
      'deleted': instance.deleted,
    };
