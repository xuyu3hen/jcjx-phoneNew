import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'patch_list.g.dart';

@JsonSerializable()
class JtMessageList extends DataList{
  JtMessageList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  List<JtMessage>? rows;

  factory JtMessageList.fromJson(Map<String,dynamic> json) => _$JtMessageListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$JtMessageListToJson(this);
}

@JsonSerializable()
class JtMessage{
    String? machineModel;
    String? vehicleNumber;
    String? faultDescription;
    String? jcNodeName;
    String? faultyComponent;
    int? reporter;
    String? reportDate;
    String? repairPicture;
    String? maintenanceNotice;
    String? faultAssumption;
    int? team;
    String? professionalSystem;
    String? requiredProcessingMethod;
    String? repairStatus;
    String? actualRepairStartDate;
    int? repairPersonnel;
    String? repairCompletionDate;
    int? assistant;
    String? riskLevel;
    int? mutualInspectionPersonnel;
    String? mutualInspectionPicture;
    String? mutualInspectionDate;
    int? specialInspectionPersonnel;
    String? specialInspectionDate;
    String? workpieceCoefficient;
    String? specialInspectionPicture;
    String? code;
    String? createdBy;
    String? createdTime;
    String? updatedBy;
    String? updatedTime;
    int? status;
    int? completeStatus;
    String? deptName;
    String? reporterName;
    String? assistantName;
    String? specialName;
    String? mutualName;
    String? repairName;
    String? trainType;
    String? trainNum;
    String? trainModelName;

    String? trainEntryCode;
    List<int>? repairDate;
    List<int>? mutualDate;
    List<int>? specialDate;
    List<int>? reportShowDate;
    String? repairResourceName;
    String? processMethodName;
    String? repairEndPicture;

    bool? selected;

    JtMessage({
        this.machineModel,
        this.vehicleNumber,
        this.faultDescription,
        this.jcNodeName,
        this.faultyComponent,
        this.reporter,
        this.reportDate,
        this.repairPicture,
        this.maintenanceNotice,
        this.faultAssumption,
        this.team,
        this.professionalSystem,
        this.requiredProcessingMethod,
        this.repairStatus,
        this.actualRepairStartDate,
        this.repairPersonnel,
        this.repairCompletionDate,
        this.assistant,
        this.riskLevel,
        this.mutualInspectionPersonnel,
        this.mutualInspectionPicture,
        this.mutualInspectionDate,
        this.specialInspectionPersonnel,
        this.specialInspectionDate,
        this.workpieceCoefficient,
        this.specialInspectionPicture,
        this.code,
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.updatedTime,
        this.status,
        this.completeStatus,
        this.deptName,
        this.reporterName,
        this.assistantName,
        this.specialName,
        this.mutualName,
        this.repairName,
        this.trainType,
        this.trainNum,
        this.trainModelName,
        this.trainEntryCode,
        this.repairDate,
        this.mutualDate,
        this.specialDate,
        this.reportShowDate,
        this.repairResourceName,
        this.processMethodName,
        this.repairEndPicture,
    });

  factory JtMessage.fromJson(Map<String,dynamic> json) => _$JtMessageFromJson(json);
  Map<String, dynamic> toJson() => _$JtMessageToJson(this);
}