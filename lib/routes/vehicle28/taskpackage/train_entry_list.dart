
import 'dart:ui';

import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_empty_view.dart';
import 'package:jcjx_phone/zjc_common/zjc_form/zjc_searchbar.dart';

class TrainEntryListByNodeCode extends StatefulWidget{
  const TrainEntryListByNodeCode({super.key});

  @override
  State<TrainEntryListByNodeCode> createState() => _TrainEntryListByNodeCodeState();
}

class _TrainEntryListByNodeCodeState extends State<TrainEntryListByNodeCode>{
  String? repairMainNodeCode;
  List<TrainEntryByNodeCode> trainList = [];
  List<MaterialColor> secondPackageColorList = [Colors.green,Colors.blue,Colors.red,Colors.purple];

  // 通过组流程节点获取机车入段信息
  void getTrainEntryByRepairMainNodeCode() async {
    var r = await JtApi().getTrainEntryByRepairMainNodeCode(
      queryParameters: {
        'repairMainNodeCode':repairMainNodeCode
      }
    );
    if(r['code'] == "S_F_S000"){
      setState(() {
        trainList =  r['data'].map<TrainEntryByNodeCode>((e) => TrainEntryByNodeCode.fromJson(e)).toList();
        // log("${r['data']}");
      });
    }else{
      showToast('机车列表获取失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    repairMainNodeCode = ModalRoute.of(context)!.settings.arguments as String;
    if(trainList.isEmpty){
      getTrainEntryByRepairMainNodeCode();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("车号列表"),
      ),
      // 打开侧边栏需要传递更低一级context
      body: _body()
    );
  }

  Widget _body(){
    if(trainList.isEmpty){
      return const ZjcEmptyView(text: "暂无列车",);
    }else{
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ZjcSearchBar(
              hintText: "请输入车号",
              inputCompletionCallBack:(value, isSubmitted) {
              },
            ),
            Container(
              alignment: Alignment.topCenter,
              height: (MediaQuery.of(context).size.height)*0.8,
              child: ListView.separated(
                itemCount: trainList.length,
                itemBuilder: (context,index){
                  return _itemWidget(trainList[index]);
                }, 
                separatorBuilder: (context,index) => const SizedBox(height: .0,), 
              )
            )
          ]
        ),
      );
    }
  }

  // 数据模板
  Widget _itemWidget(TrainEntryByNodeCode item) {
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 50),
        decoration: const BoxDecoration(
          // TODO:测试渐变效果
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ Colors.blue,Colors.blue, Colors.white],
          ),
          // color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0
            )
          ],
        ),
        // 磨砂效果
        // BackdropFilter没有圆角效果，故使用ClipRRect包裹
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed('packageviewer',arguments: item).then((value) => {
                  getTrainEntryByRepairMainNodeCode()
                });
              },
              child:Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text("${item.trainNum}",style: const TextStyle(fontSize: 20.0),)],
              )
            )
          ),
        )

      ),
    );
    return cell;
  }

  // 车号间隔变色
  secPackageColor(TaskCertainPackageList item){
    if(trainList.isNotEmpty&&trainList.indexWhere((e) => e == item.secondPackageCode) != -1 ){
      var i = (trainList.indexWhere((e) => e == item.secondPackageCode))%4;
      // print('i $i');
      return secondPackageColorList[i];
    }else{
      var a = (trainList.length-1)%4;
      // print('a $a');
      return secondPackageColorList[a];
    }
  }
}