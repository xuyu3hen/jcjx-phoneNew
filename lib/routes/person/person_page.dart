import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../index.dart';
import 'package:logger/logger.dart';

class PersonPage extends StatefulWidget {
  const PersonPage({Key? key}) : super(key: key);

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  void getPermission() async {
    Permissions p = await LoginApi().getpermissions();
    if (p.code == 200) {
      setState(() {
        Global.profile.permissions = p;
      });
    } else {
      showToast("获取用户账号信息失败");
    }
  }

  String? parentDeptName;

  @override
  Widget build(BuildContext context) {
    if (Global.profile.permissions == null) {
      getPermission();
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 40.0,
              height: 40.0,
              child: CircularProgressIndicator(
                strokeWidth: 4.0,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text(
              "正在请求用户数据",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/newBackground.png'), // 替换为你的背景图路径
                    fit: BoxFit.cover, // 调整图片适应方式
                    alignment: Alignment(0, -0.9), // 使用默认的居中对齐
                  ),
                ),
              ),
            ),
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                  statusBarIconBrightness: Brightness.light),
              child: Column(
                children: [
                  Stack(
                    children: <Widget>[
                      Container(
                        height: 180,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 40),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 20,
                        child: FutureBuilder<Widget>(
                          future: _buildByState(context),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text('无数据');
                            } else {
                              return snapshot.data!;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(child: myPageItems()),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAvatarByState(BuildContext context) {
    return SizedBox(
      child: CircleAvatar(
        radius: 15,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage("assets/head.png"),
      ),
      width: 100,
      height: 100,
    );
  }

  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );

  Future<Widget> _buildByState(BuildContext context) async {
    String? parentDeptName = null;
    UserModel usermodel = Provider.of<UserModel>(context);
    Map<String, dynamic> queryParameters = {};
    if (Global.profile.permissions?.user.dept?.parentId != null) {
      queryParameters['idList'] =
          Global.profile.permissions?.user.dept?.parentId;
      var r = await ProductApi().getDeptByDeptIdList(queryParameters);
      logger.i(r);
      parentDeptName = r.isNotEmpty ? r[0]['deptName'] : null;
    }

    // TODO:判断登录情况
    if (usermodel.isLogin) {
      
      return Text(
        "${Global.profile.permissions?.user.nickName}-${Global.profile.permissions?.user.dept?.deptName}-$parentDeptName",
        style: TextStyle(fontSize: 24, color: Colors.black),
      );
    } else {
      return Text(
        "未登录",
        style: TextStyle(fontSize: 24, color: Colors.black),
      );
    }
  }
}