import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'repairProcList.g.dart';

@JsonSerializable()
class RepairProcList extends DataList{

  List<RepairProc>? rows;

  RepairProcList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory RepairProcList.fromJson(Map<String,dynamic> json) => _$RepairProcListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RepairProcListToJson(this);

  //toMapList
  List<Map<String, dynamic>> toMapList() {
    List<Map<String, dynamic>> list = [];
    if (rows != null) {
      for (var i = 0; i < rows!.length; i++) {
        list.add(rows![i].toJson());
      }
    }
    return list;
  }
}

@JsonSerializable()
class RepairProc {

    String? code;
    String? name;
    int? sort;
    String? repairSysCode;
    String? remark;

  RepairProc({
    this.code,
    this.name,
    this.sort,
    this.repairSysCode,
    this.remark,
  });

  factory RepairProc.fromJson(Map<String,dynamic> json) => _$RepairProcFromJson(json);
  Map<String, dynamic> toJson() => _$RepairProcToJson(this);
}
