import 'dart:async';
import '../index.dart';
import 'production/train_shunting_package_page.dart';

class NormalMainPage extends StatefulWidget {
  const NormalMainPage({super.key});

  @override
  State createState() => _NormalMainPageState();
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
          dynamicTypeSelected["code"] = r.toMapList()[0]["code"];
          dynamicTypeSelected["name"] = r.toMapList()[0]["name"];
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
        'dynamicCode': dynamicTypeSelected["code"],
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

        final deptParentName = (p.user.dept?.parentName ?? '').toString().trim();
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
        showToast("获取用户账号信息失败");
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          const ListTile(
            title: Text("检修进度",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (_canShowByRouterTitle('开工点名'))
                _buildFeatureItem(
                  Icon(Icons.people, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'repairTrainManage'),
                  '开工点名',
                )
              else
                _buildFeaturePlaceholder(),
              if (_canShowByRouterTitle('机车入段'))
                _buildFeatureItem(
                  Icon(Icons.train, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'sec_enter_modify'),
                  '机车入段',
                )
              else
                _buildFeaturePlaceholder(),
              if (_canShowByRouterTitle('检修作业'))
                _buildFeatureItem(
                  Icon(Icons.build, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'trainRepairInfo'),
                  '检修作业',
                )
              else
                _buildFeaturePlaceholder(),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (_canShowByRouterTitle('报机统28（管理）'))
                _buildFeatureItem(
                  Icon(Icons.post_add, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'jt28submitManage'),
                  '报机统28（管理）',
                )
              else
                _buildFeaturePlaceholder(),
              if (_canShowByRouterTitle('检修调令'))
                _buildFeatureItem(
                  Icon(Icons.next_plan, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'repairTrainProgress'),
                  '检修调令',
                )
              else
                _buildFeaturePlaceholder(),
              if (_canShowByRouterTitle('检修进度'))
                _buildFeatureItem(
                  Icon(Icons.manage_search, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'repairTrainTempManage'),
                  '检修进度',
                )
              else
                _buildFeaturePlaceholder(),
              // Expanded(
              //   child: ElevatedButton(
              //     onPressed: () {
              //       // 跳转到ApplyList页面
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => ApplyList(
              //             trainNum: widget.locoInfo?['trainNum'] ?? '',
              //             trainNumCode: widget.locoInfo?['trainNumCode'] ?? '',
              //             typeName: widget.locoInfo?['typeName'] ?? '',
              //             typeCode: widget.locoInfo?['typeCode'] ?? '',
              //             trainEntryCode: widget.locoInfo?['code'] ?? '',
              //           ),
              //         ),
              //       );
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.blue,
              //       foregroundColor: Colors.white,
              //     ),
              //     child: const Text('检修调度命令'),
              //   ),
              // ),
              // _buildFeatureItem(
              //   Icon(Icons.assignment, color: Colors.blue[200]),
              //   () => Navigator.pushNamed(context, 'jt28'),
              //   '处理机统28',
              // ),
              // _buildFeatureItem(
              //   Icon(Icons.search, color: Colors.blue[200]),
              //   () => Navigator.pushNamed(context, 'speciallist'),
              //   '机统28查询',
              //   num: specialNum,
              // ),
            ],
          ),
          // const SizedBox(height: 15),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: <Widget>[
          //     _buildFeatureItem(
          //       Icon(Icons.alarm, color: Colors.blue[200]),
          //       () => Navigator.pushNamed(context, 'repairProgress'),
          //       '检修进度',
          //     ),
          //     _buildFeatureItem(
          //       Icon(Icons.edit_document, color: Colors.blue[200]),
          //       () => Navigator.pushNamed(context, 'repairProgress'),
          //       '检修调令',
          //     ),
          //   ],
          // ),
          
          const SizedBox(height: 15),
          // if (_canSeeShunting)
            Builder(
              builder: (_) {
                final children = <Widget>[
                  if (_canShowByRouterTitle('调车'))
                    _buildFeatureItem(
                      Icon(Icons.assignment, color: Colors.blue[200]),
                      () => Navigator.pushNamed(context, 'trainShuntingPackage'),
                      '调车',
                    ),
                  if (_canShowByRouterTitle('调车计划查询'))
                    _buildFeatureItem(
                      Icon(Icons.search, color: Colors.blue[200]),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const TrainShuntingPackagePage(readOnly: true),
                          ),
                        );
                      },
                      '调车计划查询',
                    ),
                  if (_canShowByRouterTitle('离段确认'))
                    _buildFeatureItem(
                      Icon(Icons.photo_camera_back, color: Colors.blue[200]),
                      () =>
                          Navigator.pushNamed(context, 'trainDepartureConfirm'),
                      '离段确认',
                    ),
                ];
                while (children.length < 3) {
                  children.add(_buildFeaturePlaceholder());
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: children,
                );
              },
            ),
          if (_canShowByRouterTitle('售后登记'))
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildFeatureItem(
                  Icon(Icons.assignment_outlined, color: Colors.blue[200]),
                  () => Navigator.pushNamed(
                    context,
                    'afterSaleTempRepairRegister',
                  ),
                  '售后登记',
                ),
                _buildFeaturePlaceholder(),
                _buildFeaturePlaceholder(),
              ],
            ),
          const Divider(height: 10, indent: 10, endIndent: 10),
          
        ],
      ),
    );
  }


}
