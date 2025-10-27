import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

// 最外层列表的元素模型
@JsonSerializable()
class RepairGroup {
  final List<RepairItem> children;
  final String repairProcCode;
  final String repairProcName;
  final int sort;

  RepairGroup({
    required this.children,
    required this.repairProcCode,
    required this.repairProcName,
    required this.sort,
  });

  factory RepairGroup.fromJson(Map<String, dynamic> json) =>
      _$RepairGroupFromJson(json);
}

// children 数组的元素模型
@JsonSerializable()
class RepairItem {
  final String arrivePlatformTime;
  final String assignSegmentCode;
  final String assignSegmentName;
  final int assignmentStatus;
  final C4c5ledger c4c5ledger;
  final bool canChangeRepairMainNode;
  final String cannotChangeRepairMainNodeReason;
  final String code;
  final String complete;
  final int completePackageCount;
  final String createdBy;
  final String createdTime;
  final String dynamicCode;
  final String handOverTime;
  final String leavePlatformTime;
  final String masSaleInformationCode;
  final String oilInfoImage;
  final String operateTime;
  final int operateUserId;
  final List<dynamic> queryDateRange;
  final int repairDuration;
  final int repairDurationReal;
  final String repairDynamics;
  final String repairEndTime;
  final String repairEndTimeReal;
  final String repairLocation;
  final String repairPlanCode;
  final String repairProcCode;
  final String repairProcName;
  final String repairStartTime;
  final String repairStartTimeReal;
  final String repairTimes;
  final int sort;
  final List<StateDetail> stateDetailList;
  final int status;
  final String stoppingPlace;
  final int totalPackageCount;
  final String trackNum;
  final int trainDrivingKilometer;
  final String trainNum;
  final String trainNumCode;
  final String typeCode;
  final String typeName;
  final String updatedBy;
  final String updatedTime;
  final String userName;
  final int waitingDuration;

  RepairItem({
    required this.arrivePlatformTime,
    required this.assignSegmentCode,
    required this.assignSegmentName,
    required this.assignmentStatus,
    required this.c4c5ledger,
    required this.canChangeRepairMainNode,
    required this.cannotChangeRepairMainNodeReason,
    required this.code,
    required this.complete,
    required this.completePackageCount,
    required this.createdBy,
    required this.createdTime,
    required this.dynamicCode,
    required this.handOverTime,
    required this.leavePlatformTime,
    required this.masSaleInformationCode,
    required this.oilInfoImage,
    required this.operateTime,
    required this.operateUserId,
    required this.queryDateRange,
    required this.repairDuration,
    required this.repairDurationReal,
    required this.repairDynamics,
    required this.repairEndTime,
    required this.repairEndTimeReal,
    required this.repairLocation,
    required this.repairPlanCode,
    required this.repairProcCode,
    required this.repairProcName,
    required this.repairStartTime,
    required this.repairStartTimeReal,
    required this.repairTimes,
    required this.sort,
    required this.stateDetailList,
    required this.status,
    required this.stoppingPlace,
    required this.totalPackageCount,
    required this.trackNum,
    required this.trainDrivingKilometer,
    required this.trainNum,
    required this.trainNumCode,
    required this.typeCode,
    required this.typeName,
    required this.updatedBy,
    required this.updatedTime,
    required this.userName,
    required this.waitingDuration,
  });

  factory RepairItem.fromJson(Map<String, dynamic> json) =>
      _$RepairItemFromJson(json);
}

// 嵌套的 c4c5ledger 模型
@JsonSerializable()
class C4c5ledger {
  final String code;
  final String createdBy;
  final String createdTime;
  final String firstLevelMaintenance;
  final String inspectionStatus;
  final String procRatingGrade;
  final String repairTimeoutReason;
  final String trainEntryCode;
  final String updatedBy;
  final String updatedTime;

  C4c5ledger({
    required this.code,
    required this.createdBy,
    required this.createdTime,
    required this.firstLevelMaintenance,
    required this.inspectionStatus,
    required this.procRatingGrade,
    required this.repairTimeoutReason,
    required this.trainEntryCode,
    required this.updatedBy,
    required this.updatedTime,
  });

  factory C4c5ledger.fromJson(Map<String, dynamic> json) =>
      _$C4c5ledgerFromJson(json);
}

// 嵌套的 stateDetailList 元素模型
@JsonSerializable()
class StateDetail {
  final String code;
  final String createdBy;
  final String createdTime;
  final String endTime;
  final String entryCode;
  final int exceptionCompleteCount;
  final int exceptionTotalCount;
  final int faultCompleteCount;
  final int faultTotalCount;
  final String remark;
  final String repairMainNodeCode;
  final String repairMainNodeName;
  final int sort;
  final String startTime;
  final String state;
  final String theoreticEndTime;
  final String theoreticStartTime;
  final String updatedBy;
  final String updatedTime;

  StateDetail({
    required this.code,
    required this.createdBy,
    required this.createdTime,
    required this.endTime,
    required this.entryCode,
    required this.exceptionCompleteCount,
    required this.exceptionTotalCount,
    required this.faultCompleteCount,
    required this.faultTotalCount,
    required this.remark,
    required this.repairMainNodeCode,
    required this.repairMainNodeName,
    required this.sort,
    required this.startTime,
    required this.state,
    required this.theoreticEndTime,
    required this.theoreticStartTime,
    required this.updatedBy,
    required this.updatedTime,
  });

  factory StateDetail.fromJson(Map<String, dynamic> json) =>
      _$StateDetailFromJson(json);
}