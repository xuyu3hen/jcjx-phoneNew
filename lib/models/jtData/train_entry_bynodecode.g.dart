// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'train_entry_bynodecode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainEntryByNodeCode _$TrainEntryByNodeCodeFromJson(
        Map<String, dynamic> json) =>
    TrainEntryByNodeCode(
      createdBy: json['createdBy'] as String?,
      createdTime: (json['createdTime'] as num?)?.toInt(),
      updatedBy: json['updatedBy'] as String?,
      updatedTime: (json['updatedTime'] as num?)?.toInt(),
      sort: (json['sort'] as num?)?.toInt(),
      typeCode: json['typeCode'] as String?,
      trainNum: json['trainNum'] as String?,
      assignmentStatus: (json['assignmentStatus'] as num?)?.toInt(),
      repairLocation: json['repairLocation'] as String?,
      trackNum: json['trackNum'] as String?,
      stoppingPlace: json['stoppingPlace'] as String?,
      repairProcCode: json['repairProcCode'] as String?,
      repairTimes: json['repairTimes'] as String?,
      status: (json['status'] as num?)?.toInt(),
      operateUserId: (json['operateUserId'] as num?)?.toInt(),
      operateTime: json['operateTime'] == null
          ? null
          : DateTime.parse(json['operateTime'] as String),
      code: json['code'] as String,
      arrivePlatformTime: json['arrivePlatformTime'] == null
          ? null
          : DateTime.parse(json['arrivePlatformTime'] as String),
      dynamicCode: json['dynamicCode'] as String?,
      complete: json['complete'] as String?,
    );

Map<String, dynamic> _$TrainEntryByNodeCodeToJson(
        TrainEntryByNodeCode instance) =>
    <String, dynamic>{
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'sort': instance.sort,
      'typeCode': instance.typeCode,
      'trainNum': instance.trainNum,
      'assignmentStatus': instance.assignmentStatus,
      'repairLocation': instance.repairLocation,
      'trackNum': instance.trackNum,
      'stoppingPlace': instance.stoppingPlace,
      'repairProcCode': instance.repairProcCode,
      'repairTimes': instance.repairTimes,
      'status': instance.status,
      'operateUserId': instance.operateUserId,
      'operateTime': instance.operateTime?.toIso8601String(),
      'code': instance.code,
      'arrivePlatformTime': instance.arrivePlatformTime?.toIso8601String(),
      'dynamicCode': instance.dynamicCode,
      'complete': instance.complete,
    };
