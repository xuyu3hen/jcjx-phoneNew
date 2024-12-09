import 'package:json_annotation/json_annotation.dart';
part 'permissions.g.dart';

@JsonSerializable()
class Permissions {

  Permissions({
      required this.msg,
      required this.code,
      required this.permissions,
      required this.roles,
      required this.user,
  });

  String msg;
  int code;
  List<String> permissions;
  List<String> roles;
  User user;

  factory Permissions.fromJson(Map<String,dynamic> json) => _$PermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionsToJson(this);

}

@JsonSerializable()
class User {
    String? createBy;
    DateTime? createTime;
    String? updateBy;
    DateTime? updateTime;
    String? remark;
    int? userId;
    int? deptId;
    String? userName;
    String? nickName;
    String? email;
    String? phonenumber;
    String? sex;
    String? avatar;
    String? password;
    String? status;
    String? delFlag;
    String? loginIp;
    DateTime? loginDate;
    Dept? dept;
    List<Role>? roles;
    String? roleIds;
    String? postIds;
    int? roleId;
    String? tysfId;
    bool? localUserFlag;
    String? workNumber;
    int? workerTypeCode;
    bool admin;

    User({
        this.createBy,
        this.createTime,
        this.updateBy,
        this.updateTime,
        this.remark,
        this.userId,
        this.deptId,
        this.userName,
        this.nickName,
        this.email,
        this.phonenumber,
        this.sex,
        this.avatar,
        this.password,
        this.status,
        this.delFlag,
        this.loginIp,
        this.loginDate,
        this.dept,
        this.roles,
        this.roleIds,
        this.postIds,
        this.roleId,
        this.tysfId,
        this.localUserFlag,
        this.workNumber,
        this.workerTypeCode,
        required this.admin,
    });

  factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class Dept {
    String? createBy;
    DateTime? createTime;
    String? updateBy;
    DateTime? updateTime;
    String? remark;
    int? deptId;
    int? parentId;
    String? ancestors;
    String? deptName;
    int? orderNum;
    String? leader;
    String? phone;
    String? email;
    String? status;
    String? delFlag;
    String? parentName;
    List<dynamic>? children;

    Dept({
        this.createBy,
        this.createTime,
        this.updateBy,
        this.updateTime,
        this.remark,
        this.deptId,
        this.parentId,
        this.ancestors,
        this.deptName,
        this.orderNum,
        this.leader,
        this.phone,
        this.email,
        this.status,
        this.delFlag,
        this.parentName,
        this.children,
    });

  factory Dept.fromJson(Map<String,dynamic> json) => _$DeptFromJson(json);
  Map<String, dynamic> toJson() => _$DeptToJson(this);

}

@JsonSerializable()
class Role {
    String? createBy;
    DateTime? createTime;
    String? updateBy;
    DateTime? updateTime;
    String? remark;
    int? roleId;
    String? roleName;
    String? roleKey;
    int? roleSort;
    String? dataScope;
    bool menuCheckStrictly;
    bool deptCheckStrictly;
    String? status;
    String? delFlag;
    bool? flag;
    String? menuIds;
    String? deptIds;
    List<String>? permissions;
    bool admin;

    Role({
        this.createBy,
        this.createTime,
        this.updateBy,
        this.updateTime,
        this.remark,
        this.roleId,
        this.roleName,
        this.roleKey,
        this.roleSort,
        this.dataScope,
        required this.menuCheckStrictly,
        required this.deptCheckStrictly,
        this.status,
        this.delFlag,
        this.flag,
        this.menuIds,
        this.deptIds,
        this.permissions,
        required this.admin,
    });

  factory Role.fromJson(Map<String,dynamic> json) => _$RoleFromJson(json);
  Map<String, dynamic> toJson() => _$RoleToJson(this);

}
