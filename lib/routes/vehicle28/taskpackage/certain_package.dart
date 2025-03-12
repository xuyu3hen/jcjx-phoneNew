import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/zjc_form/zjc_text_field.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../zjc_common/widgets/zjc_empty_view.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as apc;

class CertainPackage extends StatefulWidget{
  const CertainPackage({super.key});

  @override
  State<CertainPackage> createState() => _CertainPackageState();
}

class _CertainPackageState extends State<CertainPackage>{
  IndividualTaskPackage? iTpackage;
  List<TaskCertainPackageList> tpackage = [];
  List<TaskCertainPackageList> selectDispath = [];

  List<MaterialColor> secondPackageColorList = [Colors.green,Colors.blue,Colors.red,Colors.purple];
  List<String> secondPCList = [];

  // 作业项图片
  List<AssetEntity> assestPics = [];
  List<File> taskPics = [];

  // 完成作业项
  Future<int> completeTaskCertainPackage(List<TaskCertainPackageList> val) async {
    SmartDialog.showLoading();
    var list = <Map<String,dynamic>>[];
    // list转mapList
    list = val.map((e){
      return e.toJson();
      }).toList();
    // list.insert(0, json.decode(json.encode(val)));
    var r = await JtApi().completeTaskCertainPackage(
      queryParameters:list
    );
    if(r['message'] == "操作成功"&&r['code']== 200){
      print('作业项完成正常');
    }else{
      showToast('作业项完成出现错误');
    }
    SmartDialog.dismiss(status: SmartStatus.loading);
    return r['code'];
  }

  // 刷新作业项
  Future<int> getTaskCertainPackage() async {
    // print(json.decode(json.encode(val)));
    var r = await JtApi().getTaskCertainPackage(
      queryParameters:{
        'packageCode':iTpackage?.code
      }
    );
    if(r['message'] == "操作成功"&&r['code']== 200){
      print('刷新作业项');
    }else{
      showToast('获取作业项出现错误');
    }
    return r['code'];
  }

  @override
  Widget build(BuildContext context) {
    iTpackage = ModalRoute.of(context)!.settings.arguments as IndividualTaskPackage;
    if(iTpackage!.taskCertainPackageList != null&&tpackage.isEmpty){
      tpackage.insertAll(0, iTpackage!.taskCertainPackageList!) ;
      for (var element in tpackage) { 
        element.selected = false;
        element.expanded = false;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(iTpackage?.name??'作业项'),
      ),
      body: _body(),
      bottomNavigationBar:_footer(),
    );
  }

  Widget _body(){
    if(tpackage.isEmpty){
      return const ZjcEmptyView(text: '无作业项',);
    }else{
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.topCenter,
              height: (MediaQuery.of(context).size.height)*0.85,
              child: ListView.separated(
                itemCount: tpackage.length,
                itemBuilder: (context,index){
                  return _itemWidget(tpackage[index]);
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
  Widget _itemWidget(TaskCertainPackageList item) {
    MaterialColor distinguish = Colors.green;
    if(item.secondPackageCode != null){
      distinguish = secPackageColor(item);
    }
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(3),
      child: Container(
        margin: const EdgeInsets.all(2),
        // constraints: const BoxConstraints.tightFor(height: 116),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              dense: true,
              leading: Checkbox(onChanged: (bool? value) { 
                setState(() {
                  if(item.secondPackageCode == null){
                    item.selected = value;
                  }else{
                    for(var e in tpackage){
                      if(e.secondPackageCode == item.secondPackageCode){
                        e.selected = value;
                      }
                    }
                  }
                });
              }, value: item.selected,),
              title: Text("${item.packageSort}-${item.name}",style: TextStyle(fontSize: 16.0,color: item.secondPackageCode == null?Colors.black:distinguish),),
              // subtitle: Text("${item.packageSort}",style: TextStyle(fontSize: 18.0,color: item.secondPackageCode == null?Colors.black:distinguish),),
              trailing:ElevatedButton(onPressed: (){
                  // changeABDialog(item);
                }, 
                child: const Icon(Icons.remove_red_eye_outlined),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Text("完成情况",style: TextStyle(fontSize: 16.0),),
              // title: Text("${item.complete}",style: TextStyle(fontSize: 16.0)),
              trailing:Text(item.complete=='0'?'未完成':'已完成',style: TextStyle(fontSize: 16.0,color: item.complete=='0'?Colors.orange:Colors.blue))
            ),
            if(item.expanded!&&item.taskInstructContentList!.isNotEmpty)...[
              for(var e in item.taskInstructContentList!)...[
                if(e.sort == 1)...[
                  ZjcTextField(
                    labelText: '作业内容',
                    text: e.name,
                    enabled: false,
                  )
                ]else...[
                  ZjcTextField(
                    text: e.name,
                    enabled: false,
                  )
                ]
              ]
            ],
            InkWell(
              onTap: () {
                setState(() {
                  item.expanded = !(item.expanded!);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10))
                ),
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if(item.expanded!)...[
                      const Icon(Icons.keyboard_double_arrow_up_rounded)
                    ]else...[
                      const Icon(Icons.keyboard_double_arrow_down_rounded)
                    ]
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    );
    return cell;
  }

  // 根据第二作业包改色
  secPackageColor(TaskCertainPackageList item){
    if(secondPCList != []&&secondPCList.indexWhere((e) => e == item.secondPackageCode) != -1 ){
      var i = (secondPCList.indexWhere((e) => e == item.secondPackageCode))%4;
      // print('i $i');
      return secondPackageColorList[i];
    }else{
      secondPCList.add(item.secondPackageCode!);
      var a = (secondPCList.length-1)%4;
      // print('a $a');
      return secondPackageColorList[a];
    }
  }

  // 底部按钮
  Widget _footer(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: (){
            selectDispath = <TaskCertainPackageList>[];
            // var loadingFlag = false;
            for (var e in tpackage) { 
              if(e.selected!){
                selectDispath.add(e);
              }
            }
            SmartDialog.show(
              clickMaskDismiss: false,
              builder: (context){
                return StatefulBuilder(
                  builder: (context,setDialogState){
                    return Container(
                      height: (MediaQuery.of(context).size.height)*0.6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('作业项图片'),
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.all(10),
                            decoration:BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              border: Border.all(color: Colors.brown)
                            ),
                            child: ZjcAssetPicker(
                              assetType: apc.AssetType.image,
                              maxAssets: 3,
                              selectedAssets: assestPics,
                              // bgColor: Colors.grey,
                              callBack: (assetEntityList) async {
                                print('assetEntityList-------------');
                                print(assetEntityList);
                                assestPics = assetEntityList;
                                if (assetEntityList.isNotEmpty) {
                                  for (var e in assetEntityList) { 
                                    var pic = await e.file;
                                    taskPics.insert(0, pic!);
                                  }
                                } else {
                                  taskPics = [];
                                }
                                print('assetEntityList-------------');
                              },
                            ),
                          ),
                          SizedBox(
                            height: (MediaQuery.of(context).size.height-590),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // 狗屎一般的遍历下潜获取待填报参数
                                  for(var e in selectDispath)...[
                                    if(e.taskInstructContentList!.isNotEmpty)...[
                                      for(var item in e.taskInstructContentList!)...[
                                        if(item.taskContentItemList != null)...[
                                          for(var tc in item.taskContentItemList!)...[
                                            ZjcFormInputCell(
                                              title: tc.name??"",
                                              keyboardType: TextInputType.number,
                                              showRedStar: true,
                                              text: "${tc.realValue}",
                                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]')), LengthLimitingTextInputFormatter(8)],
                                              inputCallBack:(value) {
                                                tc.realValue = double.parse(value);
                                              },
                                            )
                                          ]
                                        ]
                                      ]
                                    ]
                                  ]
                                ],
                              ),
                            ) 
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints.expand(height: 30,width: 100),
                                child: ElevatedButton.icon(
                                  onPressed: (){
                                    SmartDialog.dismiss();
                                  },
                                  label: Text('取消'),
                                  icon:Icon(Icons.system_security_update_good_sharp),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(140, 40),
                                    backgroundColor: Colors.grey[100]
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints.expand(height: 30,width: 100),
                                child: ElevatedButton.icon(
                                  onPressed: (){
                                    
                                  },
                                  label: Text('确定'),
                                  icon:Icon(Icons.system_security_update_good_sharp),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(140, 40),
                                  ),
                                ),
                              ),
                            ],
                          )
                          
                        ],
                      ),
                    );
                  }
                );
              }
            );
          }, 
          child: Text('上传作业项图片'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size((MediaQuery.of(context).size.width-20)/2, 40),
            backgroundColor: Colors.orange[100]
          ),
        ),
        ElevatedButton(
          onPressed: (){
            selectDispath = <TaskCertainPackageList>[];
            var loadingFlag = false;
            for (var e in tpackage) { 
              if(e.selected!){
                selectDispath.add(e);
              }
            }
            // TODO:展示一次选中项
            SmartDialog.show(
              clickMaskDismiss: false,
              builder: (context){
                return StatefulBuilder(
                  builder: (con,setDialogState){
                    if(loadingFlag == false){
                      return Container(
                        height: 150,
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('是否完成勾选共${selectDispath.length}项',style: TextStyle(fontSize: 16.0),),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints.expand(height: 30,width: 100),
                                  child: ElevatedButton.icon(
                                    onPressed: (){
                                      SmartDialog.dismiss();
                                    },
                                    label: Text('取消'),
                                    icon:Icon(Icons.system_security_update_good_sharp),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(140, 40),
                                      backgroundColor: Colors.grey[100]
                                    ),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints.expand(height: 30,width: 100),
                                  child: ElevatedButton.icon(
                                    onPressed: (){
                                      completeTaskCertainPackage(selectDispath).then((value) => {
                                        setDialogState(() {
                                          loadingFlag = true;
                                        },)
                                      });
                                    },
                                    label: Text('确定'),
                                    icon:Icon(Icons.system_security_update_good_sharp),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(140, 40),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ]
                        ),
                      );
                    }else{
                      return Container(
                        height: 150,
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('作业项完成！',style: TextStyle(fontSize: 16.0),),
                            ConstrainedBox(
                              constraints: BoxConstraints.expand(height: 30,width: 100),
                              child: ElevatedButton.icon(
                                onPressed: (){
                                  SmartDialog.dismiss();
                                  getTaskCertainPackage();
                                },
                                label: Text('确定'),
                                icon:Icon(Icons.system_security_update_good_sharp),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(140, 40),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  });
              }
            );
          }, 
          child: Text('完成作业项'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size((MediaQuery.of(context).size.width-20)/2, 40)
          ),
        ),
      ],
    );
  }
}