import 'package:json_annotation/json_annotation.dart';
part 'trainLocation.g.dart';

@JsonSerializable()
class TrainLocation {
  int? total;
  List<Rowss>? rows;
  int? code;
  String? msg;

  TrainLocation({this.total, this.rows, this.code, this.msg});

  factory TrainLocation.fromJson(Map<String, dynamic> json) =>
      _$TrainLocationFromJson(json);
  Map<String, dynamic> toJson() => _$TrainLocationToJson(this);

  List<Map<String, dynamic>> toMapList() {
    return rows?.map((item) => item.toJson()).toList() ?? [];
  }
}

@JsonSerializable()
class Rowss {
  String? code;
  int? deptId;
  String? areaName;
  String? trackNum;
  int? sort;
  String? remark;
  String? deptName;

  Rowss(
      {this.code,
      this.deptId,
      this.areaName,
      this.trackNum,
      this.sort,
      this.remark,
      this.deptName});

  factory Rowss.fromJson(Map<String, dynamic> json) => _$RowssFromJson(json);
  Map<String, dynamic> toJson() => _$RowssToJson(this);
}
