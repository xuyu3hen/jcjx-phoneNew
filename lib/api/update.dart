import '../index.dart';

class UpdateApi extends AppApi{
  
  var logger = AppLogger.logger;
  
  // 内网分发服务器地址（HTTPS）
  // 可根据环境配置不同的服务器地址
  static String get distributionServerUrl {
    switch (F.appFlavor) {
      case Flavor.env_dev:
        return 'https://10.102.12.211:8443';
      case Flavor.env_test:
        return 'https://10.102.12.211:8443';
      case Flavor.env_release:
        return 'https://10.102.12.211:8443';
      default:
        return 'https://10.102.12.211:8443';
    }
  }
  
  // 检查版本更新，获取下载链接
  Future<MyApkVersion> checkUpdate({
    Map<String,dynamic>? queryParametrs,// 查询参数
    })async{
      try {
        // 构建完整的下载URL（使用HTTPS）
        String url = "${distributionServerUrl}/api/apk/version/last";
        
        // 添加环境参数
        Map<String, dynamic> params = Map.from(queryParametrs ?? {});
        if (!params.containsKey('env')) {
          // 根据当前环境设置env参数
          String env = 'release';
          switch (F.appFlavor) {
            case Flavor.env_dev:
              env = 'dev';
              break;
            case Flavor.env_test:
              env = 'test';
              break;
            case Flavor.env_release:
              env = 'release';
              break;
            default:
              env = 'release';
          }
          params['env'] = env;
        }
        
        logger.i('检查更新: $url, 参数: $params');
        
        var r = await AppApi.dio.get(
          url,
          queryParameters: params,
        );
        
        logger.i('最新版本信息：${r.data}');
        
        // 处理响应格式（适配新的API响应格式）
        Map<String, dynamic> responseData = r.data;
        if (responseData.containsKey('data')) {
          // 新API格式: {code: 200, message: "成功", data: {...}}
          return MyApkVersion.fromJson(responseData["data"]);
        } else {
          // 兼容旧API格式: {data: {...}}
          return MyApkVersion.fromJson(responseData);
        }
      } catch (e) {
        logger.e('检查更新失败: $e');
        rethrow;
      }
  }
}