import 'package:json_annotation/json_annotation.dart';
part 'myapkversion.g.dart';

@JsonSerializable()
class MyApkVersion {

  MyApkVersion({
    this.name,
    this.version,
    this.url,
    this.dec,
    this.id,
    this.createTime,
  });

  String? name;
  String? version;
  String? url;
  String? dec;
  String? id;
  String? createTime;

  factory MyApkVersion.fromJson(Map<String,dynamic> json) => _$MyApkVersionFromJson(json);
  Map<String, dynamic> toJson() => _$MyApkVersionToJson(this);
}

@JsonSerializable()
class SysMessageVO {

  SysMessageVO({
    this.sysMessageVO,
    this.count
  });

  List<MessageInfo>? sysMessageVO;
  int? count;

  factory SysMessageVO.fromJson(Map<String,dynamic> json) => _$SysMessageVOFromJson(json);
  Map<String, dynamic> toJson() => _$SysMessageVOToJson(this);
}

@JsonSerializable()
class MessageInfo {

  MessageInfo({
    this.number1,
    this.model,
    this.number2,
    this.status,
    this.url,
  });

  int? number1;
  String? model;
  int? number2;
  String? status;
  String? url;

  factory MessageInfo.fromJson(Map<String,dynamic> json) => _$MessageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MessageInfoToJson(this);
}