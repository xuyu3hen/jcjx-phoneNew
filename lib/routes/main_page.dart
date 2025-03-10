import 'package:jcjx_phone/routes/production/get_workPackage.dart';

import 'package:jcjx_phone/routes/production/search_work_package.dart';
import 'package:jcjx_phone/routes/production/secEnterModify.dart';
import 'package:jcjx_phone/routes/vehicle28/taskpackage/proc_node_list.dart';

import '../index.dart';

class MainPage extends StatefulWidget {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> with SingleTickerProviderStateMixin {
  PageController? pageController;
  int page = 0;
  // int page = 1;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: page);
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
        "login": (context) => LoginRoute(),
        // 入段车辆查看
        "enter_list": (context) => const EnterList(),
        // 新增入段
        "sec_enter": (context) => const SecEnter(),
        // 新增入段修改
        "sec_enter_modify": (context) => const SecEnterModify(),
        // 机统28
        "submit28": (context) => Vehicle28Form(),
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
        //预派工模块界面
        "preDispatchWork": (context) => const PreDispatchWork(),
        //获取个人作业包模块界面
        "getWorkPackage": (context) => const GetWorkPackage(),
        //查看个人作业包模块界面
        "searchWorkPackage": (context) => const SearchWorkPackage(),
        'preTrainWork': (context) => const PreTrainWork(),
        'temporaryRepairInfoPage': (context) => const TemporaryRepairInfoPage(),
        'repairProgress': (context) => const RepairProgress(),
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
            children: <Widget>[
              NormalMainPage(),
              MainScanner(),
              PersonPage(),
            ],
            controller: pageController,
            onPageChanged: onPageChanged,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '主菜单'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_2_sharp), label: '扫码'),
              BottomNavigationBarItem(
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
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: FloatingActionButton(
                onPressed: onBigImgTap,
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                )),
          ),
        ),
      ],
    );
  }

  onPageChanged(int page) {
    setState(() {
      this.page = page;
    });
  }

  //修改bottomNavigationBar的点击事件,可以在此处更换被选中表现形式
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

//添加图片的点击事件
  void onBigImgTap() {
    setState(() {
      page = 1;
      // this.bigImg = 'images/icon_home.png';
      onTap(1);
    });
  }
}
