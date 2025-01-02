
import 'package:json_annotation/json_annotation.dart';
import '../formData/datalist.dart';
part 'repairSys.g.dart';

@JsonSerializable()
class RepairSysResponse extends DataList{
    List<RepairSys>? rows;
    RepairSysResponse({
        this.rows,
        super.code,
        super.msg,
        super.total,
    });
    factory RepairSysResponse.fromJson(Map<String, dynamic> json) =>
        _$RepairSysResponseFromJson(json);

    Map<String, dynamic> toJson() => _$RepairSysResponseToJson(this);
    List<Map<String, dynamic>> toMapList() {
        return rows?.map((item) => item.toJson()).toList() ?? [];
    }

}

@JsonSerializable()
class RepairSys {
  String? code;
  String? name;
  int? sort;
  String? dynamicCode;
  String? remark;
  String? repairProcList;

  RepairSys(
      {this.code,
      this.name,
      this.sort,
      this.dynamicCode,
      this.remark,
      this.repairProcList});

  

  factory RepairSys.fromJson(Map<String, dynamic> json) =>
      _$RepairSysFromJson(json);

  Map<String, dynamic> toJson() => _$RepairSysToJson(this);
}
