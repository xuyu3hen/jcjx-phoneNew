import 'package:json_annotation/json_annotation.dart';

import '../../index.dart';
part 'getWorkPackage.g.dart';

@JsonSerializable()
class WorkPackageList {
  List<WorkPackage>? data;
  WorkPackageList({
    required this.data,
  });
  factory WorkPackageList.fromJson(Map<String, dynamic> json) =>
      _$WorkPackageListFromJson(json);
  Map<String, dynamic> toJson() => _$WorkPackageListToJson(this);
  //tomapList
  List<Map<String, dynamic>> toMapList() {
    return data?.map((item) => item.toJson()).toList() ?? [];
  }
}

@JsonSerializable()
class WorkPackage {
  String? code;
  String? remark;
  String? name;
  String? createdBy;
  String? createdTime;
  String? updatedBy;
  String? updatedTime;
  String? station;
  int? deptId;
  String? repairProcCode;
  String? ends;
  String? typeCode;
  String? repairMainNodeCode;
  String? trainEntryCode;
  String? packageVersionEncode;
  String? packageVersionCode;
  String? complete;
  int? executorId;
  String? executorName;
  bool? techMeasure;
  int? itemType;
  String? packageEternalCode;
  String? repairPersonnel;
  String? assistant;
  bool? wholePackage;
  int? assistantId;
  String? assistantName;
  String? assistantNameList;
  String? repairPersonnelNameList;
  String? jt28Code;
  String? startTime;
  String? endTime;
  List<TaskCertainPackageList>? taskCertainPackageList;
  double? progress;
  int? total;
  int? completeCount;

  WorkPackage(
      {this.code,
      this.remark,
      this.name,
      this.createdBy,
      this.createdTime,
      this.updatedBy,
      this.updatedTime,
      this.station,
      this.deptId,
      this.repairProcCode,
      this.ends,
      this.typeCode,
      this.repairMainNodeCode,
      this.trainEntryCode,
      this.packageVersionEncode,
      this.packageVersionCode,
      this.complete,
      this.executorId,
      this.executorName,
      this.techMeasure,
      this.itemType,
      this.packageEternalCode,
      this.repairPersonnel,
      this.assistant,
      this.wholePackage,
      this.assistantId,
      this.assistantName,
      this.assistantNameList,
      this.repairPersonnelNameList,
      this.jt28Code,
      this.startTime,
      this.endTime,
      this.taskCertainPackageList,
      this.progress,
      this.total,
      this.completeCount});

  factory WorkPackage.fromJson(Map<String, dynamic> json) =>
      _$WorkPackageFromJson(json);
  Map<String, dynamic> toJson() => _$WorkPackageToJson(this);
}

