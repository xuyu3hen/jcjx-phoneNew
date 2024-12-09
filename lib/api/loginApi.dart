import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../index.dart';
class LoginApi extends AppApi{

  // 登录函数
  Future<Profile> getProfile({
  Map<String,dynamic>? queryParametrs,// 分页参数
  })async{
    var r = await AppApi.dio.post(
      "/auth/login",
      data: queryParametrs,
    );
    print('登录信息：${(r.data)}');
    return Profile.fromJson(r.data);
  }

  // 获取用户信息
  Future<Permissions> getpermissions()async{
    var r = await AppApi.dio.get(
      "/system/user/getInfo",
    );
    return Permissions.fromJson(r.data);
  }

  // 获取信息中心消息
  Future<SysMessageVO> getMessageInfo({
    Map<String,dynamic>? queryParameters
  })async{
    var r = await AppApi.dio.post(
      "/jcjxsystem/message/getMessageInfo",
      data: queryParameters
    );
    return SysMessageVO.fromJson((r.data['data'])['data']);
  }

}