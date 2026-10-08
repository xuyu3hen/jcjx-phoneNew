import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter/services.dart';
import 'package:scan_gun/binding/scan_input_binding.dart';
import 'index.dart';

Future<void> main() async {
    // TextInputBinding 继承自 WidgetsFlutterBinding，创建即完成 binding 初始化
    TextInputBinding();

    // 锁定竖屏（从上至下），禁止屏幕左转/右转
    await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp],
    );

    // 全局兜底：捕获 flutter_local_notifications 的未处理异常。
    // 该插件 17.x 的 cancel/cancelAll 会反序列化本地缓存的定时通知，
    // 旧格式残留会抛 PlatformException(Missing type parameter)，
    // 即便调用处已 try/catch，部分异步路径仍会泄漏到 E/flutter。
    FlutterError.onError = (FlutterErrorDetails details) {
      final errStr = details.exception.toString();
      if (errStr.contains('Missing type parameter') ||
          errStr.contains('flutterlocalnotifications') ||
          errStr.contains('FlutterLocalNotifications')) {
        AppLogger.logger
            .w('抑制通知插件框架异常: ${details.exception}');
        return;
      }
      AppLogger.logger
          .e('Flutter错误: ${details.exception}\n${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final errStr = error.toString();
      if (errStr.contains('Missing type parameter') ||
          errStr.contains('flutterlocalnotifications') ||
          errStr.contains('FlutterLocalNotifications')) {
        AppLogger.logger.w('抑制通知插件异步异常: $error');
        return true;
      }
      AppLogger.logger.e('未处理异步异常: $error\n$stack');
      return true;
    };

    Global.init().then((e) => runApp(const MyApp()));
}