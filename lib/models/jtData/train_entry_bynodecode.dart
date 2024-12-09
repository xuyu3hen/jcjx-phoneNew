import 'package:json_annotation/json_annotation.dart';

part 'train_entry_bynodecode.g.dart';

@JsonSerializable()
class TrainEntryByNodeCode {
    String? createdBy;
    int? createdTime;
    String? updatedBy;
    int? updatedTime;
    int? sort;
    String? typeCode;
    String? trainNum;
    int? assignmentStatus;
    String? repairLocation;
    String? trackNum;
    String? stoppingPlace;
    String? repairProcCode;
    String? repairTimes;
    int? status;
    int? operateUserId;
    DateTime? operateTime;
    String code;
    DateTime? arrivePlatformTime;
    String? dynamicCode;
    String? complete;

    TrainEntryByNodeCode({
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.updatedTime,
        this.sort,
        this.typeCode,
        this.trainNum,
        this.assignmentStatus,
        this.repairLocation,
        this.trackNum,
        this.stoppingPlace,
        this.repairProcCode,
        this.repairTimes,
        this.status,
        this.operateUserId,
        this.operateTime,
      required  this.code,
        this.arrivePlatformTime,
        this.dynamicCode,
        this.complete,
    });

  factory TrainEntryByNodeCode.fromJson(Map<String,dynamic> json) => _$TrainEntryByNodeCodeFromJson(json);
  Map<String, dynamic> toJson() => _$TrainEntryByNodeCodeToJson(this);
}