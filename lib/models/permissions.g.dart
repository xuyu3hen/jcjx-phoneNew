// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Permissions _$PermissionsFromJson(Map<String, dynamic> json) => Permissions(
      msg: json['msg'] as String,
      code: (json['code'] as num).toInt(),
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PermissionsToJson(Permissions instance) =>
    <String, dynamic>{
      'msg': instance.msg,
      'code': instance.code,
      'permissions': instance.permissions,
      'roles': instance.roles,
      'user': instance.user,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      createBy: json['createBy'] as String?,
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateBy: json['updateBy'] as String?,
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      remark: json['remark'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      deptId: (json['deptId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      nickName: json['nickName'] as String?,
      email: json['email'] as String?,
      phonenumber: json['phonenumber'] as String?,
      sex: json['sex'] as String?,
      avatar: json['avatar'] as String?,
      password: json['password'] as String?,
      status: json['status'] as String?,
      delFlag: json['delFlag'] as String?,
      loginIp: json['loginIp'] as String?,
      loginDate: json['loginDate'] == null
          ? null
          : DateTime.parse(json['loginDate'] as String),
      dept: json['dept'] == null
          ? null
          : Dept.fromJson(json['dept'] as Map<String, dynamic>),
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => Role.fromJson(e as Map<String, dynamic>))
          .toList(),
      roleIds: json['roleIds'] as String?,
      postIds: json['postIds'] as String?,
      roleId: (json['roleId'] as num?)?.toInt(),
      tysfId: json['tysfId'] as String?,
      localUserFlag: json['localUserFlag'] as bool?,
      workNumber: json['workNumber'] as String?,
      workerTypeCode: (json['workerTypeCode'] as num?)?.toInt(),
      admin: json['admin'] as bool,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'createBy': instance.createBy,
      'createTime': instance.createTime?.toIso8601String(),
      'updateBy': instance.updateBy,
      'updateTime': instance.updateTime?.toIso8601String(),
      'remark': instance.remark,
      'userId': instance.userId,
      'deptId': instance.deptId,
      'userName': instance.userName,
      'nickName': instance.nickName,
      'email': instance.email,
      'phonenumber': instance.phonenumber,
      'sex': instance.sex,
      'avatar': instance.avatar,
      'password': instance.password,
      'status': instance.status,
      'delFlag': instance.delFlag,
      'loginIp': instance.loginIp,
      'loginDate': instance.loginDate?.toIso8601String(),
      'dept': instance.dept,
      'roles': instance.roles,
      'roleIds': instance.roleIds,
      'postIds': instance.postIds,
      'roleId': instance.roleId,
      'tysfId': instance.tysfId,
      'localUserFlag': instance.localUserFlag,
      'workNumber': instance.workNumber,
      'workerTypeCode': instance.workerTypeCode,
      'admin': instance.admin,
    };

Dept _$DeptFromJson(Map<String, dynamic> json) => Dept(
      createBy: json['createBy'] as String?,
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateBy: json['updateBy'] as String?,
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      remark: json['remark'] as String?,
      deptId: (json['deptId'] as num?)?.toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      ancestors: json['ancestors'] as String?,
      deptName: json['deptName'] as String?,
      orderNum: (json['orderNum'] as num?)?.toInt(),
      leader: json['leader'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String?,
      delFlag: json['delFlag'] as String?,
      parentName: json['parentName'] as String?,
      children: json['children'] as List<dynamic>?,
    );

Map<String, dynamic> _$DeptToJson(Dept instance) => <String, dynamic>{
      'createBy': instance.createBy,
      'createTime': instance.createTime?.toIso8601String(),
      'updateBy': instance.updateBy,
      'updateTime': instance.updateTime?.toIso8601String(),
      'remark': instance.remark,
      'deptId': instance.deptId,
      'parentId': instance.parentId,
      'ancestors': instance.ancestors,
      'deptName': instance.deptName,
      'orderNum': instance.orderNum,
      'leader': instance.leader,
      'phone': instance.phone,
      'email': instance.email,
      'status': instance.status,
      'delFlag': instance.delFlag,
      'parentName': instance.parentName,
      'children': instance.children,
    };

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
      createBy: json['createBy'] as String?,
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateBy: json['updateBy'] as String?,
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      remark: json['remark'] as String?,
      roleId: (json['roleId'] as num?)?.toInt(),
      roleName: json['roleName'] as String?,
      roleKey: json['roleKey'] as String?,
      roleSort: (json['roleSort'] as num?)?.toInt(),
      dataScope: json['dataScope'] as String?,
      menuCheckStrictly: json['menuCheckStrictly'] as bool,
      deptCheckStrictly: json['deptCheckStrictly'] as bool,
      status: json['status'] as String?,
      delFlag: json['delFlag'] as String?,
      flag: json['flag'] as bool?,
      menuIds: json['menuIds'] as String?,
      deptIds: json['deptIds'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      admin: json['admin'] as bool,
    );

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
      'createBy': instance.createBy,
      'createTime': instance.createTime?.toIso8601String(),
      'updateBy': instance.updateBy,
      'updateTime': instance.updateTime?.toIso8601String(),
      'remark': instance.remark,
      'roleId': instance.roleId,
      'roleName': instance.roleName,
      'roleKey': instance.roleKey,
      'roleSort': instance.roleSort,
      'dataScope': instance.dataScope,
      'menuCheckStrictly': instance.menuCheckStrictly,
      'deptCheckStrictly': instance.deptCheckStrictly,
      'status': instance.status,
      'delFlag': instance.delFlag,
      'flag': instance.flag,
      'menuIds': instance.menuIds,
      'deptIds': instance.deptIds,
      'permissions': instance.permissions,
      'admin': instance.admin,
    };
