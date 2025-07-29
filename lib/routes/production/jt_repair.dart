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

  // 零件信息
  late Map<String, dynamic> faultPart = {};

  Permissions? permissions;

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

  //
  late Map<String, dynamic> faultInfo;

// ... existing code ...
  /// 显示故障零部件列表
  void _showFaultPartList(
      BuildContext context) async {
    try {
      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // 获取零部件数据
      await getFaultPart();

      // 关闭加载提示
      Navigator.of(context).pop();

      // 显示零部件列表
      if (faultPartListInfo.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 顶部标题栏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '零部件列表',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    // 零部件列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: faultPartListInfo.length,
                        itemBuilder: (context, index) {
                          final part = faultPartListInfo[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(part['name'] ?? '未知名称'),
                              subtitle: Text('编码: ${part['code'] ?? '无'}'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                _showPartDetail(context, part);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // 没有数据时显示提示
        // 使用传入的 context 显示 SnackBar，并确保 widget 仍然挂载
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("未查询到零部件信息")),
          );
        }
      }
    } catch (e) {
      // 出错时关闭加载提示并显示错误信息
      Navigator.of(context).pop();
      // 使用传入的 context 显示 SnackBar，并确保 widget 仍然挂载
      // if (context.mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text("查询失败: $e")),
      //   );
      // }
    }
  }
// ... existing code ...
// ... existing code ...

  /// 显示零部件详细信息
  /// 显示零部件详细信息
  void _showPartDetail(BuildContext context, Map<String, dynamic> part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 顶部标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '零部件详情',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                // 详细信息列表
                Expanded(
                  child: ListView(
                    children: [
                      _buildDetailItem('名称', part['name'] ?? '无'),
                      _buildDetailItem('编码', part['code'] ?? '无'),
                      _buildDetailItem('类型', part['type'] ?? '无'),
                      _buildDetailItem('规格', part['spec'] ?? '无'),
                      _buildDetailItem('单位', part['unit'] ?? '无'),
                      _buildDetailItem('备注', part['remark'] ?? '无'),
                    ],
                  ),
                ),
                // 选择按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        faultyPartController.text = part['name'] ?? '';
                        faultPart['name'] = part['name'];
                        faultPart['code'] = part['code'];
                        getUserList();
                      });
                      Navigator.of(context).pop(); // 关闭详情弹窗
                      Navigator.of(context).pop(); // 关闭列表弹窗
                    },
                    child: const Text('选择此零部件'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建详情信息项
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


// ... existing code ...
  void _showRepairDialog() {
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
                Text("故障现象：${faultInfo['faultDescription']}"),
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
                // ... existing code ...
                // ... existing code ...
                TextField(
                  controller: faultyPartController,
                  decoration: const InputDecoration(labelText: "故障零部件"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _showFaultPartList(context);
                  },
                  child: const Text("查询零部件信息"),
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
                // 确保 widget 仍然挂载后再显示 SnackBar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("提交成功")),
                  );
                }
              },
              child: const Text("提交"),
            ),
          ],
        );
      },
    );
  }
// ... existing code ...


  //获取机统28信息
  void getInfo() async {
    Map<String, dynamic> queryParameters = {
      'pageNum': 0,
      'pageSize': 0,
      'status': 0,
      'trainEntryCode': trainNumSelected['code'],
      'repairName': permissions?.user.nickName,
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
        permissions = permissionResponse;
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

  Future<void> getFaultPart() async {
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': jcTypeListSelected["code"],
        'pageNum': 0,
        'pageSize': 0,
        'name': faultyPartController.text,
      };
      logger.i(queryParameters);
      var r = await ProductApi().getFaultPart(queryParameters);
      if (mounted) {
        setState(() {
          //将List<dynamic>转换为List<Map<String, dynamic>>
          faultPartListInfo = (r['rows'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
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

  //获取互检专检人员信息
  void getUserList() async {
    try {
      Map<String, dynamic> queryParameters = {
        'configNodeCode': jcTypeListSelected["code"],
        'riskLevel': faultInfo["riskLevel"],
        'team': 100
      };
      logger.i(queryParameters);
      var r = await ProductApi().getCheckPerson(queryParameters);
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('getTrainInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("机统28施修"),
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
                        trailing: item['completeStatus'] == 0 &&
                                item['repairName'] == permissions?.user.nickName
                            ? ElevatedButton(
                                onPressed: () {
                                  faultInfo = item;
                                  _showRepairDialog();
                                  
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
            ],
          ),
        ],
      ),
    );
  }
}
