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
    this.buildNumber,
    this.isForceUpdate,
    this.fileSize,
    this.md5,
    this.updateType,
  });

  String? name;
  String? version;
  String? url;
  String? dec;
  String? id;
  String? createTime;
  
  // 扩展字段
  @JsonKey(name: 'buildNumber')
  int? buildNumber; // 构建号
  
  @JsonKey(name: 'isForceUpdate')
  bool? isForceUpdate; // 是否强制更新
  
  @JsonKey(name: 'fileSize')
  int? fileSize; // 文件大小（字节）
  
  @JsonKey(name: 'md5')
  String? md5; // 文件 MD5 值
  
  @JsonKey(name: 'updateType')
  String? updateType; // 更新类型：full(全量) / incremental(增量)

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