import 'package:json_annotation/json_annotation.dart';

import '../formData/repairProcList.dart';
part 'repair_proc.g.dart';

@JsonSerializable()
class RepairProcAndNode extends RepairProc{
    List<RepairMainNodeList>? repairMainNodeList;

    RepairProcAndNode({
      super.code,
      super.name,
      super.sort,
      super.repairSysCode,
      super.remark,
      this.repairMainNodeList,
    });

  factory RepairProcAndNode.fromJson(Map<String,dynamic> json) => _$RepairProcAndNodeFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RepairProcAndNodeToJson(this);

}

@JsonSerializable()
class RepairMainNodeList {
    String code;
    String? name;
    int? sort;
    String? repairProcCode;
    String? remark;
    String? deptIds;
    dynamic sysDeptList;
    dynamic childList;
    bool? deleted;

    RepairMainNodeList({
      required  this.code,
        this.name,
        this.sort,
        this.repairProcCode,
        this.remark,
        this.deptIds,
        this.sysDeptList,
        this.childList,
        this.deleted,
    });

  factory RepairMainNodeList.fromJson(Map<String,dynamic> json) => _$RepairMainNodeListFromJson(json);
  Map<String, dynamic> toJson() => _$RepairMainNodeListToJson(this);
}