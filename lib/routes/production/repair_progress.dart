import '../../index.dart';

import 'package:flutter/material.dart';

// 定义工序节点类
class MaintenanceStep {
  final String name;
  bool isCompleted;

  MaintenanceStep({required this.name, this.isCompleted = false});
}

void main() {
  runApp(const MaterialApp(
    home: RepairProgress(),
  ));
}

class RepairProgress extends StatefulWidget {
  const RepairProgress({Key? key}) : super(key: key);

  @override
  _RepairProgressState createState() => _RepairProgressState();
}

class _RepairProgressState extends State<RepairProgress> {
  // 模拟工序节点列表
  List<MaintenanceStep> maintenanceSteps = [
    MaintenanceStep(name: '进厂检查'),
    MaintenanceStep(name: '拆解部件'),
    MaintenanceStep(name: '部件清洗'),
    MaintenanceStep(name: '部件检测'),
    MaintenanceStep(name: '修复或更换部件'),
    MaintenanceStep(name: '组装'),
    MaintenanceStep(name: '出厂检查'),
  ];

  // 获取当前所处的工序节点索引
  int getCurrentStepIndex() {
    for (int i = 0; i < maintenanceSteps.length; i++) {
      if (!maintenanceSteps[i].isCompleted) {
        return i;
      }
    }
    return maintenanceSteps.length - 1;
  }

  // 获取整体检修进度
  double getOverallProgress() {
    int completedSteps =
        maintenanceSteps.where((step) => step.isCompleted).length;
    return completedSteps / maintenanceSteps.length;
  }

  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );
  // 动力类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动力类型信息
  late Map<dynamic, dynamic> dynamicTypeSelected = {};

  @override
  void initState() {
    super.initState();
    getDynamicType();
  }

  // 获取动态类型
  void getDynamicType() async {
    //获取动力类型
    var r = await ProductApi().getDynamicType();
    //获取用户信息

    if (mounted) {
      setState(() {
        dynamicTypeList = r.toMapList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检修进度'),
      ),
      body: _buildBody(),
    );
  }

  // 修制列表
  late List<Map<String, dynamic>> repairSysList = [];
  //筛选的修制
  late Map<String, dynamic> repairSysSelected = {};
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

  // 修程列表
  late List<Map<String, dynamic>> repairList = [];
  // 筛选的修程
  late Map<String, dynamic> repairSelected = {};

  void getRepairProc() async {
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
                          print(selectArr);
                          if (mounted) {
                            setState(() {
                              dynamicTypeSelected["code"] = selectItem["code"];
                              dynamicTypeSelected["name"] = selectItem["name"];
                              getRepairSys();
                            });
                          }
                        },
                      );
                    }
                  },
                ),
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
              ],
            ),
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

                          // _getTrainEntry();
                        });
                      }
                    },
                  );
                }
              },
            ),
            if (trainEntryResponse.containsKey('data') &&
                trainEntryResponse['data'].isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trainEntryResponse['data'].length,
                itemBuilder: (context, index) {
                  final item = trainEntryResponse['data'][index];
                  return ListTile(
                    title: Text(item['trainNum'] ?? ''),
                    subtitle: Text(item['typeName'] ?? ''),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> trainEntryResponse = {};

  List<String> codeList = [];

  void _getTrainEntry() async {
    try {
      Map<String, dynamic> queryParameters = {};
      queryParameters['pageNum'] = 0;
      queryParameters['pageSize'] = 0;
      queryParameters['dynamicCode'] = dynamicTypeSelected['code'];
      queryParameters['repairProcCode'] = repairSelected['code'];

      Map<String, dynamic> r =
          await ProductApi().getTrainEntryDynamic(queryParameters);
      logger.i(r);

      if (r.containsKey('rows') && r['rows'].isNotEmpty) {
        List<String> codeList =
            r['rows'].map((value) => value['code']).toList();
        var statusResponse =
            await ProductApi().getRepairingTrainStatus(codeList);
        logger.i(statusResponse);

        if (mounted) {
          setState(() {
            trainEntryResponse = {'data': statusResponse['data'] ?? []};
          });
        }
      }
    } catch (e) {
      logger.e("Failed to get train entry: $e");
      if (mounted) {
        setState(() {
          trainEntryResponse = {'data': []};
        });
        showToast("获取数据失败，请重试");
      }
    }
  }
}
