import 'package:json_annotation/json_annotation.dart';
part 'mainNode.g.dart';

@JsonSerializable()
class MainNodeList {
  String? code;
  List<MainNodeAndProc>? data;
  String? message;

  MainNodeList({this.code, this.data, this.message});

  factory MainNodeList.fromJson(Map<String, dynamic> json) =>
      _$MainNodeListFromJson(json);

  Map<String, dynamic> toJson() => _$MainNodeListToJson(this);

  List<Map<String, dynamic>> toMapList() {
    return data?.map((item) => item.toJson()).toList() ?? [];
  }
}

@JsonSerializable()
class MainNodeAndProc {
  String? code;
  String? name;
  int? sort;
  String? repairSysCode;
  String? remark;
  int? drivingKiloStandard;
  List<RepairMainNodeList>? repairMainNodeList;

  MainNodeAndProc(
      {this.code,
      this.name,
      this.sort,
      this.repairSysCode,
      this.remark,
      this.drivingKiloStandard,
      this.repairMainNodeList});

  factory MainNodeAndProc.fromJson(Map<String, dynamic> json) =>
      _$MainNodeAndProcFromJson(json);

  Map<String, dynamic> toJson() => _$MainNodeAndProcToJson(this);
}

@JsonSerializable()
class RepairMainNodeList {
  String? code;
  String? name;
  int? sort;
  String? repairProcCode;
  String? remark;
  String? deptIds;
  List<String>? sysDeptList;
  List<String>? childList;
  bool? deleted;

  RepairMainNodeList(
      {this.code,
      this.name,
      this.sort,
      this.repairProcCode,
      this.remark,
      this.deptIds,
      this.sysDeptList,
      this.childList,
      this.deleted});

  factory RepairMainNodeList.fromJson(Map<String, dynamic> json) =>
      _$RepairMainNodeListFromJson(json);

  Map<String, dynamic> toJson() => _$RepairMainNodeListToJson(this);
}
