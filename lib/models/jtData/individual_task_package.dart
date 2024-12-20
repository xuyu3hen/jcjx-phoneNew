import 'package:jcjx_phone/index.dart';
import 'package:json_annotation/json_annotation.dart';
part 'individual_task_package.g.dart';

@JsonSerializable()
class IndividualTaskPackageList extends PackageBaseList {
  List<IndividualTaskPackage>? data;

  IndividualTaskPackageList({
    super.code,
    super.message,
    this.data,
  });

  factory IndividualTaskPackageList.fromJson(Map<String,dynamic> json) => _$IndividualTaskPackageListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IndividualTaskPackageListToJson(this);
}

@JsonSerializable()
class IndividualTaskPackage {
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
    List<TaskCertainPackageList>? taskCertainPackageList;
    double? progress;
    bool? wholePackage;
    int? total;
    int? completeCount;

    IndividualTaskPackage({
        this.code,
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
        this.taskCertainPackageList,
        this.progress,
        this.wholePackage,
        this.total,
        this.completeCount
    });

    factory IndividualTaskPackage.fromJson(Map<String,dynamic> json) => _$IndividualTaskPackageFromJson(json);
    Map<String, dynamic> toJson() => _$IndividualTaskPackageToJson(this);
}

@JsonSerializable()
class TaskCertainPackageList {
    String? code;
    String? station;
    int? deptId;
    String? configCode;
    String? name;
    String? repairProcCode;
    int? sort;
    String? ends;
    String? endsCode;
    String? typeCode;
    String? repairTimes;
    String? repairMainNodeCode;
    String? createdBy;
    String? createdTime;
    String? updatedBy;
    String? updatedTime;
    int? itemType;
    String? riskLevel;
    String? packageCode;
    int? packageSort;
    int? configNodeLevel;
    List<TaskInstructContentList>? taskInstructContentList;
    String? complete;
    double? progress;
    int? executorId;
    String? executorName;
    String? secondPackageCode;
    String? mutualInspectionPersonnel;
    String? specialInspectionPersonnel;
    int? mutualInspectionId;
    int? specialInspectionId;
    String? mutualInspectionName;
    String? specialInspectionName;

    bool? selected;
    bool? expanded;

    TaskCertainPackageList({
        this.code,
        this.station,
        this.deptId,
        this.configCode,
        this.name,
        this.repairProcCode,
        this.sort,
        this.ends,
        this.endsCode,
        this.typeCode,
        this.repairTimes,
        this.repairMainNodeCode,
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.updatedTime,
        this.itemType,
        this.riskLevel,
        this.packageCode,
        this.packageSort,
        this.configNodeLevel,
        this.taskInstructContentList,
        this.complete,
        this.progress,
        this.executorId,
        this.executorName,
        this.secondPackageCode,
        this.mutualInspectionPersonnel,
        this.specialInspectionPersonnel,
        this.mutualInspectionId,
        this.specialInspectionId,
        this.mutualInspectionName,
        this.specialInspectionName,
    });

    factory TaskCertainPackageList.fromJson(Map<String,dynamic> json) => _$TaskCertainPackageListFromJson(json);
    Map<String, dynamic> toJson() => _$TaskCertainPackageListToJson(this);
}

@JsonSerializable()
class TaskInstructContentList {
    String? code;
    int? sort;
    String? configCode;
    String? name;
    String? repairTimes;
    String? repairMainNodeCode;
    String? createdBy;
    int? createdTime;
    String? updatedBy;
    int? updatedTime;
    int? itemType;
    String? riskLevel;
    String? workContent;
    dynamic configNum;
    dynamic dataContent;
    dynamic standardPhoto;
    dynamic opTechnic;
    String? scopeVersionCode;
    String? complete;
    String? certainPackageCode;
    bool? packageFlag;
    bool? manufacturerFlag;
    bool? techMeasure;
    List<TaskContentItem>? taskContentItemList;

    TaskInstructContentList({
        this.code,
        this.sort,
        this.configCode,
        this.name,
        this.repairTimes,
        this.repairMainNodeCode,
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.updatedTime,
        this.itemType,
        this.riskLevel,
        this.workContent,
        this.configNum,
        this.dataContent,
        this.standardPhoto,
        this.opTechnic,
        this.scopeVersionCode,
        this.complete,
        this.certainPackageCode,
        this.packageFlag,
        this.manufacturerFlag,
        this.techMeasure,
        this.taskContentItemList,
    });

    factory TaskInstructContentList.fromJson(Map<String,dynamic> json) => _$TaskInstructContentListFromJson(json);
    Map<String, dynamic> toJson() => _$TaskInstructContentListToJson(this);
}

@JsonSerializable()
class TaskContentItem{
    String? code;
    String? name;
    String? createdBy;
    int? createdTime;
    String? updatedBy;
    int? updatedTime;
    String? instructContentCode;
    String? itemCode;
    String? dataName;
    double? limitMin;
    String? workContent;
    int? sort;
    double? limitMax;
    String? limitUnit;
    int? boundaryCaseMin;
    int? boundaryCaseMax;
    double? originalLimit;
    double? rangeMin;
    double? rangeMax;
    bool? percentage;
    double? realValue;

    TaskContentItem({
      this.code,
      this.name,
      this.createdBy,
      this.createdTime,
      this.updatedBy,
      this.updatedTime,
      this.instructContentCode,
      this.itemCode,
      this.dataName,
      this.limitMin,
      this.workContent,
      this.sort,
      this.limitMax,
      this.limitUnit,
      this.boundaryCaseMin,
      this.boundaryCaseMax,
      this.originalLimit,
      this.rangeMin,
      this.rangeMax,
      this.percentage,
      this.realValue,
    });

    factory TaskContentItem.fromJson(Map<String,dynamic> json) => _$TaskContentItemFromJson(json);
    Map<String, dynamic> toJson() => _$TaskContentItemToJson(this);
}