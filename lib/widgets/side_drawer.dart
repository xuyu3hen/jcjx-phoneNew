import '../index.dart';


class SideDrawer extends StatelessWidget {
  const SideDrawer({
    Key?key,
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // _buildHeader(),
            Expanded(child: _buildMenus()),
          ],)
        ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserModel>(
      builder: (BuildContext context,UserModel value,Widget? child){
        return GestureDetector(
          child: Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.only(top:40,bottom: 20),
            child: Row(
              children: <Widget>[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipOval(
                    child: 
                    Image.asset(
                      "assets/head.png",
                      width: 80,
                    )
                    ),
                  ),
              ]),
          ),
          onTap: (){
            if(!value.isLogin){
              Navigator.of(context).pushNamed("login");
            }
          },
        );
      }
    );
  }

  Widget _buildMenus() {
    return Consumer<UserModel>(
      builder: (BuildContext context,UserModel userModel,Widget? child){
        return ListView(
          children: <Widget>[
            // ListTile(
            //   leading: const Icon(Icons.color_lens),
            //   title: const Text("主题色"),
            //   onTap: ()=>Navigator.pushNamed(context, "theme"),
            // ),
            //检查是否登录
            if(userModel.isLogin)
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: const Text("退出登录"),
              onTap: (){
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
                            // userModel.user = null;
                            Global.profile = Profile();
                            var prefs = await SharedPreferences.getInstance();
                            prefs.remove("profile");
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
            ),
            ListTile(
              leading: const Icon(Icons.view_kanban_rounded),
              title: Text("版本号${F.version}"),
            )
          ],
        );
      });
  }
}