import 'package:jcjx_phone/models/progress.dart';

import '../../index.dart';
import 'package:intl/intl.dart';

class TrainRepairProgressPage extends StatefulWidget {
  const TrainRepairProgressPage({super.key});

  @override
  State<TrainRepairProgressPage> createState() =>
      _TrainRepairProgressPageState();
}

class _TrainRepairProgressPageState extends State<TrainRepairProgressPage> {
  var logger = AppLogger.logger;

  // 检修进度数据
  List<Map<String, dynamic>> repairProgressList = [];

  // 是否正在加载
  bool _isLoading = true;

  // 当前选中的机车
  Map<String, dynamic>? _selectedLocomotive;

  List<RepairGroup> repairGroups = [];

  // 用于追踪每个组的展开状态
  Map<int, bool> _groupExpansionStates = {};

  // 搜索文本
  String _searchText = '';

  Map<int, dynamic> noticeMap = {
    0: '调车调令',
    1: '检修计划',
    2: '临修调令',
    3: '机车配置签收',
    4: '售后服务-调车清单',
    5: '机车入段调令',
    6: '机务段下发调令',
    7: '作业人员修改调令',
    8: '转序调令',
    9: '轮径修改调令',
    10: '轮径尺寸调令',
    11: '轮径镟削调令',
    12: '修改派工单',
    13: '售后修程通知单',
    14: '放行调令',
    15: '放行申请',
    16: '计划排产调令'
  };

  @override
  void initState() {
    super.initState();
    _loadRepairProgressData();
  }

  // 加载检修进度数据
  Future<void> _loadRepairProgressData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      Map<String, dynamic> queryParametrs = {};
      List<RepairGroup> r =
          await ProductApi().getTrainEntryAndDynamics(queryParametrs);
      setState(() {
        repairGroups = r;
        logger.i(r[0].repairProcCode);
        _isLoading = false;
      });
    } catch (e) {
      logger.e('加载检修进度数据失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SmartDialog.showToast('数据加载失败');
      }
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    await _loadRepairProgressData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检修作业进度'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: Column(
        children: [
          // 添加搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '请输入车号进行搜索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: repairGroups.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : _buildRepairList(),
                  ),
          ),
        ],
      ),
    );
  }

  // 构建维修列表
  Widget _buildRepairList() {
    // 过滤数据
    List<RepairGroup> filteredGroups = [];
    if (_searchText.isEmpty) {
      filteredGroups = repairGroups;
    } else {
      for (var group in repairGroups) {
        final filteredChildren = group.children
            ?.where((item) => (item.trainNum ?? '').contains(_searchText))
            .toList();

        if (filteredChildren != null && filteredChildren.isNotEmpty) {
          filteredGroups.add(RepairGroup(
            children: filteredChildren,
            repairProcCode: group.repairProcCode,
            repairProcName: group.repairProcName,
            sort: group.sort,
          ));
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return _buildRepairGroupCard(group, index);
      },
    );
  }

  // 构建维修组卡片

  Widget _buildRepairGroupCard(RepairGroup group, int index) {
    bool isExpanded = _groupExpansionStates[index] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _groupExpansionStates[index] = !isExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 组标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${group.repairProcName} (${group.children?.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // 子项列表
            if (isExpanded)
              Column(
                children: group.children!
                    .map((item) => _buildRepairItem(item))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
// ... existing code ...

  // 构建维修项
  Widget _buildRepairItem(RepairItem item) {
    // 计算完成进度
    int progress = 0;
    int completeCount = item.completePackageCount ?? 0;
    int totalCount = item.totalPackageCount ?? 0;

    if (totalCount > 0) {
      progress = (completeCount * 100) ~/ totalCount;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Color.fromARGB(255, 53, 52, 52), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列车基本信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '车号：${item.trainNum ?? '未知车号'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status ?? 0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(item.status ?? 0)),
                ),
                child: Text(
                  _getStatusText(item.status ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(item.status ?? 0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 车型信息
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '机型：${item.typeName ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '修程：${item.repairProcName ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '修次：${item.repairTimes ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 位置和时间信息
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配属段：${item.assignSegmentName ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '预计上台日期：${item.arrivePlatformTime ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '停留地点：${item.stoppingPlace ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 检修动态
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '机车检修动态',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.repairDynamics ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // 时间信息
          const SizedBox(height: 8),
          // 包数量信息
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '检修进度',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$completeCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '($progress%)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 检修详情查询和检修调令按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showRepairProgressList(context, item);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('检修详情查询'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showMaintenanceOrderDialog(context, item);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('检修调令'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 显示检修进度列表
  void _showRepairProgressList(BuildContext context, RepairItem item) async {
    await getTrainRepairDynamics(item);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('检修进度列表'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: shuntingList.length,
                    itemBuilder: (context, index) {
                      final shuntingItem = shuntingList[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '流水号: ${shuntingItem['shuntingEncode'] ?? ''}'),
                              Text(
                                '调令类型: ${noticeMap[shuntingItem['shuntingType']] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                  '修程（故障）内容: ${shuntingItem['faultContent'] ?? ''}'),
                              Text(
                                  '检修进度内容及调令: ${shuntingItem['repairProgressContent'] ?? ''}'),
                              Text(
                                  '发送人员: ${shuntingItem['sendUserName'] ?? ''}'),
                              Text(
                                  '接受人员: ${shuntingItem['receiveUserName'] ?? ''}'),
                              Text('开始时间: ${shuntingItem['startTime'] ?? ''}'),
                              Text('结束时间: ${shuntingItem['endTime'] ?? ''}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> shuntingList = [];

  Future<void> getTrainRepairDynamics(RepairItem item) async {
    try {
      Map<String, dynamic> queryParametrs = {'trainEntryCode': item.code};
      // 获取检修进度信息内容
      var r = await ProductApi()
          .getTrainRepairDynamics(queryParametrs: queryParametrs);
      List<Map<String, dynamic>> rows =
          (r as List).map((item) => item as Map<String, dynamic>).toList();
      setState(() {
        shuntingList = rows;
      });
    } catch (e) {
      // 错误处理
    }
  }

  // 获取状态文本
  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '未开始';
      case 1:
        return '进行中';
      case 2:
        return '已完成';
      default:
        return '未知';
    }
  }

  // 获取状态颜色
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) {
      return '无';
    }
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  // 显示检修调令对话框
  void _showMaintenanceOrderDialog(BuildContext context, RepairItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择通知单类型'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('调车申请单'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    Navigator.pop(context);
                    getStopLocation();
                    _showShuntingApplicationDialog(context, item);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('调车通知单'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pop(context);
                    getStopLocation();
                    _showShuntingAnswerDialog(context, item);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('转序调令'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pop(context);
                    SmartDialog.showToast('调车通知单内容完成');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 推送选项的状态 - 只保留安全生产指挥中心
  bool _pushToCommandCenter = true;
  // 产生停留地点
  // 起始位置
  List<Map<String, dynamic>> stopLocationList = [];

  // 开始位置
  Map<String, dynamic> stopLocationSelected = {};
  // 结束位置
  Map<String, dynamic> stopLocationSelectedEnd = {};
  // 获取检修地点
  void getStopLocation() async {
    try {
      var r = await ProductApi().getstopLocation({
        'pageNum': 0,
        'pageSize': 0,
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
                  '${item.deptName}-${item.trackNum}-${item.areaName}',
              'areaName': item.areaName,
              'trackNum': item.trackNum,
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

  Map<String, dynamic> directionSelected = {};
  List<Map<String, dynamic>> directionList = [
    {
      'name': 'A',
    },
    {
      'name': 'B',
    }
  ];

  // 显示调车申请单输入对话框
  void _showShuntingApplicationDialog(BuildContext context, RepairItem item) {
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String? _selectedType;
    void savetrainShunting() async {
      Map<String, dynamic> queryParametrs = {
        'applyDeptId': Global.profile.permissions?.user.deptId,
        'applyUserId': Global.profile.permissions?.user.userId,
        'applyUserName': Global.profile.permissions?.user.userName,
        'dynamicCode': item.dynamicCode,
        'endStopPositionCode': stopLocationSelectedEnd['code'],
        'ends': directionSelected['name'],
        'remark': _reasonController.text,
        'sort': 0,
        'startStopPositionCode': stopLocationSelected['code'],
        'status': 0,
        'trainEntryCode': item.code,
        'typeCode': item.typeCode,
      };
      var r =
          await ProductApi().saveTrainShunting(queryParametrs: queryParametrs);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('调车申请单'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // 展示车号和停留地点信息
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '车号: ${item.trainNum ?? "未知"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '停留地点: ${item.stoppingPlace ?? "未知"}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  //增加朝向
                  ZjcFormSelectCell(
                      title: "端",
                      text: directionSelected["name"] ?? '',
                      hintText: "请选择",
                      clickCallBack: () {
                        if (directionList.isEmpty) {
                          showToast("无朝向可选择");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: directionList,
                            labelKey: 'name',
                            valueKey: 'name',
                            childrenKey: 'children',
                            title: "选择朝向",
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                logger.i(selectArr);
                                directionSelected['name'] = selectItem['name'];
                              });
                            },
                          );
                        }
                      }),
                  const SizedBox(height: 10),
                  ZjcFormSelectCell(
                    title: "起始位置",
                    text: stopLocationSelected["realLocation"],
                    hintText: "请选择",
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
                              stopLocationSelected["areaName"] =
                                  selectItem["areaName"];
                              stopLocationSelected["trackNum"] =
                                  selectItem["trackNum"];
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "终点位置",
                    text: stopLocationSelectedEnd["realLocation"],
                    hintText: "请选择",
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
                              stopLocationSelectedEnd["code"] =
                                  selectItem["code"];
                              stopLocationSelectedEnd["realLocation"] =
                                  selectItem["realLocation"];
                              stopLocationSelectedEnd["areaName"] =
                                  selectItem["areaName"];
                              stopLocationSelectedEnd["trackNum"] =
                                  selectItem["trackNum"];
                            });
                          },
                        );
                      }
                    },
                  ),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 处理提交逻辑
                    Navigator.pop(context);
                    savetrainShunting();
                    SmartDialog.showToast('调车申请已提交');
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 显示
  void _showShuntingAnswerDialog(BuildContext context, RepairItem item) {
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String? _selectedType;
    void savetrainShunting() async {
      Map<String, dynamic> queryParametrs = {
        'applyDeptId': Global.profile.permissions?.user.deptId,
        'applyUserId': Global.profile.permissions?.user.userId,
        'applyUserName': Global.profile.permissions?.user.userName,
        'dynamicCode': item.dynamicCode,
        'endStopPositionCode': stopLocationSelectedEnd['code'],
        'ends': directionSelected['name'],
        'remark': _reasonController.text,
        'sort': 0,
        'startStopPositionCode': stopLocationSelected['code'],
        'status': 0,
        'trainEntryCode': item.code,
        'typeCode': item.typeCode,
      };
      var r =
          await ProductApi().saveTrainShunting(queryParametrs: queryParametrs);
    }

    Future<void> _selectDate(
        BuildContext context, Function(DateTime) onDateSelected) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    }

    DateTime? _estimatedStartDate;
    DateTime? _planDateSelected;
    DateTime? _planDateSelectedEnd;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('调车通知单'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // 展示车号和停留地点信息
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '车号: ${item.trainNum ?? "未知"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '停留地点: ${item.stoppingPlace ?? "未知"}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  //增加朝向
                  ZjcFormSelectCell(
                      title: "端",
                      text: directionSelected["name"] ?? '',
                      hintText: "请选择",
                      clickCallBack: () {
                        if (directionList.isEmpty) {
                          showToast("无朝向可选择");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: directionList,
                            labelKey: 'name',
                            valueKey: 'name',
                            childrenKey: 'children',
                            title: "选择朝向",
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                logger.i(selectArr);
                                directionSelected['name'] = selectItem['name'];
                              });
                            },
                          );
                        }
                      }),
                  const SizedBox(height: 10),
                  ZjcFormSelectCell(
                    title: "起始位置",
                    text: stopLocationSelected["realLocation"],
                    hintText: "请选择",
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
                              stopLocationSelected["areaName"] =
                                  selectItem["areaName"];
                              stopLocationSelected["trackNum"] =
                                  selectItem["trackNum"];
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "终点位置",
                    text: stopLocationSelectedEnd["realLocation"],
                    hintText: "请选择",
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
                              stopLocationSelectedEnd["code"] =
                                  selectItem["code"];
                              stopLocationSelectedEnd["realLocation"] =
                                  selectItem["realLocation"];
                              stopLocationSelectedEnd["areaName"] =
                                  selectItem["areaName"];
                              stopLocationSelectedEnd["trackNum"] =
                                  selectItem["trackNum"];
                            });
                          },
                        );
                      }
                    },
                  ),
                  //计划日期 进行日期筛选
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _estimatedStartDate != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(_estimatedStartDate!)
                          : '未选择',
                    ),
                    decoration: InputDecoration(
                      labelText: '预计上台日期',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, (date) {
                          setState(() {
                            _estimatedStartDate = date;
                          });
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _planDateSelected != null
                                ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(_planDateSelected!)
                                : '请选择计划开始时间',
                          ),
                          decoration: InputDecoration(
                            labelText: '计划开始时间',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _planDateSelected ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  locale: const Locale('zh', 'CN'),
                                  helpText: '选择日期',
                                  cancelText: '取消',
                                  confirmText: '确定',
                                );

                                if (pickedDate != null) {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: _planDateSelected != null
                                        ? TimeOfDay.fromDateTime(
                                            _planDateSelected!)
                                        : TimeOfDay.now(),
                                    helpText: '选择时间',
                                    cancelText: '取消',
                                    confirmText: '确定',
                                  );
                                  if (pickedTime != null) {
                                    final DateTime dateTimeWithTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                      0,
                                    );

                                    setState(() {
                                      _planDateSelected = dateTimeWithTime;
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),   
                    ],
                  ),
                                    const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _planDateSelectedEnd != null
                                ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(_planDateSelectedEnd!)
                                : '请选择计划结束时间',
                          ),
                          decoration: InputDecoration(
                            labelText: '计划结束时间',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _planDateSelected ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  locale: const Locale('zh', 'CN'),
                                  helpText: '选择日期',
                                  cancelText: '取消',
                                  confirmText: '确定',
                                );

                                if (pickedDate != null) {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: _planDateSelected != null
                                        ? TimeOfDay.fromDateTime(
                                            _planDateSelected!)
                                        : TimeOfDay.now(),
                                    helpText: '选择时间',
                                    cancelText: '取消',
                                    confirmText: '确定',
                                  );
                                  if (pickedTime != null) {
                                    final DateTime dateTimeWithTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                      0,
                                    );

                                    setState(() {
                                      _planDateSelected = dateTimeWithTime;
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),   
                    ],
                  ),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                ])),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 处理提交逻辑
                    Navigator.pop(context);
                    savetrainShunting();
                    SmartDialog.showToast('调车申请已提交');
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
