import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'jcTypeList.g.dart';

@JsonSerializable()
class JcTypeList extends DataList {
  List<JcType>? rows;

  JcTypeList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory JcTypeList.fromJson(Map<String, dynamic> json) =>
      _$JcTypeListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$JcTypeListToJson(this);

  List<Map<String, dynamic>> toMapList() {
    return rows?.map((item) => item.toJson()).toList() ?? [];
  }
}

@JsonSerializable()
class JcType {
  String? code;
  String? name;
  String? createdBy;
  int? createdTime;
  String? updatedBy;
  int? updatedTime;
  int? sort;
  String? length;
  String? maxSpeed;
  String? maxAcceleration;
  String? maxDeceleration;
  String? standardWheel;
  String? weight;
  String? label;
  String? dynamicCode;
  bool? deleted;
  String? nodeCode;

  JcType({
    this.code,
    this.name,
    this.createdBy,
    this.createdTime,
    this.updatedBy,
    this.updatedTime,
    this.sort,
    this.length,
    this.maxSpeed,
    this.maxAcceleration,
    this.maxDeceleration,
    this.standardWheel,
    this.weight,
    this.label,
    this.dynamicCode,
    this.deleted,
    this.nodeCode,
  });

  factory JcType.fromJson(Map<String, dynamic> json) => _$JcTypeFromJson(json);
  Map<String, dynamic> toJson() => _$JcTypeToJson(this);
}
