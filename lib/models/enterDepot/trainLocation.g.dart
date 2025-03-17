// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'train_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainLocation _$TrainLocationFromJson(Map<String, dynamic> json) =>
    TrainLocation(
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => Rowss.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as int?,
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$TrainLocationToJson(TrainLocation instance) =>
    <String, dynamic>{
      'total': instance.total,
      'rows': instance.rows,
      'code': instance.code,
      'msg': instance.msg,
    };

Rowss _$RowssFromJson(Map<String, dynamic> json) => Rowss(
      code: json['code'] as String?,
      deptId: json['deptId'] as int?,
      areaName: json['areaName'] as String?,
      trackNum: json['trackNum'] as String?,
      sort: json['sort'] as int?,
      remark: json['remark'] as String?,
      deptName: json['deptName'] as String?,
    );

Map<String, dynamic> _$RowssToJson(Rowss instance) => <String, dynamic>{
      'code': instance.code,
      'deptId': instance.deptId,
      'areaName': instance.areaName,
      'trackNum': instance.trackNum,
      'sort': instance.sort,
      'remark': instance.remark,
      'deptName': instance.deptName,
    };
