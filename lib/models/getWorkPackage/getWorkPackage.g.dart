// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'getWorkPackage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkPackageList _$WorkPackageListFromJson(Map<String, dynamic> json) =>
    WorkPackageList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => WorkPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkPackageListToJson(WorkPackageList instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

WorkPackage _$WorkPackageFromJson(Map<String, dynamic> json) => WorkPackage(
      code: json['code'] as String?,
      remark: json['remark'] as String?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      station: json['station'] as String?,
      deptId: json['deptId'] as int?,
      repairProcCode: json['repairProcCode'] as String?,
      ends: json['ends'] as String?,
      typeCode: json['typeCode'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      trainEntryCode: json['trainEntryCode'] as String?,
      packageVersionEncode: json['packageVersionEncode'] as String?,
      packageVersionCode: json['packageVersionCode'] as String?,
      complete: json['complete'] as String?,
      executorId: json['executorId'] as int?,
      executorName: json['executorName'] as String?,
      techMeasure: json['techMeasure'] as bool?,
      itemType: json['itemType'] as int?,
      packageEternalCode: json['packageEternalCode'] as String?,
      repairPersonnel: json['repairPersonnel'] as String?,
      assistant: json['assistant'] as String?,
      wholePackage: json['wholePackage'] as bool?,
      assistantId: json['assistantId'] as int?,
      assistantName: json['assistantName'] as String?,
      assistantNameList: json['assistantNameList'] as String?,
      repairPersonnelNameList: json['repairPersonnelNameList'] as String?,
      jt28Code: json['jt28Code'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      taskCertainPackageList: (json['taskCertainPackageList'] as List<dynamic>?)
          ?.map(
              (e) => TaskCertainPackageList.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: (json['progress'] as num?)?.toDouble(),
      total: json['total'] as int?,
      completeCount: json['completeCount'] as int?,
    );

Map<String, dynamic> _$WorkPackageToJson(WorkPackage instance) =>
    <String, dynamic>{
      'code': instance.code,
      'remark': instance.remark,
      'name': instance.name,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'station': instance.station,
      'deptId': instance.deptId,
      'repairProcCode': instance.repairProcCode,
      'ends': instance.ends,
      'typeCode': instance.typeCode,
      'repairMainNodeCode': instance.repairMainNodeCode,
      'trainEntryCode': instance.trainEntryCode,
      'packageVersionEncode': instance.packageVersionEncode,
      'packageVersionCode': instance.packageVersionCode,
      'complete': instance.complete,
      'executorId': instance.executorId,
      'executorName': instance.executorName,
      'techMeasure': instance.techMeasure,
      'itemType': instance.itemType,
      'packageEternalCode': instance.packageEternalCode,
      'repairPersonnel': instance.repairPersonnel,
      'assistant': instance.assistant,
      'wholePackage': instance.wholePackage,
      'assistantId': instance.assistantId,
      'assistantName': instance.assistantName,
      'assistantNameList': instance.assistantNameList,
      'repairPersonnelNameList': instance.repairPersonnelNameList,
      'jt28Code': instance.jt28Code,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'taskCertainPackageList': instance.taskCertainPackageList,
      'progress': instance.progress,
      'total': instance.total,
      'completeCount': instance.completeCount,
    };
