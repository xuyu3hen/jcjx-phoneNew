import 'package:flutter/services.dart';
import '../../index.dart';

class PersonPage extends StatefulWidget {

  const PersonPage({Key? key}) : super(key:key);

  @override
  State<PersonPage> createState() => _PersonPageState();
}
class _PersonPageState extends State<PersonPage>{

  void getpermisson()async{
    Permissions p = await LoginApi().getpermissions();
    if(p.code == 200){
      setState(() {
        Global.profile.permissions = p;
      });
    }else{
      showToast("获取用户账号信息失败");
    }
  }

  @override
  Widget build(BuildContext context) {
    String image = 'BackLogo.png';
    if(Global.profile.permissions == null){
      getpermisson();
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 40.0,
              height: 40.0,
              child: CircularProgressIndicator(
                strokeWidth: 4.0,
              )),
            const SizedBox(
              height: 20.0,
            ),
            Text("正在请求用户数据",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        )
      );
    }else{
      return Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Container(
                    height: 180,
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Image.asset(
                      'assets/$image',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 40,
                    child: _buildAvatarByState(context)),
                  Positioned(
                    bottom: 5,
                    right: 80,
                    child: _buildByState(context)),
                ],
              ),

              Expanded(child: myPageItems(),)
            ])),
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

  Widget _buildByState(BuildContext context) {
    UserModel usermodel = Provider.of<UserModel>(context);
    // TODO:判断登录情况
    if(usermodel.isLogin){
      return Text(
        "${Global.profile.permissions?.user.nickName}",
        style: TextStyle(fontSize: 24,color: Theme.of(context).primaryColor),
      );
    }else{
      return Text(
        "未登录",
        style: TextStyle(fontSize: 24,color: Theme.of(context).primaryColor),
      );
    }
  }
}