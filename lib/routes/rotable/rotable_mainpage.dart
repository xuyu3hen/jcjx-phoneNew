import '../../index.dart';

class RotableMainPage extends StatefulWidget{
  @override
  _RotableMainPage createState()=> _RotableMainPage();
}

class _RotableMainPage extends State<RotableMainPage>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("周转件主页"),
      ),
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody(){
    UserModel usermodel = Provider.of<UserModel>(context);
    // 查登录
    if(!usermodel.isLogin){
      return Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed("login"),
          child: const Text('欢迎')
        ),
      );
    }else{
      // print("已登录：${usermodel.user!.userLoginName}");
      print("已登录");
    }
    // 功能选区
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text('功能入口放这里')
      ]
    );
  }

}