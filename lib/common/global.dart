import '../index.dart';
import '../models/progress.dart';

// #region agent log
void _agentLog(String location, String message, Map<String, dynamic> data,
    String hypothesisId) {
  try {
    const path = r'd:\jcjx\jcjx-phone\.cursor\debug.log';
    final m = {
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'hypothesisId': hypothesisId
    };
    final line = '${jsonEncode(m)}\n';
    File(path).writeAsStringSync(line, mode: FileMode.append);
  } catch (_) {}
  try {
    print('AGENT_LOG ${jsonEncode({
          'location': location,
          'message': message,
          'data': data,
          'hypothesisId': hypothesisId
        })}');
  } catch (_) {}
}
// #endregion

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
  static Set<String> phoneChildrenMetaTitles = <String>{};

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
  // 全部机车派工预加载 Future：开工点名/检修进度页复用，避免重复请求
  static Future<void>? _repairTrainLoadingFuture;

  // 检修进度数据缓存
  static List<RepairGroup> cachedRepairProgressData = [];
  static bool isRepairProgressDataLoaded = false;
  static DateTime? repairProgressDataLoadTime;

  // 用户个人机车作业数据缓存
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoC4 = [];
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoC5 = [];
  static List<Map<String, dynamic>> cachedUserRepairMainNodeInfoLinXiu = [];
  static bool isUserRepairTrainDataLoaded = false;
  static DateTime? userRepairTrainDataLoadTime;
  // 用户机车作业预加载 Future：登录/首页触发的在途查询，页面进入时 await 复用，避免重复请求
  static Future<void>? _userRepairTrainLoadingFuture;

  // 检修进度预加载 Future：登录成功后台触发的正在进行中的查询，页面进入时 await 复用
  static Future<List<RepairGroup>>? _repairProgressLoadingFuture;
  // 是否处于正在加载（后台）状态：true = 已启动但还未 await 结果落缓存
  static bool get isRepairProgressLoading => _repairProgressLoadingFuture != null
      && !isRepairProgressDataLoaded;

  // 可选的主题列表
  static List<MaterialColor> get themes => _theme;

  // 是否为release版
  static bool get isRelease => const bool.fromEnvironment('dart.vm.product');

  // 初始化全局信息
  static Future init() async {
    // #region agent log
    _agentLog('global.dart:init:entry', 'Global.init started', {}, 'H3');
    // #endregion
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

    // 初始化版本号（从 pubspec.yaml 统一读取）
    await F.initVersion();
    // #region agent log
    _agentLog('global.dart:before AppApi.init', 'about to call AppApi.init', {},
        'H3');
    // #endregion
    try {
      await AppApi.init();
      // #region agent log
      _agentLog(
          'global.dart:after AppApi.init', 'AppApi.init completed', {}, 'H3');
      // #endregion
    } catch (e, st) {
      // #region agent log
      _agentLog('global.dart:AppApi.init error', 'AppApi.init threw',
          {'error': e.toString(), 'stack': st.toString()}, 'H3');
      // #endregion
      rethrow;
    }
  }

  // 持久化Profile信息
  static saveProfile() =>
      _prefs.setString('profile', jsonEncode(profile.toJson()));

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
        startRepairTrainPreload(),
        _preloadRepairProgressData(),
        preloadUserRepairTrainData(),
      ]);

      logger.i('检修数据预加载完成');
    } catch (e) {
      logger.e('预加载检修数据失败: $e');
    }
  }

  static Future<void> ensureRepairProcInfoLoaded() async {
    if (Global.repairProcInfo.isNotEmpty) return;
    await _loadRepairProcInfo();
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

  // 启动全部机车派工数据预加载：多次调用复用同一个 Future
  static Future<void> startRepairTrainPreload() {
    _repairTrainLoadingFuture ??=
        _preloadRepairTrainDataInternal().whenComplete(() {
      _repairTrainLoadingFuture = null;
    });
    return _repairTrainLoadingFuture!;
  }

  // 页面进入时 await：在途则复用，未启动返回 null
  static Future<void>? awaitRepairTrainPreload() =>
      _repairTrainLoadingFuture;

  static Future<bool> _preloadRepairTrainDataInternal() async {
    final logger = AppLogger.logger;
    await Global.ensureRepairProcInfoLoaded();
    if (Global.repairProcInfo.isEmpty) {
      logger.w('修程信息为空，无法预加载机车派工数据');
      return false;
    }

    // C4 / C5 / 临修 并行查询，分项记录成功与否
    const targets = ['C4', 'C5', '临修'];
    final tasks = <Future<bool>>[];
    for (final target in targets) {
      String? procCode;
      for (final element in Global.repairProcInfo) {
        final nm = (element['name'] ??
                element['repairMainNode'] ??
                element['repairProcName'] ??
                '')
            .toString();
        if (_matchesRepairProcName(nm, target)) {
          procCode = (element['code'] ?? '').toString();
          break;
        }
      }
      if (procCode == null || procCode.isEmpty) {
        logger.w('未匹配到修程 code: $target');
        tasks.add(Future<bool>.value(false));
      } else {
        tasks.add(_loadRepairTrainDataByCode(target, procCode));
      }
    }

    final results = await Future.wait(tasks);
    // 三项都成功才标记整体加载完成；部分失败保留旧缓存，下次进入继续重试，
    // 避免一次网络抖动被当成“没有机车”缓存起来
    final allOk = results.every((ok) => ok);
    if (allOk) {
      isRepairTrainDataLoaded = true;
      repairTrainDataLoadTime = DateTime.now();
      logger.i('机车派工数据预加载完成');
    } else {
      isRepairTrainDataLoaded = false;
      logger.w('机车派工数据部分加载失败，保留旧缓存并在下次进入时重试');
    }
    return allOk;
  }

  // 加载指定修程的全部机车派工数据：成功才写缓存并返回 true，失败保留旧数据
  static Future<bool> _loadRepairTrainDataByCode(
    String name,
    String code,
  ) async {
    try {
      final data = await ProductApi()
          .getRepairingAllTrainEntryByRepairProcCode(
              queryParametrs: {'repairProcCode': code});
      final mapped = data
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String,dynamic>.from(e as Map))
          .toList();
      if (name == 'C4') {
        cachedRepairMainNodeInfoC4 = mapped;
      } else if (name == 'C5') {
        cachedRepairMainNodeInfoC5 = mapped;
      } else {
        cachedRepairMainNodeInfoLinXiu = mapped;
      }
      return true;
    } catch (e) {
      AppLogger.logger.e('加载 $name 数据失败: $e');
      return false;
    }
  }

  // 预加载检修进度数据（内部版本，返回 List<RepairGroup> 方便外面复用 Future）
  static Future<List<RepairGroup>> _preloadRepairProgressDataInternal() async {
    var logger = AppLogger.logger;
    try {
      logger.i('开始预加载检修进度数据...');
      final queryParametrs = <String, dynamic>{};
      final repairGroups =
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
      return repairGroups;
    } catch (e, stackTrace) {
      logger.e('预加载检修进度数据失败: $e');
      logger.e('堆栈信息: $stackTrace');
      isRepairProgressDataLoaded = false;
      return const [];
    }
  }

  // 预加载检修进度数据（无返回值，供 Future.wait 并行）
  // 复用 startRepairProgressPreload() 暴露的 _repairProgressLoadingFuture，
  // 这样 login.dart 里先调 startRepairProgressPreload() 再调 preloadRepairData()
  // 时不会发起两次相同请求，页面进入时也能 await 同一个 Future 复用结果。
  static Future<void> _preloadRepairProgressData() async {
    await startRepairProgressPreload();
  }

  // 启动「登录成功后台预加载」检修进度：返回的是同一个 Future，供页面 await 复用
  static Future<List<RepairGroup>> startRepairProgressPreload() {
    _repairProgressLoadingFuture ??=
        _preloadRepairProgressDataInternal().whenComplete(() {
      // 完成后把正在加载中的 Future 置空（否则下一次强制刷新不会重新请求）
      _repairProgressLoadingFuture = null;
    });
    return _repairProgressLoadingFuture!;
  }

  // 外部 await 这个 Future：
  //   - 如果后台正在加载中，则复用结果不重复请求；
  //   - 如果后台加载没启动，返回 null，让页面自己去请求
  static Future<List<RepairGroup>>? awaitRepairProgressPreload() =>
      _repairProgressLoadingFuture;

  // 外部清掉正在加载中的 Future，避免缓存过期或强制刷新时复用错数据
  static void clearRepairProgressLoadingFuture() {
    _repairProgressLoadingFuture = null;
  }

  // ===== 检修过程故障处置单发布权限（登录时预查，点击时直接读取）=====
  // 当前登录用户是否有权发布（两个接口查询结果比对后的结论）
  static bool hasFaultHandlePermission = false;
  // 预查是否完成（未完成时 case 6 可选择等待，避免过早拦截）
  static bool faultHandlePermissionChecked = false;
  static Future<void>? _faultHandlePermissionFuture;

  // 登录成功后调用：实时查询 getInfo + shuntingRole/selectAll 并比对，
  // 结果写入 hasFaultHandlePermission。同一个 Future 复用，不重复请求
  static Future<void> preloadFaultHandlePermission() {
    return _faultHandlePermissionFuture ??=
        _checkFaultHandlePermissionInternal().whenComplete(() {
      _faultHandlePermissionFuture = null;
    });
  }

  static Future<void> _checkFaultHandlePermissionInternal() async {
    final logger = AppLogger.logger;
    faultHandlePermissionChecked = false;
    hasFaultHandlePermission = false;
    try {
      final results = await Future.wait<dynamic>([
        LoginApi().getpermissions(),
        ProductApi().getShuntingRoleList(shuntingType: 25),
      ]);
      final Permissions userPerms = results[0] as Permissions;
      final List<Map<String, dynamic>> allowedRoles =
          results[1] as List<Map<String, dynamic>>;

      final allowedRoleIds = <int>{};
      for (final e in allowedRoles) {
        if (e['roleId'] is int) allowedRoleIds.add(e['roleId'] as int);
      }

      final userRoleIds = <int>{};
      final u = userPerms.user;
      if (u.roleId != null) userRoleIds.add(u.roleId!);
      if (u.roles != null) {
        for (final r in u.roles!) {
          if (r.roleId != null) userRoleIds.add(r.roleId!);
        }
      }
      if (u.roleIds != null && u.roleIds!.trim().isNotEmpty) {
        for (final s in u.roleIds!.split(',')) {
          final id = int.tryParse(s.trim());
          if (id != null) userRoleIds.add(id);
        }
      }

      hasFaultHandlePermission =
          userRoleIds.any(allowedRoleIds.contains);
      logger.i(
        '[故障处置单权限] 登录预查比对 userRoleIds=$userRoleIds '
        'allowedRoleIds=$allowedRoleIds result=$hasFaultHandlePermission',
      );
    } catch (e) {
      logger.e('[故障处置单权限] 登录预查失败: $e');
      hasFaultHandlePermission = false;
    } finally {
      faultHandlePermissionChecked = true;
    }
  }

  // 修程名匹配：与 repair_train.dart 页面保持一致，
  // 兼容 "C4修"/"C4-xx"、"售后临修" 等命名，避免精确匹配导致漏加载
  static bool _matchesRepairProcName(String name, String target) {
    final n = name.trim();
    if (n == target) return true;
    if ((target == 'C4' || target == 'C5') && n.startsWith(target)) {
      return true;
    }
    if (target == '临修' && n.contains('临修')) return true;
    return false;
  }

  // 预加载用户个人机车作业数据（公共方法，复用在途 Future，不重复请求）
  static Future<void> preloadUserRepairTrainData() =>
      startUserRepairTrainPreload();

  // 启动预加载：多次调用复用同一个 Future
  static Future<void> startUserRepairTrainPreload() {
    _userRepairTrainLoadingFuture ??=
        _preloadUserRepairTrainDataInternal().whenComplete(() {
      _userRepairTrainLoadingFuture = null;
    });
    return _userRepairTrainLoadingFuture!;
  }

  // 页面进入时 await：在途则复用，未启动返回 null 让页面自己加载
  static Future<void>? awaitUserRepairTrainPreload() =>
      _userRepairTrainLoadingFuture;

  static Future<bool> _preloadUserRepairTrainDataInternal() async {
    final logger = AppLogger.logger;
    // 等待权限信息加载（最多等待 3 秒）
    int? userId = Global.profile.permissions?.user.userId;
    var retryCount = 0;
    while (userId == null && retryCount < 6) {
      await Future.delayed(const Duration(milliseconds: 500));
      userId = Global.profile.permissions?.user.userId;
      retryCount++;
    }

    if (userId == null) {
      logger.w('用户ID为空，无法预加载用户机车作业数据（权限信息可能尚未加载）');
      return false;
    }

    await Global.ensureRepairProcInfoLoaded();
    if (Global.repairProcInfo.isEmpty) {
      logger.w('修程信息为空，无法预加载用户机车作业数据');
      return false;
    }

    // C4 / C5 / 临修 并行查询，分项记录成功与否
    const targets = ['C4', 'C5', '临修'];
    final tasks = <Future<bool>>[];
    for (final target in targets) {
      String? procCode;
      for (final element in Global.repairProcInfo) {
        final nm = (element['name'] ??
                element['repairMainNode'] ??
                element['repairProcName'] ??
                '')
            .toString();
        if (_matchesRepairProcName(nm, target)) {
          procCode = (element['code'] ?? '').toString();
          break;
        }
      }
      if (procCode == null || procCode.isEmpty) {
        logger.w('未匹配到修程 code: $target');
        tasks.add(Future<bool>.value(false));
      } else {
        tasks.add(_loadUserRepairTrainDataByCode(target, procCode, userId));
      }
    }

    final results = await Future.wait(tasks);
    // 三项都成功才标记整体加载完成；部分失败保留旧缓存并保持 loaded=false，
    // 下次进入页面会继续重试，不会把“一次网络抖动”当成“没有机车”缓存起来
    final allOk = results.every((ok) => ok);
    if (allOk) {
      isUserRepairTrainDataLoaded = true;
      userRepairTrainDataLoadTime = DateTime.now();
      logger.i('用户机车作业数据预加载完成');
    } else {
      isUserRepairTrainDataLoaded = false;
      logger.w('用户机车作业数据部分加载失败，保留旧缓存并在下次进入时重试');
    }
    return allOk;
  }

  // 加载指定修程的用户机车作业数据：成功才写缓存并返回 true，失败保留旧数据
  static Future<bool> _loadUserRepairTrainDataByCode(
    String name,
    String code,
    int userId,
  ) async {
    try {
      final data = await ProductApi()
          .getRepairingTrainEntryByUserIdAndRepairProcCode(
              queryParametrs: {'userId': userId, 'repairProcCode': code});
      if (name == 'C4') {
        cachedUserRepairMainNodeInfoC4 = data;
      } else if (name == 'C5') {
        cachedUserRepairMainNodeInfoC5 = data;
      } else {
        cachedUserRepairMainNodeInfoLinXiu = data;
      }
      return true;
    } catch (e) {
      AppLogger.logger.e('加载用户 $name 数据失败: $e');
      return false;
    }
  }
}
