import 'dart:async';
import '../index.dart';

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
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
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
    Permissions p = await LoginApi().getpermissions();
    if (p.code == 200) {
      Global.profile.permissions = p;
    } else {
      showToast("获取用户账号信息失败");
    }
    Map<String, dynamic> queryParameters = {};
    if (Global.profile.permissions?.user.dept?.parentId != null) {
      queryParameters['idList'] =
          Global.profile.permissions?.user.dept?.parentId;
      var r = await ProductApi().getDeptByDeptIdList(queryParameters);
      logger.i(r);
      Global.parentDeptName = r.isNotEmpty ? r[0]['deptName'] : null;
    }
  }

  // 初始化修程信息
  void initRepairProc() async {
    Map<String, dynamic> queryParameters = {'pageNum': 0, 'pageSize': 0};
    var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
    if (r.code == 200) {
      r.rows?.forEach((element) {
        Global.repairProcInfo.add(element.toJson());
      });
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
    return SizedBox(
      width: (MediaQuery.of(context).size.width) / 3,
      height: (MediaQuery.of(context).size.width) / 4,
      child: FeatureContainer(
        icon,
        onTap,
        title,
        width: (MediaQuery.of(context).size.width),
        height: (MediaQuery.of(context).size.height),
        num: num,
      ),
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
                  () => Navigator.pushNamed(context, 'jt28submitManage'),
                  '检修调令',
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
          const Divider(height: 10, indent: 10, endIndent: 10),
        ],
      ),
    );
  }

  Widget _buildSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const ListTile(
            title: Text("机车入段",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.directions_train, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'enter_list'),
                  '入修车辆',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.add, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'sec_enter_modify'),
                  '新增入修',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),
          const ListTile(
            title: Text("预派工",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // SizedBox(
              //   width: (MediaQuery.of(context).size.width) / 3,
              //   height: (MediaQuery.of(context).size.width) / 4,
              //   child: FeatureContainer(
              //     Icon(Icons.post_add, color: Colors.blue[200]),
              //     () => Navigator.pushNamed(context, 'submit28'),
              //     '机统28提报',
              //     width: (MediaQuery.of(context).size.width),
              //     height: (MediaQuery.of(context).size.height),
              //   ),
              // ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.fact_check_outlined, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'preDispatchWork'),
                  '预派工',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.assignment, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'preTrainWork'),
                  '机车预派工',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),
          // 增加间距
          const SizedBox(height: 15),
          const ListTile(
            title: Text("作业包，机统28",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.post_add, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'jt28submitManage'),
                  '机统28提报',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              // SizedBox(
              //   width: (MediaQuery.of(context).size.width) / 3,
              //   height: (MediaQuery.of(context).size.width) / 4,
              //   child: FeatureContainer(
              //     Icon(Icons.build, color: Colors.amber[300]),
              //     () => Navigator.pushNamed(context, 'repairlist'),
              //     '不合格项处置',
              //     width: (MediaQuery.of(context).size.width),
              //     height: (MediaQuery.of(context).size.height),
              //   ),
              // ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.folder, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'getWorkPackage'),
                  '领取作业包',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.build, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'searchWorkPackage'),
                  '查看作业包',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.group_rounded, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'mutuallist'),
                  '互检',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                  num: mutualNum,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.check_circle, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'speciallist'),
                  '专检',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                  num: specialNum,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.assignment, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'jt28'),
                  '机统28施修',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              )
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            SizedBox(
              width: (MediaQuery.of(context).size.width) / 3,
              height: (MediaQuery.of(context).size.width) / 4,
              child: FeatureContainer(
                Icon(Icons.group_rounded, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'jt28Show'),
                '机统28展示',
                width: (MediaQuery.of(context).size.width),
                height: (MediaQuery.of(context).size.height),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
