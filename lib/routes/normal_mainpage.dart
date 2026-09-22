import 'dart:async';
import '../index.dart';
import 'production/train_shunting_package_page.dart';

class NormalMainPage extends StatefulWidget {
  const NormalMainPage({super.key});

  @override
  State createState() => _NormalMainPageState();
}

// 首页功能项的声明：权限标题、显示标题、图标、跳转路由或自定义点击
class _FeatureEntry {
  final String permTitle; // 用于 _canShowByRouterTitle 判断
  final String title; // 图标下方文字
  final Icon icon;
  final String? route; // 命名路由
  final VoidCallback? onTap; // 自定义点击（优先级高于 route）

  const _FeatureEntry({
    required this.permTitle,
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
  });
}

class _NormalMainPageState extends State<NormalMainPage> {
  // String _message = '';
  Timer? _timer;
  // 互检
  int mutualNum = 0;
  // 专检
  int specialNum = 0;

  var logger = AppLogger.logger;

  // 动力类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动力类型信息
  late Map<dynamic, dynamic> dynamicTypeSelected = {};
  // 机型列表
  late List<Map<String, dynamic>> jcTypeList = [];

  @override
  void initState() {
    super.initState();
    initPermissions();
    initRepairProc();
    getDynamicType();
  }

  // 获取动态类型
  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      if (mounted) {
        setState(() {
          dynamicTypeList = r.toMapList();
          dynamicTypeSelected['code'] = r.toMapList()[0]['code'];
          dynamicTypeSelected['name'] = r.toMapList()[0]['name'];
          getJcType();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 获取机型
  void getJcType() async {
    try {
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamicTypeSelected['code'],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getJcType(queryParametrs: queryParameters);
      logger.i(r.toJson());
      if (mounted) {
        setState(() {
          Global.typeInfo = r.toMapList();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getJcType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  void dispose() {
    // 销毁定时器
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    super.dispose();
  }

  void initPermissions() async {
    try {
      Permissions p = await LoginApi().getpermissions();
      if (p.code == 200) {
        Global.profile.permissions = p;

        final deptParentName =
            (p.user.dept?.parentName ?? '').toString().trim();
        if (deptParentName.isNotEmpty && deptParentName != 'null') {
          Global.parentDeptName = deptParentName;
        }

        try {
          await LoginApi().getRouters();
        } catch (e) {
          logger.e(e);
        }

        if (mounted) {
          setState(() {});
        }

        if (!Global.isUserRepairTrainDataLoaded) {
          Global.preloadUserRepairTrainData().catchError((e) {
            logger.e('预加载用户个人机车作业数据失败: $e');
          });
        }
      } else {
        showToast('获取用户账号信息失败');
      }
      Map<String, dynamic> queryParameters = {};
      if ((Global.parentDeptName == null || Global.parentDeptName!.isEmpty) &&
          Global.profile.permissions?.user.dept?.parentId != null) {
        queryParameters['idList'] =
            Global.profile.permissions?.user.dept?.parentId;
        var r = await ProductApi().getDeptByDeptIdList(queryParameters);
        logger.i(r);
        Global.parentDeptName = r.isNotEmpty ? r[0]['deptName'] : null;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('initPermissions 方法中发生异常: $e\n堆栈信息: $stackTrace');
      if (mounted) {
        setState(() {});
      }
    }
  }

  // 初始化修程信息
  void initRepairProc() async {
    try {
      Map<String, dynamic> queryParameters = {'pageNum': 0, 'pageSize': 0};
      var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
      if (r.code == 200) {
        r.rows?.forEach((element) {
          Global.repairProcInfo.add(element.toJson());
        });
      }
    } catch (e, stackTrace) {
      logger.e('initRepairProc 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
    );
  }

  // 构建页面主体内容的方法
  Widget _buildBody() {
    return ListView(
      children: <Widget>[
        _buildSectionNew(),
      ],
    );
  }

  Widget _buildFeatureItem(Icon icon, VoidCallback onTap, String title,
      {int? num}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: SizedBox(
        height: screenWidth / 4,
        child: FeatureContainer(
          icon,
          onTap,
          title,
          width: screenWidth,
          height: MediaQuery.of(context).size.height,
          num: num,
        ),
      ),
    );
  }

  Widget _buildFeaturePlaceholder() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: SizedBox(height: screenWidth / 4),
    );
  }

  Widget _buildFeatureRows(List<Widget> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final rowChildren = items.skip(i).take(3).toList();
      while (rowChildren.length < 3) {
        rowChildren.add(_buildFeaturePlaceholder());
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: rowChildren,
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 15),
          rows[i],
        ],
      ],
    );
  }

  String _normalizeRouterTitle(String title) {
    return title
        .trim()
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll(' ', '');
  }

  bool _canShowByRouterTitle(String title) {
    final routerTitles = Global.phoneChildrenMetaTitles;
    if (routerTitles.isEmpty) {
      return false;
    }
    if (routerTitles.contains(title)) {
      return true;
    }
    final normalizedTitle = _normalizeRouterTitle(title);
    final normalizedRouterTitles =
        routerTitles.map(_normalizeRouterTitle).toSet();
    if (normalizedRouterTitles.contains(normalizedTitle)) {
      return true;
    }
    final aliases = <String, List<String>>{
      '报机统28（管理）': ['报机统28(管理)', '机统28-提报（管理）', '机统28-提报(管理)'],
    };
    final aliasTitles = aliases[title] ?? const <String>[];
    for (final alias in aliasTitles) {
      if (routerTitles.contains(alias) ||
          normalizedRouterTitles.contains(_normalizeRouterTitle(alias))) {
        return true;
      }
    }
    return false;
  }

  Widget _buildSectionNew() {
    // 所有功能项统一声明，顺序即展示顺序
    final allFeatures = <_FeatureEntry>[
      _FeatureEntry(
        permTitle: '开工点名',
        title: '开工点名',
        icon: Icon(Icons.people, color: Colors.blue[200]),
        route: 'repairTrainManage',
      ),
      _FeatureEntry(
        permTitle: '机车入段',
        title: '机车入段',
        icon: Icon(Icons.train, color: Colors.blue[200]),
        route: 'sec_enter_modify',
      ),
      _FeatureEntry(
        permTitle: '检修作业',
        title: '检修作业',
        icon: Icon(Icons.build, color: Colors.blue[200]),
        route: 'trainRepairInfo',
      ),
      _FeatureEntry(
        permTitle: '报机统28（管理）',
        title: '报机统28（管理）',
        icon: Icon(Icons.post_add, color: Colors.blue[200]),
        route: 'jt28submitManage',
      ),
      _FeatureEntry(
        permTitle: '检修调令',
        title: '检修调令',
        icon: Icon(Icons.next_plan, color: Colors.blue[200]),
        route: 'repairTrainProgress',
      ),
      _FeatureEntry(
        permTitle: '检修进度',
        title: '检修进度',
        icon: Icon(Icons.manage_search, color: Colors.blue[200]),
        route: 'repairTrainTempManage',
      ),
      _FeatureEntry(
        permTitle: '调车',
        title: '调车',
        icon: Icon(Icons.assignment, color: Colors.blue[200]),
        route: 'trainShuntingPackage',
      ),
      _FeatureEntry(
        permTitle: '调车计划查询',
        title: '调车计划查询',
        icon: Icon(Icons.search, color: Colors.blue[200]),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const TrainShuntingPackagePage(readOnly: true),
            ),
          );
        },
      ),
      _FeatureEntry(
        permTitle: '离段确认',
        title: '离段确认',
        icon: Icon(Icons.photo_camera_back, color: Colors.blue[200]),
        route: 'trainDepartureConfirm',
      ),
      _FeatureEntry(
        permTitle: '售后登记',
        title: '售后登记',
        icon: Icon(Icons.assignment_outlined, color: Colors.blue[200]),
        route: 'afterSaleTempRepairRegister',
      ),
    ];

    // 先按权限过滤掉无权限项，剩下的是连续的；
    // 再统一每 3 个一行布局，后面的自动向前补齐，中间不会留空位
    final visibleWidgets = allFeatures
        .where((f) => _canShowByRouterTitle(f.permTitle))
        .map((f) => _buildFeatureItem(
              f.icon,
              f.onTap ??
                  () => Navigator.pushNamed(context, f.route!),
              f.title,
            ))
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          const ListTile(
            title: Text('检修进度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildFeatureRows(visibleWidgets),
          const Divider(height: 10, indent: 10, endIndent: 10),
        ],
      ),
    );
  }
}
