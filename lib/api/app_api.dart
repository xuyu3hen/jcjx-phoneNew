import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../index.dart';
// import '../config/loadCA.dart';
export 'package:dio/dio.dart' show DioException;

// #region agent log
void _agentLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  try {
    const path = r'd:\jcjx\jcjx-phone\.cursor\debug.log';
    final m = {'location': location, 'message': message, 'data': data, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'sessionId': 'debug-session', 'hypothesisId': hypothesisId};
    final line = '${jsonEncode(m)}\n';
    File(path).writeAsStringSync(line, mode: FileMode.append);
  } catch (_) {}
  try { print('AGENT_LOG ${jsonEncode({'location': location, 'message': message, 'data': data, 'hypothesisId': hypothesisId})}'); } catch (_) {}
}
// #endregion

class AppApi {
  BuildContext? context;
  late Options appOptions;

  AppApi([this.context]) {
    appOptions = Options(extra: {'context': context});
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
        HttpHeaders.acceptHeader: 'application/json,'
            '*/*',
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
        HttpHeaders.acceptHeader: 'application/json,'
            '*/*',
      }));


static void disableCertificateVerification(Dio dioInstance) {
  if (dioInstance.httpClientAdapter is IOHttpClientAdapter) {
    (dioInstance.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (X509Certificate cert, String host, dynamic port) => true;
      AppLogger.logger.i("SSL certificate validation disabled for ${identical(dioInstance, dio) ? 'dio' : 'dio2'}.");
      return null;
    };
  } else {
    AppLogger.logger.e('Failed to disable SSL: httpClientAdapter is not IOHttpClientAdapter');
  }
}

// 初始化 Dio 配置
static Future<void> init() async {
  // #region agent log
  _agentLog('app_api.dart:init:entry', 'AppApi.init started', {}, 'H2');
  // #endregion
  var logger = AppLogger.logger;
  // #region agent log
  _agentLog('app_api.dart:after logger', 'logger obtained', {'hasLogger': true}, 'H2');
  // #endregion

  // 设置用户 token
  // #region agent log
  try {
    final p = Global.profile;
    _agentLog('app_api.dart:before profile', 'before Global.profile access', {'dataNull': p.data == null, 'accessTokenNull': p.accessToken == null}, 'H1');
  } catch (e) {
    _agentLog('app_api.dart:profile access threw', 'Global.profile access threw', {'error': e.toString()}, 'H1');
    rethrow;
  }
  // #endregion
  dio.options.headers[HttpHeaders.authorizationHeader] =
      Global.profile.data?.accessToken;
  // #region agent log
  _agentLog('app_api.dart:after auth header', 'first header set', {'authSet': dio.options.headers[HttpHeaders.authorizationHeader] != null}, 'H4');
  // #endregion
  logger.i(
      'authorizationHeader:${dio.options.headers[HttpHeaders.authorizationHeader]}');
  dio.options.headers.addAll({'token': Global.profile.accessToken});
  // #region agent log
  _agentLog('app_api.dart:after addAll', 'addAll done', {}, 'H4');
  // #endregion
  dio2.options.headers['content-type'] = 'application/json';
  dio2.options.headers[HttpHeaders.authorizationHeader] =
      Global.profile.data?.accessToken;
  logger.i('apptoken${dio.options.headers['token']}');
  logger.i('baseurl${dio.options.baseUrl}');

  // #region agent log
  _agentLog('app_api.dart:before disableCert', 'before disableCertificateVerification', {'dioAdapter': dio.httpClientAdapter.runtimeType.toString()}, 'H5');
  // #endregion
  if (F.appFlavor == Flavor.env_release) {
    const prefix = '/jcjx-prod-api';
    final addPrefix = InterceptorsWrapper(
      onRequest: (options, handler) {
        final p = options.path;
        if (p.startsWith('/') && !p.startsWith(prefix)) {
          options.path = '$prefix$p';
        }
        return handler.next(options);
      },
    );
    dio.interceptors.add(addPrefix);
    dio2.interceptors.add(addPrefix);
    final logUrl = InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.i('REQ ${options.method} ${options.uri}');
        return handler.next(options);
      },
    );
    dio.interceptors.add(logUrl);
    dio2.interceptors.add(logUrl);
  }
  disableCertificateVerification(dio);
  disableCertificateVerification(dio2);
  // #region agent log
  _agentLog('app_api.dart:init:exit', 'AppApi.init completed', {}, 'H5');
  // #endregion
  // 调试模式下禁用证书校验
//    if (Global.isRelease) {
//     // 生产环境加载证书
//     final context = await loadCertificate('assets/chuke-ca.crt');

//     dio.httpClientAdapter = IOHttpClientAdapter(
//       createHttpClient: () => HttpClient(context: context),
//     );
//   } else {
//     // 测试环境禁用证书验证
//     if (dio.httpClientAdapter is IOHttpClientAdapter) {
//       (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
//         client.badCertificateCallback = (cert, host, port) => true;
//         AppLogger.logger.i("SSL certificate validation disabled for debugging.");
//         return null;
//       };
//     }
// }
}
}
