import 'package:json_annotation/json_annotation.dart';
import '../index.dart';
part 'jtTypeList.g.dart';

@JsonSerializable()
class JtTypeList extends DataList{

  List<dynamic>? rows;

  JtTypeList({
    super.code,
    super.msg,
    super.total,
    this.rows,
  });

  factory JtTypeList.fromJson(Map<String,dynamic> json) => _$JtTypeListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$JtTypeListToJson(this);
}
