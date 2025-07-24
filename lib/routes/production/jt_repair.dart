import '../../index.dart';

class JtRepairPage extends StatefulWidget {
  const JtRepairPage({Key? key}) : super(key: key);
  @override
  State<JtRepairPage> createState() => _JtRepairPageState();
}

class _JtRepairPageState extends State<JtRepairPage> {
  late Map<String, dynamic> info = {};

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
  // 机统28信息
  late List<dynamic> sys28List = [];

  late Map<String, dynamic> permissions = {};

  late TextEditingController repairDetailsController = TextEditingController();

  late TextEditingController actualStartDateController =
      TextEditingController();

  late TextEditingController faultyPartController = TextEditingController();

  late TextEditingController mutualInspectorController =
      TextEditingController();

  late TextEditingController qualityInspectorController =

      TextEditingController();

  List<dynamic> faultPartList = [];

  List<Map<String, dynamic>> faultPartListInfo = [];

    // 当前选中的节点
  Map<String, dynamic>? selectedNode;

    // 显示选择器
  // void _showTreePicker(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => TreePicker(
  //       data: faultPartListInfo,
  //       labelKey: 'nodeName',
  //       valueKey: 'infoCode',
  //       childrenKey: 'children',
  //       onSelected: (selectedItem, selectedPath) {
  //         setState(() {
  //           selectedNode = selectedItem;
  //         });
  //       },
  //     ),
  //   );
  // }

  void _showRepairDialog(BuildContext context, Map<String, dynamic> item) {
    // 设置默认值（从 item 中获取，如果存在）
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("施修"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("故障现象：${item['faultDescription']}"),
                const SizedBox(height: 10),
                TextField(
                  controller: repairDetailsController,
                  decoration: const InputDecoration(labelText: "施修情况"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: actualStartDateController,
                  decoration: const InputDecoration(
                    labelText: "实际开始修理日期",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? initialDate = DateTime.now();
                    if (actualStartDateController.text.isNotEmpty) {
                      try {
                        List<String> parts =
                            actualStartDateController.text.split('-');
                        if (parts.length == 3) {
                          initialDate = DateTime(
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                            int.parse(parts[2]),
                          );
                        }
                      } catch (e) {
                        initialDate = DateTime.now();
                      }
                    }

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      actualStartDateController.text =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: faultyPartController,
                  decoration: const InputDecoration(labelText: "故障零部件"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mutualInspectorController,
                  decoration: const InputDecoration(labelText: "互检人员"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qualityInspectorController,
                  decoration: const InputDecoration(labelText: "专检人员"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 图片上传逻辑
                  },
                  child: const Text("上传销活图片"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                final String repairDetails = repairDetailsController.text;
                final String actualStartDate = actualStartDateController.text;
                final String faultyPart = faultyPartController.text;
                final String mutualInspector = mutualInspectorController.text;
                final String qualityInspector = qualityInspectorController.text;

                print("施修情况: $repairDetails");
                print("实际开始修理日期: $actualStartDate");
                print("故障零部件: $faultyPart");
                print("互检人员: $mutualInspector");
                print("专检人员: $qualityInspector");

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("提交成功")),
                );
              },
              child: const Text("提交"),
            ),
          ],
        );
      },
    );
  }

  //获取机统28信息
  void getInfo() async {
    Map<String, dynamic> queryParameters = {
      'pageNum': 0,
      'pageSize': 0,
      'status': 0,
      'trainEntryCode': trainNumSelected['code']
    };
    var r =
        await ProductApi().selectRepairSys28(queryParametrs: queryParameters);
    setState(() {
      info = r;
      sys28List = info['rows'];
    });
  }

  @override
  void initState() {
    getDynamicType();
    // ✅ 初始化施修情况控制器
    repairDetailsController = TextEditingController();
    super.initState();
  }

  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      setState(() {
        dynamicTypeList = r.toMapList();
        permissions = permissionResponse as Map<String, dynamic>;
        logger.i(permissions);
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

  void getFaultPart() async {
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': jcTypeListSelected["code"],
      };
      logger.i(queryParameters);
      var r = await ProductApi().getFaultPart(queryParameters);
      if (mounted) {
        setState(() {
          //将List<dynamic>转换为List<Map<String, dynamic>>
          faultPartListInfo =
              r.map((item) => item as Map<String, dynamic>).toList();
          faultPartList = r;
        });
      }
    } catch (e, stackTrace) {
      logger.e('getFaultPart 方法中发生异常: $e\n堆栈信息: $stackTrace');
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
        title: const Text("机统28"),
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
                      title: "选择车号",
                      clickCallBack: (selectItem, selectArr) {
                        setState(() {
                          logger.i(selectArr);
                          trainNumSelected["trainNum"] = selectItem["trainNum"];
                          trainNumSelected["code"] = selectItem["code"];
                        });
                      },
                    );
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // 调用搜索方法，重新获取数据
                  getInfo();
                },
                child: const Text('搜索机统28'),
              ),
              //展示列表信息
              // ... existing code ...
              // ... existing code ...
              if (sys28List.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sys28List.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> item = sys28List[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue), // 添加蓝色边框
                        borderRadius: BorderRadius.circular(8.0), // 可选：添加圆角
                      ),
                      margin: const EdgeInsets.all(8.0), // 可选：为每个列表项添加外边距
                      padding: const EdgeInsets.all(8.0), // 可选：为内容添加内边距
                      child: ListTile(
                        title: Text("故障现象: ${item['faultDescription']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("工序节点: ${item['processMainNode']}"),
                            Text("风险等级: ${item['riskLevel']}"),
                          ],
                        ),
                        // 判断 completeStatus 是否为 0，如果是，则显示“施修”按钮
                        trailing: item['completeStatus'] == 0
                            ? ElevatedButton(
                                onPressed: () {
                                  getFaultPart();
                                  _showRepairDialog(context, item);
                                  // 处理施修按钮点击事件
                                  // 可以在这里调用相应的业务逻辑
                                  // 例如：navigateToRepairDetails(item['id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // 按钮背景颜色
                                  foregroundColor: Colors.white, // 按钮文字颜色
                                ),
                                child: const Text("施修"),
                              )
                            : null,
                      ),
                    );
                  },
                ),
// ... existing code ...
// ... existing code ...
            ],
          ),
        ],
      ),
    );
  }
}


// class TreePicker extends StatefulWidget {
//   final List<Map<String, dynamic>> data;
//   final String labelKey;
//   final String valueKey;
//   final String childrenKey;
//   final Function(Map<String, dynamic>, List<Map<String, dynamic>>) onSelected;

//   TreePicker({
//     required this.data,
//     required this.labelKey,
//     required this.valueKey,
//     required this.childrenKey,
//     required this.onSelected,
//   });

//   @override
//   _TreePickerState createState() => _TreePickerState();
// }

// class _TreePickerState extends State<TreePicker> {
//   late List<Map<String, dynamic>> currentLevel;
//   late List<List<Map<String, dynamic>>> path;

//   @override
//   void initState() {
//     super.initState();
//     currentLevel = widget.data;
//     path = [];
//   }

//   void _selectNode(Map<String, dynamic> node) {
//     if (node.containsKey(widget.childrenKey) &&
//         node[widget.childrenKey] is List) {
//       // 如果有子节点，进入下一层
//       path.add(currentLevel);
//       currentLevel = (node[widget.childrenKey] as List)
//           .map((e) => e as Map<String, dynamic>)
//           .toList();
//     } else {
//       // 如果是叶子节点，触发选择回调
//       widget.onSelected(node, [...path, currentLevel]);
//       Navigator.of(context).pop();
//     }
//     setState(() {});
//   }

//   void _goBack() {
//     if (path.isNotEmpty) {
//       currentLevel = path.removeLast();
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 400,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               if (path.isNotEmpty)
//                 IconButton(
//                   icon: Icon(Icons.arrow_back),
//                   onPressed: _goBack,
//                 ),
//               Text(
//                 path.isEmpty ? '选择节点' : '选择子节点',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(width: 48), // 保持对齐
//             ],
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: currentLevel.length,
//               itemBuilder: (context, index) {
//                 var item = currentLevel[index];
//                 return ListTile(
//                   title: Text(item[widget.labelKey]),
//                   onTap: () => _selectNode(item),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }