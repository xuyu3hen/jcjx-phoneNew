import '../../index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class myPageItems extends StatefulWidget {

  @override
  _myPageItems createState() => _myPageItems();
}

class _myPageItems extends State<myPageItems> {
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(
            height: 10,
          ),

          _LoginTitle(context),

          const Divider(),
          _buildItem(context, Icons.info_outline, "关于应用", ""),
          const Divider(),

          Stack(
            children: [
              ListTile(
                leading: Icon(Icons.update,color: Theme.of(context).primaryColor),
                title: Text("版本号：",style: TextStyle(fontSize: 18)),
                trailing: Text("${F.version}",style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const Divider(),
        ],
      )
    );
  }

  Widget _buildItem(
          BuildContext context, IconData icon, String title, String linkTo,
          {VoidCallback? onTap}) =>
      ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title, style:  const TextStyle(fontSize: 18)),
        trailing:
            Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
        onTap: () {
          if (linkTo.isNotEmpty) {
            Navigator.of(context).pushNamed(linkTo);
            if (onTap != null) onTap();
          }
        },
      );
  
  Widget _LoginTitle(BuildContext context){
    UserModel usermodel = Provider.of<UserModel>(context);
    if(usermodel.isLogin){
      return ListTile(
        leading: Icon(Icons.logout_outlined,color: Theme.of(context).primaryColor),
        title: Text("退出登录",style: TextStyle(fontSize: 18)),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: const Text("确定退出当前号码"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("取消")
                  ),
                  TextButton(
                    onPressed: ()async{
                      usermodel.accessToken = null;
                      Global.profile = Profile();
                      print('已重置');
                      var _prefs = await SharedPreferences.getInstance();
                      _prefs.remove("profile");
                      Navigator.pop(context);
                      // Scaffold.of(context).closeDrawer();
                      // 需要改为StatefulWidget父类
                    },
                    child: const Text("确定")
                  )
                ],
              );
            }
          );
        },
      );
    }else{
      return ListTile(
        leading: Icon(Icons.logout_outlined,color: Theme.of(context).primaryColor),
        title: Text("登录",style: TextStyle(fontSize: 18)),
        onTap: () {
          Navigator.of(context).pushNamed("login");
        },
      );
    }
  }
}