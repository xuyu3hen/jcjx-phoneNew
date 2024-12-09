import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'repairTimesList.g.dart';

@JsonSerializable()
class RepairTimesList extends DataList{

  List<RepairTimes>? rows;

  RepairTimesList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory RepairTimesList.fromJson(Map<String,dynamic> json) => _$RepairTimesListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RepairTimesListToJson(this);
}

@JsonSerializable()
class RepairTimes {

    String? code;
    String? name;
    int? sort;
    String? repairProcCode;
    String? remark;

  RepairTimes({
    this.code,
    this.name,
    this.sort,
    this.repairProcCode,
    this.remark,
  });

  factory RepairTimes.fromJson(Map<String,dynamic> json) => _$RepairTimesFromJson(json);
  Map<String, dynamic> toJson() => _$RepairTimesToJson(this);
}
