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

  // 获取代办信息
  void getMessageInfo() async {
    try {
      var r = await LoginApi().getMessageInfo(queryParameters: {
        "auditDTO": {},
        "type": [4, 5]
      });
      if (r.sysMessageVO != []) {
        // log('${r.sysMessageVO}');
        r.sysMessageVO?.forEach((element) {
          if (element.model == "互检") {
            if (mounted) {
              setState(() {
                mutualNum = element.number2!;
              });
            }
          }
          if (element.model == "专检") {
            if (mounted) {
              setState(() {
                specialNum = element.number2!;
              });
            }
          }
        });
      } else {
        showToast("获取零部件表失败,请检查网络");
      }
    } catch (e, stackTrace) {
      //显示异常以及异常所在 行 异常内容
      logger.e("getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  void getpermisson() async {
    Permissions p = await LoginApi().getpermissions();
    if (p.code == 200) {
      if (mounted) {
        setState(() {
          Global.profile.permissions = p;
        });
      }
    } else {
      showToast("获取用户账号信息失败");
    }
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    getpermisson();
    getMessageInfo();
    int count = 0;
    // 五分钟查询一次
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      count++;
      logger.i("循环次数$count");
      getMessageInfo();
    });
  }

  @override
  void dispose() {
    // 销毁定时器
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Global.profile.permissions == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/mainPage.png'), // 替换为你的背景图路径
                    fit: BoxFit.cover, // 调整图片适应方式
                    alignment: Alignment(0, -0.9), // 使用默认的居中对齐
                  ),
                ),
              ),
            ),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/mainPage.png'), // 替换为你的背景图路径
                    fit: BoxFit.cover, // 调整图片适应方式
                    alignment: Alignment(0, -0.9)),
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight + 40, // 确保图片在 AppBar 之下
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBody(),
          ),
        ],
      ),
      // drawer: const SideDrawer(),
    );
  }

  // 构建页面主体内容的方法
  Widget _buildBody() {
    return ListView(
      children: <Widget>[
        // if (Global.profile.permissions != null &&
        //     Global.profile.permissions!.roles.contains("gongzhang"))
        _buildGongzhangSection(),
        // if (Global.profile.permissions != null &&
        //     (Global.profile.permissions!.roles.contains("builder") ||
        //         Global.profile.permissions!.roles.contains("chejianjishuyuan") ||
        //         Global.profile.permissions!.roles.contains("jicheyanshouyuan")))
        //   _buildBuilderSection(),
        // if (Global.profile.permissions != null &&
        //     Global.profile.permissions!.roles.contains("zhurenyanshoushi"))
        //   _buildZhurenyanjiuyuanSection(),
      ],
    );
  }

  Widget _buildZhurenyanjiuyuanSection() {
    return Column(
      children: [
        const ListTile(
          title: Text("主任验收",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const Divider(height: .0, thickness: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: (MediaQuery.of(context).size.width) / 3,
              height: (MediaQuery.of(context).size.width) / 4,
              child: FeatureContainer(
                Icon(Icons.format_list_bulleted_add,
                    color: Colors.deepPurple[300]),
                () => Navigator.pushNamed(context, 'preDispatchWork'),
                '预派工',
                width: (MediaQuery.of(context).size.width),
                height: (MediaQuery.of(context).size.height),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildGongzhangSection() {
    //让界面能够不溢出 能上下滑动

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
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.alarm, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'repairProgress'),
                  '检修进度',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),
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
                  () => Navigator.pushNamed(context, 'submit28'),
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
                  num: specialNum,
                ),
              )
            ],
          ),
          Row(
             mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.group_rounded, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'jt28Show'),
                  '机统28展示',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                  num: mutualNum,
                ),
              ),
              ] 
          )
          // Row(
          //   //临修机车导入标识
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: <Widget>[
          //     SizedBox(
          //       width: (MediaQuery.of(context).size.width) / 3,
          //       height: (MediaQuery.of(context).size.width) / 4,
          //       child: FeatureContainer(
          //         Icon(Icons.format_list_bulleted_add, color: Colors.blue[200]),
          //         () => Navigator.pushNamed(context, 'temporaryRepairInfoPage'),
          //         '临修机车导入',
          //         width: (MediaQuery.of(context).size.width),
          //         height: (MediaQuery.of(context).size.height),
          //       ),
          //     )
          //   ],
          // ),
        ],
      ),
    );
  }

  // 构建操作者相关的操的界面
  Widget _buildBuilderSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const ListTile(
          title: Text("检修进度",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: (MediaQuery.of(context).size.width) / 3,
              height: (MediaQuery.of(context).size.width) / 4,
              child: FeatureContainer(
                Icon(Icons.alarm, color: Colors.blue[200]),
                () => Navigator.pushNamed(context, 'repairProgress'),
                '检修进度',
                width: (MediaQuery.of(context).size.width),
                height: (MediaQuery.of(context).size.height),
              ),
            ),
          ],
        ),
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
                Icon(Icons.train, color: Colors.blue[200]),
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
                () => Navigator.pushNamed(context, 'submit28'),
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
                '互检1',
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
              // 机统28展示
            ),
            // SizedBox(
            //   width: (MediaQuery.of(context).size.width) / 3,
            //   height: (MediaQuery.of(context).size.width) / 4,
            //   child: FeatureContainer(
            //     Icon(Icons.check_circle, color: Colors.blue[200]),
            //     () => Navigator.pushNamed(context, 'jt28'),
            //     '机统28',
            //     width: (MediaQuery.of(context).size.width),
            //     height: (MediaQuery.of(context).size.height),
            //     num: specialNum,
            //   ),
            // )
          ],
        ),
      ],
    );
  }
}
