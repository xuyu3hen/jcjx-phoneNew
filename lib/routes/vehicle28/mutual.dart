import 'dart:developer';


import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as apc;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../config/filter_data.dart';

class Mutual extends StatefulWidget {
  const Mutual({super.key});

  @override
  State<Mutual> createState() => _MutualState();
}

class _MutualState extends State<Mutual> {
  // 互检结果
  Map<dynamic,dynamic> mutualStatus = {"label":"通过","value":1};
  // 故障图片
  List<AssetEntity> assestPics = [];
  List<File> repairPics = [];
  JtMessage? jtMes;

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    jtMes = ModalRoute.of(context)!.settings.arguments as JtMessage;
    return Scaffold(
      appBar: AppBar(
        title: const Text("互检"),
      ),
      body: _buildBody(),
      persistentFooterButtons:[
        _footer()
      ]
    );
  }

  Widget _buildBody() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: ListView(children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListTile(
              // dense: true,
              leading: Text(
                "${jtMes?.trainType}-${jtMes?.trainNum}",
                style: const TextStyle(fontSize: 18.0),
              ),
              // title: Text("${jtMes?.trainType}-${jtMes?.trainNum}",style: TextStyle(fontSize: 18.0),),
              trailing: Text("加工方法：${jtMes?.processMethodName}"),
            ),
            ListTile(
              dense: true,
              title: Text(
                "检修作业来源：${jtMes?.repairResourceName}",
                style: const TextStyle(fontSize: 18.0),
              ),
              subtitle: Text("报修人：${jtMes?.reporterName}"),
              trailing: Text("风险等级：${jtMes?.riskLevel}"),
            ),
            ListTile(
              dense: true,
              title: Text(
                "施修情况：${jtMes?.repairStatus}",
                style: const TextStyle(fontSize: 18.0),
              ),
              subtitle: Text("施修人：${jtMes?.repairName}"),
            ),
            ListTile(
              dense: true,
              title: Text(
                "故障零部件:${jtMes?.jcNodeName}",
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
            ZjcFormInputCell(
              title: "故障现象",
              text: jtMes?.faultDescription,
              maxLines: 3,
              maxLength: 200,
              enabled: false,
            ),
            ZjcFormSelectCell(
              title: "互检结果",
              text: mutualStatus['label'],
              hintText: "请选择",
              showRedStar: true,
              clickCallBack: () {
                ZjcCascadeTreePicker.show(
                  context,
                  data: FilterData.mutualStatusList,
                  isShowSearch: false,
                  title: "选择互检结果",
                  clickCallBack: (selectItem, selectArr) {
                    logger.i(selectArr);
                    setState(() {
                      mutualStatus['label'] = selectItem["label"];
                      mutualStatus['value'] = selectItem["value"];
                    });
                  },
                );
              }
            ),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: Colors.brown)),
              child: ZjcAssetPicker(
                assetType: apc.AssetType.image,
                maxAssets: 3,
                selectedAssets: assestPics,
                // bgColor: Colors.grey,
                callBack: (assetEntityList) async {
                  logger.i('assetEntityList-------------');
                  logger.i(assetEntityList);
                  assestPics = assetEntityList;
                  if (assetEntityList.isNotEmpty) {
                    for (var e in assetEntityList) { 
                      var pic = await e.file;
                      repairPics.insert(0, pic!);
                    }
                    // var asset = assetEntityList[0];
                    // var pic = await asset.file;
                    // print(await asset.file);
                    // print(await asset.originFile);
                    // repairPics.insert(0, pic!);
                  } else {
                    repairPics = [];
                  }
                  logger.i('assetEntityList-------------');
                },
              ),
            ),
          ])
      ]));
  }

  Widget _footer(){
    return ElevatedButton.icon(
      onPressed: () async {
        dynamic message;
        SmartDialog.showLoading();
        List<Map<String,dynamic>> queryParameters = [];
        queryParameters.insert(0, {
          "code":jtMes?.code,
        });
        if(mutualStatus['value'] == 0){
          queryParameters[0]['completeStatus'] = 0;
        }else if(jtMes?.specialInspectionPersonnel != null){
          queryParameters[0]['completeStatus'] = 3;
        }else{
          queryParameters[0]['completeStatus'] = 4;
        }

        if(repairPics.isNotEmpty){
          var upload = await JtApi().uploadMixJt(imagedata: repairPics);
          queryParameters[0]['mutualInspectionPicture'] = upload['data'];
        }
        queryParameters[0]['status'] = jtMes?.status;
        log("$queryParameters");
        await JtApi().uploadJt28(queryParametrs: queryParameters).then((value) async => {
          message = value,
          SmartDialog.dismiss(status: SmartStatus.loading)
        });
        log("$message");
        
        if(message['code'] == "S_T_S003"){
          SmartDialog.show(
            clickMaskDismiss: false,
            builder: (con){
              return Container(
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text("互检提报成功",style: TextStyle(fontSize: 18),),
                    ConstrainedBox(
                      constraints: const BoxConstraints.expand(height: 30,width: 160),
                      child: ElevatedButton.icon(
                        onPressed: (){
                          SmartDialog.dismiss().then((value) => Navigator.of(context).pop());
                        },
                        label: const Text('确定'),
                        icon:const Icon(Icons.system_security_update_good_sharp),
                      ),
                    ),
                  ],
                ),
            );
          }
        );
      }
      }, 
      icon: Icon(Icons.check_circle_outline_rounded), 
      label: Text("确认"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(MediaQuery.of(context).size.width, 40),
      ),
    );
  }
}
