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
              _buildFeatureItem(
                Icon(Icons.people, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'repairTrainManage'),
                '开工点名',
              ),
              _buildFeatureItem(
                Icon(Icons.train, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'sec_enter_modify'),
                '机车入段',
              ),
              _buildFeatureItem(
                Icon(Icons.build, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'trainRepairInfo'),
                '检修作业',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildFeatureItem(
                Icon(Icons.post_add, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'jt28submitManage'),
                '报机统28（管理）',
              ),
              _buildFeatureItem(
                Icon(Icons.next_plan, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'repairTrainProgress'),
                '检修调令',
              ),
              _buildFeatureItem(
                Icon(Icons.manage_search, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'repairTrainTempManage'),
                '检修进度',
              ),
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
                  _buildFeatureItem(
                    Icon(Icons.assignment, color: Colors.blue[200]),
                    () => Navigator.pushNamed(context, 'trainShuntingPackage'),
                    '调车',
                  ),
                  if (_canSeeShuntingQuery)
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
                  if (_canSeeTrainDepartureConfirm)
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
          if (_canSeeAfterSaleRegister)
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


  bool get _canSeeShuntingQuery {
    final user = Global.profile.permissions?.user;
    final name = (user?.nickName ?? user?.userName ?? '').toString();
    if (name == '朱汉' || name == '封方方') {
      return true;
    }

    final deptName = (user?.dept?.deptName ?? '').toString();
    final parentDeptName = (Global.parentDeptName ?? '').toString();
    final combinedDept = '$deptName $parentDeptName';
    if (combinedDept.contains('调度室') ||
        combinedDept.contains('生产调度') ||
        (combinedDept.contains('生产') && combinedDept.contains('调度'))) {
      return true;
    }

    final roleKeys =
        (Global.profile.permissions?.roles ?? const <String>[])
            .map((e) => e.toString())
            .toList();
    if (roleKeys.any((r) => r.contains('diaodu') || r.contains('调度'))) {
      return true;
    }

    final roleObjs =
        (Global.profile.permissions?.user.roles ?? const <dynamic>[])
            .map((e) => e)
            .toList();
    if (roleObjs.any((r) {
      final rn = (r?.roleName ?? r?['roleName'] ?? '').toString();
      final rk = (r?.roleKey ?? r?['roleKey'] ?? '').toString();
      return rn.contains('调度') || rk.contains('diaodu') || rk.contains('调度');
    })) {
      return true;
    }
    return false;
  }

  bool get _canSeeAfterSaleRegister {
    final user = Global.profile.permissions?.user;
    final name = (user?.nickName ?? user?.userName ?? '').toString();
    if (name == '田凯') {
      return true;
    }
    final deptName = (user?.dept?.deptName ?? '').toString();
    final parentDeptName = (Global.parentDeptName ?? '').toString();
    final combinedDept = '$deptName $parentDeptName';
    if (combinedDept.contains('安全生产指挥中心')) {
      return true;
    }
    if (!combinedDept.contains('技术科')) {
      return false;
    }
    return combinedDept.contains('江岸机务段') ||
        combinedDept.contains('襄阳机务段') ||
        combinedDept.contains('武昌南机务段');
  }

  bool get _canSeeTrainDepartureConfirm {
    final user = Global.profile.permissions?.user;
    final deptName = (user?.dept?.deptName ?? '').toString();
    final parentDeptName = (Global.parentDeptName ?? '').toString();
    final combinedDept = '$deptName $parentDeptName';
    if (combinedDept.contains('总成车间') && combinedDept.contains('接车')) {
      return true;
    }

    final roleKeys =
        (Global.profile.permissions?.roles ?? const <String>[])
            .map((e) => e.toString())
            .toList();
    if (roleKeys.any((r) => r.contains('总成') && r.contains('接车'))) {
      return true;
    }

    final roleObjs =
        (Global.profile.permissions?.user.roles ?? const <dynamic>[])
            .map((e) => e)
            .toList();
    if (roleObjs.any((r) {
      final rn = (r?.roleName ?? r?['roleName'] ?? '').toString();
      final rk = (r?.roleKey ?? r?['roleKey'] ?? '').toString();
      final s = '$rn $rk';
      return s.contains('总成') && s.contains('接车');
    })) {
      return true;
    }

    return false;
  }

}
