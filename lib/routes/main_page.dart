


import 'package:jcjx_phone/routes/production/jt_repair.dart';
import 'package:jcjx_phone/routes/production/repair_train.dart';

import 'package:jcjx_phone/routes/production/sec_enter_modify.dart';
import 'package:jcjx_phone/routes/production/repair_train_manage.dart';
import 'package:jcjx_phone/routes/vehicle28/taskpackage/proc_node_list.dart';

import '../index.dart';
import 'production/train_shunting_package_page.dart';
import 'message_center_page.dart';
import 'production/repair_train_temp.dart';
import 'vehicle28/submit28_manage.dart';

class MainPage extends StatefulWidget {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  const MainPage({Key? key}) : super(key: key);

  @override
  State createState() => _MainPage();
}

class _MainPage extends State<MainPage> with SingleTickerProviderStateMixin {
  PageController? pageController;
  int page = 0;
  int _messageCount = 0;
  bool _hasUpdate = false; // 新增：是否有更新的标识
  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: this.page);

    // 获取是线上版本还是线下版版本
    // queryParameters = {
    //   'app_id': F.id,
    //   'app_version': await F.getVersion(),
    //   'app_build_number': await F.getBuildNumber(),
    //   'app_flavor': F.appFlavor.toString(),
    // };
    logger.i('当前环境: ${F.appFlavor}');
    // ProductApi().getLatestOne(env: 'release');
    // 初始化更新组件
    initXUpdate();
    
    // 延迟检查更新，确保页面已加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLastUpdate();
    });
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
      logger.i("检查更新，应用ID: ${F.id}");

      // 获取当前应用版本信息
      String currentVersion = await F.getVersion();
      int currentBuildNumber = await F.getBuildNumber();

      logger.i("当前版本: $currentVersion+$currentBuildNumber");

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
      logger.i("服务器返回的版本信息: $r");
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
  int _compareVersion(String version1, String version2) {
    List<int> v1Parts =
        version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts =
        version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 补齐长度
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return -1; // version1 更新
      if (v1Parts[i] < v2Parts[i]) return 1; // version2 更新
    }
    return 0; // 相等
  }

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
    );
  }

  ///传入UpdateEntity进行更新提示
  void checkUpdateByUpdateEntity(myapk) {
    FlutterXUpdate.updateByInfo(updateEntity: customJsonParse(myapk));
  }

  Future<void> _loadMessageCount() async {
    try {
      final res = await ProductApi().getMessageInfo(
        queryParametrs: {
          'type': [8],
          'auditDTO': {},
        },
      );
      final data = res is Map ? res : <String, dynamic>{};
      final count = (data['count'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() => _messageCount = count);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
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
        "main": (context) => const MainPage(),

        // 登录
        "login": (context) => const LoginRoute(),
        // 入段车辆查看
        "enter_list": (context) => const EnterList(),
        // 新增入段修改
        // "sec_enter_modify": (context) => const SecEnterModify(),
        "sec_enter_modify": (context) => const SecEnterModifyNew(),
        // 机统28
        "submit28": (context) => const Vehicle28Form(),
        "dispatchlist": (context) => const DispatchList(),
        "repairlist": (context) => const RepairList(),
        "repair": (context) => const Repair(),
        "mutuallist": (context) => const MutualList(),
        "mutual": (context) => const Mutual(),
        "speciallist": (context) => const SpecialList(),
        "special": (context) => const Special(),
        "vehimageviewer": (context) => const VehImageViewer(),
        "certainPackage": (context) => const CertainPackage(),
        "rollcall": (context) => const RollCall(),
        "muspecial": (context) => const MuSpecialCall(),
        "procnode": (context) => const ProcNodeList(),
        "trainbynode": (context) => const TrainEntryListByNodeCode(),
        "packageviewer": (context) => const PackageViewer(),
        "preDispatchWork": (context) => const PreDispatchWork(),
        "getWorkPackage": (context) => const GetWorkPackage(),
        "searchWorkPackage": (context) =>  SearchWorkPackage(),
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
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            onPageChanged: onPageChanged,
            children: <Widget>[
              MessageCenterPage(
                onMessageCountChanged: (count) {
                  if (mounted) setState(() => _messageCount = count);
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
