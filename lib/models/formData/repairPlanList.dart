import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'repairPlanList.g.dart';

@JsonSerializable()
class RepairPlanList extends DataList{

  List<RepairPlan>? rows;

  RepairPlanList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory RepairPlanList.fromJson(Map<String,dynamic> json) => _$RepairPlanListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RepairPlanListToJson(this);
  //获取对应的数据并进行展示
  List<Map<String,dynamic>> toMapList(){
    return rows?.map((item) => item.toJson()).toList()?? [];
  }

}

@JsonSerializable()
class RepairPlan {

    String? createdBy;
    DateTime? createdTime;
    String? updatedBy;
    DateTime? updatedTime;
    int? sort;
    String? typeCode;
    int? assignmentStatus;
    String? repairLocation;
    String? trackNum;
    String? stoppingPlace;
    String? repairProcCode;
    String? repairTimes;
    int? status;
    int? operateUserId;
    String? operateTime;
    String? code;
    String? typeName;
    String? trainNum;
    String? repairProcName;
    String? userName;
    DateTime? arrivePlatformTime;
    String? dynamicCode;
    String? antiSlipImage;
    String? oilInfoImage;
    String? complete;

  RepairPlan({
    this.createdBy,
    this.createdTime,
    this.updatedBy,
    this.updatedTime,
    this.sort,
    this.typeCode,
    this.assignmentStatus,
    this.repairLocation,
    this.trackNum,
    this.stoppingPlace,
    this.repairProcCode,
    this.repairTimes,
    this.status,
    this.operateUserId,
    this.operateTime,
    this.code,
    this.typeName,
    this.trainNum,
    this.repairProcName,
    this.userName,
    this.arrivePlatformTime,
    this.dynamicCode,
    this.antiSlipImage,
    this.oilInfoImage,
    this.complete,
  });

  factory RepairPlan.fromJson(Map<String,dynamic> json) => _$RepairPlanFromJson(json);
  Map<String, dynamic> toJson() => _$RepairPlanToJson(this);
}
