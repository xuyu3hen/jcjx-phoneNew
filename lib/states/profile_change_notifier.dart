import 'package:jcjx_phone/models/accessToken.dart';

import '../index.dart';


// 持久化数据更新控制
class ProfileChangeNotifier extends ChangeNotifier {
  Profile get _profile => Global.profile;

  @override
  void notifyListeners() {
    // 保存Profile变更
    Global.saveProfile();
    super.notifyListeners();
  }
}

class UserModel extends ProfileChangeNotifier {
  // User? get user => _profile.data;
  AccessToken? get accessToken => _profile.data;

  // 校验APPToken是否有效
  bool get isLogin => _profile.data?.access_token != null;

  //TODO更新用户信息及相关widget
  // set user(User? user) {
  //   if(user?.userLoginName != _profile.lastLogin) {
  //     print('wsfafds${_profile.lastLogin}');
  //     _profile.lastLogin = user?.userLoginName;
  //     user = _profile.data;
  //     notifyListeners();
  //   }
  // }

    set accessToken(AccessToken? accessToken) {
      // if(user?.userLoginName != _profile.lastLogin) {
      //   print('wsfafds${_profile.lastLogin}');
      //   _profile.lastLogin = user?.userLoginName;
      //   user = _profile.data;
      //   notifyListeners();
      // }
        accessToken = _profile.data;
        notifyListeners();
    }
}

// 转换存在问题
class ThemeModel extends ProfileChangeNotifier {
  //获取当前主题，未设置主题，默认使用蓝色
  MaterialColor get theme => Global.themes
      .firstWhere((element) => element.value == _profile.theme, orElse: () => Colors.blue);

  set theme(MaterialColor color) {
    if(color != theme) {
      _profile.theme = color.value;
      notifyListeners();
    }
  }
}