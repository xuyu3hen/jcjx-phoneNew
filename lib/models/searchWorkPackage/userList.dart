
import 'package:json_annotation/json_annotation.dart';
part 'userList.g.dart';

@JsonSerializable()
class UserList {
  String? code;
  String? message;
  List<UserInfo>? data;

  UserList({this.code, this.message, this.data});

  factory UserList.fromJson(Map<String, dynamic> json) => _$UserListFromJson(json);

  Map<String, dynamic> toJson() => _$UserListToJson(this);

}

@JsonSerializable()
class UserInfo {
  int? userId;
  int? deptId;
  String? userName;
  String? nickName;
  String? userType;
  String? email;
  String? phonenumber;
  String? sex;
  String? avatar;
  String? password;
  String? status;
  String? delFlag;
  String? loginIp;
  String? loginDate;
  String? createBy;
  int? createTime;
  String? updateBy;
  int? updateTime;
  String? remark;
  String? tysfId;
  bool? localUserFlag;
  int? workNumber;
  int? workerTypeCode;

  UserInfo(
      {this.userId,
      this.deptId,
      this.userName,
      this.nickName,
      this.userType,
      this.email,
      this.phonenumber,
      this.sex,
      this.avatar,
      this.password,
      this.status,
      this.delFlag,
      this.loginIp,
      this.loginDate,
      this.createBy,
      this.createTime,
      this.updateBy,
      this.updateTime,
      this.remark,
      this.tysfId,
      this.localUserFlag,
      this.workNumber,
      this.workerTypeCode});

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}
