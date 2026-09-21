
import '../index.dart';
class LoginApi extends AppApi{
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );
  // 登录函数
  Future<Profile> getProfile({
  Map<String,dynamic>? queryParametrs,// 分页参数
  })async{
    var r = await AppApi.dio.post(
      '/auth/login',
      data: queryParametrs,
    );
    logger.i('登录信息：${(r.data)}');
    return Profile.fromJson(r.data);
  }

  // 获取用户信息
  Future<Permissions> getpermissions()async{
    var r = await AppApi.dio.get(
      '/system/user/getInfo',
    );
    //打印r
    logger.i(r.data);
    return Permissions.fromJson(r.data);
  }

  Future<dynamic> getRouters() async {
   
    try {
      var r = await AppApi.dio.get(
        '/system/menu/getRouters',
      );
      final raw = r.data;
      final body = raw is Map ? raw['data'] : null;
      dynamic phoneChildren;
      final List<dynamic> phoneChildrenMetaList = [];
      final Set<String> phoneChildrenMetaTitles = <String>{};
      if (body is List) {
        for (final item in body) {
          if (item is Map && item['name'] == 'Phone') {
            phoneChildren = item['children'];
            break;
          }
        }
      }
      if (phoneChildren is List) {
        for (final child in phoneChildren) {
          if (child is Map && child['meta'] != null) {
            phoneChildrenMetaList.add(child['meta']);
            final title = (child['meta'] is Map
                    ? child['meta']['title']
                    : null)
                ?.toString()
                .trim();
            if (title != null && title.isNotEmpty) {
              phoneChildrenMetaTitles.add(title);
            }
          }
        }
      }
      Global.phoneChildrenMetaTitles = phoneChildrenMetaTitles;
      logger.i({
        'api': '/system/menu/getRouters',
        'phoneChildrenMetaList': phoneChildrenMetaList,
        'phoneChildrenMetaTitles': phoneChildrenMetaTitles.toList(),
      });
      try {
        print(
          'ROUTERS /system/menu/getRouters Phone.children.metaTitles=${jsonEncode(phoneChildrenMetaTitles.toList())}',
        );
      } catch (e) {
        print(
          'ROUTERS /system/menu/getRouters Phone.children.metaTitles raw=${phoneChildrenMetaTitles.toList()}',
        );
        print('ROUTERS /system/menu/getRouters encode failed: $e');
      }
      return body;
    } catch (e, stackTrace) {
      logger.e(
        'getRouters 方法中发生异常: $e\n堆栈信息: $stackTrace',
      );
      print('ROUTERS /system/menu/getRouters error=$e');
      return null;
    }
  }

  // 获取信息中心消息
  Future<SysMessageVO> getMessageInfo({
    Map<String,dynamic>? queryParameters
  })async{
    var r = await AppApi.dio.post(
      '/jcjxsystem/message/getMessageInfo',
      data: queryParameters
    );
    return SysMessageVO.fromJson((r.data['data'])['data']);
  }

}
