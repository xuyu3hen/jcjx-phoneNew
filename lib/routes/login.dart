import 'package:dart_sm/dart_sm.dart';

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
  bool rememberPassword = false; // 记住密码选项
  final String _credentialsKey = 'credentials';
  bool _isManualInput = false;
  String publicKey = '049d14df9951e1d14dd0e411419f111cb6f42da259ab9af5beea52276ed651e74c70eabe623f56e7f2716c3211e5bae9ec041dcda194840bca87290593e0b06640';
  @override
  void initState() {
    super.initState();
    initXUpdate();
    _loadSavedCredentials(); // 加载保存的凭据
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
    setState(() {});
    // showToast(_message);
  }

  // 加载保存的凭据
  void _loadSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCredentials = prefs.getString(_credentialsKey);

    if (savedCredentials != null) {
      List<Map<String, dynamic>> credentialsList =
          List<Map<String, dynamic>>.from(json.decode(savedCredentials));
      if (credentialsList.isNotEmpty) {
        setState(() {
          _unameController.text = credentialsList.first['username'];
          _pwdController.text = credentialsList.first['password'];
          rememberPassword = credentialsList.first['rememberPassword'];
        });
      }
    }
  }

  // 保存凭据
  void _saveCredentials(String username, String password, bool remember) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCredentials = prefs.getString(_credentialsKey);

    List<Map<String, dynamic>> credentialsList = [];
    if (savedCredentials != null) {
      credentialsList =
          List<Map<String, dynamic>>.from(json.decode(savedCredentials));
    }

    // 检查是否已存在相同的用户名
    bool exists = false;
    for (var i = 0; i < credentialsList.length; i++) {
      if (credentialsList[i]['username'] == username) {
        exists = true;
        credentialsList[i]['password'] = password;
        credentialsList[i]['rememberPassword'] = remember;
        break;
      }
    }

    if (!exists) {
      credentialsList.add({
        'username': username,
        'password': password,
        'rememberPassword': remember,
      });
    }

    await prefs.setString(_credentialsKey, json.encode(credentialsList));
  }

  Future<List<String>> _getSavedUsernames() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCredentials = prefs.getString(_credentialsKey);

    if (savedCredentials != null) {
      List<Map<String, dynamic>> credentialsList =
          List<Map<String, dynamic>>.from(json.decode(savedCredentials));
      // 显式转换为 List<String>
      return credentialsList
          .where((credential) => credential['username'] is String)
          .map((credential) => credential['username'] as String)
          .toList();
    } else {
      return [];
    }
  }
  //解决问题

  void _loadPasswordForUsername(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCredentials = prefs.getString(_credentialsKey);

    if (savedCredentials != null) {
      List<Map<String, dynamic>> credentialsList =
          List<Map<String, dynamic>>.from(json.decode(savedCredentials));
      for (var credential in credentialsList) {
        if (credential['username'] == username) {
          setState(() {
            _pwdController.text = credential['password'];
            rememberPassword = credential['rememberPassword'];
          });
          break;
        }
      }
    }
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
            padding: const EdgeInsets.only(top: 100.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FutureBuilder<List<String>>(
                    future: _getSavedUsernames(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        List<String> usernames = snapshot.data ?? [];
                        if (_isManualInput) {
                          // 如果是手动输入模式，显示 TextFormField
                          return TextFormField(
                            controller: _unameController,
                            decoration: InputDecoration(
                              labelText: "请输入用户名",
                              hintText: "请输入用户名",
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            validator: (v) {
                              return v == null || v.trim().isNotEmpty
                                  ? null
                                  : "用户名不能为空";
                            },
                            autofocus: _nameAutoFouce, // 确保聚焦
                          );
                        } else {
                          // 否则显示 DropdownButtonFormField
                          return DropdownButtonFormField<String>(
                            value: _unameController.text.isNotEmpty
                                ? _unameController.text
                                : null,
                            items: [
                              // 添加一个选项用于手动输入
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('手动输入用户名'),
                              ),
                              ...usernames
                                  .map((username) => DropdownMenuItem<String>(
                                        value: username,
                                        child: Text(username),
                                      ))
                                  .toList(),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue == '') {
                                  // 切换到手动输入模式
                                  _isManualInput = true;
                                  _unameController.clear();
                                  // 确保焦点转移到 TextFormField
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                } else {
                                  // 选择已有用户名
                                  _isManualInput = false;
                                  _unameController.text = newValue ?? '';
                                  _loadPasswordForUsername(newValue ?? '');
                                }
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "选择或输入用户名",
                              hintText: "选择或输入用户名",
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            validator: (v) {
                              return v == null || v.trim().isNotEmpty
                                  ? null
                                  : "用户名不能为空";
                            },
                          );
                        }
                      }
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
                    obscureText: !pwdShow,
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
       
        
        
        // 正确调用SM2加密：encrypt(明文, 公钥)
        String passwd = SM2.encrypt(_pwdController.text, publicKey, cipherMode: 1);
        logger.i("加密后的密码：$passwd");
        logger.i(_unameController.text);
        // 调用api接口函数
        var r = await LoginApi().getProfile(
          // 账号密码

          queryParametrs: {
            'password': passwd,
            'username': _unameController.text,
          },
        );
        if (mounted) {
          if (r.code == 200) {
            profile = r;
            Global.profile = profile;
            Provider.of<UserModel>(context, listen: false).accessToken =
                profile.data;

            // 保存凭据
            _saveCredentials(
                _unameController.text, _pwdController.text, rememberPassword);


            await AppApi.init();
            
            // 登录成功后，后台预加载数据（不阻塞UI）
            Global.preloadRepairData().catchError((e) {
              logger.e('预加载数据失败: $e');
            });
          } else {
            // 登录失败，显示错误信息
            showToast("登录失败：${r.msg}");
          }
        }
      } on DioException catch (e) {
        showToast("网络错误：${e.toString()}");
      } finally {
        SmartDialog.dismiss();
      }
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
