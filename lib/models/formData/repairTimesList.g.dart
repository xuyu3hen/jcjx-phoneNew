// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repairTimesList.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairTimesList _$RepairTimesListFromJson(Map<String, dynamic> json) =>
    RepairTimesList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => RepairTimes.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RepairTimesListToJson(RepairTimesList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

RepairTimes _$RepairTimesFromJson(Map<String, dynamic> json) => RepairTimes(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sort: json['sort'] as int?,
      repairProcCode: json['repairProcCode'] as String?,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$RepairTimesToJson(RepairTimes instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sort': instance.sort,
      'repairProcCode': instance.repairProcCode,
      'remark': instance.remark,
    };
