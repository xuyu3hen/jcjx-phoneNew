import '../../index.dart';

class GetWorkPackage extends StatefulWidget {
  const GetWorkPackage({super.key});

  @override
  State<GetWorkPackage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<GetWorkPackage> {
  var logger = AppLogger.logger;
  // 动态类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动态类型信息
  late Map<dynamic, dynamic> dynamciTypeSelected = {};
  //机型列表
  late List<Map<String, dynamic>> jcTypeList = [];
  // 筛选的机型列表
  late Map<String, dynamic> jcTypeListSelected = {};
  // 车号列表
  late List<Map<String, dynamic>> trainNumCodeList = [];
  // 筛选的车号信息
  late Map<dynamic, dynamic> trainNumSelected = {};
  // 作业包列表
  late WorkPackageList workPackageList = WorkPackageList(
    data: [],
  );
  // 获取用户信息
  late Permissions permissions;

  // 用于标记主修相关按钮是否正在处理操作（防止连点）
  bool _isButtonProcessing = false;

  bool mainRepairStatus = false;
  bool cancelMainRepairStatus = false;
  bool beAssistant = false;
  bool cancelAssistant = false;

  @override
  void initState() {
    super.initState();
    //初始化动力类型
    // getDynamicType();
    initData();
  }

  String getMainRepairText(WorkPackage package) {
    try {
      if (package.repairPersonnel != null &&
          package.repairPersonnel!
              .contains(permissions.user.userId.toString()) &&
          package.executorId == null) {
        return "成为主修";
      } else if (package.repairPersonnel != null &&
          package.repairPersonnel!
              .contains(permissions.user.userId.toString()) &&
          package.executorId == permissions.user.userId) {
        return "取消主修";
      } else if (package.repairPersonnel != null &&
          package.repairPersonnel!
              .contains(permissions.user.userId.toString()) &&
          package.executorId != permissions.user.userId &&
          package.executorId != null) {
        return "已经有其他主修可选人成为主修";
      } else {
        return "无法成为主修";
      }
    } catch (e, stackTrace) {
      logger.e('getMainRepairText 方法中发生异常: $e\n堆栈信息: $stackTrace');
      return "无法成为主修";
    }
  }

  String getAssistantText(WorkPackage package) {
    try {
      if (package.assistant != null &&
          package.assistant!.contains(permissions.user.userId.toString()) &&
          package.assistantId == null) {
        return "成为辅修";
      } else if (package.assistant != null &&
          package.assistant!.contains(permissions.user.userId.toString()) &&
          package.assistantId == permissions.user.userId) {
        return "取消辅修";
      } else if (package.assistant != null &&
          package.assistant!.contains(permissions.user.userId.toString()) &&
          package.assistantId != permissions.user.userId &&
          package.assistantId != null) {
        return "已经有其他辅修可选人辅修";
      } else {
        return "无法成为辅修";
      }
    } catch (e, stackTrace) {
      logger.e('getAssistantText 方法中发生异常: $e\n堆栈信息: $stackTrace');
      return "无法成为辅修";
    }
  }

Future<void> initData() async {
  try {
    // 获取动力类型列表
    var r = await ProductApi().getDynamicType();
    var permissionResponse = await LoginApi().getpermissions();

    if (r.toMapList().isEmpty) {
      logger.e('动力类型列表为空');
      return;
    }

    // 初始化动力类型选择项
    Map<String, dynamic> initDynamicTypeSelected = r.toMapList()[0];
    Map<String, dynamic> queryParameters = {
      'dynamicCode': initDynamicTypeSelected['code'],
      'pageNum': 0,
      'pageSize': 0
    };

    // 获取机型列表
    var r1 = await ProductApi().getJcType(queryParametrs: queryParameters);
    Map<String, dynamic> initJcTypeSelected = r1.toMapList()[0];
    Map<String, dynamic> queryParameters1 = {
      'typeName': initJcTypeSelected["name"],
      'pageNum': 0,
      'pageSize': 0
    };

    // 获取车号列表
    var r2 = await ProductApi().getRepairPlanList(queryParametrs: queryParameters1);
    trainNumCodeList = r2.toMapList();
    trainNumSelected = trainNumCodeList[0];

    // 构建查询作业包参数
    Map<String, dynamic> queryParameters2 = {
      'trainEntryCode': trainNumSelected["code"],
    };

    // 获取作业包
    var r3 = await ProductApi().getWorkPackage(queryParametrs: queryParameters2);
    workPackageList = r3;

    // 更新状态
    setState(() {
      dynamicTypeList = r.toMapList();
      dynamciTypeSelected = dynamicTypeList[0];
      jcTypeList = r1.toMapList();
      jcTypeListSelected = jcTypeList[0];
      permissions = permissionResponse;
    });
  } catch (e, stackTrace) {
    logger.e('initData 方法中发生异常: $e\n堆栈信息: $stackTrace');
  }
}


  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      setState(() {
        dynamicTypeList = r.toMapList();
        permissions = permissionResponse;
        logger.i(permissions.toJson());
      });
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getJcType() async {
    try {
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamciTypeSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getJcType(queryParametrs: queryParameters);
      logger.i(r.toJson());
      setState(() {
        jcTypeList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getJcType 方法中发生异常: $e\n堆栈信息: $stackTrace');
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
      //获取车号
      var r =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      setState(() {
        trainNumCodeList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getTrainNumCodeList 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 成为主修
  Future<void> beMainRepair(String code) async {
    try {
      //用code组件一个List<String>
      List<String> queryParameters = [code];

      await ProductApi().beMainRepair(queryParameters);
      // 更新状态为已成为主修
      setState(() {
        getWorkPackage();
      });
    } catch (e, stackTrace) {
      logger.e('beMainRepair 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 取消主修
  Future<void> cancelMainRepair(String code) async {
    try {
      //构建取消主修参数
      List<String> queryParameters = [code];
      await ProductApi().cancelMainRepair(queryParameters);
      // 更新状态为已取消主修
      getWorkPackage();
    } catch (e, stackTrace) {
      logger.e('cancelMainRepair 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //成为辅修
  Future<void> beAssistantRepair(String code) async {
    try {
      //构建成为辅修参数
      List<String> queryParameters = [code];
      await ProductApi().beAssistantRepair(queryParameters);
      getWorkPackage();
    } catch (e, stackTrace) {
      logger.e('beAssistantRepair 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //取消辅修
  Future<void> cancelAssistantRepair(String code) async {
    try {
      //构建成为辅修参数
      List<String> queryParameters = [code];
      await ProductApi().cancelAssistantRepair(queryParameters);
      getWorkPackage();
    } catch (e, stackTrace) {
      logger.e('cancelAssistantRepair 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //获取作业包
  Future<void> getWorkPackage() async {
    try {
      //构建查询作业包参数
      Map<String, dynamic> queryParameters = {
        'trainEntryCode': trainNumSelected["code"],
      };
      //获取作业包
      var r =
          await ProductApi().getWorkPackage(queryParametrs: queryParameters);

      setState(() {
        workPackageList = r;
        logger.i(workPackageList.toJson());
      });
    } catch (e, stackTrace) {
      logger.e('getWorkPackage 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("领取作业包"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                        setState(() {
                          dynamciTypeSelected["code"] = selectItem["code"];
                          dynamciTypeSelected["name"] = selectItem["name"];
                          getJcType();
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
                      title: "选择车号",
                      clickCallBack: (selectItem, selectArr) {
                        setState(() {
                          logger.i(selectArr);
                          trainNumSelected["trainNum"] = selectItem["trainNum"];
                          trainNumSelected["code"] = selectItem["code"];
                          getWorkPackage();
                        });
                      },
                    );
                  }
                },
              ),
              Column(
                children: (workPackageList.data != null &&
                        workPackageList.data!.isNotEmpty)
                    ? workPackageList.data!
                        .map((package) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              width: MediaQuery.of(context).size.width - 32,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    package.name ?? '',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  // 先展示主修、辅修信息的行
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '主修：${package.executorName ?? ''}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          '辅修：${package.assistantName ?? ''}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // 再展示成为主修、成为辅修按钮的行
                                  Row(
                                    children: [
                                      // 根据repairPersonnelNameList字段判断是否显示成为主修按钮，并添加相关逻辑

                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (_isButtonProcessing) {
                                              return; // 如果按钮正在处理操作（防止连点），直接返回不执行
                                            }
                                            _isButtonProcessing =
                                                true; // 设置按钮为正在处理状态
                                            //如果这个用户的ID在这个repairPersonnal中
                                            //而且主修的用户ID为空
                                            bool mainRepairStatus =
                                                package.repairPersonnel !=
                                                        null &&
                                                    package.repairPersonnel!
                                                        .contains(permissions
                                                            .user.userId
                                                            .toString()) &&
                                                    package.executorId == null;
                                            //用户id在repairPersonnel中而且executorId为该用户ID
                                            bool cancelMainRepairStatus =
                                                package.repairPersonnel !=
                                                        null &&
                                                    package.repairPersonnel!
                                                        .contains(permissions
                                                            .user.userId
                                                            .toString()) &&
                                                    package.executorId ==
                                                        permissions.user.userId;

                                            if (mainRepairStatus) {
                                              // 如果当前不是主修状态，则调用成为主修接口
                                              beMainRepair(package.code ?? '');
                                              setState(() {
                                                getWorkPackage();
                                              });
                                            } else if (cancelMainRepairStatus) {
                                              // 如果已经是主修状态，调用取消主修接口
                                              cancelMainRepair(
                                                  package.code ?? '');
                                              setState(() {
                                                getWorkPackage();
                                              });
                                            }
                                            _isButtonProcessing = false;
                                          },
                                          child:
                                              Text(getMainRepairText(package)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // 根据assistantNameList字段判断是否显示成为辅修按钮，并添加相关逻辑
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            bool beAssistant =
                                                package.assistant != null &&
                                                    package.assistant!.contains(
                                                        permissions.user.userId
                                                            .toString()) &&
                                                    package.assistantId == null;
                                            bool cancelAssistant =
                                                package.assistant != null &&
                                                    package.assistant!.contains(
                                                        permissions.user.userId
                                                            .toString()) &&
                                                    package.assistantId ==
                                                        permissions.user.userId;
                                            if (beAssistant) {
                                              // 如果当前不是辅修状态，则调用成为辅修接口
                                              beAssistantRepair(
                                                  package.code ?? '');
                                              setState(() {
                                                getWorkPackage();
                                              });
                                            } else if (cancelAssistant) {
                                              // 如果已经是辅修状态，调用取消辅修接口
                                              cancelAssistantRepair(
                                                  package.code ?? '');
                                              setState(() {
                                                getWorkPackage();
                                              });
                                            }
                                          },
                                          child:
                                              Text(getAssistantText(package)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList()
                    : [const Text("暂无作业包信息")],
              )
            ],
          ),
        ],
      ),
    );
  }
}
