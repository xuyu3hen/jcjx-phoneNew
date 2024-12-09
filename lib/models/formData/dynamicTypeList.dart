import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'dynamicTypeList.g.dart';

@JsonSerializable()
class DynamicTypeList extends DataList {
  List<DynamicType>? rows;

  DynamicTypeList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory DynamicTypeList.fromJson(Map<String, dynamic> json) =>
      _$DynamicTypeListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DynamicTypeListToJson(this);
  List<Map<String, dynamic>> toMapList() {
    return rows?.map((item) => item.toJson()).toList() ?? [];
  }
}

@JsonSerializable()
class DynamicType {
  String? code;
  String? name;
  int? sort;
  String? nodeCode;
  String? jcTypeList;

  DynamicType({
    this.code,
    this.name,
    this.sort,
    this.nodeCode,
    this.jcTypeList,
  });

  factory DynamicType.fromJson(Map<String, dynamic> json) =>
      _$DynamicTypeFromJson(json);
  Map<String, dynamic> toJson() => _$DynamicTypeToJson(this);

  DynamicType copyWith({
    String? code,
    String? name,
    int? sort,
    String? nodeCode,
    String? jcTypeList,
  }) =>
      DynamicType(
        code: code ?? this.code,
        name: name ?? this.name,
        sort: sort ?? this.sort,
        nodeCode: nodeCode ?? this.nodeCode,
        jcTypeList: jcTypeList?? this.jcTypeList,
      );
}
