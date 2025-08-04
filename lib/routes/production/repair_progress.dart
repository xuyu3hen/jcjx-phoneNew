import '../../index.dart';

class RepairProgress extends StatefulWidget {
  const RepairProgress({Key? key}) : super(key: key);

  @override
  State createState() => _RepairProgressState();
}

class _RepairProgressState extends State<RepairProgress> {
  // 创建 Logger 实例
  var logger = AppLogger.logger;
  // 动力类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动力类型信息
  late Map<dynamic, dynamic> dynamicTypeSelected = {};

  @override
  void initState() {
    super.initState();
    initSelectInfo();
    // searchTrainEntryStatus();
  }

  // 获取动态类型
  Future<void> getDynamicType() async {
    try {
      var r = await ProductApi().getDynamicType();

      if (mounted) {
        setState(() {
          dynamicTypeList = r.toMapList();
          dynamicTypeSelected = r.toMapList()[0];
          logger.i(dynamicTypeSelected);
        });
      }
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 修制列表
  late List<Map<String, dynamic>> repairSysList = [];
  //筛选的修制
  late Map<String, dynamic> repairSysSelected = {};
  // 获取修制信息
  Future<void> getRepairSys() async {
    try {
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
        logger.i(repairSysList.toString());
        repairSelected = r.toMapList()[0];
      });
    } catch (e, stackTrace) {
      logger.e('getRepairSys 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 修程列表
  late List<Map<String, dynamic>> repairList = [];
  // 筛选的修程
  late Map<String, dynamic> repairSelected = {};

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

  Map<String, dynamic> trainEntryResponse = {};

  List<String> codeList = [];

  List<Map<String, dynamic>> repairMainNodeStatusList = [];

  void getTrainEntry() async {
    try {
      Map<String, dynamic> queryParameters = {};
      queryParameters['pageNum'] = 0;
      queryParameters['pageSize'] = 0;
      queryParameters['dynamicCode'] = dynamicTypeSelected['code'];
      queryParameters['repairProcCode'] = repairSelected['code'];

      Map<String, dynamic> r =
          await ProductApi().getTrainEntryDynamic(queryParameters);

      if (r.containsKey('rows') && r['rows'].isNotEmpty) {
        List<String> codeList =
            r['rows'].map((value) => value['code']).cast<String>().toList();

        var statusResponse =
            await ProductApi().getRepairingTrainStatus(codeList);

        logger.i(statusResponse);

        if (mounted) {
          setState(() {
            trainEntryResponse = {'data': statusResponse['data'] ?? []};
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('getTrainEntry 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 初始化筛选信息 依次获得数据
  Future<void> initSelectInfo() async {
    try {
      var r = await ProductApi().getDynamicType();
      if (r.toMapList().isEmpty) {
        logger.e('动力类型列表为空');
        return;
      }
      Map<String, dynamic> initDynamicTypeSelected = r.toMapList()[0];
      Map<String, dynamic> queryParameters = {
        'dynamicCode': initDynamicTypeSelected['code'],
        'pageNum': 0,
        'pageSize': 0
      };
      var r1 =
          await ProductApi().selectRepairSys(queryParametrs: queryParameters);
      if (r1.toMapList().isEmpty) {
        logger.e('修制列表为空');
        return;
      }
      Map<String, dynamic> initRepairSysSelected = r1.toMapList()[0];
      Map<String, dynamic> queryParameters1 = {
        'repairSysCode': initRepairSysSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r2 =
          await ProductApi().getRepairProc(queryParametrs: queryParameters1);
      if (r2.toMapList().isEmpty) {
        logger.e('修程列表为空');
        return;
      }
      Map<String, dynamic> queryParameters2 = {
        'pageNum': 0,
        'pageSize': 0,
        'dynamicCode': initDynamicTypeSelected['code'],
        'repairProcCode': initRepairSysSelected['code']
      };
      var r3 = await ProductApi().getTrainEntryDynamic(queryParameters2);
      if (!r3.containsKey('rows') || r3['rows'].isEmpty) {
        logger.e('列车条目列表为空');
        return;
      }

      List<String> codeList =
          r3['rows'].map((value) => value['code']).cast<String>().toList();

      var statusResponse = await ProductApi().getRepairingTrainStatus(codeList);
      Map<String, dynamic> queryParameters3 = {
        'repairProcCode': r2.toMapList()[0]['code'],
        'pageNum': 0,
        'pageSize': 0
      };

      List<Map<String, dynamic>> r4 = await ProductApi()
          .getRepairMainNode(queryParameters: queryParameters3);

      List<String> codeList1 =
          r4.map((item) => item['code'] as String).toList();
      logger.i(codeList1.toString());
      Map<String, List<dynamic>> statusResponse1 =
          await ProductApi().getTrainEntryByRepairMainNodeCodeList(codeList1);

      int num = 1;
      for (var element in codeList1) {
        String repairMainNodeName = '';
        bool found = false;
        for (Map<String, dynamic> item in r4) {
          if (element == item['code']) {
            repairMainNodeName = item['name'];
            found = true;
            break;
          }
        }
        if (found) {
          ProcessNode processNode =
              ProcessNode(id: num++, name: repairMainNodeName, locomotives: []);
          processNodeList.add(processNode);
        }
      }
      statusResponse1.forEach((key, value) {
        String repairMainNodeName = '';
        for (Map<String, dynamic> item in r4) {
          if (key == item['code']) {
            repairMainNodeName = item['name'];
          }
        }
        List<String> locomotives =
            value.map((e) => e['trainNum'] as String).toList();
        for (ProcessNode processNode in processNodeList) {
          if (repairMainNodeName == processNode.name) {
            processNode.locomotives = locomotives;
          }
        }
      });
      //遍历输出
      logger.i(processNodeList.length);
      for (ProcessNode processNode in processNodeList) {
        logger.i('节点ID: ${processNode.id}');
        logger.i('节点名称: ${processNode.name}');
        logger.i(processNode.locomotives.toString());
      }

      if (mounted) {
        setState(() {
          dynamicTypeList = r.toMapList();
          dynamicTypeSelected = initDynamicTypeSelected;
          repairSysList = r1.toMapList();
          repairSysSelected = initRepairSysSelected;
          repairList = r2.toMapList();
          repairSelected = r2.toMapList()[0];
          trainEntryResponse = {'data': statusResponse['data'] ?? []};
        });
      }
    } catch (e, stackTrace) {
      logger.e('initSelectInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  late List<ProcessNode> processNodeList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检修进度'),
        actions: [
           TextButton(
            onPressed: () {
              if (processNodeList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FlowChartPage(processNodes: processNodeList),
                  ),
                );
              } else {
                showToast("进度图数据为空");
              }
            },
            child: const Text(
              '全流程节点机车图',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
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
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(8.0), // 将 padding 移到这里
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '机型: ${item['trainNum'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '车号: ${item['typeName'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (item['stateDetailList'] != null)
                          for (var info in item['stateDetailList'])
                            if (info['state'] == '1')
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '工序节点: ${info['repairMainNodeName'] ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}

class ProcessNode {
  int id;
  String name;
  List<String> locomotives;

  ProcessNode({
    required this.id,
    required this.name,
    required this.locomotives,
  });
}

// ... existing code ...
class FlowChartPage extends StatelessWidget {
  final List<ProcessNode> processNodes;

  const FlowChartPage({Key? key, required this.processNodes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Graph graph = Graph();
    final algo = SugiyamaConfiguration();
    algo.orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM; // 修改方向配置

    for (var node in processNodes) {
      final vertex = Node.Id(node.id);
      graph.addNode(vertex);
    }

    for (int i = 0; i < processNodes.length - 1; i++) {
      final source = Node.Id(processNodes[i].id);
      final target = Node.Id(processNodes[i + 1].id);
      graph.addEdge(source, target);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('各流程节点机车'),
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5.6,
        child: SingleChildScrollView(
          child: GraphView(
            graph: graph,
            algorithm: SugiyamaAlgorithm(algo),
            paint: Paint()
              ..color = Colors.green
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke,
            builder: (Node node) {
              final processNode = processNodes.firstWhere(
                (element) => element.id == node.key!.value,
              );
              return Container(
                width: 200, // 设置固定宽度
                height: 150, // 设置固定高度
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('节点: ${processNode.id}'), // 修改文本显示
                    Text(
                      '工序节点: ${processNode.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(
                          '机车: ${processNode.locomotives.join(', ')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
// ... existing code ...