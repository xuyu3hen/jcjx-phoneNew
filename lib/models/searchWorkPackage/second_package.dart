import 'package:json_annotation/json_annotation.dart';

import '../jtData/individual_task_package.dart';

part 'secondPackage.g.dart';


@JsonSerializable()
class SecondShowPackage{
  TaskCertainPackageList? taskCertainPackageList;
  String? secondPackageNode;
  int? color;

  SecondShowPackage({this.taskCertainPackageList, this.secondPackageNode, this.color});

  factory SecondShowPackage.fromJson(Map<String, dynamic> json) =>
      _$SecondShowPackageFromJson(json);
    
  Map<String, dynamic> toJson() => _$SecondShowPackageToJson(this);
  
}
@JsonSerializable()
class SecondPackage {
  int? total;
  List<Rows>? rows;
  int? code;
  String? msg;

  SecondPackage({this.total, this.rows, this.code, this.msg});

  factory SecondPackage.fromJson(Map<String, dynamic> json) =>
      _$SecondPackageFromJson(json);

  Map<String, dynamic> toJson() => _$SecondPackageToJson(this);
}

@JsonSerializable()
class Rows {
  String? code;
  String? certainPackageCode;
  String? instructPackageCode;
  String? riskLevel;
  String? createdBy;
  int? createdTime;
  String? updatedBy;
  int? updatedTime;
  String? secondPackageName;
  String? secondPackageCode;
  int? sort;

  Rows(
      {this.code,
      this.certainPackageCode,
      this.instructPackageCode,
      this.riskLevel,
      this.createdBy,
      this.createdTime,
      this.updatedBy,
      this.updatedTime,
      this.secondPackageName,
      this.secondPackageCode,
      this.sort});

  factory Rows.fromJson(Map<String, dynamic> json) => _$RowsFromJson(json);

  Map<String, dynamic> toJson() => _$RowsToJson(this);
}
