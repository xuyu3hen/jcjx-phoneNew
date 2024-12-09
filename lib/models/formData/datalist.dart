import 'package:json_annotation/json_annotation.dart';
part 'datalist.g.dart';

@JsonSerializable()
class DataList {

    int? total;
    int? code;
    String? msg;

  DataList({
    this.total,
    this.code,
    this.msg,
  });

  factory DataList.fromJson(Map<String,dynamic> json) => _$DataListFromJson(json);
  Map<String, dynamic> toJson() => _$DataListToJson(this);
}
