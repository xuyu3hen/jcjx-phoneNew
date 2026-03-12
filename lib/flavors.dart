import 'package:package_info_plus/package_info_plus.dart';

enum Flavor {
  env_dev,
  env_release,
  env_test,
}

class F {
  static Flavor? appFlavor;
  
  // 缓存的版本号（从 pubspec.yaml 动态获取）
  static String? _cachedVersion;
  static int? _cachedBuildNumber;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.env_dev:
        return '机车检修(本地)';
      case Flavor.env_release:
        return '机车检修';
      case Flavor.env_test:
        return '机车检修(测试)';
      default:
        return 'title';
    }
  }

  static String get baseURL {
    switch (appFlavor) {
      case Flavor.env_dev:
        return 'http://10.105.84.122:8080';
      case Flavor.env_release:
        // return 'https://10.102.81.15:30652';
        return 'https://10.102.124.50/jcjx-prod-api/';
      // return 'https://10.105.84.122:8080';
      case Flavor.env_test:
        return 'http://10.105.84.122:8080';
      default:
        return 'http://10.105.84.122:8080';
    }
  }

  static String get appBaseURL {
    switch (appFlavor) {
      case Flavor.env_dev:
        return 'http://10.105.84.122:8080';
      case Flavor.env_release:
        // return 'https://10.102.81.15:30652';
        return 'https://10.102.124.50/jcjx-prod-api/';
      // return 'https://10.105.84.122:8080';
      case Flavor.env_test:
        return 'http://10.105.84.122:8080';
      default:
        return 'http://10.105.84.122:8080';
    }
  }

  static String get id {
    switch (appFlavor) {
      case Flavor.env_dev:
        return 'com.jcjx_phone_dev';
      case Flavor.env_release:
        return 'com.jcjx_phone_release';
      case Flavor.env_test:
        return 'com.jcjx_phone_test';
      default:
        return 'com.jcjx_phone_release';
    }
  }

  // 初始化版本号（在应用启动时调用）
  static Future<void> initVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedVersion = packageInfo.version;
      _cachedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    } catch (e) {
      // 如果获取失败，使用默认值
      _cachedVersion = '1.0.0';
      _cachedBuildNumber = 0;
    }
  }

  // 获取版本号（同步方法，返回缓存的值）
  // 注意：在应用启动后调用 initVersion() 来初始化版本号
  static String get version {
    return _cachedVersion ?? '加载中...';
  }
  
  // 获取构建号（同步方法，返回缓存的值）
  static int get buildNumber {
    return _cachedBuildNumber ?? 0;
  }
  
  // 获取动态版本号（异步方法，推荐使用）
  static Future<String> getVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedVersion = packageInfo.version; // 更新缓存
      return packageInfo.version;
    } catch (e) {
      // 如果获取失败，返回缓存的值或默认值
      return _cachedVersion ?? '1.0.0';
    }
  }
  
  // 获取构建号（异步方法）
  static Future<int> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0; // 更新缓存
      return _cachedBuildNumber!;
    } catch (e) {
      return _cachedBuildNumber ?? 0;
    }
  }
}
