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

  @override
  void initState() {
    super.initState();
    getDynamicType();
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
                        setState(() {
                          dynamicTypeSelected["code"] = selectItem["code"];
                          dynamicTypeSelected["name"] = selectItem["name"];
                          getJcType();
                        });
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
                        setState(() {
                          print(selectArr);
                          jcTypeListSelected["name"] = selectItem["name"];
                          jcTypeListSelected["code"] = selectItem["code"];
                          // 在这里添加获取车号等后续逻辑，如果有的话
                        });
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
                        setState(() {
                          print(selectArr);
                          repairSysSelected["name"] = selectItem["name"];
                          //将主键进行选取
                          repairSysSelected["code"] = selectItem["code"];
                          //获取修程信息
                          getRepairProc();
                        });
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
                        setState(() {
                          print(selectArr);
                          repairSelected["name"] = selectItem["name"];
                          //将主键进行选取
                          repairSelected["code"] = selectItem["code"];
                          getRepairTimes();
                          getRepairMainNode();
                        });
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
                        setState(() {
                          print(selectArr);
                          repairTimesSelected["name"] = selectItem["name"];
                          //将主键进行选取
                          repairTimesSelected["code"] = selectItem["code"];
                        });
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
                        setState(() {
                          print(selectArr);
                          procNodeSelected["name"] = selectItem["name"];
                          //将主键进行选取
                          procNodeSelected["code"] = selectItem["code"];
                          getWorkPackage();
                        });
                      },
                    );
                  }
                },
              ),
              // 将packageUserDTOList进行展示
              Container(
                width: MediaQuery.of(context).size.width,
                height: (packageUserDTOList?.length ?? 0) *
                    100.0, // 根据数据长度计算高度，并调整每行高度为 100
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
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            height: 80, // 减少容器高度
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 5), // 调整内边距
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    // 增加序号中文
                                    Text(
                                      '序号 ${packageUserDTOList!.indexOf(packageUserDTO) + 1}',
                                      style:
                                          const TextStyle(fontSize: 16), // 放大文字
                                    ),
                                    Text(
                                      '作业包 ${packageUserDTO.packageName ?? ''}',
                                      style:
                                          const TextStyle(fontSize: 16), // 放大文字
                                    ),
                                    Text(
                                      '工位 ${station}',
                                      style:
                                          const TextStyle(fontSize: 16), // 放大文字
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5), // 增加行间距
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      '主修 ${mainRepair}',
                                      style:
                                          const TextStyle(fontSize: 16), // 放大文字
                                    ),
                                    Text(
                                      '辅修 ${assistant}',
                                      style:
                                          const TextStyle(fontSize: 16), // 放大文字
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }

  // 获取动态类型
  void getDynamicType() async {
    //获取动力类型
    var r = await ProductApi().getDynamicType();
    //获取用户信息
    var permissionResponse = await LoginApi().getpermissions();
    setState(() {
      dynamicTypeList = r.toMapList();
      permissions = permissionResponse;
      print(permissions.toJson());
    });
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
    setState(() {
      jcTypeList = r.toMapList();
      getRepairSys();
    });
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

  // 修程
  void getRepairProc() async {
    Map<String, dynamic> queryParameters = {
      'repairSysCode': repairSysSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().getRepairProc(queryParametrs: queryParameters);
    if (r.rows != []) {
      setState(() {
        //将获取的信息列表
        repairList = r.toMapList();
      });
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
      setState(() {
        //将获取的信息列表
        repairTImesList = r.toMapList();
      });
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
      setState(() {
        //将获取的信息列表
        procNodeList = r.toMapList();
      });
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
