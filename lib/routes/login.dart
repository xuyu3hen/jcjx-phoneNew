import 'package:dart_sm/dart_sm.dart';

import '../index.dart';

// toast 统一使用 showToast 包装

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
  String publicKey =
      '049d14df9951e1d14dd0e411419f111cb6f42da259ab9af5beea52276ed651e74c70eabe623f56e7f2716c3211e5bae9ec041dcda194840bca87290593e0b06640';
  @override
  void initState() {
    super.initState();
    initXUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLastUpdate();
    });
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

  Future<List<Map<String, dynamic>>> _getSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCredentials = prefs.getString(_credentialsKey);

    if (savedCredentials != null) {
      final decoded = json.decode(savedCredentials);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return [];
  }

  Future<void> _showHistoryLoginSheet() async {
    final credentialsList = await _getSavedCredentials();
    if (!mounted) return;
    if (credentialsList.isEmpty) {
      showToast("暂无历史登录信息");
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final dialogHeight = screenHeight * 0.5 > 420 ? 420.0 : screenHeight * 0.5;
        return AlertDialog(
          title: const Center(child: Text("历史账号")),
          content: SizedBox(
            width: double.maxFinite,
            height: dialogHeight,
            child: ListView.separated(
              itemCount: credentialsList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = credentialsList[index];
                final username = (item['username'] ?? '').toString();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Center(
                    child: Text(username.isNotEmpty ? username : "未知账号"),
                  ),
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("取消"),
            ),
          ],
        );
      },
    );

    if (!mounted || selected == null) return;

    final username = (selected['username'] ?? '').toString();
    final password = (selected['password'] ?? '').toString();
    final remember = selected['rememberPassword'] == true;

    setState(() {
      _unameController.text = username;
      _pwdController.text = password;
      rememberPassword = remember;
    });

    if (username.isNotEmpty && password.isNotEmpty) {
      _loginIn();
    } else {
      showToast("历史账号信息不完整");
    }
  }

  @override
  Widget build(BuildContext context) {
    // UserModel usermodel = Provider.of<UserModel>(context, listen: false);
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
                  TextFormField(
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
                    autofocus: _nameAutoFouce,
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
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _showHistoryLoginSheet,
                      child: const Text("历史账号"),
                    ),
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
        final username = _unameController.text.trim();
        final passwordPlain = _pwdController.text;
        if (username.isEmpty) {
          showToast("账号不能为空");
          return;
        }
        if (passwordPlain.trim().isEmpty) {
          showToast("密码不能为空");
          return;
        }
        SmartDialog.showLoading();
        // 正确调用SM2加密：encrypt(明文, 公钥)
        String passwd =
            SM2.encrypt(passwordPlain, publicKey, cipherMode: 1);
        // 调用api接口函数
        var r = await LoginApi().getProfile(
          // 账号密码

          queryParametrs: {
            'password': passwd,
            'username': username,
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
                username, passwordPlain, rememberPassword);

            await AppApi.init();

            // 登录成功后，后台预加载数据（不阻塞UI）
            Global.preloadRepairData().catchError((e) {
              logger.e('预加载数据失败: $e');
            });
          } else {
            // 登录失败，显示错误信息
            final msg = (r.msg ?? '').toString().trim();
            final text = msg.isEmpty ? "用户名或密码错误" : msg;
            SmartDialog.dismiss(status: SmartStatus.loading);
            if (text.contains('剩余重试次数') ||
                text.contains('锁定') ||
                text.contains('不在指定范围')) {
              await _showLoginErrorDialog(text);
            } else {
              showToast("登录失败：$text");
            }
          }
        }
      } on DioException catch (e) {
        String? serverMsg;
        final data = e.response?.data;
        if (data is Map) {
          serverMsg = (data["msg"] ??
                  data["message"] ??
                  data["error"] ??
                  data["data"])
              ?.toString();
        } else if (data is String) {
          serverMsg = data;
        }
        serverMsg = serverMsg?.trim();
        final statusCode = e.response?.statusCode;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          SmartDialog.dismiss(status: SmartStatus.loading);
          if (mounted &&
              (serverMsg.contains('剩余重试次数') ||
                  serverMsg.contains('锁定') ||
                  serverMsg.contains('不在指定范围'))) {
            await _showLoginErrorDialog(serverMsg);
          } else {
            showToast(serverMsg);
          }
        } else if (statusCode == 401) {
          SmartDialog.dismiss(status: SmartStatus.loading);
          showToast("用户名或密码错误");
        } else if (statusCode == 423 || statusCode == 429) {
          SmartDialog.dismiss(status: SmartStatus.loading);
          if (mounted) {
            await _showLoginErrorDialog("密码错误次数过多，账号已锁定，请联系管理员");
          } else {
            showToast("密码错误次数过多，账号已锁定，请联系管理员");
          }
        } else {
          SmartDialog.dismiss(status: SmartStatus.loading);
          showToast("登录失败，请检查网络后重试");
        }
      } finally {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    }

    // 验证表单字符是否合法
  }

  Future<void> _showLoginErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('登录失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void getLastUpdate() async {
    try {
      logger.i("检查更新，应用ID: ${F.id}");

      // 获取当前应用版本信息
      String currentVersion = await F.getVersion();
      int currentBuildNumber = await F.getBuildNumber();

      logger.i("当前版本: $currentVersion+$currentBuildNumber");

      // 获取当前环境对应的 env 参数
      String env = 'release';
      switch (F.appFlavor) {
        case Flavor.env_dev:
          env = 'dev';
          break;
        case Flavor.env_test:
          env = 'test';
          break;
        case Flavor.env_release:
          env = 'release';
          break;
        default:
          env = 'release';
      }

      // 使用 getLatestOne 获取最新版本信息
      var r = await ProductApi().getLatestOne(env: env);
      logger.i("最新版本信息123: $r");
      if (r is! Map) {
        return;
      }
      String downloadUrl = (r['downloadUrl'] ?? r['url'] ?? '').toString();
      String version = (r['version'] ?? r['versionName'] ?? '').toString();
      String description =
          (r['description'] ?? r['dec'] ?? r['updateContent'] ?? '').toString();
      logger.i(
          "更新信息: version=$version, url=$downloadUrl, description=$description");
      // 比较版本并使用 XUpdate 下载与安装
      if (version.isNotEmpty && downloadUrl.isNotEmpty) {
        final cmp = _compareVersion(version, currentVersion);
        if (cmp == -1) {
          // 发现新版本，开始手动下载流程
          //使用 xupdate 进行更新
          FlutterXUpdate.updateByInfo(
            updateEntity: customJsonParse(r),
          );
        }
      }
    } catch (e) {
      logger.e("检查更新失败: $e");
      // 不显示错误提示，避免影响用户体验
    }
  }

  // 比较版本号（语义化版本号比较）
  // 返回值: >0 表示 version1 > version2, <0 表示 version1 < version2, 0 表示相等
  int _compareVersion(String version1, String version2) {
    List<int> v1Parts =
        version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts =
        version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 补齐长度
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return -1; // version1 更新
      if (v1Parts[i] < v2Parts[i]) return 1; // version2 更新
    }
    return 0; // 相等
  }

  // 转义成UpdateEntity
  UpdateEntity customJsonParse(Map<dynamic, dynamic> apk) {
    String downloadUrl = (apk['downloadUrl'] ?? apk['url'] ?? '').toString();
    if (downloadUrl.isNotEmpty && !downloadUrl.startsWith('http')) {
      String baseUrl = F.baseURL;
      //如果是env_release环境将baseUrl转换为http开头的 原来是这样的https://10.102.124.50/jcjx-prod-api/
      if (baseUrl.startsWith('https')) {
        baseUrl = 'http://10.102.124.50/xc-prod-api';
      }

      //将downloadUrl第一个/去掉
    
     
      downloadUrl =
          '$baseUrl/fileserver/FileOperation/generalDownloadFile?url=$downloadUrl';
    }
    logger.d('downloadUrl: $downloadUrl');

    final isForce = (apk['isForceUpdate'] == true) || (apk['force'] == true);
    final versionCodeRaw = apk['buildNumber'];
    final versionCode = versionCodeRaw is num
        ? versionCodeRaw.toInt()
        : int.tryParse(versionCodeRaw?.toString() ?? '') ?? 1;

    final versionName =
        (apk['version'] ?? apk['versionName'] ?? '未知版本').toString();
    final updateContent =
        (apk['dec'] ?? apk['description'] ?? apk['updateContent'] ?? '新版本更新')
            .toString();

    return UpdateEntity(
      hasUpdate: true,
      isForce: isForce,
      isIgnorable: !isForce,
      versionCode: versionCode,
      versionName: versionName,
      updateContent: updateContent,
      downloadUrl: downloadUrl,
    );
  }

  ///传入UpdateEntity进行更新提示
  void checkUpdateByUpdateEntity(Map<String, dynamic> apk) {
    FlutterXUpdate.updateByInfo(updateEntity: customJsonParse(apk));
  }
}
