import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SecEnterModifyNew extends StatefulWidget {
  const SecEnterModifyNew({Key? key}) : super(key: key);

  @override
  State createState() => _SecEnterModifyStateNew();
}

class _SecEnterModifyStateNew extends State<SecEnterModifyNew> {
  // 创建 Logger 实例
  var logger = AppLogger.logger;
  // 动力类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动力类型信息
  late Map<dynamic, dynamic> dynamicTypeSelected = {};
  // 机型列表
  late List<Map<String, dynamic>> jcTypeList = [];
  // 筛选的机型列表
  late Map<String, dynamic> jcTypeListSelected = {};
  // 修制列表
  late List<Map<String, dynamic>> repairSysList = [];
  //筛选的修制
  late Map<String, dynamic> repairSysSelected = {};
  // 修程列表
  late List<Map<String, dynamic>> repairList = [];
  // 筛选的修程
  late Map<String, dynamic> repairSelected = {};
  // 修次列表
  late List<Map<String, dynamic>> repairTImesList = [];
  // 筛选修次
  late Map<String, dynamic> repairTimesSelected = {};
  //科室车间列表
  late List<dynamic> deptList = [];
  // 筛选科室车间
  late Map<String, dynamic> deptSelected = {};
  // 班组列表
  late List<dynamic> groupList = [];
  // 筛选班组
  late Map<String, dynamic> groupSelected = {};
  // 工序节点列表
  late List<Map<String, dynamic>> procNodeList = [];
  // 工序节点筛选信息
  late Map<String, dynamic> procNodeSelected = {'name': '', 'code': ''};

  //   // 车号筛选信息
  // late Map<dynamic, dynamic> trainNumSelected = {};

  // 将作业包进行展示
  late List<PackageUserDTOList>? packageUserDTOList = [];

  // 获取用户信息
  late Permissions permissions;

  late PackageUserDTOList? selectedPackage;

  // 检修地点
  late List<Map<String, dynamic>> stopLocationList = [];
  // 存储选择的检修地点信息
  late Map<dynamic, dynamic> stopLocationSelected = {};

  // 车号列表
  late List<Map<String, dynamic>> trainNumCodeList = [];
  // 筛选的车号信息
  late Map<dynamic, dynamic> trainNumSelected = {};

  late String trainNum = '';

  // 图片传输相关变量定义
  List<AssetEntity> assestPics = [];
  List<File> faultPics = [];

  // 提报状态，true 表示正在提报
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getStopLocation();
  }

  // 获取动态类型
  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      if (mounted) {
        setState(() {
          dynamicTypeList = r.toMapList();
          permissions = permissionResponse;
          logger.i(permissions.toJson());
        });
      }
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 获取机型
  void getJcType() async {
    try {
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamicTypeSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getJcType(queryParametrs: queryParameters);
      logger.i(r.toJson());
      if (mounted) {
        setState(() {
          jcTypeList = r.toMapList();
          getRepairSys();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getJcType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 获取修制信息
  Future<void> getRepairSys() async {
    try {
      logger.i(dynamicTypeSelected["code"]);
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamicTypeSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r =
          await ProductApi().selectRepairSys(queryParametrs: queryParameters);
      setState(() {
        logger.i(r.rows!.length);
        repairSysList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getRepairSys 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 修次
  void getRepairProc() async {
    try {
      Map<String, dynamic> queryParameters = {
        'repairSysCode': repairSysSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
      if (r.rows != []) {
        if (mounted) {
          setState(() {
            //将获取的信息列表
            repairList = r.toMapList();
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('getRepairProc 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //修次查询
  void getRepairTimes() async {
    try {
      Map<String, dynamic> queryParameters = {
        'repairProcCode': repairSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r =
          await ProductApi().getRepairTimes(queryParametrs: queryParameters);
      if (r.rows != []) {
        if (mounted) {
          setState(() {
            //将获取的信息列表
            repairTImesList = r.toMapList();
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('getRepairTimes 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 获取检修地点
  void getStopLocation() async {
    try {
      var r = await ProductApi().getstopLocation({
        'pageNum': 1,
        'pageSize': 10,
      });
      List<Map<String, dynamic>> processedStopLocations = [];
      if (r.rows != null && r.rows!.isNotEmpty) {
        for (var item in r.rows!) {
          if (item.areaName != null &&
              item.deptName != null &&
              item.trackNum != null) {
            processedStopLocations.add({
              'code': item.code,
              'deptName': item.deptName,
              'realLocation':
                  '${item.deptName}-${item.trackNum}-${item.areaName}'
            });
          }
        }
      }
      setState(() {
        stopLocationList = processedStopLocations;
        logger.i(stopLocationList);
      });
    } catch (e, stackTrace) {
      logger.e('initSelectInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getTrainNumCodeList() async {
    try {
      //构建查询车号参数
      Map<String, dynamic> queryParameters = {
        'typeName': jcTypeListSelected["name"],
        'pageNum': 0,
        'pageSize': 0
      };
      logger.i(queryParameters);
      //获取车号
      var r =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      if (mounted) {
        setState(() {
          trainNumCodeList = r.toMapList();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getTrainNumCodeList 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机车入段'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _footer(),
    );
  }

  // 上传防溜函数
  Future<dynamic> uploadSlip(val) async {
    if (faultPics.isNotEmpty) {
      var file = faultPics[0];
      logger.i(file);
      logger.i('val' + val);
      var r = await ProductApi().upSlipImg(
          queryParametrs: {"trainEntryCode": val}, imagedata: File(file.path));
      if (r == 200) {
        showToast("上传成功");
        SmartDialog.dismiss();
        // _image = null;
        // widget.updateList.call();
      }
    }
  }

  Future<String> newEntry() async {
    try {
      if (isSubmitting) {
        return ""; // 如果正在提报，直接返回空字符串
      }
      setState(() {
        isSubmitting = true; // 开始提报，设置状态为正在提报
      });
      Map<String, dynamic> queryParameter = {
        'dynamicCode': dynamicTypeSelected["code"],
        'dynamicName': dynamicTypeSelected["name"],
        'typeCode': jcTypeListSelected["code"],
        'trainNum': trainNumSelected['trainNum'],
        'trainNumCode': trainNumSelected['code'],
        'repairTimes': repairTimesSelected["name"],
        'repairProcName': repairSelected['name'],
        'repairProcCode': repairSelected['code'],
        'repairLocation': stopLocationSelected["code"],
      };
      try {
        var r = await ProductApi().trainEntrySave(queryParameter);
        if (r["code"] == "S_F_S000") {
          logger.i("trainEntrySave success: ${r['data']['code']}");

          if (r['data'] == null || r['data']['code'] == null) {
            logger.e('trainEntrySave data or code is null');
            showToast("基础信息保存成功，但缺少必要数据无法上传图片");
            return "";
          }

          if (faultPics.isEmpty) {
            logger.w('没有选择图片，跳过上传');
            showToast("基础信息保存成功，但未选择图片");
            return r["code"];
          }

          try {
            SmartDialog.showLoading(msg: '正在上传图片...');
            await uploadSlip(r['data']['code']);
            showToast("新增入修成功");
            return r["code"];
          } catch (e, stackTrace) {
            logger.e('uploadSlip 发生异常: $e\n堆栈信息: $stackTrace');
            showToast("图片上传失败，但基础信息已保存");
            return "";
          } finally {
            SmartDialog.dismiss();
          }
        } else {
          showToast("新增入修失败");
          return "";
        }
      } finally {
        setState(() {
          isSubmitting = false; // 提报结束，设置状态为未提报
        });
      }
    } catch (e, stackTrace) {
      logger.e('initSelectInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
      return "错误";
    }
  }

  Widget _buildBody() {
    return Stack(children: [
      ListView(children: [
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          ZjcFormInputCell(
            title: "车号",
            hintText: "请输入车号",
            showRedStar: true,
            rightWidget: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            inputCallBack: (value) {
              setState(() {
                trainNumSelected["trainNum"] = value;
              });
            },
          ),

          // ZjcFormSelectCell(
          //   title: "车号",
          //   text: trainNumSelected["trainNum"],
          //   hintText: "请选择",
          //   showRedStar: true,
          //   clickCallBack: () {
          //     if (trainNumCodeList.isEmpty) {
          //       showToast("无车号可以选择");
          //     } else {
          //       ZjcCascadeTreePicker.show(
          //         context,
          //         data: trainNumCodeList,
          //         labelKey: 'trainNum',
          //         valueKey: 'code',
          //         childrenKey: 'children',
          //         title: "选择车号",
          //         clickCallBack: (selectItem, selectArr) {
          //           setState(() {
          //             logger.i(selectArr);
          //             trainNumSelected["trainNum"] = selectItem["trainNum"];
          //             trainNumSelected["code"] = selectItem["code"];
          //           });
          //         },
          //       );
          //     }
          //   },
          // ),
          //配属段信息上传
          // ZjcFormSelectCell(),
          ZjcFormSelectCell(
            title: "动力类型",
            text: dynamicTypeSelected["name"] ?? '',
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (dynamicTypeList.isEmpty) {
                showToast("无动力类型选择");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: dynamicTypeList,
                  labelKey: 'name',
                  valueKey: 'code',
                  childrenKey: 'children',
                  title: "选择动力类型",
                  clickCallBack: (selectItem, selectArr) {
                    logger.i(selectArr);
                    if (mounted) {
                      setState(() {
                        dynamicTypeSelected["code"] = selectItem["code"];
                        dynamicTypeSelected["name"] = selectItem["name"];
                        getJcType();
                      });
                    }
                  },
                );
              }
            },
          ),
          ZjcFormSelectCell(
            title: "机型",
            text: jcTypeListSelected["name"] ?? '',
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
                    if (mounted) {
                      setState(() {
                        logger.i(selectArr);
                        jcTypeListSelected["name"] = selectItem["name"];
                        jcTypeListSelected["code"] = selectItem["code"];
                        // getTrainNumCodeList();
                        // 在这里添加获取车号等后续逻辑，如果有的话
                      });
                    }
                  },
                );
              }
            },
          ),

          // 修制筛选
          ZjcFormSelectCell(
            title: "修制",
            text: repairSysSelected["name"] ?? '',
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (repairSysList.isEmpty) {
                showToast("无修制信息");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: repairSysList,
                  labelKey: 'name',
                  valueKey: 'code',
                  childrenKey: 'children',
                  title: "选择修制",
                  clickCallBack: (selectItem, selectArr) {
                    if (mounted) {
                      setState(() {
                        logger.i(selectArr);
                        repairSysSelected["name"] = selectItem["name"];
                        //将主键进行选取
                        repairSysSelected["code"] = selectItem["code"];
                        //获取修程信息
                        getRepairProc();
                      });
                    }
                  },
                );
              }
            },
          ),
          //修程筛选框
          ZjcFormSelectCell(
            title: "修程",
            text: repairSelected["name"] ?? '',
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (repairList.isEmpty) {
                showToast("无修程信息");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: repairList,
                  labelKey: 'name',
                  valueKey: 'code',
                  childrenKey: 'children',
                  title: "选择修程",
                  clickCallBack: (selectItem, selectArr) {
                    if (mounted) {
                      setState(() {
                        logger.i(selectArr);
                        repairSelected["name"] = selectItem["name"];
                        //将主键进行选取
                        repairSelected["code"] = selectItem["code"];
                        getRepairTimes();
                        // getRepairMainNode();
                      });
                    }
                  },
                );
              }
            },
          ),
          //修次筛选框
          ZjcFormSelectCell(
            title: "修次",
            text: repairTimesSelected["name"] ?? '',
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (repairTImesList.isEmpty) {
                showToast("无修次信息");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: repairTImesList,
                  labelKey: 'name',
                  valueKey: 'code',
                  childrenKey: 'children',
                  title: "选择修次",
                  clickCallBack: (selectItem, selectArr) {
                    if (mounted) {
                      setState(() {
                        logger.i(selectArr);
                        repairTimesSelected["name"] = selectItem["name"];
                        //将主键进行选取
                        repairTimesSelected["code"] = selectItem["code"];
                      });
                    }
                  },
                );
              }
            },
          ),
          // 车号填写

          ZjcFormSelectCell(
            title: "检修地点",
            text: stopLocationSelected["realLocation"],
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (stopLocationList.isEmpty) {
                showToast("无检修地点可选择");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: stopLocationList,
                  labelKey: 'realLocation',
                  valueKey: 'code',
                  childrenKey: 'children',
                  title: "选择检修地点",
                  clickCallBack: (selectItem, selectArr) {
                    setState(() {
                      logger.i(selectArr);
                      stopLocationSelected["code"] = selectItem["code"];
                      stopLocationSelected["realLocation"] =
                          selectItem["realLocation"];
                    });
                  },
                );
              }
            },
          ),
          // 在_buildBody()方法中的图片选择器组件
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: Colors.brown)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('防溜图片',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ZjcAssetPicker(
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
              ],
            ),
          ),
        ])
      ])
    ]);
  }

  Widget _footer() {
    return SafeArea(
      child: InkWell(
        onTap: () async {
          if (isSubmitting) return; // 如果正在提报，不处理点击事件
          newEntry().then((code) {
            if (code != "") {
              exitDialog();
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.lightBlue[200],
          height: 50,
          child: isSubmitting
              ? const CircularProgressIndicator() // 显示加载指示器
              : const Text('新 增 入 段',
                  style: TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }

  void exitDialog() {
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
                "机车入段提报成功",
                style: TextStyle(fontSize: 18),
              ),
              ConstrainedBox(
                constraints:
                    const BoxConstraints.expand(height: 30, width: 160),
                child: ElevatedButton.icon(
                  onPressed: () {
                    SmartDialog.dismiss()
                        .then((value) => Navigator.of(context).pop());
                  },
                  label: const Text('确定'),
                  icon: const Icon(Icons.system_security_update_good_sharp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
