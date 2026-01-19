import 'package:package_info_plus/package_info_plus.dart';

enum Flavor {
  env_dev,
  env_release,
  env_test,
}

class F {
  static Flavor? appFlavor;

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
        // return 'https://10.102.81.15:30652';
        return 'https://10.105.84.122:8080';
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
        // return 'https://10.102.81.15:30652';
        return 'https://10.105.84.122:8080';
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

  // 注意：version 现在应该从 package_info_plus 动态获取
  // 保留此方法以兼容旧代码，但建议使用 PackageInfo.fromPlatform() 获取
  static String get version {
    // 这个方法已废弃，应该使用 package_info_plus 动态获取
    // 保留此方法仅用于向后兼容
    switch (appFlavor) {
      case Flavor.env_dev:
        return '1.1.5';
      case Flavor.env_release:
        return '1.1.8';
      case Flavor.env_test:
        return '1.1.5';
      default:
        return '1.0.0';
    }
  }
  
  // 获取动态版本号（推荐使用）
  static Future<String> getVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      // 如果获取失败，返回默认值
      return version;
    }
  }
  
  // 获取构建号
  static Future<int> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return int.tryParse(packageInfo.buildNumber) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
