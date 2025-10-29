import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

// 最外层列表的元素模型
@JsonSerializable()
class RepairGroup {
  final List<RepairItem>? children;
  final String? repairProcCode;
  final String? repairProcName;
  final int? sort;

  RepairGroup({
    this.children,
    this.repairProcCode,
    this.repairProcName,
    this.sort,
  });

  factory RepairGroup.fromJson(Map<String, dynamic> json) =>
      _$RepairGroupFromJson(json);
}

// children 数组的元素模型
@JsonSerializable()
class RepairItem {
  final String? arrivePlatformTime;
  final String? assignSegmentCode;
  final String? assignSegmentName;
  final int? assignmentStatus;
  final C4c5ledger? c4c5ledger;
  final bool? canChangeRepairMainNode;
  final String? cannotChangeRepairMainNodeReason;
  final String? code;
  final String? complete;
  final int? completePackageCount;
  final String? createdBy;
  final String? createdTime;
  final String? dynamicCode;
  final String? handOverTime;
  final String? leavePlatformTime;
  final String? masSaleInformationCode;
  final String? oilInfoImage;
  final String? operateTime;
  final int? operateUserId;
  final List<dynamic>? queryDateRange;
  final int? repairDuration;
  final int? repairDurationReal;
  final String? repairDynamics;
  final String? repairEndTime;
  final String? repairEndTimeReal;
  final String? repairLocation;
  final String? repairPlanCode;
  final String? repairProcCode;
  final String? repairProcName;
  final String? repairStartTime;
  final String? repairStartTimeReal;
  final String? repairTimes;
  final int? sort;
  final List<StateDetail>? stateDetailList;
  final int? status;
  final String? stoppingPlace;
  final int? totalPackageCount;
  final String? trackNum;
  final int? trainDrivingKilometer;
  final String? trainNum;
  final String? trainNumCode;
  final String? typeCode;
  final String? typeName;
  final String? updatedBy;
  final String? updatedTime;
  final String? userName;
  final int? waitingDuration;

  RepairItem({
    this.arrivePlatformTime,
    this.assignSegmentCode,
    this.assignSegmentName,
    this.assignmentStatus,
    this.c4c5ledger,
    this.canChangeRepairMainNode,
    this.cannotChangeRepairMainNodeReason,
    this.code,
    this.complete,
    this.completePackageCount,
    this.createdBy,
    this.createdTime,
    this.dynamicCode,
    this.handOverTime,
    this.leavePlatformTime,
    this.masSaleInformationCode,
    this.oilInfoImage,
    this.operateTime,
    this.operateUserId,
    this.queryDateRange,
    this.repairDuration,
    this.repairDurationReal,
    this.repairDynamics,
    this.repairEndTime,
    this.repairEndTimeReal,
    this.repairLocation,
    this.repairPlanCode,
    this.repairProcCode,
    this.repairProcName,
    this.repairStartTime,
    this.repairStartTimeReal,
    this.repairTimes,
    this.sort,
    this.stateDetailList,
    this.status,
    this.stoppingPlace,
    this.totalPackageCount,
    this.trackNum,
    this.trainDrivingKilometer,
    this.trainNum,
    this.trainNumCode,
    this.typeCode,
    this.typeName,
    this.updatedBy,
    this.updatedTime,
    this.userName,
    this.waitingDuration,
  });

  factory RepairItem.fromJson(Map<String, dynamic> json) =>
      _$RepairItemFromJson(json);
}

// 嵌套的 c4c5ledger 模型
@JsonSerializable()
class C4c5ledger {
  final String? code;
  final String? createdBy;
  final String? createdTime;
  final String? firstLevelMaintenance;
  final String? inspectionStatus;
  final String? procRatingGrade;
  final String? repairTimeoutReason;
  final String? trainEntryCode;
  final String? updatedBy;
  final String? updatedTime;

  C4c5ledger({
    this.code,
    this.createdBy,
    this.createdTime,
    this.firstLevelMaintenance,
    this.inspectionStatus,
    this.procRatingGrade,
    this.repairTimeoutReason,
    this.trainEntryCode,
    this.updatedBy,
    this.updatedTime,
  });

  factory C4c5ledger.fromJson(Map<String, dynamic> json) =>
      _$C4c5ledgerFromJson(json);
}

// 嵌套的 stateDetailList 元素模型
@JsonSerializable()
class StateDetail {
  final String? code;
  final String? createdBy;
  final String? createdTime;
  final String? endTime;
  final String? entryCode;
  final int? exceptionCompleteCount;
  final int? exceptionTotalCount;
  final int? faultCompleteCount;
  final int? faultTotalCount;
  final String? remark;
  final String? repairMainNodeCode;
  final String? repairMainNodeName;
  final int? sort;
  final String? startTime;
  final String? state;
  final String? theoreticEndTime;
  final String? theoreticStartTime;
  final String? updatedBy;
  final String? updatedTime;

  StateDetail({
    this.code,
    this.createdBy,
    this.createdTime,
    this.endTime,
    this.entryCode,
    this.exceptionCompleteCount,
    this.exceptionTotalCount,
    this.faultCompleteCount,
    this.faultTotalCount,
    this.remark,
    this.repairMainNodeCode,
    this.repairMainNodeName,
    this.sort,
    this.startTime,
    this.state,
    this.theoreticEndTime,
    this.theoreticStartTime,
    this.updatedBy,
    this.updatedTime,
  });

  factory StateDetail.fromJson(Map<String, dynamic> json) =>
      _$StateDetailFromJson(json);
}