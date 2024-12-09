import 'package:json_annotation/json_annotation.dart';
part 'group_data_list.g.dart';

@JsonSerializable()
class GroupData{
  String code;
  String message;
  List<PhotoData>? data;

  GroupData({
    required this.code,
    required this.message,
    this.data,
  });

  factory GroupData.fromJson(Map<String,dynamic> json) => _$GroupDataFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDataToJson(this);
}

@JsonSerializable()
class PhotoData{
  String? code;
  String? fileType;
  String? groupId;
  String? fileSize;
  String? downloadUrl;
  String? fileName;
  String? remark;
  String? createdBy;
  int? createdTime;
  String? updatedBy;
  int? updatedTime;

  PhotoData({
    this.code,
    this.fileType,
    this.groupId,
    this.fileSize,
    this.downloadUrl,
    this.fileName,
    this.remark,
    this.createdBy,
    this.createdTime,
    this.updatedBy,
    this.updatedTime,
  });

  factory PhotoData.fromJson(Map<String,dynamic> json) => _$PhotoDataFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoDataToJson(this);
}