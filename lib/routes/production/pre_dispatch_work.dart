import '../../index.dart';

class PreDispatchWork extends StatefulWidget {
  const PreDispatchWork({super.key});

  @override
  State<PreDispatchWork> createState() => _PreDispatchWorkState();
}

class _PreDispatchWorkState extends State<PreDispatchWork> {
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
  late List<Map<String, dynamic>> deptList = [];
  // 筛选科室车间
  late Map<String, dynamic> deptSelected = {};
  // 班组列表
  late List<Map<String, dynamic>> groupList = [];
  // 筛选班组
  late Map<String, dynamic> groupSelected = {};
  // 工序节点列表
  late List<Map<String, dynamic>> procNodeList = [];
  // 工序节点筛选信息
  late Map<String, dynamic> procNodeSelected = {'name': '', 'code': ''};

  // 将作业包进行展示
  late List<PackageUserDTOList>? packageUserDTOList = [];

  // 获取用户信息
  late Permissions permissions;

  late PackageUserDTOList? selectedPackage = null;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getDept();
  }

  void initData() async {
    getDynamicType();
  }

  // 获取科室车间
  void getDept() async {
    try {
      Map<String, dynamic> queryParameters = {
        'parentIdList': "231,232,233,234,235,236,237,230",
      };
      var r = await ProductApi()
          .getDeptTreeByParentIdList(queryParametrs: queryParameters);
      if (mounted) {
        setState(() {
          //将 List<dynamic> 转为 List<Map<String, dynamic>>
          if (r != null) {
            if (r is List) {
              deptList = r.map((item) => item as Map<String, dynamic>).toList();
            } else if (r is Map<String, dynamic>) {
              deptList = [r];
            } else {
              deptList = [];
            }
          } else {
            deptList = [];
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('getDept 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
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

  //获取工序节点
  void getRepairMainNode() async {
    try {
      //对工序节点进行查询
      Map<String, dynamic> queryParameters = {
        'repairProcCode': repairSelected["code"],
        'pageNum': 0,
        'pageSize': 0,
        'deptIds': deptSelected["deptId"]
      };
      var r = await ProductApi()
          .getRepairMainNodeAll(queryParametrs: queryParameters);
      if (r.rows != null) {
        if (mounted) {
          setState(() {
            //将获取的信息列表
            procNodeList = r.toMapList();
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('getRepairMainNode 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //同步作业包
  void syncWorkPackageToPackageUser() async {
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': jcTypeListSelected["code"],
        'deptId': deptSelected["deptId"],
        'repairTimes': repairTimesSelected["name"],
        'repairMainNodeCode': procNodeSelected["code"],
      };
      logger.i(queryParameters);
      await ProductApi()
          .syncWorkPackageToPackageUser(queryParametrs: queryParameters);
    } catch (e, stackTrace) {
      logger.e('syncWorkPackageToPackageUser 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //获取作业包
  void getWorkPackage() async {
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': jcTypeListSelected["code"],
        'deptId': groupSelected["deptId"],
        'repairTimes': repairTimesSelected["name"],
        'repairMainNodeCode': procNodeSelected["code"],
      };
      logger.i(queryParameters);
      var r =
          await JtApi().getPackageUserList(queryParameters: queryParameters);
      if (mounted) {
        setState(() {
          packageUserDTOList = [];
          if (r.data != null && r.data!.isNotEmpty) {
            //将获取的信息列表
            //将r.data进行遍历,获取相关信息进行展示
            for (PackageUser item in r.data!) {
              logger.i(item.packageUserDTOList!.length);
              packageUserDTOList?.addAll(item.packageUserDTOList!);
            }
          }
          // 如果没有数据，packageUserDTOList 保持为空列表
        });
      }
    } catch (e, stackTrace) {
      logger.e('getWorkPackage 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机车修程预派工'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                // 对科室车间进行筛选
                ZjcFormSelectCell(
                  title: "科室车间",
                  text: deptSelected["deptName"] ?? '',
                  hintText: "请选择",
                  showRedStar: true,
                  clickCallBack: () {
                    if (deptList.isEmpty) {
                      showToast("无科室车间");
                    } else {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: deptList,
                        labelKey: 'deptName',
                        valueKey: 'deptId',
                        title: "选择科室车间",
                        childrenKey: 'children1',
                        clickCallBack: (selectItem, selectArr) {
                          if (mounted) {
                            setState(() {
                              logger.i(selectArr);
                              deptSelected["deptName"] = selectItem["deptName"];
                              deptSelected["deptId"] = selectItem["deptId"];

                              if (selectItem["children"] != null &&
                                  selectItem["children"] is List) {
                                groupList = (selectItem["children"] as List)
                                    .map((item) => item is Map<String, dynamic>
                                        ? item
                                        : Map<String, dynamic>.from(
                                            item as Map))
                                    .toList();
                              } else {
                                groupList = [];
                              }
                              getRepairMainNode();
                            });
                          }
                        },
                      );
                    }
                  },
                ),
                // 对班组进行筛选
                ZjcFormSelectCell(
                  title: "班组",
                  text: groupSelected["deptName"] ?? '',
                  hintText: "请选择",
                  showRedStar: true,
                  clickCallBack: () {
                    if (groupList.isEmpty) {
                      showToast("无班组信息");
                    } else {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: groupList,
                        labelKey: 'deptName',
                        valueKey: 'deptId',
                        childrenKey: 'children',
                        title: "选择班组",
                        clickCallBack: (selectItem, selectArr) {
                          if (mounted) {
                            setState(() {
                              logger.i(selectArr);
                              groupSelected["deptName"] =
                                  selectItem["deptName"];
                              groupSelected["deptId"] = selectItem["deptId"];
                            });
                          }
                        },
                      );
                    }
                  },
                ),
                //对工序节点进行查询
                ZjcFormSelectCell(
                  title: "工序节点",
                  text: procNodeSelected["name"] ?? '',
                  hintText: "请选择",
                  showRedStar: true,
                  clickCallBack: () {
                    if (procNodeList.isEmpty) {
                      showToast("无工序节点信息");
                    } else {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: procNodeList,
                        labelKey: 'name',
                        valueKey: 'code',
                        childrenKey: 'children',
                        title: "选择工序节点",
                        clickCallBack: (selectItem, selectArr) {
                          if (mounted) {
                            setState(() {
                              logger.i(selectArr);
                              procNodeSelected["name"] = selectItem["name"];
                              //将主键进行选取
                              procNodeSelected["code"] = selectItem["code"];
                              getWorkPackage();
                            });
                          }
                        },
                      );
                    }
                  },
                ),
                // 通过搜索按钮 查看作业包  
                
                                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(children: [
                    ElevatedButton(
                      onPressed: () {
                        // 检查必要条件是否已选择
                        if (jcTypeListSelected["code"] == null || 
                            jcTypeListSelected["code"] == '') {
                          showToast("请选择机型");
                          return;
                        }
                        if (repairTimesSelected["code"] == null || 
                            repairTimesSelected["code"] == '') {
                          showToast("请选择修次");
                          return;
                        }
                        if (procNodeSelected["code"] == null || 
                            procNodeSelected["code"] == '') {
                          showToast("请选择工序节点");
                          return;
                        }
                        
                        getWorkPackage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 70, 130, 180), // 设置按钮颜色为钢蓝色
                        minimumSize: const Size(
                            double.infinity, 60), // 设置按钮宽度为屏幕宽度，高度为60
                      ),
                      child: const Text('搜索作业包'),
                    ),
                  ]),
                ),
                //展示同步作业包按钮 使用正常绿色按钮
                Container(
                    width: MediaQuery.of(context).size.width,
                    // 去掉高度的固定计算，让列表自适应内容
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(children: [
                      ElevatedButton(
                        onPressed: () {
                          syncWorkPackageToPackageUser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                              255, 146, 231, 147), // 设置按钮颜色为绿色
                          minimumSize: const Size(
                              double.infinity, 60), // 设置按钮宽度为屏幕宽度，高度为60
                        ),
                        child: const Text('同步作业包'),
                      ),
                    ])),
                
            

                  // 将packageUserDTOList进行展示
                  Container(
                    width: MediaQuery.of(context).size.width,
                    // 去掉高度的固定计算，让列表自适应内容
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        // 数据行
                        ...(packageUserDTOList?.map((packageUserDTO) {
                              String station = packageUserDTO.station ?? '';
                              String mainRepair = packageUserDTO
                                          .workInstructPackageUserList
                                          ?.isNotEmpty ==
                                      true
                                  ? packageUserDTO
                                          .workInstructPackageUserList![0]
                                          .repairPersonnelName ??
                                      ''
                                  : '';
                              String assistant = packageUserDTO
                                          .workInstructPackageUserList
                                          ?.isNotEmpty ==
                                      true
                                  ? packageUserDTO
                                          .workInstructPackageUserList![0]
                                          .assistantName ??
                                      ''
                                  : '';
                              return InkWell(
                                onTap: () {
                                  // 点击事件处理函数，跳转到新的界面
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PreWorkList(
                                        packageUserDTO: packageUserDTO,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 100, // 减少容器高度
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.blue),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5), // 调整内边距
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value:
                                            selectedPackage == packageUserDTO,
                                        onChanged: (value) {
                                          if (mounted) {
                                            setState(() {
                                              if (value!) {
                                                selectedPackage =
                                                    packageUserDTO;
                                              } else {
                                                selectedPackage = null;
                                              }
                                            });
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Wrap(
                                              spacing: 8, // 调整间距
                                              runSpacing: 4, // 调整行间距
                                              children: [
                                                // 增加序号中文
                                                Text(
                                                  '序号 ${packageUserDTOList!.indexOf(packageUserDTO) + 1}',
                                                  style: const TextStyle(
                                                      fontSize: 16), // 放大文字
                                                ),
                                                Text(
                                                  '作业包 ${packageUserDTO.packageName ?? ''}',
                                                  style: const TextStyle(
                                                      fontSize: 16), // 放大文字
                                                ),
                                                Text(
                                                  '工位 $station',
                                                  style: const TextStyle(
                                                      fontSize: 16), // 放大文字
                                                ),
                                                Text(
                                                  '主修 $mainRepair',
                                                  style: const TextStyle(
                                                      fontSize: 16), // 放大文字
                                                ),
                                                Text(
                                                  '辅修 $assistant',
                                                  style: const TextStyle(
                                                      fontSize: 16), // 放大文字
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList() ??
                            []),
                      ],
                    ),
                  )
              ],
            ),
          ],
        ),

        // 使用 Positioned 将设置施修人按钮固定在屏幕底部
        if (selectedPackage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetRepairPersonScreen(
                      packageUserDTO: selectedPackage!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 设置按钮颜色为蓝色
                minimumSize:
                    const Size(double.infinity, 60), // 设置按钮宽度为屏幕宽度，高度为60
              ),
              child: const Text('设置施修人'),
            ),
          ),
      ],
    );
  }
}

class SetRepairPersonScreen extends StatefulWidget {
  final PackageUserDTOList packageUserDTO;

  const SetRepairPersonScreen({Key? key, required this.packageUserDTO})
      : super(key: key);

  @override
  State createState() => _SetRepairPersonScreenState();
}

class _SetRepairPersonScreenState extends State<SetRepairPersonScreen> {
  late List<dynamic> userList = [];
  // 用于存储主修
  late List<int> mainUsers = [];
  // 用于存储辅修
  late List<int> assistantUsers = [];
  // 存储主修名称
  late List<String> mainUsersName = [];
  // 存储辅修名称
  late List<String> assistantUsersName = [];

  var logger = AppLogger.logger;
  // 获取班组成员
  void getUserList() async {
    Map<String, dynamic> queryParameters = {
      'pageNum': 0,
      'pageSize': 0,
      'deptId': Global.profile.permissions!.user.deptId
    };
    var r = await JtApi().getUserList(queryParametrs: queryParameters);
    if (r['code'] == 200) {
      if (mounted) {
        setState(() {
          userList = r['rows'];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getUserList(); // 在初始化时调用 getUserList 方法
    mainUsers = [];
    assistantUsers = [];
    mainUsersName = [];
    assistantUsersName = [];
    // Bug 修复：添加闭合括号
    WorkInstructPackageUserList item =
        widget.packageUserDTO.workInstructPackageUserList![0];
    String? repairName = item.repairPersonnelName;
    //对repairName进行分割赋值
    if (repairName != null && repairName != '') {
      List<String> repairNameList = repairName.split(',');
      for (String item1 in repairNameList) {
        mainUsersName.add(item1);
      }
    }
    String? assistantName = item.assistantName;
    //对assistantName进行分割赋值
    if (assistantName != null && assistantName != '') {
      List<String> assistantNameList = assistantName.split(',');
      for (String item1 in assistantNameList) {
        assistantUsersName.add(item1);
      }
    }
    String? repair = item.repairPersonnel;
    // repair格式为'1129,1130'将其转化为[1129,1130]
    if (repair != null && repair != '') {
      List<String> repairList = repair.split(',');
      for (String item1 in repairList) {
        mainUsers.add(int.parse(item1));
      }
    }
    logger.i(mainUsers.toString());
    String? assistant = item.assistant;
    logger.i(assistant);
    if (assistant != null && assistant != '') {
      List<String> assistantList = assistant.split(',');
      for (String assistant in assistantList) {
        logger.i(assistant);
        assistantUsers.add(int.parse(assistant));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置施修人'),
      ),
      body: Column(
        children: [
          const Text("主修"),
          Expanded(
            child: userList.isNotEmpty
                ? ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      var user = userList[index];
                      return CheckboxListTile(
                        title: Text(user['nickName']),
                        value: mainUsers.contains(user['userId']),
                        onChanged: (bool? value) {
                          if (mounted) {
                            setState(() {
                              if (value!) {
                                mainUsers.add(user['userId']);
                                mainUsersName.add(user['nickName']);
                              } else {
                                mainUsers.remove(user['userId']);
                                mainUsersName.remove(user['nickName']);
                              }
                            });
                          }
                        },
                        // 添加其他需要展示的用户信息
                      );
                    },
                  )
                : const CircularProgressIndicator(), // 显示加载指示器
          ),
          const Text("辅修"),
          Expanded(
            child: userList.isNotEmpty
                ? ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      var user = userList[index];
                      return CheckboxListTile(
                        title: Text(user['nickName']),
                        value: assistantUsers.contains(user['userId']),
                        onChanged: (bool? value) {
                          if (mounted) {
                            setState(() {
                              if (value!) {
                                assistantUsers.add(user['userId']);
                                assistantUsersName.add(user['nickName']);
                              } else {
                                assistantUsers.remove(user['userId']);
                                assistantUsersName.remove(user['nickName']);
                              }
                            });
                          }
                        },
                        // 添加其他需要展示的用户信息
                      );
                    },
                  )
                : const CircularProgressIndicator(), // 显示加载指示器
          ),
        ],
      ),
      // 最底部放一个保存按钮
      floatingActionButton: FloatingActionButton(
        tooltip: '保存', // 修改提示文本为“保存”
        onPressed: () {
          // 在这里处理保存按钮的点击事件
          save();
        },
        child: const Icon(Icons.save), // 修改图标为保存图标
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 将按钮位置设置为右下角
    );
  }

  //保存施修人
  void save() async {
    // 遍历mainUsers和assistantUsers，将其转化为字符串
    String mainUsersStr = mainUsers.join(',');
    String assistantUsersStr = assistantUsers.join(',');
    //名称转换为字符串
    String mainUsersNameStr = mainUsersName.join(',');
    String assistantUsersNameStr = assistantUsersName.join(',');
    //打印结果
    logger.i(mainUsersStr);
    logger.i(mainUsersNameStr);
    //对所有作业项遍
    //将结果转换为List<Map<String, dynamic>>
    List<Map<String, dynamic>> list = [];
    for (WorkInstructPackageUserList item
        in widget.packageUserDTO.workInstructPackageUserList!) {
      item.repairPersonnel = mainUsersStr;
      item.assistant = assistantUsersStr;
      item.repairPersonnelName = mainUsersNameStr;
      item.assistantName = assistantUsersNameStr;
      // print(item.toJson());
      list.add(item.toJson());
    }
    if (mounted) {
      ProductApi().saveAssociated(list);
      //清空mainUsers和assistantUsers和mainUsersName和assistantUsersName
      showToast('主修辅修保存成功');
      Navigator.pop(context, true);
    }
  }
}

class PreWorkList extends StatefulWidget {
  final PackageUserDTOList packageUserDTO;

  const PreWorkList({Key? key, required this.packageUserDTO}) : super(key: key);

  @override
  State createState() => _PreWorkListState();
}

class _PreWorkListState extends State<PreWorkList> {
  // 用于存储已勾选的作业项
  List<WorkInstructPackageUserList> selectedWorkItems = [];

  @override
  Widget build(BuildContext context) {
    // 获取packageUserDTO中workInstructPackageUserList
    List<WorkInstructPackageUserList>? workInstructPackageUserList =
        widget.packageUserDTO.workInstructPackageUserList;

    // 获取packageUserDTO中wholePackage用于判断是否需要点击一个之后将作业项全部勾选，取消一个全部取消
    bool wholePackage = widget.packageUserDTO.wholePackage!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('作业项点'),
      ),
      body: ListView.builder(
        itemCount: workInstructPackageUserList?.length ?? 0,
        itemBuilder: (context, index) {
          WorkInstructPackageUserList workInstructPackageUser =
              workInstructPackageUserList![index];
          String workItem = workInstructPackageUser.name ?? '';
          String riskLevel = workInstructPackageUser.riskLevel ?? '';
          String mutualCheck =
              workInstructPackageUser.mutualPersonnelName ?? '';
          String specialCheck =
              workInstructPackageUser.specialPersonnelName ?? '';

          return Container(
            width: MediaQuery.of(context).size.width,
            height: 150,
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Checkbox(
                  value: selectedWorkItems.contains(workInstructPackageUser),
                  onChanged: (bool? value) {
                    if (mounted) {
                      setState(() {
                        // 如果是全选，将所有作业项勾选
                        if (value! && wholePackage) {
                          selectedWorkItems = workInstructPackageUserList;
                        } else if (value && !wholePackage) {
                          selectedWorkItems.add(workInstructPackageUser);
                        } else if (!value && wholePackage) {
                          selectedWorkItems = [];
                        } else {
                          selectedWorkItems.remove(workInstructPackageUser);
                        }
                      });
                    }
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '作业项 $workItem',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '风险等级 $riskLevel',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '互检人员 $mutualCheck',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '专检人员 $specialCheck',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // 如果有勾选的作业项，显示设置专检按钮
      bottomNavigationBar: selectedWorkItems.isNotEmpty
          ? Container(
              height: 50,
              color: Colors.blue,
              child: TextButton(
                onPressed: () {
                  // 处理设置专检的逻辑
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetSpecialCheck(
                        selectedWorkItems: selectedWorkItems,
                      ),
                    ),
                  );
                },
                child: const Text(
                  '设置专互检',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            )
          : null,
    );
  }
}
