// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trainEntryList.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainEntryList _$TrainEntryListFromJson(Map<String, dynamic> json) =>
    TrainEntryList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => TrainEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainEntryListToJson(TrainEntryList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

TrainEntry _$TrainEntryFromJson(Map<String, dynamic> json) => TrainEntry(
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      sort: json['sort'] as int?,
      typeCode: json['typeCode'] as String?,
      trainNumCode: json['trainNumCode'] as String?,
      assignmentStatus: json['assignmentStatus'] as int?,
      repairLocation: json['repairLocation'] as String?,
      trackNum: json['trackNum'] as String?,
      stoppingPlace: json['stoppingPlace'] as String?,
      repairProcCode: json['repairProcCode'] as String?,
      repairTimes: json['repairTimes'] as String?,
      status: json['status'] as int?,
      operateUserId: json['operateUserId'] as int?,
      operateTime: json['operateTime'] as String?,
      code: json['code'] as String?,
      typeName: json['typeName'] as String?,
      trainNum: json['trainNum'] as String?,
      repairProcName: json['repairProcName'] as String?,
      userName: json['userName'],
      arrivePlatformTime: json['arrivePlatformTime'] as String?,
      dynamicCode: json['dynamicCode'] as String?,
      antiSlipImage: json['antiSlipImage'] as String?,
      oilInfoImage: json['oilInfoImage'] as String?,
    );

Map<String, dynamic> _$TrainEntryToJson(TrainEntry instance) =>
    <String, dynamic>{
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'sort': instance.sort,
      'typeCode': instance.typeCode,
      'trainNumCode': instance.trainNumCode,
      'assignmentStatus': instance.assignmentStatus,
      'repairLocation': instance.repairLocation,
      'trackNum': instance.trackNum,
      'stoppingPlace': instance.stoppingPlace,
      'repairProcCode': instance.repairProcCode,
      'repairTimes': instance.repairTimes,
      'status': instance.status,
      'operateUserId': instance.operateUserId,
      'operateTime': instance.operateTime,
      'code': instance.code,
      'typeName': instance.typeName,
      'trainNum': instance.trainNum,
      'repairProcName': instance.repairProcName,
      'userName': instance.userName,
      'arrivePlatformTime': instance.arrivePlatformTime,
      'dynamicCode': instance.dynamicCode,
      'antiSlipImage': instance.antiSlipImage,
      'oilInfoImage': instance.oilInfoImage,
    };
