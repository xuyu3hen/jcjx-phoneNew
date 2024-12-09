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
        return 'http://10.102.72.103:8080';
      case Flavor.env_release:
        return 'http://10.111.154.85:8080';
      case Flavor.env_test:
        return 'http://10.102.72.243:8080';
      default:
        return 'http://10.111.154.85:8080';
    }
  }

  static String get appBaseURL {
    switch (appFlavor) {
      case Flavor.env_dev:
        return 'http://10.102.72.103:8080';
      case Flavor.env_release:
        return 'http://10.111.154.85:8080';
      case Flavor.env_test:
        return 'http://10.102.72.103:8080';
      default:
        return 'http://10.111.154.85:8080';
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

  static String get version {
    switch (appFlavor) {
      case Flavor.env_dev:
        return '1.0.0';
      case Flavor.env_release:
        return '1.0.0';
      case Flavor.env_test:
        return '1.0.7';
      default:
        return '1.0.0';
    }
  }

}
