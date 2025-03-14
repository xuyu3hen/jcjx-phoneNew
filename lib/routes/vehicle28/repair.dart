import 'dart:developer';


import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as apc;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class Repair extends StatefulWidget {
  const Repair({super.key});

  @override
  State<Repair> createState() => _RepairState();
}

class _RepairState extends State<Repair> {
  // 施修情况
  String repairStatus = "";
  // 报修时间
  DateTime? actualRepairStartDate;
  // 故障零部件
  Map<dynamic, dynamic> componentName = {"nodeName": "", "configCode": ""};
  // 零部件
  List<dynamic> configTree = [];
  // 互检人员
  Map<dynamic, dynamic> mutualInspectionPersonnel = {
    "userId": 0,
    "nickName": ""
  };
  // 互检列表
  List<dynamic> mutualList = [];
  // 专检人员
  Map<dynamic, dynamic> specialInspectionPersonnel = {
    "userId": 0,
    "nickName": ""
  };
  // 专检列表
  List<dynamic> specialList = [];
  // 故障图片
  List<AssetEntity> assestPics = [];
  List<File> repairPics = [];
  JtMessage? jtMes;

  @override
  void initState() {
    actualRepairStartDate = DateTime.now();
    super.initState();
  }

  // 零部件
  void getAllConfigTreeByCode() async {
    try {
      var r = await JtApi().getAllConfigTreeByCode(
          queryParametrs: {'typeCode': jtMes?.machineModel});
      if (r['code'] != 200) {
        setState(() {
          configTree = r['data'];
        });
      } else {
        showToast("获取零部件表失败");
      }
    } catch (e) {
      log("$e");
      showToast("获取零部件表失败");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  // 查询专互检
  void getCheckList() async {
    try {
      // print(jtMes?.riskLevel);
      var r = await JtApi()
          .getCheckList(queryParameters: {'riskLevel': jtMes?.riskLevel});
      setState(() {
        mutualList = r['互检'];
        specialList = r['专检'];
      });
    } catch (e) {
      log("$e");
      showToast("获取专互检人员表失败");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    jtMes = ModalRoute.of(context)!.settings.arguments as JtMessage;
    if(mutualList.isEmpty){
      getCheckList();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("施修"),
      ),
      body: _buildBody(),
      // bottomNavigationBar:_footer(),
      persistentFooterButtons:[
        _footer()
      ]
    );
  }

  Widget _buildBody() {
    if (configTree.isEmpty) {
      getAllConfigTreeByCode();
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
            Text("正在请求零部件列表",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        )
      );
    } else {
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
                      "检修作业来源:${jtMes?.repairResourceName}",
                      style: const TextStyle(fontSize: 18.0),
                    ),
                    subtitle: Text("报修人：${jtMes?.reporterName}"),
                    trailing: Text("风险等级：${jtMes?.riskLevel}"),
                  ),
                  ZjcFormInputCell(
                    title: "故障现象",
                    text: jtMes?.faultDescription,
                    maxLines: 3,
                    maxLength: 200,
                    enabled: false,
                  ),
                  ZjcFormInputCell(
                    title: "施修情况",
                    text: repairStatus,
                    maxLines: 5,
                    maxLength: 200,
                    showRedStar: true,
                    inputCallBack: (value) {
                      repairStatus = value;
                    },
                  ),
                  ZjcFormInputCell(
                    title: "实际开始修理日期",
                    text: formatDate(actualRepairStartDate!,
                        [yyyy, '-', mm, '-', dd, ' ']),
                    hintText: "请选择",
                    showRedStar: true,
                    enabled: false,
                    // clickCallBack: () async {
                      // var time = await await showBoardDateTimePicker(
                      //   context: context,
                      //   pickerType: DateTimePickerType.datetime,
                      // );
                      // setState(() {
                      //   actualRepairStartDate = time;
                      // });
                    // },
                  ),
                  ZjcFormSelectCell(
                    title: "故障零部件",
                    text: componentName['nodeName'],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: configTree,
                        labelKey: 'nodeName',
                        valueKey: 'configCode',
                        title: "选择故障零部件",
                        clickCallBack: (selectItem, selectArr) {
                        
                          setState(() {
                            componentName['nodeName'] = selectItem["nodeName"];
                            componentName['configCode'] =
                                selectItem["configCode"];
                          });
                        },
                      );
                    },
                  ),
                  ZjcFormSelectCell(
                      title: "互检人员",
                      text: mutualInspectionPersonnel['nickName'],
                      hintText: "请选择",
                      clickCallBack: () {
                        ZjcCascadeTreePicker.show(context,
                          data: mutualList,
                          labelKey: 'nickName',
                          valueKey: 'userId',
                          title: "选择互检人员",
                          clickCallBack: (selectItem, selectArr) {
                            // print(selectArr);
                            setState((){
                              mutualInspectionPersonnel['nickName'] = selectItem["nickName"];
                              mutualInspectionPersonnel['userId'] = selectItem["userId"];
                            });
                          },
                        );
                      }),
                  if(jtMes!.riskLevel!.contains('A')||jtMes!.riskLevel!.contains('B'))
                  ZjcFormSelectCell(
                      title: "专检人员",
                      text: specialInspectionPersonnel['nickName'],
                      hintText: "请选择",
                      clickCallBack: () {
                        ZjcCascadeTreePicker.show(context,
                          data: specialList,
                          labelKey: 'nickName',
                          valueKey: 'userId',
                          title: "选择专检人员",
                          clickCallBack: (selectItem, selectArr) {
                            // print(selectArr);
                            setState((){
                              specialInspectionPersonnel['nickName'] = selectItem["nickName"];
                              specialInspectionPersonnel['userId'] = selectItem["userId"];
                            });
                          },
                        );
                      }),
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
                        
                      },
                    ),
                  ),
                ])
          ]));
    }
  }

  Widget _footer(){
    return ElevatedButton.icon(
      onPressed: () async {
        dynamic message;
        SmartDialog.showLoading();
        List<Map<String,dynamic>> queryParameters = [];
        queryParameters.insert(0, {
          "code":jtMes?.code,
          "repairStatus":repairStatus,
          "completeStatus":2,
          "actualRepairStartDate":actualRepairStartDate?.toIso8601String(),
          "faultyComponent":componentName['configCode'],
          "mutualInspectionPersonnel":mutualInspectionPersonnel['userId'],
        });
        if(specialInspectionPersonnel['userId'] != ""){
          queryParameters[0]['specialInspectionPersonnel'] = specialInspectionPersonnel['userId'];
        }
        if(repairPics.isNotEmpty){
          var upload = await JtApi().uploadMixJt(imagedata: repairPics);
          queryParameters[0]['repairEndPicture'] = upload['data'];
        }
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
                    const Text("施修提报成功",style: TextStyle(fontSize: 18),),
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
      icon: const Icon(Icons.handyman_outlined), 
      label: const Text("施修"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(MediaQuery.of(context).size.width, 40),
      ),
    );
  }
}
