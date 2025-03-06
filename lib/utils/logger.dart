// lib/utils/logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );

  static Logger get logger => _logger;
}