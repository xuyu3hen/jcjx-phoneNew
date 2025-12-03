import 'package:http/http.dart';
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
    // await getTrainRepairDynamics(item);
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: const Text('检修进度列表'),
    //       content: SizedBox(
    //         width: double.maxFinite,
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             SizedBox(
    //               height: MediaQuery.of(context).size.height * 0.6,
    //               child: ListView.builder(
    //                 itemCount: shuntingList.length,
    //                 itemBuilder: (context, index) {
    //                   final shuntingItem = shuntingList[index];
    //                   return Card(
    //                     child: Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Column(
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Text(
    //                               '流水号: ${shuntingItem['shuntingEncode'] ?? ''}'),
    //                           Text(
    //                             '调令类型: ${noticeMap[shuntingItem['shuntingType']] ?? ''}',
    //                             style: const TextStyle(
    //                               color: Colors.green,
    //                               fontWeight: FontWeight.bold,
    //                             ),
    //                           ),
    //                           Text(
    //                               '修程（故障）内容: ${shuntingItem['faultContent'] ?? ''}'),
    //                           Text(
    //                               '检修进度内容及调令: ${shuntingItem['repairProgressContent'] ?? ''}'),
    //                           Text(
    //                               '发送人员: ${shuntingItem['sendUserName'] ?? ''}'),
    //                           Text(
    //                               '接受人员: ${shuntingItem['receiveUserName'] ?? ''}'),
    //                           Text('开始时间: ${shuntingItem['startTime'] ?? ''}'),
    //                           Text('结束时间: ${shuntingItem['endTime'] ?? ''}'),
    //                         ],
    //                       ),
    //                     ),
    //                   );
    //                 },
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //           },
    //           child: const Text('关闭'),
    //         ),
    //       ],
    //     );
    //   },
    // );
        await getTrainRepairDynamics(item);
    // 导航到新的页面而不是显示对话框
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepairProgressDetailPage(
          shuntingList: shuntingList,
          noticeMap: noticeMap,
        ),
      ),
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

  List<Map<String, dynamic>> investigateList = [];

  Future<void> getMasInvestigate(RepairItem item) async {
    try {
      Map<String, dynamic> queryParametrs = {
        'trainEntryCode': item.code,
      };
      var r =
          await ProductApi().getMasInestigate(queryParametrs: queryParametrs);

      // 修复类型转换错误，确保返回的是List类型
      List<Map<String, dynamic>> rows = [];
      if (r != null && r is List) {
        rows = r.map((item) => item as Map<String, dynamic>).toList();
      }

      setState(() {
        investigateList = rows;
        logger.i(investigateList);
      });
    } catch (e) {
      logger.e('获取调查清单失败: $e');
      showToast('获取数据失败');
    }
  }

  List<Map<String, dynamic>> masSaleList = [];

  Future<void> getMasSale(RepairItem item) async {
    try {
      Map<String, dynamic> queryParametrs = {
        'trainEntryCode': item.code,
      };
      var r = await ProductApi()
          .getMasAfterSaleShunting(queryParametrs: queryParametrs);

      // 修复类型转换错误，确保返回的是List类型
      List<Map<String, dynamic>> rows = [];
      if (r != null && r is List) {
        rows = r.map((item) => item as Map<String, dynamic>).toList();
      }

      setState(() {
        masSaleList = rows;
        logger.i(masSaleList);
      });
    } catch (e) {
      logger.e('获取调查清单失败: $e');
      showToast('获取数据失败');
    }
  }

  // 显示检修调令对话框

  // ... existing code ...
  // 显示检修调令对话框
  void _showMaintenanceOrderDialog(BuildContext context, RepairItem item) {
    int selectedOption = -1; // -1表示未选择，0表示调车申请单，1表示调车通知单，2表示调查清单

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      leading: Radio<int>(
                        value: 0,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('调车申请单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 0;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Radio<int>(
                        value: 1,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('调车通知单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 1;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Radio<int>(
                        value: 2,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('调查清单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 2;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Radio<int>(
                        value: 3,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('售后服务通知单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 3;
                        });
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
                ElevatedButton(
                  onPressed: selectedOption == -1
                      ? null
                      : () async {
                          Navigator.pop(context);
                          switch (selectedOption) {
                            case 0: // 调车申请单
                              getStopLocation();
                              _showShuntingApplicationDialog(context, item);
                              break;
                            case 1: // 调车通知单
                              getStopLocation();
                              _showShuntingAnswerDialog(context, item);
                              break;
                            case 2: // 调查清单
                              //跳转到PlanListPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PlanListPage(repairItem: item)),
                              );
                              break;
                            case 3: // 售后服务通知单
                              getMasSale(item);
                              _showServiceAnswerDialog(context, item);
                              break;
                          }
                        },
                  child: const Text('下一步'),
                ),
              ],
            );
          },
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

  // ... existing code ...
  void _showInvestigateListDialog(BuildContext context, RepairItem item) {
    // 展示investigateList
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('调查清单'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                if (investigateList.isEmpty)
                  const Text('暂无调查清单')
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: investigateList.length,
                      itemBuilder: (context, index) {
                        final investigateItem = investigateList[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '故障现象: ${investigateItem['faultInformation'] ?? ''}'),
                                Text(
                                    '故障类别: ${investigateItem['failureCategory'] ?? ''}'),
                                Text(
                                    '故障时间: ${investigateItem['faultDate'] ?? ''}'),
                                Text(
                                    '停留地点: ${investigateItem['trainLocation'] ?? ''}'),
                                Text(
                                    '填报时间: ${investigateItem['createdTime'] ?? ''}'),
                                // 新增一个按钮填写调查内容与签收情况
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showInvestigateInputDialog(
                                        context, item, investigateItem);
                                  },
                                  child: const Text('填写调查内容与签收情况'),
                                ),
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

  // 显示调查清单
  void _showServiceAnswerDialog(BuildContext context, RepairItem item) {
    // 展示investigateList
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('调查清单'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                if (masSaleList.isEmpty)
                  const Text('暂无调查清单')
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: masSaleList.length,
                      itemBuilder: (context, index) {
                        final masSaleItem = masSaleList[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '客户联系人: ${masSaleItem['customerContact'] ?? ''}'),
                                Text(
                                    '外包厂家信息: ${masSaleItem['outSourcingFactory'] ?? ''}'),
                                Text(
                                    '故障信息: ${masSaleItem['faultInformation'] ?? ''}'),
                                Text(
                                    '处置方案: ${masSaleItem['disposalPlan'] ?? ''}'),
                                Text(
                                    '审批意见: ${masSaleItem['planAuditOpinion'] ?? ''}'),
                                Text(
                                    '队长所属车间: ${masSaleItem['leaderDeptName'] ?? ''}'),
                                Text(
                                    '处置车间: ${masSaleItem['disposalDeptName'] ?? ''}'),
                                Text(
                                    '发货时间: ${masSaleItem['materialDeliveryTime'] ?? ''}'),    
                                //填报人
                                Text(
                                    '填报人: ${masSaleItem['reportUserName'] ?? ''}'),
                                
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

  // 显示调查内容输入对话框
  void _showInvestigateInputDialog(BuildContext context, RepairItem item,
      Map<String, dynamic> investigateItem) {
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _resultController = TextEditingController();
    final masInvestigateList = investigateItem['masInvestigateListList'] ?? [];
    final shuntingNoticeList = investigateItem['shuntingNoticeList'] ?? [];
    List<Map<String, dynamic>> mappedList = [];
    List<Map<String, dynamic>> shuntingMappedList = [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    if (shuntingNoticeList is List) {
      shuntingMappedList = shuntingNoticeList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('填写调查内容与签收情况'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //展示mappedList内容
                //标题是调查内容
                const Text(
                  '调查内容',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: mappedList.length,
                    itemBuilder: (context, index) {
                      final masItem = mappedList[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('调查内容发布人: ${masItem['createdBy'] ?? ''}'),
                              Text('发布时间: ${masItem['createdTime'] ?? ''}'),
                              Text(
                                  '调查内容: ${masItem['investigateContent'] ?? ''}'),
                              Text(
                                  '调查结果: ${masItem['investigateResult'] ?? ''}'),
                              Text('调查部门: ${masItem['deptName'] ?? ''}'),
                              Text('调查班组: ${masItem['teamName'] ?? ''}'),
                              Text('调查人: ${masItem['reportUserName'] ?? ''}'),
                              // 自己的部门或者父部门
                              if (Global.profile.permissions?.user.deptId ==
                                      masItem['deptId'] ||
                                  Global.profile.permissions?.user.dept
                                          ?.parentId ==
                                      masItem['deptId'])
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showEditInvestigateDialog(
                                          context, item, masItem);
                                    },
                                    child: const Text('编辑'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '调令内容',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: shuntingMappedList.length,
                    itemBuilder: (context, index) {
                      final shuntingItem = shuntingMappedList[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '调令发布人: ${shuntingItem['applyUserName'] ?? ''}'),
                              Text('发布时间: ${shuntingItem['applyTime'] ?? ''}'),
                              Text(
                                  '签收部门: ${shuntingItem['auditDeptName'] ?? ''}'),
                              Text(
                                  '签收人: ${shuntingItem['auditUserName'] ?? ''}'),
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
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 显示编辑调查内容对话框
  void _showEditInvestigateDialog(BuildContext context, RepairItem item,
      Map<String, dynamic> investigateItem) {
    final TextEditingController _contentController = TextEditingController(
        text: investigateItem['investigateContent'] as String? ?? '');
    final TextEditingController _resultController = TextEditingController(
        text: investigateItem['investigateResult'] as String? ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('填写调查结果'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('调查内容'),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      investigateItem['investigateContent'] as String? ?? '',
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _resultController,
                  decoration: const InputDecoration(
                    labelText: '调查结果',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 更新调查内容
                await ProductApi().updateMasInvestigateList({
                  'code': investigateItem['code'],
                  'deptId': Global.profile.permissions?.user.deptId,
                  'deptName': Global.profile.permissions?.user.dept?.deptName,
                  'investigateResult': _resultController.text,
                  'reportUserId': Global.profile.permissions?.user.userId,
                  'reportUserName': Global.profile.permissions?.user.nickName,
                  'teamId': Global.profile.permissions?.user.deptId,
                  'teamName': Global.profile.permissions?.user.dept?.deptName,
                });

                // 关闭对话框
                Navigator.of(context).pop();

                // 刷新界面
                await _loadRepairProgressData();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 显示调车申请单输入对话框
  void _showShuntingApplicationDialog(BuildContext context, RepairItem item) {
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String? _selectedType;
    void savetrainShunting() async {
      try {
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
        var r = await ProductApi()
            .saveTrainShunting(queryParametrs: queryParametrs);
      } catch (e) {
        logger.e('savetrainShunting 方法中发生异常: $e');
      }
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
                    FocusScope.of(context).unfocus(); // 确保收起键盘
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

  // 显示调车通知单
  void _showShuntingAnswerDialog(BuildContext context, RepairItem item) {
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String? _selectedType;
    DateTime? _estimatedStartDate;
    DateTime? _planDateSelected;
    DateTime? _planDateSelectedEnd;
    void saveShuntingAnswer() async {
      try {
        logger
            .i('_planDateSelected.toString(): ${_planDateSelected.toString()}');
        logger.i(
            '_planDateSelectedEnd.toString(): ${_planDateSelectedEnd.toString()}');
        List<Map<String, dynamic>> queryParametrs = [
          {
            'endStopPositionCode': stopLocationSelectedEnd['code'],
            'ends': directionSelected['name'],
            'planDate': _estimatedStartDate!.millisecondsSinceEpoch,
            'planStartTime': _planDateSelected.toString(),
            'planEndTime': _planDateSelectedEnd.toString(),
            'remark': _reasonController.text,
            'sort': 0,
            'startStopPositionCode': stopLocationSelected['code'],
            'status': 0,
            'trainEntryCode': item.code,
            'trainNum': item.trainNum,
            'typeCode': item.typeCode,
          }
        ];
        var r = await ProductApi()
            .addTrainShuntingPlan(queryParametrs: queryParametrs);
      } catch (e) {
        logger.e('saveShuntingAnswer 方法中发生异常: $e');
      }
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
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  child: const Text('此刻'),
                                  onPressed: () {
                                    setState(() {
                                      _planDateSelected = DateTime.now();
                                    });
                                  },
                                ),
                                IconButton(
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
                                        final DateTime dateTimeWithTime =
                                            DateTime(
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
                              ],
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
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  child: const Text('此刻'),
                                  onPressed: () {
                                    setState(() {
                                      _planDateSelectedEnd = DateTime.now();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _planDateSelectedEnd ??
                                          DateTime.now(),
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
                                        initialTime:
                                            _planDateSelectedEnd != null
                                                ? TimeOfDay.fromDateTime(
                                                    _planDateSelectedEnd!)
                                                : TimeOfDay.now(),
                                        helpText: '选择时间',
                                        cancelText: '取消',
                                        confirmText: '确定',
                                      );
                                      if (pickedTime != null) {
                                        final DateTime dateTimeWithTime =
                                            DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                          0,
                                        );

                                        setState(() {
                                          _planDateSelectedEnd =
                                              dateTimeWithTime;
                                        });
                                      }
                                    }
                                  },
                                ),
                              ],
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
                    FocusScope.of(context).unfocus();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 处理提交逻辑
                    Navigator.pop(context);
                    saveShuntingAnswer();
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

// 检修进度详情页面
class RepairProgressDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> shuntingList;
  final Map<int, dynamic> noticeMap;

  const RepairProgressDetailPage({
    Key? key,
    required this.shuntingList,
    required this.noticeMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检修进度列表'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: shuntingList.length,
        itemBuilder: (context, index) {
          final shuntingItem = shuntingList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '流水号: ${shuntingItem['shuntingEncode'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '调令类型: ${noticeMap[shuntingItem['shuntingType']] ?? ''}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '修程（故障）内容: ${shuntingItem['faultContent'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '检修进度内容及调令: ${shuntingItem['repairProgressContent'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '发送人员: ${shuntingItem['sendUserName'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '接受人员: ${shuntingItem['receiveUserName'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开始时间: ${shuntingItem['startTime'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '结束时间: ${shuntingItem['endTime'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
