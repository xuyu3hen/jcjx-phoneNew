import '../index.dart';
import '../models/progress.dart';
import '../api/production_api.dart';



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

  static String? parentDeptName;

  //修程信息
  static List<Map<String, dynamic>> repairProcInfo = [];

  //机型信息
  static List<Map<String, dynamic>> typeInfo = [];

  static List<Map<String, dynamic>> repairInfo = [];

  static List<Map<String, dynamic>> faultPartList = [];

  static List<Map<String, dynamic>> packageList = [];
  
  // 机车派工数据缓存
  static List<Map<String, dynamic>> cachedRepairMainNodeInfoC4 = [];
  static List<Map<String, dynamic>> cachedRepairMainNodeInfoC5 = [];
  static List<Map<String, dynamic>> cachedRepairMainNodeInfoLinXiu = [];
  static bool isRepairTrainDataLoaded = false;
  static DateTime? repairTrainDataLoadTime;
  
  // 检修进度数据缓存
  static List<RepairGroup> cachedRepairProgressData = [];
  static bool isRepairProgressDataLoaded = false;
  static DateTime? repairProgressDataLoadTime;
  
  // 用户个人机车作业数据缓存（repair_train.dart 使用）
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoC4 = [];
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoC5 = [];
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoLinXiu = [];
  static bool isUserRepairTrainDataLoaded = false;
  static DateTime? userRepairTrainDataLoadTime;
  
  // 可选的主题列表
  static List<MaterialColor> get themes => _theme;

  // 是否为release版
  static bool get isRelease => const bool.fromEnvironment("dart.vm.product");

  // 初始化全局信息
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();

    _prefs = await SharedPreferences.getInstance();
    // var _profile = _prefs.getString("profile");

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

  // 预加载机车派工和检修进度数据
  static Future<void> preloadRepairData() async {
    var logger = AppLogger.logger;
    try {
      logger.i('开始预加载检修数据...');
      
      // 先确保修程信息已加载
      if (Global.repairProcInfo.isEmpty) {
        logger.i('修程信息为空，先加载修程信息...');
        await _loadRepairProcInfo();
      }
      
      // 并行加载所有数据以提高速度（用户个人数据需要权限信息，可能稍后加载）
      await Future.wait([
        _preloadRepairTrainData(),
        _preloadRepairProgressData(),
        preloadUserRepairTrainData(),
      ]);
      
      logger.i('检修数据预加载完成');
    } catch (e) {
      logger.e('预加载检修数据失败: $e');
    }
  }
  
  // 加载修程信息
  static Future<void> _loadRepairProcInfo() async {
    try {
      Map<String, dynamic> queryParameters = {'pageNum': 0, 'pageSize': 0};
      var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
      if (r.code == 200) {
        Global.repairProcInfo.clear();
        r.rows?.forEach((element) {
          Global.repairProcInfo.add(element.toJson());
        });
      }
    } catch (e) {
      AppLogger.logger.e('加载修程信息失败: $e');
    }
  }

  // 预加载机车派工数据
  static Future<void> _preloadRepairTrainData() async {
    var logger = AppLogger.logger;
    try {
      // 获取修程信息
      if (Global.repairProcInfo.isEmpty) {
        logger.w('修程信息为空，无法预加载机车派工数据');
        return;
      }

      // 查找 C4, C5, 临修 的修程代码
      String? c4Code, c5Code, linXiuCode;
      for (var element in Global.repairProcInfo) {
        if (element['name'] == 'C4') {
          c4Code = element['code'];
        } else if (element['name'] == 'C5') {
          c5Code = element['code'];
        } else if (element['name'] == '临修') {
          linXiuCode = element['code'];
        }
      }

      // 并行查询三个修程的数据
      List<Future> futures = [];
      if (c4Code != null) {
        futures.add(_loadRepairTrainDataByCode('C4', c4Code, (data) {
          cachedRepairMainNodeInfoC4 = data;
        }));
      }
      if (c5Code != null) {
        futures.add(_loadRepairTrainDataByCode('C5', c5Code, (data) {
          cachedRepairMainNodeInfoC5 = data;
        }));
      }
      if (linXiuCode != null) {
        futures.add(_loadRepairTrainDataByCode('临修', linXiuCode, (data) {
          cachedRepairMainNodeInfoLinXiu = data;
        }));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
        isRepairTrainDataLoaded = true;
        repairTrainDataLoadTime = DateTime.now();
        logger.i('机车派工数据预加载完成');
      }
    } catch (e) {
      logger.e('预加载机车派工数据失败: $e');
    }
  }

  // 加载指定修程的机车派工数据
  static Future<void> _loadRepairTrainDataByCode(
    String name,
    String code,
    Function(List<Map<String, dynamic>>) onSuccess,
  ) async {
    try {
      Map<String, dynamic> params = {
        'repairProcCode': code
      };
      var response = await ProductApi()
          .getRepairingAllTrainEntryByRepairProcCode(queryParametrs: params);
      
      // response 已经是 List 类型
      List<Map<String, dynamic>> data = (response as List)
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
      onSuccess(data);
    } catch (e) {
      AppLogger.logger.e('加载 $name 数据失败: $e');
    }
  }

  // 预加载检修进度数据
  static Future<void> _preloadRepairProgressData() async {
    var logger = AppLogger.logger;
    try {
      logger.i('开始预加载检修进度数据...');
      Map<String, dynamic> queryParametrs = {};
      List<RepairGroup> repairGroups =
          await ProductApi().getTrainEntryAndDynamics(queryParametrs);
      
      if (repairGroups.isNotEmpty) {
        cachedRepairProgressData = repairGroups;
        isRepairProgressDataLoaded = true;
        repairProgressDataLoadTime = DateTime.now();
        logger.i('检修进度数据预加载完成，共 ${repairGroups.length} 条数据');
      } else {
        logger.w('检修进度数据预加载完成，但数据为空');
        cachedRepairProgressData = [];
        isRepairProgressDataLoaded = true;
        repairProgressDataLoadTime = DateTime.now();
      }
    } catch (e, stackTrace) {
      logger.e('预加载检修进度数据失败: $e');
      logger.e('堆栈信息: $stackTrace');
      // 即使失败也标记为已加载，避免重复尝试
      isRepairProgressDataLoaded = false;
    }
  }

  // 预加载用户个人机车作业数据（公共方法，可在权限加载后调用）
  static Future<void> preloadUserRepairTrainData() async {
    var logger = AppLogger.logger;
    try {
      // 等待权限信息加载（最多等待3秒）
      int? userId = Global.profile.permissions?.user.userId;
      int retryCount = 0;
      while (userId == null && retryCount < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
        userId = Global.profile.permissions?.user.userId;
        retryCount++;
      }
      
      if (userId == null) {
        logger.w('用户ID为空，无法预加载用户个人机车作业数据（权限信息可能尚未加载）');
        return;
      }

      // 获取修程信息
      if (Global.repairProcInfo.isEmpty) {
        logger.w('修程信息为空，无法预加载用户个人机车作业数据');
        return;
      }

      // 查找 C4, C5, 临修 的修程代码
      String? c4Code, c5Code, linXiuCode;
      for (var element in Global.repairProcInfo) {
        if (element['name'] == 'C4') {
          c4Code = element['code'];
        } else if (element['name'] == 'C5') {
          c5Code = element['code'];
        } else if (element['name'] == '临修') {
          linXiuCode = element['code'];
        }
      }

      // 并行查询三个修程的数据
      List<Future> futures = [];
      if (c4Code != null) {
        futures.add(_loadUserRepairTrainDataByCode('C4', c4Code, userId, (data) {
          cachedUserRepairMainNodeInfoC4 = data;
        }));
      }
      if (c5Code != null) {
        futures.add(_loadUserRepairTrainDataByCode('C5', c5Code, userId, (data) {
          cachedUserRepairMainNodeInfoC5 = data;
        }));
      }
      if (linXiuCode != null) {
        futures.add(_loadUserRepairTrainDataByCode('临修', linXiuCode, userId, (data) {
          cachedUserRepairMainNodeInfoLinXiu = data;
        }));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
        isUserRepairTrainDataLoaded = true;
        userRepairTrainDataLoadTime = DateTime.now();
        logger.i('用户个人机车作业数据预加载完成');
      }
    } catch (e) {
      logger.e('预加载用户个人机车作业数据失败: $e');
    }
  }

  // 加载指定修程的用户个人机车作业数据
  static Future<void> _loadUserRepairTrainDataByCode(
    String name,
    String code,
    int userId,
    Function(List<Map<String, dynamic>>) onSuccess,
  ) async {
    try {
      Map<String, dynamic> params = {
        'userId': userId,
        'repairProcCode': code
      };
      var response = await ProductApi()
          .getRepairingTrainEntryByUserIdAndRepairProcCode(queryParametrs: params);
      
      // response 已经是 List 类型
      List<Map<String, dynamic>> data = (response as List)
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
      onSuccess(data);
    } catch (e) {
      AppLogger.logger.e('加载用户 $name 数据失败: $e');
    }
  }

}