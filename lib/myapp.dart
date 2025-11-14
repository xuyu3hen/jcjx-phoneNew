
import 'index.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// void main() {
//   TextInputBinding();
//   Global.init().then((e) => runApp(const MyApp()));
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 预载持久化内容
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModel()),
        ChangeNotifierProvider(create: (_) => UserModel()),
      ],
      child: Consumer2<ThemeModel,UserModel>(
        builder: (BuildContext context, themeModel, userModel, child) {
          return MaterialApp(
            title: F.title,
            debugShowCheckedModeBanner: false,
            // debugShowCheckedModeBanner: true,
            theme: ThemeData(
              // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              // 调用主题色时直接Theme.of(context).primaryColor即可
              primarySwatch: themeModel.theme,
              // useMaterial3: true
            ),
            // 添加本地化配置
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'), // 中文
              Locale('en', 'US'), // English
            ],
            home: firstPage(context),
              
            // 注册路由表
            routes: <String, WidgetBuilder>{
              // 开屏(废弃)
              // "opening":(context) => const MyHomePage(title: 'Maitre Scan Home Page'),
              // 主路由展示
              "main_page":(context) => const NormalMainPage(),
              // 筛选器测试
              // "menu":(context) => DownnMenu(),
              // 拣配
              // "assort":(context) => Assort(),
              // 周转件
              // "scanrotable":(context) => ScannerRotable(),
            },
          );
        }
      ),

        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.

        // 预定义主题颜色

      );
  }

  Widget firstPage(context){
    // UserModel userModel = Provider.of<UserModel>(context);
    if(Global.profile.data == null){
      return const LoginRoute();
    }else{
      return const MainPage();
    }
  }
}
