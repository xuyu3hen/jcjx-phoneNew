import '../index.dart';
class UpdateApi extends AppApi{
  
  // 检查版本更新，获取下载链接
  Future<MyApkVersion> checkUpdate({
    Map<String,dynamic>? queryParametrs,// 分页参数
    })async{
      var r = await AppApi.dio.get(
        "http://10.102.12.211:8000/distributionplatform/main/get/apk/version/last",
        queryParameters: queryParametrs,
      );
      print('最新版本信息：${r.data}');
      return MyApkVersion.fromJson(r.data["data"]);
  }
}