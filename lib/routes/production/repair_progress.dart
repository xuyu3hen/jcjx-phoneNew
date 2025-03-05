import '../../index.dart';

class RepairProgress extends StatefulWidget {
  const RepairProgress({Key? key}) : super(key: key);

  @override
  State createState() => _RepairProgressState();
}

class _RepairProgressState extends State<RepairProgress> {
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );
  // 动力类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动力类型信息
  late Map<dynamic, dynamic> dynamicTypeSelected = {
    "code": "6f94f29b744340a2efb3628ad858abed",
    "name": "交流传动电力机车",
  };

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getRepairSys();
    getRepairProc();
    getTrainEntry();
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
  late Map<String, dynamic> repairSysSelected = {
    "code": "f246102c365c7c0c73010926dc29e5ec",
    "name": "高级修"
  };
  // 获取修制信息
  Future<void> getRepairSys() async {
    Map<String, dynamic> queryParameters = {
      'dynamicCode': dynamicTypeSelected["code"],
      'pageNum': 0,
      'pageSize': 0
    };
    var r = await ProductApi().selectRepairSys(queryParametrs: queryParameters);
    setState(() {
      logger.i(r.rows!.length);
      repairSysList = r.toMapList();
    });
  }

  // 修程列表
  late List<Map<String, dynamic>> repairList = [];
  // 筛选的修程
  late Map<String, dynamic> repairSelected = {
    "code": "45d742af7f22d20201f9d91541058381",
    "name": "C5",
  };

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
    return SingleChildScrollView(
      child: Column(
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
                        repairSysSelected["code"] = selectItem["code"];
                        getRepairProc();
                      });
                    }
                  },
                );
              }
            },
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
                        repairSelected["code"] = selectItem["code"];
                        getTrainEntry();
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item['trainNum'] ?? ''),
                          ),
                          Expanded(
                            child: Text(item['typeName'] ?? ''),
                          ),
                        ],
                      ),
                      if (item['stateDetailList'] != null)
                        for (var info in item['stateDetailList'])
                          if (info['state'] == '1')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(4.0),
                                  // padding: const EdgeInsets.all(8.0),
                                ),
                                child: Text(info['repairMainNodeName'] ?? ''),
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),

          //展示repairMainNodeStatusList
          // if (repairMainNodeStatusList.isNotEmpty)
          //   ListView.builder(
          //       shrinkWrap: true,
          //       physics: const NeverScrollableScrollPhysics(),
          //       itemCount: repairMainNodeStatusList.length,
          //       itemBuilder: (context, index) {
          //         final item = repairMainNodeStatusList[index];
          //         return ListTile(
          //           title: Text(item['repairMainNodeName'] ?? ''),
          //           subtitle: Text(item['state'] ?? ''),
          //         );
          //       })
        ],
      ),
    );
  }

  Map<String, dynamic> trainEntryResponse = {};

  List<String> codeList = [];

  List<Map<String, dynamic>> repairMainNodeStatusList = [];
  void getTrainEntry() async {
    // try {
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
          r['rows'].map((value) => value['code']).cast<String>().toList();
      var statusResponse = await ProductApi().getRepairingTrainStatus(codeList);
      logger.i(statusResponse);

      if (mounted) {
        setState(() {
          trainEntryResponse = {'data': statusResponse['data'] ?? []};
          for (Map<String, dynamic> item in trainEntryResponse['data'][0]
              ['stateDetailList']) {
            Map<String, dynamic> temp = {};
            temp['repairMainNodeName'] = item['repairMainNodeName'];
            item['state'] = item['state'];
            repairMainNodeStatusList.add(temp);
          }
          print(repairMainNodeStatusList.toString());
        });
      }
    }
    // } catch (e) {
    //   logger.e("Failed to get train entry: $e");
    //   if (mounted) {
    //     setState(() {
    //       trainEntryResponse = {'data': []};
    //     });
    //     showToast("获取数据失败，请重试");
    //   }
    // }
  }
}
