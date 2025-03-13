import '../index.dart';
import 'package:shared_preferences/shared_preferences.dart';


// 该参数用于程序样式控制(主题颜色)

const _theme = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
];

class Global {
  // 持久化控制
  static late SharedPreferences _prefs;
  static Profile profile = Profile(theme: 0);


  
  // 可选的主题列表
  static List<MaterialColor> get themes => _theme;

  // 是否为release版
  static bool get isRelease => const bool.fromEnvironment("dart.vm.product");

  // 初始化全局信息
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();

    _prefs = await SharedPreferences.getInstance();
    var _profile = _prefs.getString("profile");

    // if(_profile != null) {
    //   try {
    //     // 校验token有效性
    //     var data = await LoginApi().getuserInfo();
        
    //     if(data == 200){
    //       profile = Profile.fromJson(jsonDecode(_profile));
    //     }else{
    //       _prefs.remove("profile");
    //       profile = Profile(theme: 4);
    //     }
    //   }catch(e){
    //     print(e);
    //   }
    // }else{
    //   //写法变更，实现效果存疑
    //   profile = Profile(theme: 4);
    // }

    //缓存策略 A??B表示 A为null则取值为B
    // ..为Flutter语法糖，等同于 CacheConfig.enable = true,Dart中的setter与getter方法为隐式
    profile.cache = profile.cache ?? CacheConfig()
    ..enable = true
    ..maxAge = 3600
    ..maxCount = 100;


    AppApi.init();
  }

  // 持久化Profile信息
  static saveProfile() => _prefs.setString("profile", jsonEncode(profile.toJson()));



}