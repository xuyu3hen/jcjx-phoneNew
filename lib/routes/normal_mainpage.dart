import 'dart:async';
import 'dart:developer';
import '../index.dart';

class NormalMainPage extends StatefulWidget {
  @override
  _NormalMainPageState createState() => _NormalMainPageState();
}

class _NormalMainPageState extends State<NormalMainPage> {
  // String _message = '';
  Timer? _timer;
  // 互检
  int mutualNum = 0;
  // 专检
  int specialNum = 0;

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
            setState(() {
              mutualNum = element.number2!;
            });
          }
          if (element.model == "专检") {
            setState(() {
              specialNum = element.number2!;
            });
          }
        });
      } else {
        showToast("获取零部件表失败,请检查网络");
      }
    } catch (e) {
      log("$e");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  @override
  void initState() {
    getMessageInfo();
    int _count = 0;
    // 五分钟查询一次
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _count++;
      print("循环次数$_count");
      getMessageInfo();
    });
    super.initState();
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
    return Scaffold(
      // key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          '主页',
          style: TextStyle(
              color: Color.fromARGB(169, 0, 0, 0), fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
      // drawer: const SideDrawer(),
    );
  }

  // 构建页面主体内容的方法
  Widget _buildBody() {
    // 功能选
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 机车入修功能区域
          const ListTile(
            title: Text("机车入修",
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
                  Icon(Icons.library_books_outlined, color: Colors.blue[200]),
                  () => Navigator.pushNamed(context, 'enter_list'),
                  '入修车辆',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              // SizedBox(
              //   width: (MediaQuery.of(context).size.width) / 3,
              //   height: (MediaQuery.of(context).size.width) / 4,
              //   child: FeatureContainer(
              //     Icon(Icons.format_list_bulleted_add, color: Colors.deepPurple[300]),
              //     () => Navigator.pushNamed(context, 'sec_enter'),
              //     '新增入修',
              //     width: (MediaQuery.of(context).size.width),
              //     height: (MediaQuery.of(context).size.height),
              //   ),
              // ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.format_list_bulleted_add,
                      color: Colors.deepPurple[300]),
                  () => Navigator.pushNamed(context, 'sec_enter_modify'),
                  '新增入修',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),

          // 预派工，作业包，机统28功能区域
          const ListTile(
            title: Text("预派工，作业包，机统28",
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
                  Icon(Icons.build, color: Colors.amber[300]),
                  () => Navigator.pushNamed(context, 'procnode'),
                  '检修作业',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              // 以下部分被注释掉，可能是个人作业包相关，如有需要可恢复
              // SizedBox(
              //   width: (MediaQuery.of(context).size.width) / 3,
              //   height: (MediaQuery.of(context).size.width) / 4,
              //   child: FeatureContainer(
              //     Icon(Icons.fact_check_outlined, color: Colors.amber[300]),
              //     () => Navigator.pushNamed(context, 'taskpackage'),
              //     '个人作业包',
              //     width: (MediaQuery.of(context).size.width),
              //     height: (MediaQuery.of(context).size.height),
              //   ),
              // ),
              // SizedBox(
              //   width: (MediaQuery.of(context).size.width) / 3,
              //   height: (MediaQuery.of(context).size.width) / 4,
              //   child: FeatureContainer(
              //     Icon(Icons.fact_check_outlined, color: Colors.amber[300]),
              //     () => Navigator.pushNamed(context, 'preDispatchWork'),
              //     '预派工单',
              //     width: (MediaQuery.of(context).size.width),
              //     height: (MediaQuery.of(context).size.height),
              //   ),
              // ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.format_list_bulleted_add,
                      color: Colors.deepPurple[300]),
                  () => Navigator.pushNamed(context, 'submit28'),
                  '机统28提报',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.build, color: Colors.amber[300]),
                  () => Navigator.pushNamed(context, 'repairlist'),
                  '不合格项处置',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                ),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            SizedBox(
              width: (MediaQuery.of(context).size.width) / 3,
              height: (MediaQuery.of(context).size.width) / 4,
              child: FeatureContainer(
                Icon(Icons.build, color: Colors.amber[300]),
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
                Icon(Icons.build, color: Colors.amber[300]),
                () => Navigator.pushNamed(context, 'searchWorkPackage'),
                '查看作业包',
                width: (MediaQuery.of(context).size.width),
                height: (MediaQuery.of(context).size.height),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width) / 3,
              height: (MediaQuery.of(context).size.width) / 4,
              child: FeatureContainer(
                Icon(Icons.group_rounded, color: Colors.deepOrange[300]),
                () => Navigator.pushNamed(context, 'mutuallist'),
                '互检',
                width: (MediaQuery.of(context).size.width),
                height: (MediaQuery.of(context).size.height),
                num: mutualNum,
              ),
            ),
          ]),
          // 其他相关操作功能区域
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width) / 3,
                height: (MediaQuery.of(context).size.width) / 4,
                child: FeatureContainer(
                  Icon(Icons.construction_outlined,
                      color: Colors.deepOrange[300]),
                  () => Navigator.pushNamed(context, 'speciallist'),
                  '专检',
                  width: (MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height),
                  num: specialNum,
                ),
              ),
            ],
          ),

          //   // 工班长相关操作功能区域（根据权限显示）
          //   if (Global.profile.permissions!.permissions.contains("system:gongzhang:assign") ||
          //       Global.profile.permissions!.permissions.contains("*:*:*"))
          //  ...[
          //       const ListTile(
          //         title: Text("工班长", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          //       ),
          //       const Divider(height:.0, thickness: 1),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.start,
          //         children: <Widget>[
          //           SizedBox(
          //             width: (MediaQuery.of(context).size.width) / 3,
          //             height: (MediaQuery.of(context).size.width) / 4,
          //              child: FeatureContainer(
          //               Icon(Icons.contact_page_rounded, color: Colors.red[300]),
          //             () => Navigator.pushNamed(context, 'rollcall'),
          //             '开工点名',
          //             width: (MediaQuery.of(context).size.width),
          //             height: (MediaQuery.of(context).size.height),
          //           ),),

          //           SizedBox(
          //             width: (MediaQuery.of(context).size.width) / 3,
          //             height: (MediaQuery.of(context).size.width) / 4,
          //             child: FeatureContainer(
          //               Icon(Icons.contact_page_rounded, color: Colors.red[300]),
          //               () => Navigator.pushNamed(context, 'dispatchlist'),
          //               '不合格项派工',
          //               width: (MediaQuery.of(context).size.width),
          //               height: (MediaQuery.of(context).size.height),
          //           ),
          //           )
          //         ]
          //       )
          //     ]
        ]);
  }
}
