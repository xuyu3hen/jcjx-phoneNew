


import 'package:flutter/services.dart' show PlatformException;
import 'package:jcjx_phone/routes/production/jt_repair.dart';
import 'package:jcjx_phone/routes/production/repair_train.dart';

import 'package:jcjx_phone/routes/production/after_sale_temp_repair_register_page.dart';
import 'package:jcjx_phone/routes/production/repair_train_manage.dart';
import 'package:jcjx_phone/routes/production/train_departure_confirm_page.dart';
import 'package:jcjx_phone/routes/vehicle28/taskpackage/proc_node_list.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data'; // 引入 Int64List 所需的包

import '../index.dart';
import 'production/train_shunting_package_page.dart';
import 'vehicle28/submit28_manage.dart';

class MainPage extends StatefulWidget {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  const MainPage({Key? key}) : super(key: key);

  @override
  State createState() => _MainPage();
}

class _MainPage extends State<MainPage> with SingleTickerProviderStateMixin {
  static const String _prefMessageVibrationEnabled =
      'pref_message_vibration_enabled';

  PageController? pageController;
  int page = 0;
  int _messageCount = 0;
  final bool _hasUpdate = false;
  var logger = AppLogger.logger;
  bool _isPageSwiping = false;
  int? _pendingMessageCount;

  // 通知插件实例
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 通知本地缓存是否已损坏（旧版本残留的定时通知无法反序列化）。
  // 首次 cancel 抛 Missing type parameter 后置 true，后续跳过 cancel，
  // 避免每 15 秒刷一次错误日志
  bool _notificationCacheCorrupt = false;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: page);
    pageController?.addListener(_handlePageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        pageController?.jumpToPage(page);
      }
      _startPolling();
    });

    // 获取是线上版本还是线下版版本
    // queryParameters = {
    //   'app_id': F.id,
    //   'app_version': await F.getVersion(),
    //   'app_build_number': await F.getBuildNumber(),
    //   'app_flavor': F.appFlavor.toString(),
    // };
    logger.i('当前环境: ${F.appFlavor}');
    // 覆盖 token 有效、重启后直接进主页（不走登录页）的场景：
    // 未预查过故障处置单权限则补查一次；登录页已查过则不重复请求
    if (!Global.faultHandlePermissionChecked &&
        Global.profile.data != null) {
      Global.preloadFaultHandlePermission().catchError((e) {
        logger.e('预查故障处置单权限失败: $e');
      });
    }
    // ProductApi().getLatestOne(env: 'release');
    _initLocalNotifications();
    // 初始化更新组件
    initXUpdate();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // 立即执行一次
    if (mounted) {
      _loadMessageCount();
    }
    // 每隔 15 秒主动去服务端拉取一次最新数量
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        if (_isPageSwiping) return;
        _loadMessageCount();
      }
    });
  }

  void _handlePageScroll() {
    final p = pageController?.page;
    if (p == null) return;
    final isSwiping = (p - p.round()).abs() > 0.001;
    if (_isPageSwiping == isSwiping) return;
    _isPageSwiping = isSwiping;
    if (!isSwiping && _pendingMessageCount != null && mounted) {
      final next = _pendingMessageCount!;
      _pendingMessageCount = null;
      setState(() => _messageCount = next);
      _updateAppBadge(next);
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// 安全取消通知。
  /// flutter_local_notifications 17.x 的 cancel/cancelAll 内部会
  /// 调用 loadScheduledNotifications 反序列化本地缓存的定时通知，
  /// 旧版本/旧格式残留会抛 PlatformException(Missing type parameter)。
  /// 使用 .catchError 兜底 + try/catch 双重保护，确保异常被吞掉。
  Future<void> _safeCancelNotification(int id) async {
    if (_notificationCacheCorrupt) return;
    try {
      // 用 .catchError 在 Future 层先吞一道，避免 await 抛出后
      // 被框架当作 unhandled exception 打到 E/flutter
      await flutterLocalNotificationsPlugin
          .cancel(id)
          .catchError((Object e) {
        AppLogger.logger.w('cancel catchError: $e');
        _notificationCacheCorrupt = true;
      });
    } on PlatformException catch (e) {
      AppLogger.logger.w('取消通知失败，缓存可能损坏: $e');
      _notificationCacheCorrupt = true;
    } catch (e) {
      AppLogger.logger.w('取消通知未知异常: $e');
      _notificationCacheCorrupt = true;
    }
  }

  // 更新组件初始化
  void initXUpdate() {
    if (Platform.isAndroid) {
      FlutterXUpdate.init(
        ///是否输出日志
        debug: true,

        ///是否使用post请求
        isPost: true,

        ///post请求是否是上传json
        isPostJson: false,

        ///请求响应超时时间
        timeout: 25000,

        ///是否开启自动模式
        isWifiOnly: false,

        ///是否开启自动模式
        isAutoMode: false,

        ///需要设置的公共参数
        supportSilentInstall: false,

        ///在下载过程中，如果点击了取消的话，是否弹出切换下载方式的重试提示弹窗
        enableRetry: false,
      ).then((value) {
        // updateMessage('初始化成功: $value');
      }).catchError((error) {
        // logger.e(error);
      });
    } else {
      // updateMessage('ios暂不支持XUpdate更新');
    }
  }

  void getLastUpdate() async {
    try {
      var logger = AppLogger.logger;
      logger.i('检查更新，应用ID: ${F.id}');

      // 获取当前应用版本信息
      String currentVersion = await F.getVersion();
      int currentBuildNumber = await F.getBuildNumber();

      logger.i('当前版本: $currentVersion+$currentBuildNumber');

      // 获取当前环境对应的 env 参数
      String env = 'release';
      switch (F.appFlavor) {
        case Flavor.env_dev:
          env = 'dev';
          break;
        case Flavor.env_test:
          env = 'test';
          break;
        case Flavor.env_release:
          env = 'release';
          break;
        default:
          env = 'release';
      }

      // 使用 getLatestOne 获取最新版本信息
      var r = await ProductApi().getLatestOne(env: env);
      logger.i('服务器返回的版本信息: $r');
      // if (r == null || r.version == null) {
      //   logger.i("服务器返回的版本信息为空");
      //   return;
      // }

      // 比较版本号（支持语义化版本号比较）


      // 更新状态
  

      // if (hasUpdate) {
      //   logger.i("准备弹出更新提示框，下载地址: ${r.url}");
      //   checkUpdateByUpdateEntity(r);
      // } else {
      //   logger.i("无需更新");
      //   // showToast("已是最新版本");
      // }
    } catch (e) {
      // logger.e("检查更新失败: $e");
      // 不显示错误提示，避免影响用户体验
    }
  }

  // 比较版本号（语义化版本号比较）
  // 返回值: >0 表示 version1 > version2, <0 表示 version1 < version2, 0 表示相等
  // 转义成UpdateEntity
  UpdateEntity customJsonParse(myapk) {
    // 构建完整的下载URL（如果是相对路径，需要添加服务器地址）
    String downloadUrl = myapk.url ?? '';
    if (downloadUrl.isNotEmpty && !downloadUrl.startsWith('http')) {
      // 相对路径，添加服务器地址
      String baseUrl = UpdateApi.distributionServerUrl;
      if (!downloadUrl.startsWith('/')) {
        downloadUrl = '/$downloadUrl';
      }
      downloadUrl = '$baseUrl$downloadUrl';
    }

    return UpdateEntity(
      isForce: myapk.isForceUpdate ?? false, // 使用服务器返回的强制更新标志
      hasUpdate: true,
      isIgnorable: !(myapk.isForceUpdate ?? false), // 强制更新时不可忽略
      versionCode: myapk.buildNumber ?? 1,
      versionName: myapk.version ?? '未知版本',
      updateContent: myapk.dec ?? '新版本更新',
      downloadUrl: downloadUrl,
      apkSize: (myapk.fileSize ?? 0) >= 1024 * 1024
          ? ((myapk.fileSize ?? 0) / 1024).ceil()
          : myapk.fileSize,
      apkMd5: (myapk.md5 ?? '').toString().trim().isEmpty ? null : myapk.md5,
    );
  }

  ///传入UpdateEntity进行更新提示
  void checkUpdateByUpdateEntity(myapk) {
    FlutterXUpdate.updateByInfo(updateEntity: customJsonParse(myapk));
  }

  int _lastNotificationCount = -1;

  Future<void> _updateAppBadge(int count) async {
    try {
      // Android 13 及以上，如果不授予通知权限，桌面角标功能将直接被系统屏蔽。
      // 避免重复请求权限导致异常
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        // We do not await here if it throws "already running" error, 
        // we can safely catch it or just try to request without breaking the whole flow.
        try {
          await Permission.notification.request();
        } catch (e) {
          AppLogger.logger.w('请求通知权限忽略异常: $e');
        }
      }

      bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
      AppLogger.logger.i('角标支持状态: $isSupported, 当前数量: $count');
      
      if (isSupported || Platform.isAndroid) {
        if (count > 0) {
          FlutterAppBadger.updateBadgeCount(count);
          // 只有数量发生变化时，才触发新的通知（避免每15秒震动一次）
          if (count != _lastNotificationCount) {
             _showNotification(count);
             _lastNotificationCount = count;
          }
        } else {
          FlutterAppBadger.removeBadge();
          // cancel 内部会反序列化本地缓存的定时通知，旧格式残留会抛
          // PlatformException(Missing type parameter)，用安全方法取消
          await _safeCancelNotification(888);
          _lastNotificationCount = 0;
        }
      }
    } catch (e) {
      AppLogger.logger.e('更新角标失败: $e');
    }
  }

  Future<void> _showNotification(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vibrationEnabled = prefs.getBool(_prefMessageVibrationEnabled) ?? true;
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'jcjx_message_channel',
        '系统消息通知',
        channelDescription: '用于显示机车检修系统的未读消息和调令数量',
        importance: Importance.max, // 修改为最高重要性
        priority: Priority.high,    // 修改为高优先级
        ticker: 'ticker',
        ongoing: true, // 设置为正在进行，使其常驻
        autoCancel: false,
        enableVibration: vibrationEnabled,
        vibrationPattern: vibrationEnabled
            ? Int64List.fromList([0, 500, 200, 500])
            : null,
        playSound: true, // 确保声音也被触发
        number: count, // Android 8.0+ 的系统桌面角标长按数字显示，并用于更新图标上的未读消息数量
        channelShowBadge: true, // 确保渠道本身允许展示角标
      );
      final NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);
      
      await flutterLocalNotificationsPlugin.show(
        888, // 固定的通知ID
        '机车检修消息中心',
        '您有 $count 条未读消息待处理', // 纯粹展示未读消息
        notificationDetails,
        payload: 'item x',
      );
    } catch (e) {
      AppLogger.logger.e('发送常驻通知失败: $e');
    }
  }

  Future<void> _loadMessageCount() async {
    try {
      // 1. 获取消息中心的数量 (包含类型 8 和类型 21: 售后故障录入通知)
      final resMessage = await ProductApi().getMessageInfo(
        queryParametrs: {
          'type': [8, 21],
          'auditDTO': {},
        },
      );
      final dataMessage = resMessage is Map ? resMessage : <String, dynamic>{};
      final messageCount = (dataMessage['count'] as num?)?.toInt() ?? 0;

      // 2. 获取未读调车通知的数量 (status: 0 代表未读)
      int shuntingUnreadCount = 0;
      if (Global.profile.permissions == null) {
        final p = await LoginApi().getpermissions();
        if (p.code == 200 && mounted) {
          Global.profile.permissions = p;
        }
      }
      final user = Global.profile.permissions?.user;
      final resShunting = await DefaultShuntingNoticeApi().getShuntingNotice(
        queryParametrs: {
          'auditUserName': user?.nickName ?? user?.userName ?? '',
          'auditUserId': user?.userId ?? '',
          'status': 0,
          'pageNum': 1,
          'pageSize': 1, // 只需要 total，不需要拉取具体列表
        },
      );
      final dataShunting = resShunting is Map ? resShunting : <String, dynamic>{};
      final shuntingTotal = dataShunting['total'];
      if (shuntingTotal is num) {
        shuntingUnreadCount = shuntingTotal.toInt();
      } else {
        shuntingUnreadCount = int.tryParse(shuntingTotal?.toString() ?? '') ?? 0;
      }

      // 我们发现调车通知详情里的通知也属于消息的一种。这里为了不重复叠加数量，
      // 因为之前的逻辑 messageCount 已经包含了总的调车通知消息（卡片）数量。
      // 如果您希望直接使用 `messageCount` 作为唯一数字，可以直接把下面的 `totalCount` 改成 `messageCount`。
      // 这里根据您的反馈“翻倍了”，说明 messageCount 实际上可能已经涵盖了或者不需要额外再加上去。
      final totalCount = shuntingUnreadCount > 0 ? shuntingUnreadCount : messageCount; 

      if (_isPageSwiping) {
        _pendingMessageCount = totalCount;
        return;
      }
      if (mounted) {
        setState(() => _messageCount = totalCount);
      }
      _updateAppBadge(totalCount);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    pageController?.removeListener(_handlePageScroll);
    pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 除去debug红角标
      debugShowCheckedModeBanner: false,
      navigatorKey: MainPage.navigatorKey,
      home: _buildBody(),
      theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          focusColor: Colors.lightBlue,
          appBarTheme: AppBarTheme(
            elevation: 4.0,
            backgroundColor: Colors.lightBlue[100],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[100]))),
      routes: <String, WidgetBuilder>{
        'main': (context) => const MainPage(),

        // 登录
        'login': (context) => const LoginRoute(),
        // 入段车辆查看
        'enter_list': (context) => const EnterList(),
        // 新增入段修改
        'sec_enter_modify': (context) => const SecEnterModifyNew(),
        'sec_enter_detail_record': (context) => const SecEnterModifyNew(),
        // 机统28
        'submit28': (context) => const Vehicle28Form(),
        'dispatchlist': (context) => const DispatchList(),
        'repairlist': (context) => const RepairList(),
        'repair': (context) => const Repair(),
        'mutuallist': (context) => const MutualList(),
        'mutual': (context) => const Mutual(),
        'speciallist': (context) => const SpecialList(),
        'special': (context) => const Special(),
        'vehimageviewer': (context) => const VehImageViewer(),
        'certainPackage': (context) => const CertainPackage(),
        'rollcall': (context) => const RollCall(),
        'muspecial': (context) => const MuSpecialCall(),
        'procnode': (context) => const ProcNodeList(),
        'trainbynode': (context) => const TrainEntryListByNodeCode(),
        'packageviewer': (context) => const PackageViewer(),
        'preDispatchWork': (context) => const PreDispatchWork(),
        'getWorkPackage': (context) => const GetWorkPackage(),
        'searchWorkPackage': (context) =>  SearchWorkPackage(),
        'preTrainWork': (context) => const PreTrainWork(),
        'temporaryRepairInfoPage': (context) => const TemporaryRepairInfoPage(),
        'repairProgress': (context) => const RepairProgress(),
        'jt28': (context) => const JtRepairPage(), 
        'jt28Show':(context) => const JtShow(),
        'trainRepairInfo':(context) => const TrainRepairPage(),
        'jt28submitManage':(context) => const Vehicle28FormManage(),
        'repairTrainManage':(context) => const TrainRepairPageManage(),
        'repairTrainProgress':(context) => const TrainRepairProgressPage(),
        'trainShuntingPackage':(context) => const TrainShuntingPackagePage(),
        'workProgress':(context) => const WorkProgressPage(),
        'repairTrainTempManage':(context) => const TrainRepairTempManage(),
        'enterDetailRecord': (context) => const SecEnterModifyNew(),
        'afterSaleTempRepairRegister': (context) =>
            const AfterSaleTempRepairRegisterPage(),
        'trainDepartureConfirm': (context) => const TrainDepartureConfirmPage(),
      },
      builder: FlutterSmartDialog.init(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: PageView(
            physics: const PageScrollPhysics(),
            controller: pageController,
            onPageChanged: onPageChanged,
            children: <Widget>[
              MessageCenterPage(
                onMessageCountChanged: (count) {
                  if (_isPageSwiping) {
                    _pendingMessageCount = count;
                    return;
                  }
                  if (mounted) setState(() => _messageCount = count);
                  _updateAppBadge(count);
                },
              ),
              const NormalMainPage(),
              const PersonPage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (_messageCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _messageCount > 99
                                ? '99+'
                                : '$_messageCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: '消息',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.work), label: '工作'),
              BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.person),
                      if (_hasUpdate)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: '我的'),
            ],
            onTap: onTap,
            currentIndex: page,
            type: BottomNavigationBarType.fixed,
            fixedColor: Colors.lightBlue[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            backgroundColor: Colors.white,
          ),
        ),

      ],
    );
  }

  onPageChanged(int page) {
    setState(() {
      this.page = page;
    });
    if (page == 0) _loadMessageCount();
  }

  //修改bottomNavigationBar的点击事件,可以在此处更换被选中表现形式s
  void onTap(int index) {
    // if (index != 1) {
    //   setState(() {
    //     this.bigImg = 'images/home_green.png';
    //   });
    // }
    // jumpToPage无动画跳转
    pageController?.jumpToPage(index);
    // 动画效果持续时间&曲线
    // pageController?.animateToPage(index,
    //     duration: const Duration(milliseconds: 300), curve: Curves.easeInOutExpo);
  }

//添加图片的点击事件（跳转到「我的」页）
  void onBigImgTap() {
    setState(() {
      page = 2;
      onTap(2);
    });
  }
}
