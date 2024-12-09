// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mainNode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MainNodeList _$MainNodeListFromJson(Map<String, dynamic> json) => MainNodeList(
      code: json['code'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MainNodeAndProc.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$MainNodeListToJson(MainNodeList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
      'message': instance.message,
    };

MainNodeAndProc _$MainNodeAndProcFromJson(Map<String, dynamic> json) =>
    MainNodeAndProc(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairSysCode: json['repairSysCode'] as String?,
      remark: json['remark'] as String?,
      drivingKiloStandard: json['drivingKiloStandard'] as int?,
      repairMainNodeList: (json['repairMainNodeList'] as List<dynamic>?)
          ?.map((e) => RepairMainNodeList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MainNodeAndProcToJson(MainNodeAndProc instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'repairSysCode': instance.repairSysCode,
      'remark': instance.remark,
      'drivingKiloStandard': instance.drivingKiloStandard,
      'repairMainNodeList': instance.repairMainNodeList,
    };

RepairMainNodeList _$RepairMainNodeListFromJson(Map<String, dynamic> json) =>
    RepairMainNodeList(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairProcCode: json['repairProcCode'] as String?,
      remark: json['remark'] as String?,
      deptIds: json['deptIds'] as String?,
      sysDeptList: (json['sysDeptList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      childList: (json['childList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
