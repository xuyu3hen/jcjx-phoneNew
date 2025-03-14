import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'train_entry_list.g.dart';

@JsonSerializable()
class TrainEntryList extends DataList{

  List<TrainEntry>? rows;

  TrainEntryList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory TrainEntryList.fromJson(Map<String,dynamic> json) => _$TrainEntryListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TrainEntryListToJson(this);
}

@JsonSerializable()
class TrainEntry {

    String? createdBy;
    String? createdTime;
    String? updatedBy;
    String? updatedTime;
    int? sort;
    String? typeCode;
    String? trainNumCode;
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
    dynamic userName;
    String? arrivePlatformTime;
    String? dynamicCode;
    String? antiSlipImage;
    String? oilInfoImage;

  TrainEntry({
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.updatedTime,
        this.sort,
        this.typeCode,
        this.trainNumCode,
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
  });

  factory TrainEntry.fromJson(Map<String,dynamic> json) => _$TrainEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TrainEntryToJson(this);
}
