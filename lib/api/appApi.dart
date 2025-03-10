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

  static void init() {
    // TODO:添加缓存插件
    // 创建 Logger 实例
    var logger = AppLogger.logger;
    // 设置用户token
    dio.options.headers[HttpHeaders.authorizationHeader] =
        Global.profile.data?.access_token;

    logger.i(
        "authorizationHeader:${dio.options.headers[HttpHeaders.authorizationHeader]}");
    dio.options.headers.addAll({'token': Global.profile.access_token});
    dio2.options.headers["content-type"] = "application/json";
    dio2.options.headers[HttpHeaders.authorizationHeader] =
        Global.profile.data?.access_token;

    logger.i(
        "authorizationHeader:${dio.options.headers[HttpHeaders.authorizationHeader]}");
    dio2.options.headers.addAll({'token': Global.profile.access_token});
    logger.i('apptoken${dio.options.headers['token']}');
    logger.i('baseurl${dio.options.baseUrl}');

    //调试抓包及禁用证书校验
    if (!Global.isRelease) {
      // dio.httpClientAdapter = IOHttpClientAdapter(
      //   onHttpClientCreate: (client) {
      //     client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      //   },
      // );
      // (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
      //   (client){client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;} as CreateHttpClient?;
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    }
  }
}
