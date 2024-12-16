// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userList.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserList _$UserListFromJson(Map<String, dynamic> json) => UserList(
      code: json['code'] as String?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserListToJson(UserList instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      userId: json['userId'] as int?,
      deptId: json['deptId'] as int?,
      userName: json['userName'] as String?,
      nickName: json['nickName'] as String?,
      userType: json['userType'] as String?,
      email: json['email'] as String?,
      phonenumber: json['phonenumber'] as String?,
      sex: json['sex'] as String?,
      avatar: json['avatar'] as String?,
      password: json['password'] as String?,
      status: json['status'] as String?,
      delFlag: json['delFlag'] as String?,
      loginIp: json['loginIp'] as String?,
      loginDate: json['loginDate'] as String?,
      createBy: json['createBy'] as String?,
      createTime: json['createTime'] as int?,
      updateBy: json['updateBy'] as String?,
      updateTime: json['updateTime'] as int?,
      remark: json['remark'] as String?,
      tysfId: json['tysfId'] as String?,
      localUserFlag: json['localUserFlag'] as bool?,
      workNumber: json['workNumber'] as int?,
      workerTypeCode: json['workerTypeCode'] as int?,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'userId': instance.userId,
      'deptId': instance.deptId,
      'userName': instance.userName,
      'nickName': instance.nickName,
      'userType': instance.userType,
      'email': instance.email,
      'phonenumber': instance.phonenumber,
      'sex': instance.sex,
      'avatar': instance.avatar,
      'password': instance.password,
      'status': instance.status,
      'delFlag': instance.delFlag,
      'loginIp': instance.loginIp,
      'loginDate': instance.loginDate,
      'createBy': instance.createBy,
      'createTime': instance.createTime,
      'updateBy': instance.updateBy,
      'updateTime': instance.updateTime,
      'remark': instance.remark,
      'tysfId': instance.tysfId,
      'localUserFlag': instance.localUserFlag,
      'workNumber': instance.workNumber,
      'workerTypeCode': instance.workerTypeCode,
    };
