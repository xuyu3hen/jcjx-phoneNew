
import 'dart:developer';


import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../config/filter_data.dart';
import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class Vehicle28Form extends StatefulWidget {
  const Vehicle28Form({Key? key}) : super(key: key);

  @override
  State createState() => _Vehicle28FormState();
}

class _Vehicle28FormState extends State<Vehicle28Form> {
  // 动力类型
  // List<DynamicType> dynamicList = [];
  String? dynamicCode;
  String? dynamicName;
  // 机型
  Map<dynamic, dynamic> jcTypeListSelected = {"name": "", "code": ""};
  List<Map<String, dynamic>> jcTypeList = [];
  // 车号
  Map<dynamic, dynamic> trainNumSelected = {"trainNum": "", "code": ""};
  List<Map<String, dynamic>> trainNumCodeList = []; 
  String? trainNum;
  String? trainCode;
  // 检修作业来源
  Map<dynamic, dynamic> repairWorkResource = {"name": "", "code": ""};
  // 风险等级
  String? riskLevel;
  // 加工方法
  Map<dynamic, dynamic> requiredProcessingMethod = {"dictName": "", "code": ""};
  // 故障现象
  String? faultDesc;
  // 故障假设
  String? faultAssumption;
  // 故障零部件
  Map<dynamic, dynamic> componentName = {"nodeName": "", "configCode": ""};
  // 报修时间
  DateTime? reportDate;
  // 故障图片
  List<AssetEntity> assestPics = [];
  List<File> faultPics = [];
  // 修程通知单
  String? maintenanceNotice;
  // 报修人
  String? reporter;
  // 科室车间
  String? workshop;
  // 班组
  String? team;
  int? teamCode;
  // 施修人员
  // Map<dynamic,dynamic> userSelected = {"userId":0,"nickName":""};
  // String? assignCode;

  List<Map<String, dynamic>> dynamicList = [];
  // 车组信息(组件试用版Map)
  List<dynamic> cascaderList = [];
  // 车厢信息
  List<dynamic> vehicleList = [];
  // 系统分类
  List<dynamic> sysTypeList = [];
  List<dynamic> workDeptIdList = [];
  // 零部件
  List<dynamic> configTree = [];
  // 车间班组
  List<dynamic> deptTree = [];
  List<dynamic> teamTree = [];
  // 班组人员
  List<dynamic> userList = [];
  // 检修作业来源
  List<dynamic> jtTypeList = [];
  // 加工方法
  List<dynamic> jt28DictList = [];

  // 自动派活
  bool isAssigned = false;
  String completeLabel = "自检自修";
  int completeStatus = 0;
  
  Map<dynamic, dynamic> dynamciTypeSelected = {};

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getUserDeptree();
    getJtType();
    getJt28Dict();
  }

  // 动力类型
  void getDynamicType() async {
    var r = await ProductApi().getDynamicType();
    if (r.rows != []) {
      setState(() {
        List<DynamicType> dyn = r.rows!;
        List<Map<String, dynamic>> temp = [];
        for(DynamicType item in dyn){
          temp.add(item.toJson());
        }
        dynamicList = temp;

      });
    }
  }

  // 机型
  //List<Map<String, dynamic>>类型才能够使用
  void getTypeCode() async {
    var r = await ProductApi().getJcType(queryParametrs: {
      'dynamicCode': dynamciTypeSelected['code'],
    });
    if (r.rows != []) {
      setState(() {
        jcTypeList = r.toMapList();
        
      });
    }
  }

  // 车号
  void getTrainNumCodeList() async {
    var r = await ProductApi().getRepairPlanList(queryParametrs: {
      "pageNum": 0,
      "pageSize": 0,
      "typeName": jcTypeListSelected["name"]
    });
    logger.i(r.rows);
    setState(() {
      trainNum = "";
      trainNumCodeList = r.toMapList();
    });
  }

  // 零部件
  void getAllConfigTreeByCode() async {
    try {
      var r = await JtApi().getAllConfigTreeByCode(
          queryParametrs: {'typeCode': jcTypeListSelected['code']});
      if (r['code'] != 200) {
        setState(() {
          configTree = r['data'];
        });
      } else {
        showToast("获取零部件表失败,请检查网络");
      }
    } catch (e) {
      log("$e");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  // 车间班组
  void getUserDeptree() async {
    try {
      var r = await JtApi().getUserDeptree();
      if (r != [] && r != null) {
        setState(() {
          deptTree = ((r[0])["children"])[0]["children"];
        });
      } else {
        showToast("未能获取车间班组");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 班组人员
  void getJtUsers() async {
    try {
      var r = await JtApi().getUserList(
          queryParametrs: {'pageNum': 0, 'pageSize': 0, 'deptId': teamCode});
      if (r != [] && r != null) {
        setState(() {
          userList = r['rows'];
        });
      } else {
        showToast("未能获取班组人员");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 检修作业来源
  void getJtType() async {
    try {
      var r = await JtApi().getJtType();
      if (r.code == 200 && r.rows != null) {
        setState(() {
          jtTypeList = r.rows!;
        });
      } else {
        showToast("未能获取作业来源");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 加工方法
  void getJt28Dict() async {
    try {
      var r = await JtApi().getJt28Dict();
      if (r.code == 200 && r.rows != null) {
        setState(() {
          jt28DictList = r.rows!;
        });
      } else {
        showToast("未能获取加工方法");
      }
    } catch (e) {
      log("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("机统28"),
      ),
      // resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar: _footer(),
    );
  }

  Widget _buildBody() {
    // reportDate = DateTime.now();
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView(
          children: <Widget>[
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ZjcFormSelectCell(
                    title: "动力类型",
                    text: dynamciTypeSelected["name"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (dynamicList.isEmpty) {
                        showToast("无动力类型选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: dynamicList,
                          labelKey: 'name',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择动力类型",
                          clickCallBack: (selectItem, selectArr) {
                            logger.i(selectArr);
                            setState(() {
                              dynamciTypeSelected["code"] = selectItem["code"];
                              dynamciTypeSelected["name"] = selectItem["name"];
                              getTypeCode();
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "机型",
                    text: jcTypeListSelected["name"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (jcTypeList.isEmpty) {
                        showToast("无机型可以选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: jcTypeList,
                          labelKey: 'name',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择机型",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              logger.i(selectArr);
                              jcTypeListSelected["name"] = selectItem["name"];
                              jcTypeListSelected["code"] = selectItem["code"];
                              getTrainNumCodeList();
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "车号",
                    text: trainNumSelected["trainNum"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (trainNumCodeList.isEmpty) {
                        showToast("无车号可以选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: trainNumCodeList,
                          labelKey: 'trainNum',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择检修地点",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              logger.i(selectArr);
                              trainNumSelected["trainNum"] =
                                  selectItem["trainNum"];
                              trainNumSelected["code"] = selectItem["code"];
                              
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "检修作业来源",
                    text: repairWorkResource["name"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: jtTypeList,
                        labelKey: 'name',
                        valueKey: 'code',
                        title: "选择检修作业来源",
                        clickCallBack: (selectItem, selectArr) {
                          logger.i(selectArr);
                          setState(() {
                            repairWorkResource["name"] = selectItem["name"];
                            repairWorkResource["code"] = selectItem["code"];
                            riskLevel = selectItem["riskLevel"];
                          });
                        },
                      );
                    },
                  ),
                  ZjcFormInputCell(
                    title: "风险等级",
                    showRedStar: true,
                    text: riskLevel,
                    enabled: false,
                  ),
                  ZjcFormSelectCell(
                    title: "加工方法",
                    text: requiredProcessingMethod["dictName"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: jt28DictList,
                        labelKey: 'dictName',
                        valueKey: 'code',
                        title: "选择加工方法",
                        clickCallBack: (selectItem, selectArr) {
                          logger.i(selectArr);
                          setState(() {
                            requiredProcessingMethod["dictName"] =
                                selectItem["dictName"];
                            requiredProcessingMethod["code"] =
                                selectItem["code"];
                          });
                        },
                      );
                    },
                  ),
                  ZjcFormInputCell(
                    title: "故障现象",
                    text: faultDesc,
                    maxLines: 7,
                    maxLength: 300,
                    showRedStar: true,
                    inputCallBack: (value) {
                      faultDesc = value;
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "派工方式",
                    text: completeLabel,
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: FilterData.completeStatusList,
                        isShowSearch: false,
                        title: "选择派工方式",
                        clickCallBack: (selectItem, selectArr) {
                          setState(() {
                            completeLabel = selectItem["label"];
                            completeStatus = selectItem["value"];
                          });
                        },
                      );
                    },
                  ),
                  // 自动派活组
                  if (completeStatus == 1) ...[
                    ZjcFormSelectCell(
                      title: "科室车间",
                      hintText: "请选择",
                      showRedStar: true,
                      text: workshop,
                      clickCallBack: () {
                        ZjcCascadeTreePicker.show(context,
                            isShowSearch: false,
                            data: deptTree,
                            labelKey: 'label',
                            valueKey: 'label',
                            childrenKey: 'child',
                            title: "选择科室车间",
                            clickCallBack: (selectItem, selectArr) {
                          setState(() {
                            workshop = selectItem["label"];
                            if (selectItem["children"] != null) {
                              teamTree = selectItem["children"];
                            }
                            team = "";
                          });
                        });
                      },
                    ),
                    ZjcFormSelectCell(
                      title: "班组",
                      hintText: "请选择",
                      showRedStar: true,
                      text: team,
                      clickCallBack: () {
                        if (teamTree.isEmpty) {
                          showToast("请先选择科室车间");
                        } else {
                          ZjcCascadeTreePicker.show(context,
                              isShowSearch: false,
                              data: teamTree,
                              labelKey: 'label',
                              valueKey: 'id',
                              title: "选择班组",
                              clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              team = selectItem["label"];
                              teamCode = selectItem["id"];
                            });
                            // getJtUsers();
                          });
                        }
                      },
                    ),
                    // ZjcFormSelectCell(
                    //   title: "施修人员",
                    //   hintText: "请选择",
                    //   showRedStar: true,
                    //   text: userSelected["nickName"],
                    //   clickCallBack: () {
                    //     ZjcCascadeTreePicker.show(context,
                    //       isShowSearch: false,
                    //       data: userList,
                    //       labelKey: 'nickName',
                    //       valueKey: 'userId',
                    //       title: "施修人员",
                    //       clickCallBack: (selectItem, selectArr) {
                    //         setState(() {
                    //           userSelected['nickName'] = selectItem['nickName'];
                    //           userSelected['userId'] = selectItem['userId'];
                    //         });
                    //       }
                    //     );
                    //   },
                    // ),
                  ],
                  // if(faultPics.isNotEmpty)
                  // Container(child: Image.file(faultPics[0],width: 200,height: 200,),),
                  // 图片传输
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(color: Colors.brown)),
                    child: ZjcAssetPicker(
                      assetType: APC.AssetType.image,
                      maxAssets: 1,
                      selectedAssets: assestPics,
                      // bgColor: Colors.grey,
                      callBack: (assetEntityList) async {
                        logger.i('assetEntityList-------------');
                        logger.i(assetEntityList);
                        if (assetEntityList.isNotEmpty) {
                          var asset = assetEntityList[0];
                          var pic = await asset.file;
                          logger.i(await asset.file);
                          logger.i(await asset.originFile);
                          faultPics.insert(0, pic!);
                        } else {
                          faultPics = [];
                        }
                        logger.i('assetEntityList-------------');
                      },
                    ),
                  ),
                ])
          ],
        ));
  }

  Widget _footer() {
    return SafeArea(
        child: InkWell(
      onTap: () async {
        if ((faultDesc == null ||
            repairWorkResource['code'] == "" ||
            riskLevel == null ||
            requiredProcessingMethod['code'] == "")) {
          showToast("内容未填写完");
        } else {
          var submit;
          List<Map<String, dynamic>> l = [];
          try {
            SmartDialog.showLoading();
            Map<String, dynamic> queryParameters = {
              // "faultAssumption": faultAssumption,
              "faultDescription": faultDesc,
              // "faultyComponent": componentName['configCode'],
              "machineModel": jcTypeListSelected['code'],
              // "maintenanceNotice": maintenanceNotice,
              "trainEntryCode": trainNumSelected["code"],
              "repairWorkResource": repairWorkResource["code"],
              "riskLevel": riskLevel,
              "requiredProcessingMethod": requiredProcessingMethod["code"],
              "completeStatus": completeStatus
            };
            if (completeStatus == 1) {
              queryParameters["team"] = teamCode;
              // queryParameters["repairPersonnel"] = userSelected["userId"];
            } else {
              queryParameters["team"] = Global.profile.permissions?.user.deptId;
              queryParameters["repairPersonnel"] =
                  Global.profile.permissions?.user.userId;
            }
            if (faultPics.isNotEmpty) {
              await JtApi().uploadJt(imagedata: faultPics[0]).then(
                    (value) async => {
                      if (value['data'] != null && value['data'] != "")
                        {
                          queryParameters["repairPicture"] = value['data'],
                          l.insert(0, queryParameters),
                          submit = await JtApi().uploadJt28(queryParametrs: l),
                          if (submit['data'] != null)
                            {
                              showToast("${submit['data']}"),
                              // SmartDialog.dismiss(status: SmartStatus.loading)
                            }
                        }
                      else
                        {
                          showToast("图片上传失败，请检查网络连接"),
                          // SmartDialog.dismiss(status: SmartStatus.loading)
                        }
                    },
                  );
            } else {
              log("$queryParameters");
              l.insert(0, queryParameters);
              submit = await JtApi().uploadJt28(queryParametrs: l);
              if (submit["code"] == "S_T_S003") {
                showToast("${submit['message']}");
                // SmartDialog.dismiss(status: SmartStatus.loading);
              } else {
                showToast("机统28提报失败，请检查网络连接");
                // SmartDialog.dismiss(status: SmartStatus.loading);
              }
            }
          } on DioException catch (e) {
            showToast("故障提报失败");
            logger.i(e.toString());
          } finally {
            
            SmartDialog.dismiss(status: SmartStatus.loading);
            if (submit['code'] == "S_T_S003") {
              SmartDialog.show(
                  clickMaskDismiss: false,
                  builder: (con) {
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
                          const Text(
                            "机统28提报成功",
                            style: TextStyle(fontSize: 18),
                          ),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints.expand(height: 30, width: 160),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                SmartDialog.dismiss().then(
                                    (value) => Navigator.of(context).pop());
                              },
                              label: const Text('确定'),
                              icon:
                                  const Icon(Icons.system_security_update_good_sharp),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            }
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.blueGrey[100],
        height: 50,
        child: const Text('故障提报',
            style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
    ));
  }

  Future<String> selectDate(str) async {
    DateTimePickerType dt;
    if (str == "datetime") {
      dt = DateTimePickerType.datetime;
    } else if (str == "date") {
      dt = DateTimePickerType.date;
    } else {
      dt = DateTimePickerType.time;
    }

    var val = await showBoardDateTimePicker(
      context: context,
      pickerType: dt,
    );
    if (val != null && str == "datetime") {
      String str =
          formatDate(val, [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);
      logger.i(str);
      return str;
    } else if (val != null && str == "date") {
      String str = formatDate(val, [yyyy, '-', mm, '-', dd]);
      return str;
    } else {
      return "";
    }
  }
}
