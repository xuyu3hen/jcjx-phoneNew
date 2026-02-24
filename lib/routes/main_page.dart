
import 'package:jcjx_phone/routes/production/jt_repair.dart';
import 'package:jcjx_phone/routes/production/repair_train.dart';

import 'package:jcjx_phone/routes/production/sec_enter_modify.dart';
import 'package:jcjx_phone/routes/production/repair_train_manage.dart';
import 'package:jcjx_phone/routes/vehicle28/taskpackage/proc_node_list.dart';

import '../index.dart';
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

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: page);
    _loadMessageCount();
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
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: '我的'),
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
