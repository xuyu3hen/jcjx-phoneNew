import 'package:flutter_xupdate/flutter_xupdate.dart';
import '../index.dart';

class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});

  @override
  State createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  var logger = AppLogger.logger;

  final TextEditingController _unameController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final bool _nameAutoFouce = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool pwdShow = false;

  @override
  void initState() {
    super.initState();
    initXUpdate();
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
        updateMessage('初始化成功: $value');
      }).catchError((error) {
        logger.e(error);
      });
    } else {
      updateMessage('ios暂不支持XUpdate更新');
    }
  }

  void updateMessage(String message) {
    setState(() {
    });
    // showToast(_message);
  }

  @override
  Widget build(BuildContext context) {
    // UserModel usermodel = Provider.of<UserModel>(context, listen: false);
    if (F.id != 'com.jcjx_phone_dev') {
      getLastUpdate();
    }
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              'assets/login1.png',
              fit: BoxFit.cover,
            ),
          ),
          // 登录表单
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    autofocus: _nameAutoFouce,
                    controller: _unameController,
                    decoration: InputDecoration(
                      labelText: "用户名",
                      hintText: "用户名",
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    // 校验用户名
                    validator: (v) {
                      return v == null || v.trim().isNotEmpty
                          ? null
                          : "用户名不能为空";
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwdController,
                    autofocus: !_nameAutoFouce,
                    decoration: InputDecoration(
                      labelText: "密码",
                      hintText: "密码",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                            pwdShow ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            pwdShow = !pwdShow;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    // 密文密码显示
                    obscureText: !pwdShow,
                    // 校验空值
                    validator: (v) {
                      return v == null || v.trim().isNotEmpty
                          ? null
                          : "密码不能为空！";
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.expand(height: 55.0),
                      child: ElevatedButton(
                        onPressed: _loginIn,
                        child: const Text("登录"),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loginIn() async {
    // 便于测试本地一键登录
    Profile? profile;
    // if(F.id == "com.jcjx_phone_dev"){
    if (true) {
      try {
        // 调用api接口函数
        var r = await LoginApi().getProfile(
          // queryParametrs: {
          //   'password':'Jcjx@6217.',
          //   'username':'admin',
          // }
          // 工长刘扬
          // queryParametrs: {
          //   'username': '60599',
          //   'password': 'Jxd#6453',
          // }
          // 账号密码
          queryParametrs: {
            'password': _pwdController.text,
            'username': _unameController.text,
          },
          // 邹晗
          // queryParametrs: {
          //   'password':'Jxd#6453',
          //   'username':'60467',
          // }
        );
        if (mounted) {
          if (r.code == 200) {
            // print("显示token:${r.data?.access_token}");
            profile = r;
            Global.profile = profile;
            Provider.of<UserModel>(context, listen: false).accessToken =
                profile.data;

            // Permissions p = await LoginApi().getpermissions();
            // if(p.code == 200){
            //   Global.profile.permissions = p;
            // }else{
            //   showToast("获取用户账号信息失败");
            // }
            AppApi.init();
          }
        }
      } on DioException catch (e) {
        showToast(e.toString());
      } finally {
        SmartDialog.dismiss();
      }
      // if(profile != null){
      //   Navigator.of(context).pop();
      //   Navigator.of(context).pushNamed('main_page');
      // }
    }

    // 验证表单字符是否合法
  
  }

  void getLastUpdate() async {
    logger.i("id${F.id}");
    var r = await UpdateApi().checkUpdate(queryParametrs: {
      'id': F.id,
    });
    if (F.version != r.version) {
      checkUpdateByUpdateEntity(r);
    } else {
      // showToast("已是最新版本");
    }
  }

  // 转义成UpdateEntity
  UpdateEntity customJsonParse(myapk) {
    return UpdateEntity(
      isForce: true,
      hasUpdate: true,
      isIgnorable: false,
      versionCode: 1,
      versionName: myapk.version,
      updateContent: myapk.dec,
      downloadUrl: myapk.url,
    );
  }

  ///传入UpdateEntity进行更新提示
  void checkUpdateByUpdateEntity(myapk) {
    FlutterXUpdate.updateByInfo(updateEntity: customJsonParse(myapk));
  }
}
