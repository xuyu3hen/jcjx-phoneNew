import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../index.dart';
export 'package:dio/dio.dart' show DioException;

class AppApi {
  BuildContext? context;
  late Options appOptions;

  AppApi([this.context]) {
    appOptions = Options(extra: {"context": context});
  }

//服务
  static Dio dio = Dio(BaseOptions(
      // 正式服
      // baseUrl: 'http://10.102.12.211:8000/supply',
      // 测试服
      // baseUrl: 'http://10.102.12.211:8000/supplytest',
      // 本地
      // baseUrl: 'http://10.102.12.211:8000/supplyapplocal',
      baseUrl: F.appBaseURL,
      headers: {
        HttpHeaders.acceptHeader: "application/json,"
            "*/*",
      }));
  //服务
  static Dio dio2 = Dio(BaseOptions(
      // 正式服
      // baseUrl: 'http://10.102.12.211:8000/supply',
      // 测试服
      // baseUrl: 'http://10.102.12.211:8000/supplytest',
      // 本地
      // baseUrl: 'http://10.102.12.211:8000/supplyapplocal',
      baseUrl: F.appBaseURL,
      headers: {
        HttpHeaders.acceptHeader: "application/json,"
            "*/*",
      }));



// 初始化 Dio 配置
static void init() {
  var logger = AppLogger.logger;

  // 设置用户 token
  dio.options.headers[HttpHeaders.authorizationHeader] =
      Global.profile.data?.accessToken;
  logger.i(
      "authorizationHeader:${dio.options.headers[HttpHeaders.authorizationHeader]}");
  dio.options.headers.addAll({'token': Global.profile.accessToken});
  dio2.options.headers["content-type"] = "application/json";
  dio2.options.headers[HttpHeaders.authorizationHeader] =
      Global.profile.data?.accessToken;
  logger.i('apptoken${dio.options.headers['token']}');
  logger.i('baseurl${dio.options.baseUrl}');

  // 调试模式下禁用证书校验
    if (!Global.isRelease) {
    // 确保 httpClientAdapter 是 DefaultHttpClientAdapter 类型
    if (dio.httpClientAdapter is IOHttpClientAdapter ) {
      (dio.httpClientAdapter as IOHttpClientAdapter ).onHttpClientCreate =
          (client) {
        // 忽略所有无效或自签名的 SSL 证书
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        AppLogger.logger.i("SSL certificate validation disabled for debugging.");
        return null;
      };
    } else {
      AppLogger.logger.e(
          "Failed to disable SSL certificate validation: httpClientAdapter is not DefaultHttpClientAdapter.");
    }
  }
}
}
