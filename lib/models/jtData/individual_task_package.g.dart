// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'individual_task_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndividualTaskPackageList _$IndividualTaskPackageListFromJson(
        Map<String, dynamic> json) =>
    IndividualTaskPackageList(
      code: json['code'] as String?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map(
              (e) => IndividualTaskPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IndividualTaskPackageListToJson(
        IndividualTaskPackageList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

IndividualTaskPackage _$IndividualTaskPackageFromJson(
        Map<String, dynamic> json) =>
    IndividualTaskPackage(
      code: json['code'] as String?,
      remark: json['remark'] as String?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      station: json['station'] as String?,
      deptId: (json['deptId'] as num?)?.toInt(),
      repairProcCode: json['repairProcCode'] as String?,
      ends: json['ends'] as String?,
      typeCode: json['typeCode'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      trainEntryCode: json['trainEntryCode'] as String?,
      packageVersionEncode: json['packageVersionEncode'] as String?,
      packageVersionCode: json['packageVersionCode'] as String?,
      complete: json['complete'] as String?,
      executorId: (json['executorId'] as num?)?.toInt(),
      executorName: json['executorName'] as String?,
      techMeasure: json['techMeasure'] as bool?,
      itemType: (json['itemType'] as num?)?.toInt(),
      packageEternalCode: json['packageEternalCode'] as String?,
      taskCertainPackageList: (json['taskCertainPackageList'] as List<dynamic>?)
          ?.map(
              (e) => TaskCertainPackageList.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: (json['progress'] as num?)?.toDouble(),
      wholePackage: json['wholePackage'] as bool?,
      total: (json['total'] as num?)?.toInt(),
      completeCount: (json['completeCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IndividualTaskPackageToJson(
        IndividualTaskPackage instance) =>
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
      'taskCertainPackageList': instance.taskCertainPackageList,
      'progress': instance.progress,
      'wholePackage': instance.wholePackage,
      'total': instance.total,
      'completeCount': instance.completeCount,
    };

TaskCertainPackageList _$TaskCertainPackageListFromJson(
        Map<String, dynamic> json) =>
    TaskCertainPackageList(
      code: json['code'] as String?,
      station: json['station'] as String?,
      deptId: (json['deptId'] as num?)?.toInt(),
      configCode: json['configCode'] as String?,
      name: json['name'] as String?,
      repairProcCode: json['repairProcCode'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      ends: json['ends'] as String?,
      endsCode: json['endsCode'] as String?,
      typeCode: json['typeCode'] as String?,
      repairTimes: json['repairTimes'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      itemType: (json['itemType'] as num?)?.toInt(),
      riskLevel: json['riskLevel'] as String?,
      packageCode: json['packageCode'] as String?,
      packageSort: (json['packageSort'] as num?)?.toInt(),
      configNodeLevel: (json['configNodeLevel'] as num?)?.toInt(),
      taskInstructContentList:
          (json['taskInstructContentList'] as List<dynamic>?)
              ?.map((e) =>
                  TaskInstructContentList.fromJson(e as Map<String, dynamic>))
              .toList(),
      complete: json['complete'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      executorId: (json['executorId'] as num?)?.toInt(),
      executorName: json['executorName'] as String?,
      secondPackageCode: json['secondPackageCode'] as String?,
      mutualInspectionPersonnel: json['mutualInspectionPersonnel'] as String?,
      specialInspectionPersonnel: json['specialInspectionPersonnel'] as String?,
      mutualInspectionId: (json['mutualInspectionId'] as num?)?.toInt(),
      specialInspectionId: (json['specialInspectionId'] as num?)?.toInt(),
      mutualInspectionName: json['mutualInspectionName'] as String?,
      specialInspectionName: json['specialInspectionName'] as String?,
      selected: json['selected'] as bool?,
      expanded: json['expanded'] as bool?,
      completeTime: json['completeTime'] == null
          ? null
          : DateTime.parse(json['completeTime'] as String),
    );

Map<String, dynamic> _$TaskCertainPackageListToJson(
        TaskCertainPackageList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'station': instance.station,
      'deptId': instance.deptId,
      'configCode': instance.configCode,
      'name': instance.name,
      'repairProcCode': instance.repairProcCode,
      'sort': instance.sort,
      'ends': instance.ends,
      'endsCode': instance.endsCode,
      'typeCode': instance.typeCode,
      'repairTimes': instance.repairTimes,
      'repairMainNodeCode': instance.repairMainNodeCode,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'itemType': instance.itemType,
      'riskLevel': instance.riskLevel,
      'packageCode': instance.packageCode,
      'packageSort': instance.packageSort,
      'configNodeLevel': instance.configNodeLevel,
      'taskInstructContentList': instance.taskInstructContentList,
      'complete': instance.complete,
      'progress': instance.progress,
      'executorId': instance.executorId,
      'executorName': instance.executorName,
      'secondPackageCode': instance.secondPackageCode,
      'mutualInspectionPersonnel': instance.mutualInspectionPersonnel,
      'specialInspectionPersonnel': instance.specialInspectionPersonnel,
      'mutualInspectionId': instance.mutualInspectionId,
      'specialInspectionId': instance.specialInspectionId,
      'mutualInspectionName': instance.mutualInspectionName,
      'specialInspectionName': instance.specialInspectionName,
      'selected': instance.selected,
      'expanded': instance.expanded,
      'completeTime': instance.completeTime?.toIso8601String(),
    };

TaskInstructContentList _$TaskInstructContentListFromJson(
        Map<String, dynamic> json) =>
    TaskInstructContentList(
      code: json['code'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      configCode: json['configCode'] as String?,
      name: json['name'] as String?,
      repairTimes: json['repairTimes'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: (json['createdTime'] as num?)?.toInt(),
      updatedBy: json['updatedBy'] as String?,
      updatedTime: (json['updatedTime'] as num?)?.toInt(),
      itemType: (json['itemType'] as num?)?.toInt(),
      riskLevel: json['riskLevel'] as String?,
      workContent: json['workContent'] as String?,
      configNum: json['configNum'],
      dataContent: json['dataContent'],
      standardPhoto: json['standardPhoto'],
      opTechnic: json['opTechnic'],
      scopeVersionCode: json['scopeVersionCode'] as String?,
      complete: json['complete'] as String?,
      certainPackageCode: json['certainPackageCode'] as String?,
      packageFlag: json['packageFlag'] as bool?,
      manufacturerFlag: json['manufacturerFlag'] as bool?,
      techMeasure: json['techMeasure'] as bool?,
      taskContentItemList: (json['taskContentItemList'] as List<dynamic>?)
          ?.map((e) => TaskContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TaskInstructContentListToJson(
        TaskInstructContentList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'sort': instance.sort,
      'configCode': instance.configCode,
      'name': instance.name,
      'repairTimes': instance.repairTimes,
      'repairMainNodeCode': instance.repairMainNodeCode,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'itemType': instance.itemType,
      'riskLevel': instance.riskLevel,
      'workContent': instance.workContent,
      'configNum': instance.configNum,
      'dataContent': instance.dataContent,
      'standardPhoto': instance.standardPhoto,
      'opTechnic': instance.opTechnic,
      'scopeVersionCode': instance.scopeVersionCode,
      'complete': instance.complete,
      'certainPackageCode': instance.certainPackageCode,
      'packageFlag': instance.packageFlag,
      'manufacturerFlag': instance.manufacturerFlag,
      'techMeasure': instance.techMeasure,
      'taskContentItemList': instance.taskContentItemList,
    };

TaskContentItem _$TaskContentItemFromJson(Map<String, dynamic> json) =>
    TaskContentItem(
      code: json['code'] as String?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: (json['createdTime'] as num?)?.toInt(),
      updatedBy: json['updatedBy'] as String?,
      updatedTime: (json['updatedTime'] as num?)?.toInt(),
      instructContentCode: json['instructContentCode'] as String?,
      itemCode: json['itemCode'] as String?,
      dataName: json['dataName'] as String?,
      limitMin: (json['limitMin'] as num?)?.toDouble(),
      workContent: json['workContent'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      limitMax: (json['limitMax'] as num?)?.toDouble(),
      limitUnit: json['limitUnit'] as String?,
      boundaryCaseMin: (json['boundaryCaseMin'] as num?)?.toInt(),
      boundaryCaseMax: (json['boundaryCaseMax'] as num?)?.toInt(),
      originalLimit: (json['originalLimit'] as num?)?.toDouble(),
      rangeMin: (json['rangeMin'] as num?)?.toDouble(),
      rangeMax: (json['rangeMax'] as num?)?.toDouble(),
      percentage: json['percentage'] as bool?,
      realValue: (json['realValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TaskContentItemToJson(TaskContentItem instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'instructContentCode': instance.instructContentCode,
      'itemCode': instance.itemCode,
      'dataName': instance.dataName,
      'limitMin': instance.limitMin,
      'workContent': instance.workContent,
      'sort': instance.sort,
      'limitMax': instance.limitMax,
      'limitUnit': instance.limitUnit,
      'boundaryCaseMin': instance.boundaryCaseMin,
      'boundaryCaseMax': instance.boundaryCaseMax,
      'originalLimit': instance.originalLimit,
      'rangeMin': instance.rangeMin,
      'rangeMax': instance.rangeMax,
      'percentage': instance.percentage,
      'realValue': instance.realValue,
    };
