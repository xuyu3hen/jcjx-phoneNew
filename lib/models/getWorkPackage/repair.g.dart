// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairResponse _$RepairResponseFromJson(Map<String, dynamic> json) =>
    RepairResponse(
      code: json['code'] as String?,
      data: json['data'] as String?,
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$RepairResponseToJson(RepairResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
      'msg': instance.msg,
    };

FaultResponse _$FaultResponseFromJson(Map<String, dynamic> json) =>
    FaultResponse(
      code: json['code'] as String?,
      data: json['data'] == null
          ? null
          : FaultShow.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      time: json['time'] as String?,
    );

Map<String, dynamic> _$FaultResponseToJson(FaultResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
      'message': instance.message,
      'time': instance.time,
    };

FaultShow _$FaultShowFromJson(Map<String, dynamic> json) => FaultShow(
      msg: json['msg'] as String?,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$FaultShowToJson(FaultShow instance) => <String, dynamic>{
      'msg': instance.msg,
      'code': instance.code,
    };
