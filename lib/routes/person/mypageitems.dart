import '../../index.dart';


class MyPageItems extends StatefulWidget {
  const MyPageItems({super.key});

  @override
  State createState() => _MyPageItems();
}

class _MyPageItems extends State<MyPageItems> {
  static const String _prefMessageVibrationEnabled =
      'pref_message_vibration_enabled';

  bool _messageVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefMessageVibrationEnabled);
    if (!mounted) return;
    setState(() {
      _messageVibrationEnabled = v ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
        behavior: const ScrollBehavior(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            Stack(
              children: [
                FutureBuilder<String>(
                  future: F.getVersion(),
                  builder: (context, snapshot) {
                    String version = snapshot.data ?? F.version;
                    return ListTile(
                      leading:
                          Icon(Icons.update, color: Theme.of(context).primaryColor),
                      title: const Text('版本号：', style: TextStyle(fontSize: 18)),
                      trailing:
                          Text(version, style: const TextStyle(fontSize: 18)),
                    );
                  },
                ),
              ],
            ),
            SwitchListTile(
              secondary:
                  Icon(Icons.vibration, color: Theme.of(context).primaryColor),
              title: const Text('消息中心震动', style: TextStyle(fontSize: 18)),
              value: _messageVibrationEnabled,
              onChanged: (v) async {
                setState(() => _messageVibrationEnabled = v);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_prefMessageVibrationEnabled, v);
              },
            ),
            _loginTitle(context),
          ],
        ));
  }

  Widget _buildItem(
          BuildContext context, IconData icon, String title, String linkTo,
          {VoidCallback? onTap}) =>
      ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing:
            Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
        onTap: () {
          if (linkTo.isNotEmpty) {
            Navigator.of(context).pushNamed(linkTo);
            if (onTap != null) onTap();
          }
        },
      );

  Widget _loginTitle(BuildContext context) {
    UserModel usermodel = Provider.of<UserModel>(context);
    if (usermodel.isLogin) {
      return ListTile(
        leading:
            Icon(Icons.logout_outlined, color: Theme.of(context).primaryColor),
        title: const Text('退出登录', style: TextStyle(fontSize: 18)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text('退出登录'),
                  actions: <Widget>[
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () async {
                          usermodel.accessToken = null;
                          Global.profile = Profile();
                         
                          var prefs = await SharedPreferences.getInstance();
                          prefs.remove('profile');
                          Navigator.pop(context);
                          // Scaffold.of(context).closeDrawer();
                          // 需要改为StatefulWidget父类
                        },
                        child: const Text('确定'))
                  ],
                );
              });
        },
      );
    } else {
      return ListTile(
        leading:
            Icon(Icons.logout_outlined, color: Theme.of(context).primaryColor),
        title: const Text('登录', style: TextStyle(fontSize: 18)),
        onTap: () {
          Navigator.of(context).pushNamed('login');
        },
      );
    }
  }
}
