import 'dart:convert';

import 'package:jcjx_phone/routes/production/getWorkPackage.dart';

import '../../index.dart';

class PreDispatchWork extends StatefulWidget {
  const PreDispatchWork({super.key});

  @override
  State<PreDispatchWork> createState() => _PreDispatchWorkState();
}

class _PreDispatchWorkState extends State<PreDispatchWork> {
  // 动态类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动态类型信息
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
  late Map<String, dynamic> procNodeSelected = {};

  // 将作业包进行展示
  late List<PackageUserDTOList>? packageUserDTOList = [];

  // 获取用户信息
  late Permissions permissions;

  late PackageUserDTOList? selectedPackage;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    selectedPackage = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预派工'),
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
                        print(selectArr);
                        if(mounted){
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
                        if(mounted){
                          setState(() {
                          print(selectArr);
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
                        if(mounted){
                          setState(() {
                          print(selectArr);
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
                        if(mounted){
                          setState(() {
                          print(selectArr);
                          repairSelected["name"] = selectItem["name"];
                          //将主键进行选取
                          repairSelected["code"] = selectItem["code"];
                          getRepairTimes();
                          getRepairMainNode();
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
                        if(mounted){
                          setState(() {
                          print(selectArr);
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
                        if(mounted){
                          setState(() {
                          print(selectArr);
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
              // 将packageUserDTOList进行展示
              Container(
                width: MediaQuery.of(context).size.width,
                height: (packageUserDTOList?.length ?? 0) *
                    150.0, // 根据数据长度计算高度，并调整每行高度为 100
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
                              ? packageUserDTO.workInstructPackageUserList![0]
                                      .repairPersonnelName ??
                                  ''
                              : '';
                          String assistant = packageUserDTO
                                      .workInstructPackageUserList
                                      ?.isNotEmpty ==
                                  true
                              ? packageUserDTO.workInstructPackageUserList![0]
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
                              margin: const EdgeInsets.symmetric(vertical: 5),
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
                                    value: selectedPackage == packageUserDTO,
                                    onChanged: (value) {
                                      if(mounted)
                                      setState(() {
                                        if (value!) {
                                          selectedPackage = packageUserDTO;
                                        } else {
                                          selectedPackage = null;
                                        }
                                      });
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
                                              '工位 ${station}',
                                              style: const TextStyle(
                                                  fontSize: 16), // 放大文字
                                            ),
                                            Text(
                                              '主修 ${mainRepair}',
                                              style: const TextStyle(
                                                  fontSize: 16), // 放大文字
                                            ),
                                            Text(
                                              '辅修 ${assistant}',
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
                    // 弹出的设置施修人按钮
                    if (selectedPackage != null)
                      Expanded(
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
                          style: ButtonStyle(
                            minimumSize:
                                MaterialStateProperty.all(Size.fromHeight(50)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                          ),
                          child: const Text('设置施修人'),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // 获取动态类型
  void getDynamicType() async {
    //获取动力类型
    var r = await ProductApi().getDynamicType();
    //获取用户信息
    var permissionResponse = await LoginApi().getpermissions();
      if(mounted){
        setState(() {
      dynamicTypeList = r.toMapList();
      permissions = permissionResponse;
      print(permissions.toJson());
    });
      }
    
  }

  // 获取机型
  void getJcType() async {
    Map<String, dynamic> queryParameters = {
      'dynamicCode': dynamicTypeSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().getJcType(queryParametrs: queryParameters);
    print(r.toJson());
    if(mounted){
      setState(() {
      jcTypeList = r.toMapList();
      getRepairSys();
    });
    }
    
  }

  // 获取修制信息
  Future<void> getRepairSys() async {
    print(dynamicTypeSelected["code"]);
    Map<String, dynamic> queryParameters = {
      'dynamicCode': dynamicTypeSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().selectRepairSys(queryParametrs: queryParameters);
    setState(() {
      print(r.rows!.length);
      repairSysList = r.toMapList();
    });
  }

  // 修
  // 修次
  void getRepairProc() async {
    Map<String, dynamic> queryParameters = {
      'repairSysCode': repairSysSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
    if (r.rows != []) {
      if(mounted){
        setState(() {
        //将获取的信息列表
        repairList = r.toMapList();
      });
      }
      
    }
  }

  //修次查询

  void getRepairTimes() async {
    Map<String, dynamic> queryParameters = {
      'repairProcCode': repairSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().getRepairTimes(queryParametrs: queryParameters);
    if (r.rows != []) {
      if(mounted){
        setState(() {
        //将获取的信息列表
        repairTImesList = r.toMapList();
      });
      }
      
    }
  }

  //获取工序节点
  void getRepairMainNode() async {
    //对工序节点进行查询
    Map<String, dynamic> queryParameters = {
      'repairProcCode': repairSelected["code"],
      'pageNum': 0,
      'pageSize': 0,
      'deptIds': Global.profile.permissions!.user.dept!.parentId
    };
    var r = await ProductApi()
        .getRepairMainNodeAll(queryParametrs: queryParameters);
    if (r.rows != null) {
      if(mounted){
        setState(() {
        //将获取的信息列表
        procNodeList = r.toMapList();
      });
      }
      
    }
  }

  //获取作业包
  void getWorkPackage() async {
    print("开始查询");
    Map<String, dynamic> queryParameters = {
      'typeCode': jcTypeListSelected["code"],
      'deptId': Global.profile.permissions!.user.deptId,
      'repairTimes': repairTimesSelected["name"],
      'repairMainNodeCode': procNodeSelected["code"],
    };
    var r = await JtApi().getPackageUserList(queryParameters: queryParameters);
    if (r.data != 0) {
      if(mounted){
        setState(() {
        //将获取的信息列表
        //将r.data进行遍历,获取相关信息进行展示
        packageUserDTOList = [];
        for (PackageUser item in r.data!) {
          print(item.packageUserDTOList!.length);
          packageUserDTOList?.addAll(item.packageUserDTOList!);
        }
        // print(packageUserDTOList!.length);
      });
      }
      
    }
  }
}

class SetRepairPersonScreen extends StatefulWidget {
  final PackageUserDTOList packageUserDTO;

  const SetRepairPersonScreen({Key? key, required this.packageUserDTO})
      : super(key: key);

  @override
  _SetRepairPersonScreenState createState() => _SetRepairPersonScreenState();
}

class _SetRepairPersonScreenState extends State<SetRepairPersonScreen> {
  late List<dynamic> userList = [];
  late List<int> mainUsers = []; // 用于存储主修
  late List<int> assistantUsers = []; // 用于存储辅修
  //存储主修名称
  late List<String> mainUsersName = [];
  //存储辅修名称
  late List<String> assistantUsersName = [];

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
        print(item1);
        mainUsersName.add(item1);
      }
    }
    String? assistantName = item.assistantName;
    //对assistantName进行分割赋值
    if (assistantName != null && assistantName != '') {
      List<String> assistantNameList = assistantName.split(',');
      for (String item1 in assistantNameList) {
        print(item1);
        assistantUsersName.add(item1);
      }
    }

    String? repair = item.repairPersonnel;
    //打印repair

    // repair格式为'1129,1130'将其转化为[1129,1130]

    if (repair != null && repair != '') {
      List<String> repairList = repair.split(',');
      for (String item1 in repairList) {
        print(item1);
        mainUsers.add(int.parse(item1));
      }
    }
    print(mainUsers.toString());
    String? assistant = item.assistant;
    print(assistant);
    if (assistant != null && assistant != '') {
      List<String> assistantList = assistant.split(',');
      for (String assistant in assistantList) {
        print(assistant);
        assistantUsers.add(int.parse(assistant));
      } // Bug 修复：添加闭合括号
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
          Container(
            child: Text("主修"),
          ),
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
                          if(mounted){
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
          Container(
            child: Text("辅修"),
          ),
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
                          if(mounted){
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
    print(mainUsersStr);
    print(mainUsersNameStr);
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
    ProductApi().saveAssociated(list);
    //清空mainUsers和assistantUsers和mainUsersName和assistantUsersName

    Navigator.pop(context);
  }
}

class PreWorkList extends StatefulWidget {
  final PackageUserDTOList packageUserDTO;

  const PreWorkList({Key? key, required this.packageUserDTO}) : super(key: key);

  @override
  _PreWorkListState createState() => _PreWorkListState();
}

class _PreWorkListState extends State<PreWorkList> {
  // 用于存储已勾选的作业项
  List<WorkInstructPackageUserList> selectedWorkItems = [];

  @override
  Widget build(BuildContext context) {
    // 获取packageUserDTO中workInstructPackageUserList
    List<WorkInstructPackageUserList>? workInstructPackageUserList =
        widget.packageUserDTO.workInstructPackageUserList;

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
                    if(mounted){
                      setState(() {
                      if (value!) {
                        selectedWorkItems.add(workInstructPackageUser);
                      } else {
                        selectedWorkItems.remove(workInstructPackageUser);
                      }
                    });  
                    }
                    
                  },
                ),
                Expanded(
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


