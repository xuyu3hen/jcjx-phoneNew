import 'dart:developer';

import 'package:card_swiper/card_swiper.dart';
import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_empty_view.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_top_tabbar.dart';

class VehImageViewer extends StatefulWidget{
  const VehImageViewer({super.key});

  @override
  State<VehImageViewer> createState() => _vehImageViewerState();
}

class _vehImageViewerState extends State<VehImageViewer>{

  JtMessage? jtMes;
  List<PhotoData> repairPictureList = [];

  
  void getByGroupId(val) async {
    try{
      var r = await JtApi().getByGroupId(
        queryParameters: {
          "groupId":val
        }
      );
      if(r.code == "S_F_S000"&&r.data != null){
        setState(() {
          repairPictureList = r.data!;
        });
      }else{
        showToast("未能获取图片信息");
      }
    }catch(e){
      log("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    jtMes = ModalRoute.of(context)!.settings.arguments as JtMessage;
    return ZjcTopTabBar(
      title: '履历照片一览',
      tabModelArr: [
        ZjcTopTabBarModel(title: '机统提报', widget: repiarImageViwer("repairPicture")),
        ZjcTopTabBarModel(title: '施修', widget: repiarImageViwer("repairEndPicture")),
        ZjcTopTabBarModel(title: '互检', widget: repiarImageViwer("mutualInspectionPicture")),
        ZjcTopTabBarModel(title: '专检', widget: repiarImageViwer("specialInspectionPicture")),
      ],
      // showCenterLine: true,
      isScrollable: false,
    );
  }

  Widget imageContent(){
    return Text("${jtMes?.reporter}");
  }

  Widget repiarImageViwer(str){
    var jtMesMap = jtMes?.toJson();
    if(jtMesMap?['$str'] == null){
      return const ZjcEmptyView(text:"暂未上传图片");
    }else if(jtMesMap?['$str'] != null&&repairPictureList.isEmpty){
      getByGroupId(jtMesMap?['$str']);
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
            Text("正在获取图片信息",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        )
      );
    }else{
      return Swiper(
        itemBuilder: (context, index) {
          return Image(
            image: NetworkImage(
              "http://10.102.72.103:8080/fileserver/FileOperation/previewImage?url=${repairPictureList[index].downloadUrl}",
            ),
            fit: BoxFit.fill,
            );
          },
          autoplay: true,
        itemCount: repairPictureList.length,
        scrollDirection: Axis.vertical,
        pagination: const SwiperPagination(alignment: Alignment.centerRight),
        control: const SwiperControl(),
        );
    }
  }
  
}