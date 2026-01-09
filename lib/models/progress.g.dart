// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairGroup _$RepairGroupFromJson(Map<String, dynamic> json) => RepairGroup(
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => RepairItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      repairProcCode: json['repairProcCode'] as String?,
      repairProcName: json['repairProcName'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RepairGroupToJson(RepairGroup instance) =>
    <String, dynamic>{
      'children': instance.children,
      'repairProcCode': instance.repairProcCode,
      'repairProcName': instance.repairProcName,
      'sort': instance.sort,
    };

RepairItem _$RepairItemFromJson(Map<String, dynamic> json) => RepairItem(
      arrivePlatformTime: json['arrivePlatformTime'] as String?,
      assignSegmentCode: json['assignSegmentCode'] as String?,
      assignSegmentName: json['assignSegmentName'] as String?,
      assignmentStatus: (json['assignmentStatus'] as num?)?.toInt(),
      c4c5ledger: json['c4c5ledger'] == null
          ? null
          : C4c5ledger.fromJson(json['c4c5ledger'] as Map<String, dynamic>),
      canChangeRepairMainNode: json['canChangeRepairMainNode'] as bool?,
      cannotChangeRepairMainNodeReason:
          json['cannotChangeRepairMainNodeReason'] as String?,
      code: json['code'] as String?,
      complete: json['complete'] as String?,
      completePackageCount: (json['completePackageCount'] as num?)?.toInt(),
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      dynamicCode: json['dynamicCode'] as String?,
      handOverTime: json['handOverTime'] as String?,
      leavePlatformTime: json['leavePlatformTime'] as String?,
      masSaleInformationCode: json['masSaleInformationCode'] as String?,
      oilInfoImage: json['oilInfoImage'] as String?,
      operateTime: json['operateTime'] as String?,
      operateUserId: (json['operateUserId'] as num?)?.toInt(),
      queryDateRange: json['queryDateRange'] as List<dynamic>?,
      repairDuration: (json['repairDuration'] as num?)?.toInt(),
      repairDurationReal: (json['repairDurationReal'] as num?)?.toInt(),
      repairDynamics: json['repairDynamics'] as String?,
      repairEndTime: json['repairEndTime'] as String?,
      repairEndTimeReal: json['repairEndTimeReal'] as String?,
      repairLocation: json['repairLocation'] as String?,
      repairPlanCode: json['repairPlanCode'] as String?,
      repairProcCode: json['repairProcCode'] as String?,
      repairProcName: json['repairProcName'] as String?,
      repairStartTime: json['repairStartTime'] as String?,
      repairStartTimeReal: json['repairStartTimeReal'] as String?,
      repairTimes: json['repairTimes'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      stateDetailList: (json['stateDetailList'] as List<dynamic>?)
          ?.map((e) => StateDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: (json['status'] as num?)?.toInt(),
      stoppingPlace: json['stoppingPlace'] as String?,
      totalPackageCount: (json['totalPackageCount'] as num?)?.toInt(),
      trackNum: json['trackNum'] as String?,
      trainDrivingKilometer: (json['trainDrivingKilometer'] as num?)?.toInt(),
      trainNum: json['trainNum'] as String?,
      trainNumCode: json['trainNumCode'] as String?,
      typeCode: json['typeCode'] as String?,
      typeName: json['typeName'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      userName: json['userName'] as String?,
      waitingDuration: (json['waitingDuration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RepairItemToJson(RepairItem instance) =>
    <String, dynamic>{
      'arrivePlatformTime': instance.arrivePlatformTime,
      'assignSegmentCode': instance.assignSegmentCode,
      'assignSegmentName': instance.assignSegmentName,
      'assignmentStatus': instance.assignmentStatus,
      'c4c5ledger': instance.c4c5ledger,
      'canChangeRepairMainNode': instance.canChangeRepairMainNode,
      'cannotChangeRepairMainNodeReason':
          instance.cannotChangeRepairMainNodeReason,
      'code': instance.code,
      'complete': instance.complete,
      'completePackageCount': instance.completePackageCount,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'dynamicCode': instance.dynamicCode,
      'handOverTime': instance.handOverTime,
      'leavePlatformTime': instance.leavePlatformTime,
      'masSaleInformationCode': instance.masSaleInformationCode,
      'oilInfoImage': instance.oilInfoImage,
      'operateTime': instance.operateTime,
      'operateUserId': instance.operateUserId,
      'queryDateRange': instance.queryDateRange,
      'repairDuration': instance.repairDuration,
      'repairDurationReal': instance.repairDurationReal,
      'repairDynamics': instance.repairDynamics,
      'repairEndTime': instance.repairEndTime,
      'repairEndTimeReal': instance.repairEndTimeReal,
      'repairLocation': instance.repairLocation,
      'repairPlanCode': instance.repairPlanCode,
      'repairProcCode': instance.repairProcCode,
      'repairProcName': instance.repairProcName,
      'repairStartTime': instance.repairStartTime,
      'repairStartTimeReal': instance.repairStartTimeReal,
      'repairTimes': instance.repairTimes,
      'sort': instance.sort,
      'stateDetailList': instance.stateDetailList,
      'status': instance.status,
      'stoppingPlace': instance.stoppingPlace,
      'totalPackageCount': instance.totalPackageCount,
      'trackNum': instance.trackNum,
      'trainDrivingKilometer': instance.trainDrivingKilometer,
      'trainNum': instance.trainNum,
      'trainNumCode': instance.trainNumCode,
      'typeCode': instance.typeCode,
      'typeName': instance.typeName,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'userName': instance.userName,
      'waitingDuration': instance.waitingDuration,
    };

C4c5ledger _$C4c5ledgerFromJson(Map<String, dynamic> json) => C4c5ledger(
      code: json['code'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      firstLevelMaintenance: json['firstLevelMaintenance'] as String?,
      inspectionStatus: json['inspectionStatus'] as String?,
      procRatingGrade: json['procRatingGrade'] as String?,
      repairTimeoutReason: json['repairTimeoutReason'] as String?,
      trainEntryCode: json['trainEntryCode'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
    );

Map<String, dynamic> _$C4c5ledgerToJson(C4c5ledger instance) =>
    <String, dynamic>{
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'firstLevelMaintenance': instance.firstLevelMaintenance,
      'inspectionStatus': instance.inspectionStatus,
      'procRatingGrade': instance.procRatingGrade,
      'repairTimeoutReason': instance.repairTimeoutReason,
      'trainEntryCode': instance.trainEntryCode,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
    };

StateDetail _$StateDetailFromJson(Map<String, dynamic> json) => StateDetail(
      code: json['code'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      endTime: json['endTime'] as String?,
      entryCode: json['entryCode'] as String?,
      exceptionCompleteCount: (json['exceptionCompleteCount'] as num?)?.toInt(),
      exceptionTotalCount: (json['exceptionTotalCount'] as num?)?.toInt(),
      faultCompleteCount: (json['faultCompleteCount'] as num?)?.toInt(),
      faultTotalCount: (json['faultTotalCount'] as num?)?.toInt(),
      remark: json['remark'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      repairMainNodeName: json['repairMainNodeName'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      startTime: json['startTime'] as String?,
      state: json['state'] as String?,
      theoreticEndTime: json['theoreticEndTime'] as String?,
      theoreticStartTime: json['theoreticStartTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
    );

Map<String, dynamic> _$StateDetailToJson(StateDetail instance) =>
    <String, dynamic>{
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'endTime': instance.endTime,
      'entryCode': instance.entryCode,
      'exceptionCompleteCount': instance.exceptionCompleteCount,
      'exceptionTotalCount': instance.exceptionTotalCount,
      'faultCompleteCount': instance.faultCompleteCount,
      'faultTotalCount': instance.faultTotalCount,
      'remark': instance.remark,
      'repairMainNodeCode': instance.repairMainNodeCode,
      'repairMainNodeName': instance.repairMainNodeName,
      'sort': instance.sort,
      'startTime': instance.startTime,
      'state': instance.state,
      'theoreticEndTime': instance.theoreticEndTime,
      'theoreticStartTime': instance.theoreticStartTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
    };

DeptProgress _$DeptProgressFromJson(Map<String, dynamic> json) => DeptProgress(
      deptId: (json['deptId'] as num?)?.toInt(),
      deptName: json['deptName'] as String?,
      repairMainNodeProgressList: (json['repairMainNodeProgressList'] as List<dynamic>?)
          ?.map((e) => RepairMainNodeProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DeptProgressToJson(DeptProgress instance) =>
    <String, dynamic>{
      'deptId': instance.deptId,
      'deptName': instance.deptName,
      'repairMainNodeProgressList': instance.repairMainNodeProgressList,
    };

RepairMainNodeProgress _$RepairMainNodeProgressFromJson(Map<String, dynamic> json) => RepairMainNodeProgress(
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      repairMainNodeName: json['repairMainNodeName'] as String?,
      repairProcCode: json['repairProcCode'] as String?,
      totalSelfInspectionCount: (json['totalSelfInspectionCount'] as num?)?.toInt(),
      completeSelfInspectionCount: (json['completeSelfInspectionCount'] as num?)?.toInt(),
      totalMutualInspectionCount: (json['totalMutualInspectionCount'] as num?)?.toInt(),
      completeMutualInspectionCount: (json['completeMutualInspectionCount'] as num?)?.toInt(),
      totalJt28Count: (json['totalJt28Count'] as num?)?.toInt(),
      completeJt28Count: (json['completeJt28Count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RepairMainNodeProgressToJson(RepairMainNodeProgress instance) =>
    <String, dynamic>{
      'repairMainNodeCode': instance.repairMainNodeCode,
      'repairMainNodeName': instance.repairMainNodeName,
      'repairProcCode': instance.repairProcCode,
      'totalSelfInspectionCount': instance.totalSelfInspectionCount,
      'completeSelfInspectionCount': instance.completeSelfInspectionCount,
      'totalMutualInspectionCount': instance.totalMutualInspectionCount,
      'completeMutualInspectionCount': instance.completeMutualInspectionCount,
      'totalJt28Count': instance.totalJt28Count,
      'completeJt28Count': instance.completeJt28Count,
    };