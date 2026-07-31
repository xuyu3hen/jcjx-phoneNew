import 'package:jcjx_phone/models/progress.dart';

import '../../index.dart';
import 'package:intl/intl.dart';

class TrainRepairProgressPage extends StatefulWidget {
  final String? initialSearchText;
  const TrainRepairProgressPage({super.key, this.initialSearchText});

  @override
  State<TrainRepairProgressPage> createState() =>
      _TrainRepairProgressPageState();
}

class _ShuntingFormData {
  Map<String, dynamic> repairMainNodeSelected = {'name': '', 'code': ''};
  List<Map<String, dynamic>> scheduleNodePickerList = [];
  Map<String, dynamic> scheduleNodeSelected = {
    'name': '',
    'code': '',
    'scheduleNodeName': ''
  };
  bool scheduleNodeLoading = false;
  Map<String, dynamic> directionSelected = {};
  Map<String, dynamic> stopLocationSelected = {};
  Map<String, dynamic> stopLocationSelectedEnd = {};
  bool deptMove = false;
  final TextEditingController reasonController = TextEditingController();

  // 动力类型、机型、车号
  Map<String, dynamic> dynamicTypeSelected = {'name': '', 'code': ''};
  List<Map<String, dynamic>> jcTypeList = [];
  Map<String, dynamic> jcTypeSelected = {'name': '', 'code': ''};
  List<Map<String, dynamic>> trainNumList = [];
  Map<String, dynamic> trainNumSelected = {'trainNum': '', 'code': ''};
  bool jcTypeLoading = false;
  bool trainNumLoading = false;
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

  final Map<String, Future<String>> _stopLocationDisplayFutureByCode = {};

  Future<String> _getStopLocationDisplayByCode(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) {
      return Future.value('');
    }
    return _stopLocationDisplayFutureByCode.putIfAbsent(trimmed, () async {
      try {
        final r = await ProductApi().getstopLocation({
          'pageNum': 0,
          'pageSize': 0,
          'code': trimmed,
        });
        final first =
            (r.rows != null && r.rows!.isNotEmpty) ? r.rows!.first : null;
        final deptName = first?.deptName;
        final trackNum = first?.trackNum;
        final areaName = first?.areaName;
        if (deptName != null &&
            deptName.isNotEmpty &&
            trackNum != null &&
            trackNum.isNotEmpty &&
            areaName != null &&
            areaName.isNotEmpty) {
          return '$deptName-$trackNum-$areaName';
        }
        return trimmed;
      } catch (_) {
        return trimmed;
      }
    });
  }

  // 用于追踪每个组的展开状态
  Map<int, bool> _groupExpansionStates = {};

  // 搜索文本
  String _searchText = '';

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchText);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('车号查询'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入车号进行搜索',
            ),
            autofocus: true,
            onSubmitted: (_) {
              final kw = controller.text.trim();
              setState(() {
                _searchText = kw;
              });
              if (kw.isNotEmpty && !_hasTrainNumMatch(kw)) {
                SmartDialog.showToast('车号查询为空');
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchText = '';
                });
                Navigator.of(context).pop();
              },
              child: const Text('清空'),
            ),
            TextButton(
              onPressed: () {
                final kw = controller.text.trim();
                setState(() {
                  _searchText = kw;
                });
                if (kw.isNotEmpty && !_hasTrainNumMatch(kw)) {
                  SmartDialog.showToast('车号查询为空');
                }
                Navigator.of(context).pop();
              },
              child: const Text('查询'),
            ),
          ],
        );
      },
    );
  }

  Map<int, dynamic> noticeMap = {
    0: '调车调令',
    1: '检修计划',
    2: '临修调令',
    3: '机车配置签收',
    4: '售后服务-调查清单',
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
    16: '计划排产调令',
    17: '售后通知单',
    18: '工人工装变更通知单',
    19: '材料工艺变更通知单',
    20: 'jt28提报单'
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchText != null) {
      _searchText = widget.initialSearchText!;
    }
    _loadRepairProgressData();
  }

  // 加载检修进度数据
  Future<void> _loadRepairProgressData({bool forceRefresh = false}) async {
    try {
      final cacheValid = !forceRefresh &&
          Global.isRepairProgressDataLoaded &&
          Global.repairProgressDataLoadTime != null &&
          DateTime.now()
                  .difference(Global.repairProgressDataLoadTime!)
                  .inMinutes <
              5 &&
          Global.cachedRepairProgressData.isNotEmpty;

      if (cacheValid) {
        setState(() {
          repairGroups = Global.cachedRepairProgressData;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // 如果没有缓存或缓存过期，则重新加载
      Map<String, dynamic> queryParametrs = {};
      List<RepairGroup> r =
          await ProductApi().getTrainEntryAndDynamics(queryParametrs);

      // 更新缓存
      Global.cachedRepairProgressData = r;
      Global.isRepairProgressDataLoaded = true;
      Global.repairProgressDataLoadTime = DateTime.now();

      setState(() {
        repairGroups = r;
        if (r.isNotEmpty) {
          logger.i(r[0].repairProcCode);
        }
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
    await _loadRepairProgressData(forceRefresh: true);
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
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: repairGroups.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 180),
                        Center(child: Text('暂无数据')),
                      ],
                    )
                  : _buildRepairList(),
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

  bool _hasTrainNumMatch(String kw) {
    for (final g in repairGroups) {
      final children = g.children ?? const <RepairItem>[];
      for (final it in children) {
        final tn = (it.trainNum ?? '').toString();
        if (tn.contains(kw)) return true;
      }
    }
    return false;
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
    final trainNumWithEnds = formatTrainNumWithEnds(item.trainNum, item.ends);
    final baseTrainNum = (item.trainNum ?? '').toString().trim();
    final trainNumText = trainNumWithEnds.isNotEmpty
        ? trainNumWithEnds
        : (baseTrainNum.isNotEmpty ? baseTrainNum : '未知车号');
    final typeNameText = (item.typeName ?? '').toString().trim();
    final headerText =
        typeNameText.isEmpty ? trainNumText : '$typeNameText $trainNumText';

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
                headerText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                FutureBuilder<String>(
                  future: _getStopLocationDisplayByCode(item.repairLocation),
                  builder: (context, snapshot) {
                    final text = snapshot.data ?? (item.repairLocation ?? '');
                    return Text(
                      '停留地点：$text',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    );
                  },
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
          item: item,
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
  void _showMaintenanceOrderDialog(BuildContext rootContext, RepairItem item) {
    int selectedOption = -1; // -1表示未选择，0表示调车作业申请单，1表示调车作业通知单，2表示调查清单

    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
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
                      title: const Text('调车作业申请单'),
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
                      title: const Text('调车作业通知单'),
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
                    const Divider(),
                    ListTile(
                      leading: Radio<int>(
                        value: 4,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('转序通知单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 4;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Radio<int>(
                        value: 5,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? -1;
                          });
                        },
                      ),
                      title: const Text('修程通知单'),
                      onTap: () {
                        setState(() {
                          selectedOption = 5;
                        });
                      },
                    ),
// ... existing code ...
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: selectedOption == -1
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          switch (selectedOption) {
                            case 0: // 调车作业申请单
                              await getStopLocation(item);
                              if (!mounted) return;
                              _showShuntingApplicationDialog(rootContext, item);
                              break;
                            case 1: // 调车作业通知单
                              await getStopLocation(item);
                              if (!mounted) return;
                              _showShuntingAnswerDialog(rootContext, item);
                              break;
                            case 2: // 调查清单
                              //跳转到PlanListPage
                              if (!mounted) return;
                              Navigator.push(
                                rootContext,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PlanListPage(repairItem: item)),
                              );
                              break;
                            case 3: // 售后服务通知单
                              getMasSale(item);
                              if (!mounted) return;
                              _showServiceAnswerDialog(rootContext, item);
                              break;
                            case 4: // 转序通知单
                              break;
                            case 5: // 修程通知单
                              await getMasSale(item);
                              if (!mounted) return;
                              final noticeCandidates = masSaleList.isNotEmpty
                                  ? List<Map<String, dynamic>>.from(masSaleList)
                                  : <Map<String, dynamic>>[
                                      {
                                        'code': item.masSaleInformationCode ??
                                            item.code ??
                                            '',
                                        'faultInformation':
                                            item.repairDynamics ?? '',
                                        'trainNum': item.trainNum ?? '',
                                        'typeName': item.typeName ?? '',
                                        'repairProcName':
                                            item.repairProcName ?? '',
                                        'repairTimes': item.repairTimes ?? '',
                                        'trainLocation': item.stoppingPlace ??
                                            item.repairLocation ??
                                            '',
                                        'assignSegmentName':
                                            item.assignSegmentName ?? '',
                                      }
                                    ];
                              if (masSaleList.isEmpty) {
                                showToast('未查询到现成修程数据，已打开填写界面');
                              }
                              await Navigator.push(
                                rootContext,
                                MaterialPageRoute(
                                  builder: (context) => RepairProcessNoticePage(
                                    item: item,
                                    noticeCandidates: noticeCandidates,
                                  ),
                                ),
                              );
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
  List<Map<String, dynamic>> startStopLocationList = [];

  // 开始位置
  Map<String, dynamic> stopLocationSelected = {};
  // 结束位置
  Map<String, dynamic> stopLocationSelectedEnd = {};
  // 获取检修地点
  Future<void> getStopLocation(RepairItem item) async {
    await _refreshAllStopLocations();
    _applyDefaultStartStopLocation(item, null);
  }

  Future<void> _refreshAllStopLocations() async {
    try {
      final queryParametrs = <String, dynamic>{
        'pageNum': 0,
        'pageSize': 0,
      };
      var r = await ProductApi().getstopLocation(queryParametrs);
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
      if (!mounted) return;
      setState(() {
        stopLocationList = processedStopLocations;
        startStopLocationList = processedStopLocations;
      });
    } catch (e, stackTrace) {
      logger.e('initSelectInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  Map<String, dynamic> _computeDefaultStartStopLocation(
      RepairItem item, String? endValue) {
    final e = (endValue ?? '').toUpperCase();
    String codeParam;
    if (e == 'B') {
      codeParam = (item.repairLocationB ?? '').trim();
    } else {
      codeParam = (item.repairLocation ?? '').trim();
    }
    if (codeParam.isEmpty) {
      return {};
    }
    final match = stopLocationList.cast<Map<String, dynamic>>().where((m) {
      return (m['code']?.toString() ?? '') == codeParam;
    }).toList();
    return match.isEmpty ? {} : Map<String, dynamic>.from(match.first);
  }

  void _applyDefaultStartStopLocation(RepairItem item, String? endValue) {
    if (!mounted) return;
    setState(() {
      stopLocationSelected = _computeDefaultStartStopLocation(item, endValue);
    });
  }

  Map<String, dynamic> directionSelected = {};
  List<Map<String, dynamic>> directionList = [
    {
      'name': 'A',
      'value': 'A',
    },
    {
      'name': 'B',
      'value': 'B',
    },
    {
      'name': 'AB',
      'value': 'AB',
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

  // 显示调车作业申请单输入对话框
  void _showShuntingApplicationDialog(BuildContext context, RepairItem item) {
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String? _selectedType;
    List<Map<String, dynamic>> repairMainNodeList = [];
    Map<String, dynamic> repairMainNodeSelected = {'name': '', 'code': ''};
    bool repairMainNodeRequested = false;
    bool repairMainNodeLoading = false;
    List<Map<String, dynamic>> scheduleNodePickerList = [];
    Map<String, dynamic> scheduleNodeSelected = {
      'name': '',
      'code': '',
      'scheduleNodeName': '',
    };
    bool scheduleNodeLoading = false;

    List<Map<String, dynamic>> parseScheduleRows(dynamic response) {
      dynamic raw = response;
      if (raw is Map) {
        raw = raw['rows'] ??
            raw['records'] ??
            raw['data'] ??
            raw['list'] ??
            raw['result'] ??
            raw;
        if (raw is Map) {
          final lists = raw.values.whereType<List>().toList();
          if (lists.length == 1) {
            raw = lists.first;
          }
        }
      }
      final list = raw is List ? raw : const <dynamic>[];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    String scheduleNodeName(Map<String, dynamic> row) {
      return (row['schedleNodeName'] ??
              row['scheduleNodeName'] ??
              row['mainNodeSchedleNodeName'] ??
              row['nodeName'] ??
              row['name'] ??
              '')
          .toString();
    }

    int scheduleNodeSort(Map<String, dynamic> row) {
      final v = row['sort'] ?? row['orderNum'] ?? row['seq'] ?? row['index'];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    bool isScheduleNodeActive(Map<String, dynamic> row) {
      final state = row['state'];
      if (state != null) {
        if (state is bool) return state;
        final s = state.toString().trim().toLowerCase();
        if (s == 'false') return false;
        return true;
      }
      final status = row['status'];
      if (status != null) {
        if (status is bool) return status;
        if (status is num) return true;
        final s = status.toString().trim().toLowerCase();
        if (s == 'false') return false;
        return true;
      }
      final enabled = row['enabled'] ?? row['enable'];
      if (enabled != null) {
        if (enabled is bool) return enabled;
        if (enabled is num) return enabled.toInt() != 0;
        final s = enabled.toString().trim().toLowerCase();
        if (s == 'false' || s == '0') return false;
        return true;
      }
      return true;
    }

    String scheduleNodeTimeRange(Map<String, dynamic> row) {
      final startRaw = (row['planStartTime'] ??
              row['theoreticStartTime'] ??
              row['startTime'] ??
              '')
          .toString();
      final endRaw = (row['planEndTime'] ??
              row['theoreticEndTime'] ??
              row['endTime'] ??
              '')
          .toString();
      if (startRaw.trim().isEmpty && endRaw.trim().isEmpty) return '';
      final start = startRaw.trim().isEmpty ? '' : _formatDateTime(startRaw);
      final end = endRaw.trim().isEmpty ? '' : _formatDateTime(endRaw);
      if (start.isEmpty) return end;
      if (end.isEmpty) return start;
      return '$start ~ $end';
    }

    Future<void> loadScheduleNodes(StateSetter setState) async {
      final repairMainNodeCode =
          (repairMainNodeSelected['code'] ?? '').toString().trim();
      if (repairMainNodeCode.isEmpty) {
        setState(() {
          scheduleNodePickerList = [];
          scheduleNodeSelected = {
            'name': '',
            'code': '',
            'scheduleNodeName': ''
          };
          scheduleNodeLoading = false;
        });
        return;
      }
      setState(() {
        scheduleNodeLoading = true;
        scheduleNodePickerList = [];
        scheduleNodeSelected = {'name': '', 'code': '', 'scheduleNodeName': ''};
      });
      try {
        final r = await ProductApi().getMainNodeSchedleNodeAll(
          queryParametrs: <String, dynamic>{
            'pageNum': 0,
            'pageSize': 0,
            'repairMainNodeCode': repairMainNodeCode,
          },
        );
        var rows = parseScheduleRows(r);
        rows = rows.where((m) => m['deleted'] != true).toList();
        final activeRows = rows.where(isScheduleNodeActive).toList();
        if (activeRows.isNotEmpty && activeRows.length != rows.length) {
          rows = activeRows;
        }
        rows.sort((a, b) => scheduleNodeSort(a).compareTo(scheduleNodeSort(b)));
        final pickerList = rows
            .map((row) {
              final code = (row['code'] ??
                      row['mainNodeSchedleNodeCode'] ??
                      row['mainNodeScheduleNodeCode'] ??
                      row['scheduleNodeCode'] ??
                      row['schedleNodeCode'] ??
                      '')
                  .toString();
              final name = scheduleNodeName(row);
              final timeText = scheduleNodeTimeRange(row);
              final displayName = timeText.isEmpty ? name : '$name  $timeText';
              return <String, dynamic>{
                'code': code,
                'name': displayName,
                'scheduleNodeName': name,
                'sort': scheduleNodeSort(row),
              };
            })
            .where((m) => (m['code'] ?? '').toString().trim().isNotEmpty)
            .toList();
        setState(() {
          scheduleNodePickerList = pickerList;
          if (pickerList.length == 1) {
            scheduleNodeSelected = {
              'name': pickerList.first['name'],
              'code': pickerList.first['code'],
              'scheduleNodeName': pickerList.first['scheduleNodeName'],
            };
          }
          scheduleNodeLoading = false;
        });
      } catch (_) {
        setState(() {
          scheduleNodePickerList = [];
          scheduleNodeSelected = {
            'name': '',
            'code': '',
            'scheduleNodeName': ''
          };
          scheduleNodeLoading = false;
        });
      }
    }

    void savetrainShunting() async {
      try {
        Map<String, dynamic> queryParametrs = {
          'applyDeptId': Global.profile.permissions?.user.deptId,
          'applyUserId': Global.profile.permissions?.user.userId,
          'applyUserName': Global.profile.permissions?.user.userName,
          'dynamicCode': item.dynamicCode,
          'endStopPositionCode': stopLocationSelectedEnd['code'],
          'remark': _reasonController.text,
          'sort': 0,
          'startStopPositionCode': stopLocationSelected['code'],
          'status': 0,
          'trainEntryCode': item.code,
          'typeCode': item.typeCode,
        };
        final nodeCode =
            (repairMainNodeSelected['code'] ?? '').toString().trim();
        if (nodeCode.isNotEmpty) {
          queryParametrs['repairMainNodeCode'] = nodeCode;
          queryParametrs['repairMainNodeName'] =
              (repairMainNodeSelected['name'] ?? '').toString();
        }
        final scheduleCode =
            (scheduleNodeSelected['code'] ?? '').toString().trim();
        if (scheduleCode.isNotEmpty) {
          queryParametrs['scheduleNodeCode'] = scheduleCode;
          queryParametrs['scheduleNodeName'] =
              (scheduleNodeSelected['scheduleNodeName'] ??
                      scheduleNodeSelected['name'] ??
                      '')
                  .toString();
        }
        if (item.doubleCarriage == true) {
          queryParametrs['ends'] =
              directionSelected['value'] ?? directionSelected['name'];
        }
        await ProductApi().saveTrainShunting(queryParametrs: queryParametrs);
      } catch (e) {
        logger.e('savetrainShunting 方法中发生异常: $e');
      }
    }

    if (item.doubleCarriage != true) {
      directionSelected = {};
    }
    stopLocationSelected = {};
    stopLocationSelectedEnd = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!repairMainNodeRequested) {
              repairMainNodeRequested = true;
              repairMainNodeLoading = true;
              Future(() async {
                try {
                  final repairProcCode = (item.repairProcCode ?? '').trim();
                  final queryParametrs = <String, dynamic>{
                    'pageNum': 0,
                    'pageSize': 0,
                    'repairProcCode': repairProcCode,
                  };
                  final r = await ProductApi()
                      .getRepairMainNodeAll(queryParametrs: queryParametrs);
                  var list = r.toMapList();
                  list = list.where((m) => m['deleted'] != true).toList();
                  list.sort((a, b) {
                    final sa = (a['sort'] as num?)?.toInt() ?? 0;
                    final sb = (b['sort'] as num?)?.toInt() ?? 0;
                    return sa.compareTo(sb);
                  });
                  final activeCodes = (item.stateDetailList ?? const [])
                      .where((e) => (e.state ?? '').toString() == '1')
                      .map(
                          (e) => (e.repairMainNodeCode ?? '').toString().trim())
                      .where((e) => e.isNotEmpty)
                      .toSet();
                  if (activeCodes.isNotEmpty) {
                    list = list
                        .where((m) =>
                            activeCodes.contains((m['code'] ?? '').toString()))
                        .toList();
                  }
                  if (!context.mounted) return;
                  setState(() {
                    repairMainNodeList = list;
                    if (((repairMainNodeSelected['code'] ?? '')
                            .toString()
                            .trim())
                        .isEmpty) {
                      if (list.length == 1) {
                        repairMainNodeSelected = {
                          'name': list.first['name'],
                          'code': list.first['code'],
                        };
                      }
                    }
                    repairMainNodeLoading = false;
                  });
                  if (!context.mounted) return;
                  if (((repairMainNodeSelected['code'] ?? '').toString().trim())
                      .isNotEmpty) {
                    await loadScheduleNodes(setState);
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  setState(() {
                    repairMainNodeList = [];
                    repairMainNodeLoading = false;
                  });
                }
              });
            }
            return AlertDialog(
              title: const Text('调车作业申请单'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '车号: ${item.trainNum ?? "未知"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ZjcFormSelectCell(
                      title: "工序节点",
                      text: repairMainNodeSelected['name'] ?? '',
                      hintText: repairMainNodeLoading ? "加载中..." : "请选择",
                      clickCallBack: () {
                        if (repairMainNodeLoading) return;
                        if (repairMainNodeList.isEmpty) {
                          showToast("无工序节点可选择");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: repairMainNodeList,
                            labelKey: 'name',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: "选择工序节点",
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                repairMainNodeSelected = {
                                  'name': selectItem['name'],
                                  'code': selectItem['code'],
                                };
                                scheduleNodePickerList = [];
                                scheduleNodeSelected = {
                                  'name': '',
                                  'code': '',
                                  'scheduleNodeName': '',
                                };
                                scheduleNodeLoading = true;
                              });
                              loadScheduleNodes(setState);
                            },
                          );
                        }
                      },
                    ),
                    ZjcFormSelectCell(
                      title: "排程节点",
                      text: scheduleNodeSelected['name'] ?? '',
                      hintText: scheduleNodeLoading ? "加载中..." : "请选择",
                      clickCallBack: () {
                        if (scheduleNodeLoading) return;
                        if (scheduleNodePickerList.isEmpty) {
                          showToast("无排程节点可选择");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: scheduleNodePickerList,
                            labelKey: 'name',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: "选择排程节点",
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                scheduleNodeSelected = {
                                  'name': selectItem['name'],
                                  'code': selectItem['code'],
                                  'scheduleNodeName':
                                      selectItem['scheduleNodeName'],
                                };
                              });
                            },
                          );
                        }
                      },
                    ),
                    ZjcFormSelectCell(
                        title: "端",
                        text: directionSelected["name"] ?? '',
                        hintText: item.doubleCarriage == true ? "请选择" : "无需选择",
                        clickCallBack: () {
                          if (item.doubleCarriage != true) {
                            showToast("非重联无需选择端");
                            return;
                          }
                          if (directionList.isEmpty) {
                            showToast("无端可选择");
                          } else {
                            ZjcCascadeTreePicker.show(
                              context,
                              data: directionList,
                              labelKey: 'name',
                              valueKey: 'value',
                              childrenKey: 'children',
                              title: "选择端",
                              clickCallBack: (selectItem, selectArr) {
                                final selectedEnd =
                                    (selectItem['value'] ?? selectItem['name'])
                                        ?.toString();
                                setState(() {
                                  directionSelected['name'] =
                                      selectItem['name'];
                                  directionSelected['value'] = selectedEnd;
                                  stopLocationSelected = {};
                                });
                                _applyDefaultStartStopLocation(
                                    item, selectedEnd);
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
                        if (startStopLocationList.isEmpty) {
                          showToast("无检修地点可选择");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: startStopLocationList,
                            labelKey: 'realLocation',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: "选择检修地点",
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                logger.i(selectArr);
                                stopLocationSelected["code"] =
                                    selectItem["code"];
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
                    final nodeCode = (repairMainNodeSelected['code'] ?? '')
                        .toString()
                        .trim();
                    if (nodeCode.isEmpty) {
                      showToast("请选择工序节点");
                      return;
                    }
                    final scheduleCode =
                        (scheduleNodeSelected['code'] ?? '').toString().trim();
                    if (scheduleCode.isEmpty) {
                      showToast("请选择排程节点");
                      return;
                    }
                    final endCode = (stopLocationSelectedEnd['code'] ?? '')
                        .toString()
                        .trim();
                    if (endCode.isEmpty) {
                      showToast("请选择终点位置");
                      return;
                    }
                    Navigator.pop(context);
                    savetrainShunting();
                    SmartDialog.showToast('调车作业申请已提交');
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

  // 显示调车作业通知单
  void _showShuntingAnswerDialog(BuildContext context, RepairItem item) {
    final List<_ShuntingFormData> formDataList = [_ShuntingFormData()];
    DateTime? _planDateSelected;
    List<Map<String, dynamic>> repairMainNodeList = [];
    bool repairMainNodeRequested = false;
    bool repairMainNodeLoading = false;

    bool dynamicTypeRequested = false;
    bool dynamicTypeLoading = false;
    List<Map<String, dynamic>> globalDynamicTypeList = [];

    Future<void> _loadJcType(StateSetter setState, _ShuntingFormData fd) async {
      final dynamicCode =
          (fd.dynamicTypeSelected['code'] ?? '').toString().trim();
      if (dynamicCode.isEmpty) {
        setState(() {
          fd.jcTypeList = [];
          fd.jcTypeSelected = {'name': '', 'code': ''};
          fd.jcTypeLoading = false;
          fd.trainNumList = [];
          fd.trainNumSelected = {'trainNum': '', 'code': ''};
        });
        return;
      }
      setState(() {
        fd.jcTypeLoading = true;
        fd.jcTypeList = [];
        fd.jcTypeSelected = {'name': '', 'code': ''};
        fd.trainNumList = [];
        fd.trainNumSelected = {'trainNum': '', 'code': ''};
      });
      try {
        var r = await ProductApi().getJcType(queryParametrs: {
          'dynamicCode': dynamicCode,
          'pageNum': 0,
          'pageSize': 0
        });
        setState(() {
          fd.jcTypeList = r.toMapList();
          fd.jcTypeLoading = false;
        });
      } catch (_) {
        setState(() {
          fd.jcTypeList = [];
          fd.jcTypeLoading = false;
        });
      }
    }

    Future<void> _loadTrainNum(
        StateSetter setState, _ShuntingFormData fd) async {
      final typeCode = (fd.jcTypeSelected['code'] ?? '').toString().trim();
      if (typeCode.isEmpty) {
        setState(() {
          fd.trainNumList = [];
          fd.trainNumSelected = {'trainNum': '', 'code': ''};
          fd.trainNumLoading = false;
        });
        return;
      }
      setState(() {
        fd.trainNumLoading = true;
        fd.trainNumList = [];
        fd.trainNumSelected = {'trainNum': '', 'code': ''};
      });
      try {
        final r = await ProductApi().getTrainEntryDynamic({
          'typeCode': typeCode,
          'complete': 0,
          'tempRepair': false,
          'pageNum': 0,
          'pageSize': 0
        });
        dynamic raw = r;
        if (raw is Map) {
          raw = raw['rows'] ??
              raw['records'] ??
              raw['data'] ??
              raw['list'] ??
              raw['result'] ??
              raw;
          if (raw is Map) {
            final lists = raw.values.whereType<List>().toList();
            if (lists.length == 1) {
              raw = lists.first;
            }
          }
        }
        final List<Map<String, dynamic>> list =
            (raw is List ? raw : const <dynamic>[])
                .where((e) => e is Map)
                .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['displayTrainNum'] =
              formatTrainNumWithEnds(m['trainNum'], m['ends']);
          return m;
        }).toList();
        setState(() {
          fd.trainNumList = list;
          fd.trainNumLoading = false;
        });
      } catch (_) {
        setState(() {
          fd.trainNumList = [];
          fd.trainNumLoading = false;
        });
      }
    }

    List<Map<String, dynamic>> _parseScheduleRows(dynamic response) {
      dynamic raw = response;
      if (raw is Map) {
        raw = raw['rows'] ??
            raw['records'] ??
            raw['data'] ??
            raw['list'] ??
            raw['result'] ??
            raw;
        if (raw is Map) {
          final lists = raw.values.whereType<List>().toList();
          if (lists.length == 1) {
            raw = lists.first;
          }
        }
      }
      final list = raw is List ? raw : const <dynamic>[];
      return list
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    String _scheduleNodeName(Map<String, dynamic> row) {
      return (row['schedleNodeName'] ??
              row['scheduleNodeName'] ??
              row['mainNodeSchedleNodeName'] ??
              row['nodeName'] ??
              row['name'] ??
              '')
          .toString();
    }

    int _scheduleNodeSort(Map<String, dynamic> row) {
      final v = row['sort'] ?? row['orderNum'] ?? row['seq'] ?? row['index'];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    bool _isScheduleNodeActive(Map<String, dynamic> row) {
      final state = row['state'];
      if (state != null) {
        if (state is bool) return state;
        final s = state.toString().trim().toLowerCase();
        if (s == 'false') return false;
        return true;
      }
      final status = row['status'];
      if (status != null) {
        if (status is bool) return status;
        if (status is num) return true;
        final s = status.toString().trim().toLowerCase();
        if (s == 'false') return false;
        return true;
      }
      final enabled = row['enabled'] ?? row['enable'];
      if (enabled != null) {
        if (enabled is bool) return enabled;
        if (enabled is num) return enabled.toInt() != 0;
        final s = enabled.toString().trim().toLowerCase();
        if (s == 'false' || s == '0') return false;
        return true;
      }
      return true;
    }

    String _scheduleNodeTimeRange(Map<String, dynamic> row) {
      final startRaw = (row['planStartTime'] ??
              row['theoreticStartTime'] ??
              row['startTime'] ??
              '')
          .toString();
      final endRaw = (row['planEndTime'] ??
              row['theoreticEndTime'] ??
              row['endTime'] ??
              '')
          .toString();
      if (startRaw.trim().isEmpty && endRaw.trim().isEmpty) return '';
      final start = startRaw.trim().isEmpty ? '' : _formatDateTime(startRaw);
      final end = endRaw.trim().isEmpty ? '' : _formatDateTime(endRaw);
      if (start.isEmpty) return end;
      if (end.isEmpty) return start;
      return '$start ~ $end';
    }

    Future<void> _loadScheduleNodes(
        StateSetter setState, _ShuntingFormData fd) async {
      final repairMainNodeCode =
          (fd.repairMainNodeSelected['code'] ?? '').toString().trim();
      if (repairMainNodeCode.isEmpty) {
        setState(() {
          fd.scheduleNodePickerList = [];
          fd.scheduleNodeSelected = {
            'name': '',
            'code': '',
            'scheduleNodeName': ''
          };
          fd.scheduleNodeLoading = false;
        });
        return;
      }
      setState(() {
        fd.scheduleNodeLoading = true;
        fd.scheduleNodePickerList = [];
        fd.scheduleNodeSelected = {
          'name': '',
          'code': '',
          'scheduleNodeName': ''
        };
      });
      try {
        final r = await ProductApi().getMainNodeSchedleNodeAll(
          queryParametrs: <String, dynamic>{
            'pageNum': 0,
            'pageSize': 0,
            'repairMainNodeCode': repairMainNodeCode,
          },
        );
        var rows = _parseScheduleRows(r);
        rows = rows.where((m) => m['deleted'] != true).toList();
        final activeRows = rows.where(_isScheduleNodeActive).toList();
        if (activeRows.isNotEmpty && activeRows.length != rows.length) {
          rows = activeRows;
        }
        rows.sort(
            (a, b) => _scheduleNodeSort(a).compareTo(_scheduleNodeSort(b)));
        final pickerList = rows
            .map((row) {
              final code = (row['code'] ??
                      row['mainNodeSchedleNodeCode'] ??
                      row['mainNodeScheduleNodeCode'] ??
                      row['scheduleNodeCode'] ??
                      row['schedleNodeCode'] ??
                      '')
                  .toString();
              final name = _scheduleNodeName(row);
              final timeText = _scheduleNodeTimeRange(row);
              final displayName = timeText.isEmpty ? name : '$name  $timeText';
              return <String, dynamic>{
                'code': code,
                'name': displayName,
                'scheduleNodeName': name,
                'sort': _scheduleNodeSort(row),
              };
            })
            .where((m) => (m['code'] ?? '').toString().trim().isNotEmpty)
            .toList();
        setState(() {
          fd.scheduleNodePickerList = pickerList;
          if (pickerList.length == 1) {
            fd.scheduleNodeSelected = {
              'name': pickerList.first['name'],
              'code': pickerList.first['code'],
              'scheduleNodeName': pickerList.first['scheduleNodeName'],
            };
          }
          fd.scheduleNodeLoading = false;
        });
      } catch (_) {
        setState(() {
          fd.scheduleNodePickerList = [];
          fd.scheduleNodeSelected = {
            'name': '',
            'code': '',
            'scheduleNodeName': ''
          };
          fd.scheduleNodeLoading = false;
        });
      }
    }

    void saveShuntingAnswer() async {
      try {
        final planStart = _planDateSelected ?? DateTime.now();
        List<Map<String, dynamic>> queryParametrs = [];

        for (final fd in formDataList) {
          final row = <String, dynamic>{
            'endStopPositionCode': fd.stopLocationSelectedEnd['code'],
            'planDate': planStart.millisecondsSinceEpoch,
            'planStartTime': planStart.toString(),
            'remark': fd.reasonController.text,
            'sort': 0,
            'startStopPositionCode': fd.stopLocationSelected['code'],
            'ends': fd.directionSelected['value'],
            'deptMove': fd.deptMove,
            'trainEntryCode': fd.trainNumSelected['code'],
            'trainNum': fd.trainNumSelected['trainNum'],
            'typeCode': fd.jcTypeSelected['code'],
          };
          final nodeCode =
              (fd.repairMainNodeSelected['code'] ?? '').toString().trim();
          if (nodeCode.isNotEmpty) {
            row['repairMainNodeCode'] = nodeCode;
            row['repairMainNodeName'] =
                (fd.repairMainNodeSelected['name'] ?? '').toString();
          }
          final scheduleCode =
              (fd.scheduleNodeSelected['code'] ?? '').toString().trim();
          if (scheduleCode.isNotEmpty) {
            row['scheduleNodeCode'] = scheduleCode;
            row['scheduleNodeName'] =
                (fd.scheduleNodeSelected['scheduleNodeName'] ??
                        fd.scheduleNodeSelected['name'] ??
                        '')
                    .toString();
          }
          if (item.doubleCarriage == true) {
            row['ends'] =
                fd.directionSelected['value'] ?? fd.directionSelected['name'];
          }
          queryParametrs.add(row);
        }

        var r = await ProductApi()
            .directPublishShuntingPlan(queryParametrs: queryParametrs);
      } catch (e) {
        logger.e('saveShuntingAnswer 方法中发生异常: $e');
      }
    }

    for (final fd in formDataList) {
      if (item.doubleCarriage != true) {
        fd.directionSelected = {};
      }
      fd.stopLocationSelectedEnd = {};
      fd.stopLocationSelected = _computeDefaultStartStopLocation(
          item, fd.directionSelected['value']?.toString());
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!repairMainNodeRequested) {
              repairMainNodeRequested = true;
              repairMainNodeLoading = true;
              Future(() async {
                try {
                  final repairProcCode = (item.repairProcCode ?? '').trim();
                  final queryParametrs = <String, dynamic>{
                    'pageNum': 0,
                    'pageSize': 0,
                    'repairProcCode': repairProcCode,
                  };
                  final r = await ProductApi()
                      .getRepairMainNodeAll(queryParametrs: queryParametrs);
                  var list = r.toMapList();
                  list = list.where((m) => m['deleted'] != true).toList();
                  list.sort((a, b) {
                    final sa = (a['sort'] as num?)?.toInt() ?? 0;
                    final sb = (b['sort'] as num?)?.toInt() ?? 0;
                    return sa.compareTo(sb);
                  });
                  final activeCodes = (item.stateDetailList ?? const [])
                      .where((e) => (e.state ?? '').toString() == '1')
                      .map(
                          (e) => (e.repairMainNodeCode ?? '').toString().trim())
                      .where((e) => e.isNotEmpty)
                      .toSet();
                  if (activeCodes.isNotEmpty) {
                    list = list
                        .where((m) =>
                            activeCodes.contains((m['code'] ?? '').toString()))
                        .toList();
                  }
                  if (!context.mounted) return;
                  setState(() {
                    repairMainNodeList = list;
                    for (var fd in formDataList) {
                      if (((fd.repairMainNodeSelected['code'] ?? '')
                              .toString()
                              .trim())
                          .isEmpty) {
                        if (list.length == 1) {
                          fd.repairMainNodeSelected = {
                            'name': list.first['name'],
                            'code': list.first['code'],
                          };
                        }
                      }
                    }
                    repairMainNodeLoading = false;
                  });
                  if (!context.mounted) return;
                  for (var fd in formDataList) {
                    if (((fd.repairMainNodeSelected['code'] ?? '')
                            .toString()
                            .trim())
                        .isNotEmpty) {
                      await _loadScheduleNodes(setState, fd);
                    }
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  setState(() {
                    repairMainNodeList = [];
                    repairMainNodeLoading = false;
                  });
                }
              });
            }
            Future<void> pickDateTime({
              required DateTime? current,
              required void Function(DateTime dateTime) onPicked,
            }) async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: current ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('zh', 'CN'),
                helpText: '选择日期',
                cancelText: '取消',
                confirmText: '确定',
              );

              if (pickedDate == null) return;

              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: current != null
                    ? TimeOfDay.fromDateTime(current)
                    : TimeOfDay.now(),
                helpText: '选择时间',
                cancelText: '取消',
                confirmText: '确定',
              );

              if (pickedTime == null) return;

              final DateTime dateTimeWithTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
                0,
              );

              setState(() {
                onPicked(dateTimeWithTime);
              });
            }

            if (!dynamicTypeRequested) {
              dynamicTypeRequested = true;
              dynamicTypeLoading = true;
              Future(() async {
                try {
                  var r = await ProductApi().getDynamicType();
                  if (!context.mounted) return;
                  setState(() {
                    globalDynamicTypeList = r.toMapList();
                    for (var fd in formDataList) {
                      var match = globalDynamicTypeList.firstWhere(
                        (e) => e['code'] == item.dynamicCode,
                        orElse: () => globalDynamicTypeList.isNotEmpty
                            ? globalDynamicTypeList.first
                            : {'name': '', 'code': ''},
                      );
                      if ((fd.dynamicTypeSelected['code'] ?? '')
                          .toString()
                          .isEmpty) {
                        fd.dynamicTypeSelected =
                            Map<String, dynamic>.from(match);
                      }
                    }
                    dynamicTypeLoading = false;
                  });

                  if (!context.mounted) return;
                  for (var fd in formDataList) {
                    if ((fd.dynamicTypeSelected['code'] ?? '')
                        .toString()
                        .isNotEmpty) {
                      await _loadJcType(setState, fd);
                      if (!context.mounted) return;
                      var jcMatch = fd.jcTypeList.firstWhere(
                        (e) => e['code'] == item.typeCode,
                        orElse: () => fd.jcTypeList.isNotEmpty
                            ? fd.jcTypeList.first
                            : {'name': '', 'code': ''},
                      );
                      if ((fd.jcTypeSelected['code'] ?? '')
                          .toString()
                          .isEmpty) {
                        setState(() {
                          fd.jcTypeSelected =
                              Map<String, dynamic>.from(jcMatch);
                        });
                        await _loadTrainNum(setState, fd);
                        if (!context.mounted) return;
                        final desiredTrainNum =
                            (item.trainNum ?? '').toString().trim();
                        final desiredEnds = formatEndsSuffix(item.ends);
                        var trainMatch = fd.trainNumList.firstWhere(
                          (e) {
                            final tn = (e['trainNum'] ?? '').toString().trim();
                            if (tn != desiredTrainNum) return false;
                            if (desiredEnds.isEmpty) return true;
                            return formatEndsSuffix(e['ends']) == desiredEnds;
                          },
                          orElse: () => fd.trainNumList.isNotEmpty
                              ? fd.trainNumList.first
                              : {'trainNum': '', 'code': ''},
                        );
                        if ((fd.trainNumSelected['code'] ?? '')
                            .toString()
                            .isEmpty) {
                          setState(() {
                            fd.trainNumSelected =
                                Map<String, dynamic>.from(trainMatch);
                          });
                        }
                      }
                    }
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  setState(() {
                    globalDynamicTypeList = [];
                    dynamicTypeLoading = false;
                  });
                }
              });
            }

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('调车作业通知单'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        formDataList.add(_ShuntingFormData());
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 10),
                  ...(formDataList).asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final _ShuntingFormData fd = entry.value;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: Colors.grey.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (formDataList.length > 1)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('作业单 ${idx + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      if (formDataList.length > 1) {
                                        setState(() {
                                          formDataList.removeAt(idx);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            // 新增: 动力类型
                            ZjcFormSelectCell(
                              title: "动力类型",
                              text: fd.dynamicTypeSelected['name'] ?? '',
                              hintText: dynamicTypeLoading ? "加载中..." : "请选择",
                              clickCallBack: () {
                                if (dynamicTypeLoading) return;
                                if (globalDynamicTypeList.isEmpty) {
                                  showToast("无动力类型可选择");
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: globalDynamicTypeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: "选择动力类型",
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.dynamicTypeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                        };
                                      });
                                      _loadJcType(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            // 新增: 机型
                            ZjcFormSelectCell(
                              title: "机型",
                              text: fd.jcTypeSelected['name'] ?? '',
                              hintText: fd.jcTypeLoading ? "加载中..." : "请选择",
                              clickCallBack: () {
                                if (fd.jcTypeLoading) return;
                                if (fd.jcTypeList.isEmpty) {
                                  showToast("无机型可选择");
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.jcTypeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: "选择机型",
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.jcTypeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                        };
                                      });
                                      _loadTrainNum(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            // 新增: 车号
                            ZjcFormSelectCell(
                              title: "车号",
                              text: (fd.trainNumSelected['displayTrainNum'] ??
                                      fd.trainNumSelected['trainNum'] ??
                                      '')
                                  .toString(),
                              hintText: fd.trainNumLoading ? "加载中..." : "请选择",
                              clickCallBack: () {
                                if (fd.trainNumLoading) return;
                                if (fd.trainNumList.isEmpty) {
                                  showToast("无车号可选择");
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.trainNumList,
                                    labelKey: 'displayTrainNum',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: "选择车号",
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.trainNumSelected = {
                                          'trainNum': selectItem['trainNum'],
                                          'code': selectItem['code'],
                                          'displayTrainNum':
                                              selectItem['displayTrainNum'],
                                          'ends': selectItem['ends'],
                                        };
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            //增加朝向
                            ZjcFormSelectCell(
                              title: "工序节点",
                              text: fd.repairMainNodeSelected['name'] ?? '',
                              hintText:
                                  repairMainNodeLoading ? "加载中..." : "请选择",
                              clickCallBack: () {
                                if (repairMainNodeLoading) return;
                                if (repairMainNodeList.isEmpty) {
                                  showToast("无工序节点可选择");
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: repairMainNodeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: "选择工序节点",
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.repairMainNodeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                        };
                                        fd.scheduleNodePickerList = [];
                                        fd.scheduleNodeSelected = {
                                          'name': '',
                                          'code': '',
                                          'scheduleNodeName': '',
                                        };
                                        fd.scheduleNodeLoading = true;
                                      });
                                      _loadScheduleNodes(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            ZjcFormSelectCell(
                              title: "排程节点",
                              text: fd.scheduleNodeSelected['name'] ?? '',
                              hintText:
                                  fd.scheduleNodeLoading ? "加载中..." : "请选择",
                              clickCallBack: () {
                                if (fd.scheduleNodeLoading) return;
                                if (fd.scheduleNodePickerList.isEmpty) {
                                  showToast("无排程节点可选择");
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.scheduleNodePickerList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: "选择排程节点",
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.scheduleNodeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                          'scheduleNodeName':
                                              selectItem['scheduleNodeName'],
                                        };
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            ZjcFormSelectCell(
                                title: "端",
                                text: fd.directionSelected["name"] ?? '',
                                hintText: item.doubleCarriage == true
                                    ? "请选择"
                                    : "无需选择",
                                clickCallBack: () {
                                  if (item.doubleCarriage != true) {
                                    showToast("非重联无需选择端");
                                    return;
                                  }
                                  if (directionList.isEmpty) {
                                    showToast("无端可选择");
                                  } else {
                                    ZjcCascadeTreePicker.show(
                                      context,
                                      data: directionList,
                                      labelKey: 'name',
                                      valueKey: 'value',
                                      childrenKey: 'children',
                                      title: "选择端",
                                      clickCallBack: (selectItem, selectArr) {
                                        final selectedEnd =
                                            (selectItem['value'] ??
                                                    selectItem['name'])
                                                ?.toString();
                                        setState(() {
                                          logger.i(selectArr);
                                          fd.directionSelected['name'] =
                                              selectItem['name'];
                                          fd.directionSelected['value'] =
                                              selectedEnd;
                                          fd.stopLocationSelected =
                                              _computeDefaultStartStopLocation(
                                                  item, selectedEnd);
                                        });
                                      },
                                    );
                                  }
                                }),
                            const SizedBox(height: 10),
                            ZjcFormSelectCell(
                              title: "起始位置",
                              text: fd.stopLocationSelected["realLocation"],
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
                                        fd.stopLocationSelected["code"] =
                                            selectItem["code"];
                                        fd.stopLocationSelected[
                                                "realLocation"] =
                                            selectItem["realLocation"];
                                        fd.stopLocationSelected["areaName"] =
                                            selectItem["areaName"];
                                        fd.stopLocationSelected["trackNum"] =
                                            selectItem["trackNum"];
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            ZjcFormSelectCell(
                              title: "终点位置",
                              text: fd.stopLocationSelectedEnd["realLocation"],
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
                                        fd.stopLocationSelectedEnd["code"] =
                                            selectItem["code"];
                                        fd.stopLocationSelectedEnd[
                                                "realLocation"] =
                                            selectItem["realLocation"];
                                        fd.stopLocationSelectedEnd["areaName"] =
                                            selectItem["areaName"];
                                        fd.stopLocationSelectedEnd["trackNum"] =
                                            selectItem["trackNum"];
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            CheckboxListTile(
                              value: fd.deptMove,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('库内移车'),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) {
                                setState(() {
                                  fd.deptMove = v == true;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: fd.reasonController,
                              decoration: const InputDecoration(
                                labelText: '备注',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                    for (int i = 0; i < formDataList.length; i++) {
                      final fd = formDataList[i];

                      final dynamicCode = (fd.dynamicTypeSelected['code'] ?? '')
                          .toString()
                          .trim();
                      if (dynamicCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择动力类型");
                        return;
                      }

                      final typeCode =
                          (fd.jcTypeSelected['code'] ?? '').toString().trim();
                      if (typeCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择机型");
                        return;
                      }

                      final trainCode =
                          (fd.trainNumSelected['code'] ?? '').toString().trim();
                      if (trainCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择车号");
                        return;
                      }

                      final nodeCode = (fd.repairMainNodeSelected['code'] ?? '')
                          .toString()
                          .trim();
                      if (nodeCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择工序节点");
                        return;
                      }
                      final scheduleCode =
                          (fd.scheduleNodeSelected['code'] ?? '')
                              .toString()
                              .trim();
                      if (scheduleCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择排程节点");
                        return;
                      }
                      final endCode = (fd.stopLocationSelectedEnd['code'] ?? '')
                          .toString()
                          .trim();
                      if (endCode.isEmpty) {
                        showToast("作业单 ${i + 1}: 请选择终点位置");
                        return;
                      }
                    }
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
  final RepairItem item;
  final List<Map<String, dynamic>> shuntingList;
  final Map<int, dynamic> noticeMap;

  const RepairProgressDetailPage({
    Key? key,
    required this.shuntingList,
    required this.noticeMap,
    required this.item,
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
                  GestureDetector(
                    onTap: () {
                      // 跳转到流水号详情页面
                      if (shuntingItem['shuntingType'] == 4) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlanListPage(
                                repairItem: item,
                                shuntingItem: shuntingItem,
                              ),
                            ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '流水号: ${shuntingItem['shuntingEncode'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
// ... existing code ...,
// ... existing code ...),
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

class RepairProcessNoticePage extends StatefulWidget {
  final RepairItem item;
  final List<Map<String, dynamic>> noticeCandidates;

  const RepairProcessNoticePage({
    super.key,
    required this.item,
    required this.noticeCandidates,
  });

  @override
  State<RepairProcessNoticePage> createState() =>
      _RepairProcessNoticePageState();
}

class _RepairProcessNoticePageState extends State<RepairProcessNoticePage> {
  final _logger = AppLogger.logger;
  final Map<int, List<Map<String, dynamic>>> _teamsByDeptId = {};
  final Map<int, List<Map<String, dynamic>>> _usersByDeptId = {};
  final List<Map<String, dynamic>> _signeeList = [
    {
      'signDept': null,
      'signTeam': null,
      'signUsers': <Map<String, dynamic>>[],
    }
  ];

  List<Map<String, dynamic>> _deptList = [];
  List<Map<String, dynamic>> _receiveGroupOptions = [];
  Map<String, dynamic>? _selectedReceiveGroup;
  List<Map<String, dynamic>> _jt28Options = [];
  List<Map<String, dynamic>> _processingMethodOptions = [];
  List<Map<String, dynamic>> _riskLevelOptions = [];
  List<Map<String, dynamic>> _configOptions = [];
  final List<_RepairProcessWorkBlock> _workBlocks = [];
  Map<String, dynamic>? _selectedJt28;
  Map<String, dynamic>? _selectedProcessingMethod;
  Map<String, dynamic>? _selectedRiskLevel;
  Map<String, dynamic>? _selectedConfig;
  late Map<String, dynamic> _selectedNotice;
  late Future<String> _stopLocationFuture;
  String _stopLocationDisplay = '';
  bool _loadingNoticeDetail = false;
  bool _loadingDept = false;
  bool _loadingJt28 = false;
  bool _loadingProcessingMethod = false;
  bool _loadingRiskLevel = false;
  bool _loadingConfig = false;
  bool _loadingReceiveGroup = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedNotice = widget.noticeCandidates.isNotEmpty
        ? Map<String, dynamic>.from(widget.noticeCandidates.first)
        : <String, dynamic>{};
    _workBlocks.add(_createWorkBlock());
    _stopLocationFuture = _resolveStopLocationDisplay();
    _stopLocationFuture.then((value) {
      if (!mounted) return;
      setState(() {
        _stopLocationDisplay = value;
      });
    });
    _loadDepts();
    _loadReceiveGroupOptions();
    _loadJt28Options();
    _loadProcessingMethodOptions();
    _loadRiskLevelOptions();
    _loadConfigOptions();
  }

  @override
  void dispose() {
    for (final block in _workBlocks) {
      block.dispose();
    }
    super.dispose();
  }

  String _asText(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text == 'null') return '';
    return text;
  }

  String _pickText(Map<String, dynamic>? map, List<String> keys) {
    final source = map ?? const <String, dynamic>{};
    for (final key in keys) {
      final text = _asText(source[key]);
      if (text.isNotEmpty) return text;
    }
    for (final value in source.values) {
      if (value is Map) {
        final text = _pickText(Map<String, dynamic>.from(value), keys);
        if (text.isNotEmpty) return text;
      } else if (value is List) {
        for (final element in value) {
          if (element is Map) {
            final text = _pickText(Map<String, dynamic>.from(element), keys);
            if (text.isNotEmpty) return text;
          }
        }
      }
    }
    return '';
  }

  String _pickTextFromSources(
    List<Map<String, dynamic>?> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final text = _pickText(source, keys);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<Map<String, dynamic>> _pickList(
    Map<String, dynamic>? map,
    List<String> keys,
  ) {
    final source = map ?? const <String, dynamic>{};
    for (final key in keys) {
      final raw = source[key];
      final parsed = _parseList(raw);
      if (parsed.isNotEmpty) return parsed;
    }
    for (final value in source.values) {
      if (value is Map) {
        final parsed = _pickList(Map<String, dynamic>.from(value), keys);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) {
    dynamic value = raw;
    if (value is Map) {
      value = value['rows'] ??
          value['records'] ??
          value['data'] ??
          value['list'] ??
          value;
      if (value is Map) {
        final nestedLists = value.values.whereType<List>().toList();
        if (nestedLists.length == 1) {
          value = nestedLists.first;
        }
      }
    }
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _requiredText(String text) {
    return text.trim().isEmpty ? '-' : text.trim();
  }

  bool get _signeeLockedByReceiveGroup => _selectedReceiveGroup != null;

  String _jt28Label(Map<String, dynamic>? item) {
    return _pickText(item, [
      'jt28DisplayText',
      'faultDescription',
      'faultInformation',
      'faultDesc',
      'faultPhenomenon',
    ]);
  }

  String _processingMethodLabel(Map<String, dynamic>? item) {
    return _pickText(item, [
      'dictName',
      'jtDictName',
      'processingMethodName',
      'requiredProcessingMethodName',
      'processingMethod',
      'requiredProcessingMethod',
    ]);
  }

  String _riskLevelLabel(Map<String, dynamic>? item) {
    return _pickText(item, ['riskLevel', 'riskLevelName', 'name', 'dictLabel']);
  }

  String _configLabel(Map<String, dynamic>? item) {
    return _pickText(item, [
      'displayText',
      'nodeName',
      'configNodeName',
      'configName',
      'structure',
      'componentName',
      'name',
      'config',
    ]);
  }

  Map<String, dynamic> get _selectedWork {
    final rows = _pickWorkRows(_selectedNotice);
    return rows.isNotEmpty ? rows.first : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _pickWorkRows(Map<String, dynamic>? source) {
    final rows = _pickList(source, [
      'masNoticeDeptList',
      'masAfterSaleWorkList',
      'workList',
      'masAfterSaleWorkDeptList',
    ]);
    return rows;
  }

  String _defaultProcessingMethodText() {
    return _pickTextFromSources([
      _selectedJt28,
      _selectedWork
    ], [
      'jtDictName',
      'jtDictCode',
      'processingMethod',
      'processingMethodName',
      'requiredProcessingMethodName',
      'requiredProcessingMethod',
    ]);
  }

  String _defaultRiskLevelText() {
    return _pickTextFromSources(
      [_selectedJt28, _selectedWork],
      ['riskLevel', 'riskLevelName'],
    );
  }

  String _defaultConfigText() {
    return _pickTextFromSources([
      _selectedJt28,
      _selectedWork
    ], [
      'configNodeName',
      'structure',
      'configName',
      'componentName',
      'nodeName',
      'config',
    ]);
  }

  String _defaultOutsourceFactoryText() {
    return _pickTextFromSources([
      _selectedJt28,
      _selectedWork
    ], [
      'outsourcingVendor',
      'outSourcingFactory',
      'outsourcingFactory',
    ]);
  }

  String _defaultRepairPlanText() {
    return _pickTextFromSources([
      _selectedJt28,
      _selectedWork
    ], [
      'maintenanceNotice',
      'repairProcContent',
      'repairScheme',
      'repairProgram',
      'repairPlan',
      'repairPlanContent',
      'repairContent',
      'workContent',
      'content',
    ]);
  }

  String _defaultTechGuideText() {
    return _pickTextFromSources([
      _selectedJt28,
      _selectedWork
    ], [
      'techGuideName',
      'technicalGuidance',
      'guide',
      'techGuide',
    ]);
  }

  StateDetail? get _activeStateDetail {
    final details = widget.item.stateDetailList ?? const <StateDetail>[];
    for (final detail in details) {
      if ((detail.state ?? '').toString().trim() == '1') {
        return detail;
      }
    }
    return details.isNotEmpty ? details.first : null;
  }

  String get _currentProcessNodeName {
    final fromNotice = _pickText(_selectedNotice, ['repairMainNodeName']);
    if (fromNotice.isNotEmpty) return fromNotice;
    final fromJt28 = _pickText(_selectedJt28, ['processMainNode']);
    if (fromJt28.isNotEmpty) return fromJt28;
    return (_activeStateDetail?.repairMainNodeName ?? '').trim();
  }

  void _applyDefaultProcessNodeFromActive() {
    final jt28Name = _pickText(_selectedJt28, ['processMainNode']);
    final jt28Code = _pickText(_selectedJt28, ['mainProcessPoint']);
    final active = _activeStateDetail;
    final activeName = (active?.repairMainNodeName ?? '').trim();
    final activeCode = (active?.repairMainNodeCode ?? '').trim();
    final defaultName = jt28Name.isNotEmpty ? jt28Name : activeName;
    final defaultCode = jt28Code.isNotEmpty ? jt28Code : activeCode;
    if (defaultName.isEmpty && defaultCode.isEmpty) return;
    _selectedNotice = Map<String, dynamic>.from(_selectedNotice);
    if (_pickText(_selectedNotice, ['repairMainNodeName']).isEmpty &&
        defaultName.isNotEmpty) {
      _selectedNotice['repairMainNodeName'] = defaultName;
    }
    if (_pickText(_selectedNotice, ['repairMainNodeCode']).isEmpty &&
        defaultCode.isNotEmpty) {
      _selectedNotice['repairMainNodeCode'] = defaultCode;
    }
    _logger.i(
      '[修程通知单回写] 机统28选中后先默认回写工序节点 '
      'repairMainNodeName=${_pickText(_selectedNotice, [
            'repairMainNodeName'
          ])} '
      'repairMainNodeCode=${_pickText(_selectedNotice, [
            'repairMainNodeCode'
          ])}',
    );
  }

  void _applyDefaultRepairPlanFromJt28() {
    final repairPlan = _defaultRepairPlanText();
    if (repairPlan.isEmpty) return;
    _selectedNotice = Map<String, dynamic>.from(_selectedNotice);
    if (_pickText(_selectedNotice, ['repairProcContent']).isEmpty) {
      _selectedNotice['repairProcContent'] = repairPlan;
    }
    if (_pickText(_selectedNotice, ['maintenanceNotice']).isEmpty) {
      _selectedNotice['maintenanceNotice'] = repairPlan;
    }
    _logger.i(
      '[修程通知单回写] 机统28选中后先默认回写施修方案 '
      'repairProcContent=${_pickText(_selectedNotice, ['repairProcContent'])}',
    );
  }

  String _noticeStopLocationText(Map<String, dynamic>? source) {
    return _pickText(source, [
      'stoppingPlace',
      'trainLocation',
      'parkingLocation',
      'stopLocation',
    ]);
  }

  int _noticeDetailScore(Map<String, dynamic> row) {
    final hasProcess =
        _pickText(row, ['repairMainNodeName', 'repairMainNodeCode']).isNotEmpty;
    final hasStop = _noticeStopLocationText(row).isNotEmpty;
    if (hasProcess && hasStop) return 3;
    if (hasProcess) return 2;
    if (hasStop) return 1;
    return 0;
  }

  DateTime? _parseNoticeDateTime(dynamic value) {
    final text = _asText(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  Map<String, dynamic> _pickLatestNoticeDetail(
      List<Map<String, dynamic>> rows) {
    if (rows.length == 1) return Map<String, dynamic>.from(rows.first);
    final sorted = rows.map((e) => Map<String, dynamic>.from(e)).toList();
    sorted.sort((a, b) {
      final scoreCompare =
          _noticeDetailScore(b).compareTo(_noticeDetailScore(a));
      if (scoreCompare != 0) return scoreCompare;
      final bTime = _parseNoticeDateTime(b['updatedTime']) ??
          _parseNoticeDateTime(b['createdTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final aTime = _parseNoticeDateTime(a['updatedTime']) ??
          _parseNoticeDateTime(a['createdTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return sorted.first;
  }

  bool get _canConfirm {
    return !_submitting &&
        !_loadingNoticeDetail &&
        _validateBeforeSubmit(showError: false);
  }

  bool _validateBeforeSubmit({required bool showError}) {
    String? error;
    if (_jt28Options.isNotEmpty && _jt28Label(_selectedJt28).isEmpty) {
      error = '请选择一条机统28';
    } else if (_currentProcessNodeName.isEmpty) {
      error = '工序节点未回写完成，请稍后';
    } else if (_stopLocationDisplay.trim().isEmpty) {
      error = '停留位置未回写完成，请稍后';
    } else {
      for (var i = 0; i < _workBlocks.length; i++) {
        final block = _workBlocks[i];
        final prefix = '工艺块 ${i + 1}: ';
        if (block.processingMethodText.trim().isEmpty) {
          error = '${prefix}请选择加工方法';
          break;
        }
        if (block.riskLevelText.trim().isEmpty) {
          error = '${prefix}请选择风险等级';
          break;
        }
        if (block.configText.trim().isEmpty) {
          error = '${prefix}请选择关联构型';
          break;
        }
        if (block.outsourceFactoryController.text.trim().isEmpty) {
          error = '${prefix}请输入外包厂家';
          break;
        }
        if (block.repairPlanController.text.trim().isEmpty) {
          error = '${prefix}请输入施修方案';
          break;
        }
      }
    }
    if (error == null && _selectedReceiveGroup == null) {
      error = '请选择签收组';
    }
    if (error == null) {
      for (var i = 0; i < _signeeList.length; i++) {
        final signee = _signeeList[i];
        final dept = signee['signDept'];
        final users = signee['signUsers'];
        if (dept is! Map) {
          error = '签收人第 ${i + 1} 行: 请选择部门';
          break;
        }
        if (users is! List || users.whereType<Map>().isEmpty) {
          error = '签收人第 ${i + 1} 行: 请选择签收人';
          break;
        }
      }
    }
    if (error != null && showError) {
      showToast(error);
    }
    return error == null;
  }

  _RepairProcessWorkBlock _createWorkBlockFromSource(
      Map<String, dynamic> source) {
    final processingText = _pickText(source, [
      'requiredProcessingMethodName',
      'processingMethodName',
      'processingMethod',
      'jtDictName',
    ]);
    final riskText = _pickText(source, ['riskLevel', 'riskLevelName']);
    final configText = _pickText(source, [
      'configNodeName',
      'configName',
      'nodeName',
      'structure',
      'componentName',
      'config',
    ]);
    final block = _RepairProcessWorkBlock(
      processingMethodText: processingText,
      riskLevelText: riskText,
      configText: configText,
      outsourceFactoryText: _pickText(source, [
        'outsourcingVendor',
        'outSourcingFactory',
        'outsourcingFactory',
      ]),
      repairPlanText: _pickText(source, [
        'repairProcContent',
        'maintenanceNotice',
        'repairScheme',
        'repairPlan',
      ]),
      techGuideText: _pickText(source, [
        'techGuideName',
        'technicalGuidance',
        'guide',
        'techGuide',
      ]),
    );
    final processingCode =
        _pickText(source, ['jtDictCode', 'requiredProcessingMethod']);
    final riskCode = _pickText(source, ['riskLevelCode', 'dictCode']);
    final configCode =
        _pickText(source, ['configNodeCode', 'configCode', 'code']);
    block.selectedProcessingMethod = _findOptionByIdOrName(
      _processingMethodOptions,
      id: processingCode,
      idKeys: const ['code', 'dictCode'],
      name: processingText,
      nameKeys: const ['displayText', 'dictName', 'jtDictName'],
    );
    block.selectedRiskLevel = _findOptionByIdOrName(
      _riskLevelOptions,
      id: riskCode,
      idKeys: const ['dictCode', 'code'],
      name: riskText,
      nameKeys: const ['displayText', 'dictLabel', 'name'],
    );
    block.selectedConfig = _findOptionByIdOrName(
      _configOptions,
      id: configCode,
      idKeys: const ['configCode', 'code'],
      name: configText,
      nameKeys: const [
        'displayText',
        'configName',
        'configNodeName',
        'nodeName',
        'structure',
        'componentName',
        'name',
        'config',
      ],
    );
    return block;
  }

  Future<void> _loadNoticeDetailByJt28(
      Map<String, dynamic> selectedJt28) async {
    final jt28Code =
        _pickText(selectedJt28, ['jt28Code', 'code', 'masSaleInformationCode']);
    if (jt28Code.isEmpty || _loadingNoticeDetail) {
      return;
    }
    _logger.i('[修程通知单回写] 选中故障现象后开始回写 jt28Code=$jt28Code');
    if (mounted) {
      setState(() => _loadingNoticeDetail = true);
    }
    try {
      final res = await ProductApi().getMasNoticeSelectAll(
        queryParametrs: {'jt28Code': jt28Code},
      );
      final rows = _parseList(res);
      if (rows.isEmpty) {
        _logger.w('[修程通知单回写] 未查询到回写数据 jt28Code=$jt28Code');
        return;
      }
      final nextNotice = _pickLatestNoticeDetail(rows);
      nextNotice['jt28Code'] = jt28Code;
      final workRows = _pickWorkRows(nextNotice);
      final nextBlocks = workRows.isNotEmpty
          ? workRows.map(_createWorkBlockFromSource).toList()
          : <_RepairProcessWorkBlock>[_createWorkBlockFromSource(nextNotice)];
      if (!mounted) return;
      setState(() {
        _selectedNotice = nextNotice;
        for (final block in _workBlocks) {
          block.dispose();
        }
        _workBlocks
          ..clear()
          ..addAll(nextBlocks);
        final stopLocationText = _noticeStopLocationText(nextNotice);
        _stopLocationDisplay = stopLocationText;
        _stopLocationFuture = Future.value(stopLocationText);
      });
      _logger.i(
        '[修程通知单回写] 回写完成 workRows=${nextBlocks.length} '
        'repairMainNodeName=${_pickText(nextNotice, ['repairMainNodeName'])} '
        'stoppingPlace=${_noticeStopLocationText(nextNotice)} '
        'createdTime=${_pickText(nextNotice, ['createdTime'])}',
      );
    } catch (e) {
      _logger.e('[修程通知单回写] 回写失败 error=$e');
    } finally {
      if (mounted) {
        setState(() => _loadingNoticeDetail = false);
      }
    }
  }

  List<Map<String, dynamic>> _buildRepairProcessNoticeList({
    required dynamic user,
  }) {
    final applyUserName = ((user.nickName ?? user.userName) ?? '').toString();
    final groupCode = _selectedReceiveGroup == null
        ? ''
        : _receiveGroupCode(_selectedReceiveGroup);
    final groupName = _selectedReceiveGroup == null
        ? ''
        : _receiveGroupLabel(_selectedReceiveGroup);
    final seenKeys = <String>{};
    final notices = <Map<String, dynamic>>[];

    for (final signee in _signeeList) {
      final dept = signee['signDept'];
      final team = signee['signTeam'];
      final users = signee['signUsers'];
      final deptMap = dept is Map ? Map<String, dynamic>.from(dept) : null;
      final teamMap = team is Map ? Map<String, dynamic>.from(team) : null;
      final deptId = deptMap?['deptId'];
      final deptName = _pickText(deptMap, ['deptName']);
      final teamId = teamMap?['deptId'] ?? teamMap?['teamId'];
      final teamName = _pickText(teamMap, ['deptName', 'teamName']);
      if (users is! List) continue;
      for (final item in users) {
        if (item is! Map) continue;
        final userMap = Map<String, dynamic>.from(item);
        final auditUserId = userMap['userId'];
        final auditUserName =
            _pickText(userMap, ['nickName', 'userName', 'name']);
        final dedupeKey =
            '${_asText(deptId)}_${_asText(teamId)}_${_asText(auditUserId)}';
        if (_asText(auditUserId).isEmpty || seenKeys.contains(dedupeKey)) {
          continue;
        }
        seenKeys.add(dedupeKey);
        notices.add({
          'applyUserId': user.userId,
          'applyUserName': applyUserName,
          if (deptId != null) 'auditDeptId': deptId,
          if (deptName.isNotEmpty) 'auditDeptName': deptName,
          if (teamId != null) 'auditTeamId': teamId,
          if (teamName.isNotEmpty) 'auditTeamName': teamName,
          'auditUserId': auditUserId,
          'auditUserName': auditUserName,
          if (groupCode.isNotEmpty) 'receiveGroupCode': groupCode,
          if (groupName.isNotEmpty) 'receiveGroupName': groupName,
          'shuntingType': 13,
          'status': 0,
        });
      }
    }
    return notices;
  }

  List<Map<String, dynamic>> _buildMasNoticeDeptList({
    required dynamic user,
    required List<Map<String, dynamic>> workListPayload,
  }) {
    final activeStateDetail = _activeStateDetail;
    final reportUserId = _selectedNotice['reportUserId'] ?? user.userId;
    final reportUserName =
        _pickText(_selectedNotice, ['reportUserName']).isNotEmpty
            ? _pickText(_selectedNotice, ['reportUserName'])
            : ((user.nickName ?? user.userName) ?? '').toString();
    final trainEntryCode =
        (widget.item.code ?? widget.item.c4c5ledger?.trainEntryCode ?? '')
                .trim()
                .isNotEmpty
            ? (widget.item.code ?? widget.item.c4c5ledger?.trainEntryCode ?? '')
                .trim()
            : _pickText(_selectedNotice, ['trainEntryCode']);
    final trainNum = (widget.item.trainNum ?? '').trim().isNotEmpty
        ? (widget.item.trainNum ?? '').trim()
        : _pickText(_selectedNotice, ['trainNum', 'trainName']);
    final trainNumCode = (widget.item.trainNumCode ?? '').trim().isNotEmpty
        ? (widget.item.trainNumCode ?? '').trim()
        : _pickText(_selectedNotice, ['trainNumCode', 'trainCode']);
    final trainCodeCandidate = _pickTextFromSources([
      _selectedJt28,
      _selectedNotice
    ], [
      'trainCode',
      'trainNumCode',
    ]);
    final trainCode = trainCodeCandidate.isNotEmpty
        ? trainCodeCandidate
        : (trainNumCode.isNotEmpty ? trainNumCode : trainEntryCode);
    final typeCode = (widget.item.typeCode ?? '').trim().isNotEmpty
        ? (widget.item.typeCode ?? '').trim()
        : _pickText(_selectedNotice, ['typeCode']);
    final typeName = (widget.item.typeName ?? '').trim().isNotEmpty
        ? (widget.item.typeName ?? '').trim()
        : _pickText(_selectedNotice, ['typeName']);
    final repairMainNodeCode =
        (_activeStateDetail?.repairMainNodeCode ?? '').trim().isNotEmpty
            ? (_activeStateDetail?.repairMainNodeCode ?? '').trim()
            : _pickText(_selectedNotice, ['repairMainNodeCode']);
    final repairMainNodeName =
        (_activeStateDetail?.repairMainNodeName ?? '').trim().isNotEmpty
            ? (_activeStateDetail?.repairMainNodeName ?? '').trim()
            : _pickText(_selectedNotice, ['repairMainNodeName']);

    return workListPayload.map((workItem) {
      final item = Map<String, dynamic>.from(workItem);
      final result = <String, dynamic>{};
      final detailCode = _asText(item['code']);
      if (detailCode.isNotEmpty) {
        result['code'] = detailCode;
      }
      final configCode = _asText(item['configCode']);
      if (configCode.isNotEmpty) {
        result['configCode'] = configCode;
      }
      final configName =
          _pickText(item, ['configName', 'configNodeName', 'nodeName']);
      if (configName.isNotEmpty) {
        result['configName'] = configName;
      }
      final jtDictCode = _asText(item['jtDictCode']);
      if (jtDictCode.isNotEmpty) {
        result['jtDictCode'] = jtDictCode;
      }
      final jtDictName =
          _pickText(item, ['jtDictName', 'requiredProcessingMethodName']);
      if (jtDictName.isNotEmpty) {
        result['jtDictName'] = jtDictName;
      }
      final outsourcingVendor = _pickText(item, ['outsourcingVendor']);
      if (outsourcingVendor.isNotEmpty) {
        result['outsourcingVendor'] = outsourcingVendor;
      }
      final repairProcContent = _pickText(item, ['repairProcContent']);
      if (repairProcContent.isNotEmpty) {
        result['repairProcContent'] = repairProcContent;
      }
      final riskLevel = _pickText(item, ['riskLevel']);
      if (riskLevel.isNotEmpty) {
        result['riskLevel'] = riskLevel;
      }
      if (repairMainNodeCode.isNotEmpty) {
        result['repairMainNodeCode'] = repairMainNodeCode;
      }
      if (repairMainNodeName.isNotEmpty) {
        result['repairMainNodeName'] = repairMainNodeName;
      }
      result['reportUserId'] = reportUserId;
      if (reportUserName.isNotEmpty) {
        result['reportUserName'] = reportUserName;
      }
      if (trainCode.isNotEmpty) {
        result['trainCode'] = trainCode;
      }
      if (trainEntryCode.isNotEmpty) {
        result['trainEntryCode'] = trainEntryCode;
      }
      if (trainNum.isNotEmpty) {
        result['trainNum'] = trainNum;
      }
      if (trainNumCode.isNotEmpty) {
        result['trainNumCode'] = trainNumCode;
      }
      if (typeCode.isNotEmpty) {
        result['typeCode'] = typeCode;
      }
      if (typeName.isNotEmpty) {
        result['typeName'] = typeName;
      }
      return result;
    }).toList();
  }

  _RepairProcessWorkBlock _createWorkBlock() {
    return _RepairProcessWorkBlock(
      processingMethodText: _defaultProcessingMethodText(),
      riskLevelText: _defaultRiskLevelText(),
      configText: _defaultConfigText(),
      outsourceFactoryText: _defaultOutsourceFactoryText(),
      repairPlanText: _defaultRepairPlanText(),
      techGuideText: _defaultTechGuideText(),
    );
  }

  void _applyDefaultsToWorkBlock(
    _RepairProcessWorkBlock block, {
    bool overwrite = false,
  }) {
    final processing = _defaultProcessingMethodText();
    final risk = _defaultRiskLevelText();
    final config = _defaultConfigText();
    final outsource = _defaultOutsourceFactoryText();
    final repairPlan = _defaultRepairPlanText();
    final techGuide = _defaultTechGuideText();

    if (overwrite || block.processingMethodText.trim().isEmpty) {
      block.processingMethodText = processing;
      block.selectedProcessingMethod = null;
    }
    if (overwrite || block.riskLevelText.trim().isEmpty) {
      block.riskLevelText = risk;
      block.selectedRiskLevel = null;
    }
    if (overwrite || block.configText.trim().isEmpty) {
      block.configText = config;
      block.selectedConfig = null;
    }
    if (overwrite || block.outsourceFactoryController.text.trim().isEmpty) {
      block.outsourceFactoryController.text = outsource;
    }
    if (overwrite || block.repairPlanController.text.trim().isEmpty) {
      block.repairPlanController.text = repairPlan;
    }
    if (overwrite || block.techGuideController.text.trim().isEmpty) {
      block.techGuideController.text = techGuide;
    }
  }

  String get _pageTitle {
    final typeName = (widget.item.typeName ?? '').trim();
    final trainNum =
        formatTrainNumWithEnds(widget.item.trainNum, widget.item.ends).trim();
    final repairProc = (widget.item.repairProcName ?? '').trim();
    final parts = <String>[
      if (typeName.isNotEmpty) typeName,
      if (trainNum.isNotEmpty) trainNum,
      if (repairProc.isNotEmpty) repairProc,
    ];
    final prefix = parts.join('-');
    return prefix.isEmpty ? '下发修程通知单' : '$prefix-下发修程通知单';
  }

  Future<String> _resolveStopLocationDisplay() async {
    final fromNotice = _noticeStopLocationText(_selectedNotice);
    if (fromNotice.isNotEmpty) return fromNotice;
    final code = (widget.item.repairLocation ?? '').trim();
    if (code.isEmpty) return '';
    try {
      final r = await ProductApi().getstopLocation({
        'pageNum': 0,
        'pageSize': 0,
        'code': code,
      });
      final first =
          (r.rows != null && r.rows!.isNotEmpty) ? r.rows!.first : null;
      final deptName = first?.deptName;
      final trackNum = first?.trackNum;
      final areaName = first?.areaName;
      if (deptName != null &&
          deptName.isNotEmpty &&
          trackNum != null &&
          trackNum.isNotEmpty &&
          areaName != null &&
          areaName.isNotEmpty) {
        return '$deptName-$trackNum-$areaName';
      }
    } catch (_) {}
    return code;
  }

  Future<void> _loadDepts() async {
    if (_loadingDept) return;
    setState(() => _loadingDept = true);
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': 101},
      );
      final list = <Map<String, dynamic>>[];
      if (res is List && res.isNotEmpty) {
        final children = res.first['children'];
        if (children is List) {
          for (final e in children) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _deptList = list;
        _loadingDept = false;
      });
    } catch (e) {
      _logger.e('加载签收部门失败: $e');
      if (!mounted) return;
      setState(() => _loadingDept = false);
    }
  }

  Future<void> _loadJt28Options() async {
    final trainEntryCode =
        (widget.item.code ?? widget.item.c4c5ledger?.trainEntryCode ?? '')
            .trim();
    if (trainEntryCode.isEmpty) {
      _logger.w('[修程通知单JT28] 进入页面未取到 trainEntryCode');
      return;
    }
    _logger.i('[修程通知单JT28] 进入修程通知单，开始查询 trainEntryCode=$trainEntryCode');
    if (mounted) {
      setState(() => _loadingJt28 = true);
    }
    try {
      final res = await ProductApi().getJt28SelectAll(
        queryParametrs: {
          'trainEntryCode': trainEntryCode,
          'derived': false,
          'pageNum': 0,
          'pageSize': 0,
          'status': 0,
        },
      );
      final list = <Map<String, dynamic>>[];
      dynamic rows = res;
      if (res is Map) {
        rows = res['rows'] ?? res['data'] ?? res['list'];
      }
      if (rows is List) {
        for (final e in rows) {
          if (e is Map) {
            final row = Map<String, dynamic>.from(e);
            row['jt28DisplayText'] = _jt28Label(row);
            list.add(row);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _jt28Options = list;
        _selectedJt28 = null;
        _loadingJt28 = false;
      });
      _logger.i('[修程通知单JT28] 页面收到机统28 rows=${list.length}');
    } catch (e) {
      _logger.e('[修程通知单JT28] 加载机统28故障现象失败: $e');
      if (!mounted) return;
      setState(() {
        _jt28Options = [];
        _selectedJt28 = null;
        _loadingJt28 = false;
      });
    }
  }

  Future<void> _loadProcessingMethodOptions() async {
    if (mounted) {
      setState(() => _loadingProcessingMethod = true);
    }
    try {
      final r = await JtApi().getJt28Dict();
      final list = <Map<String, dynamic>>[];
      final rows = r.rows ?? [];
      for (final item in rows) {
        if (item is Map) {
          final row = Map<String, dynamic>.from(item);
          row['displayText'] = _processingMethodLabel(row);
          list.add(row);
        }
      }
      if (!mounted) return;
      setState(() {
        _processingMethodOptions = list;
        _loadingProcessingMethod = false;
      });
    } catch (e) {
      _logger.e('加载加工方法失败: $e');
      if (!mounted) return;
      setState(() {
        _processingMethodOptions = [];
        _loadingProcessingMethod = false;
      });
    }
  }

  Future<void> _loadRiskLevelOptions() async {
    if (mounted) {
      setState(() => _loadingRiskLevel = true);
    }
    try {
      final r = await ProductApi().getDictCode({
        'pageNum': 0,
        'pageSize': 0,
        'dictType': 'tech_risk_level',
        'status': 0,
      });
      final list = <Map<String, dynamic>>[];
      final seen = <String>{};
      final rows = r is Map && r['rows'] is List ? r['rows'] as List : const [];
      for (final item in rows) {
        if (item is Map) {
          final row = Map<String, dynamic>.from(item);
          final risk = _riskLevelLabel(row);
          if (risk.isEmpty || seen.contains(risk)) continue;
          seen.add(risk);
          list.add({
            'riskLevel': risk,
            'displayText': risk,
          });
        }
      }
      if (!mounted) return;
      setState(() {
        _riskLevelOptions = list;
        _loadingRiskLevel = false;
      });
    } catch (e) {
      _logger.e('加载风险等级失败: $e');
      if (!mounted) return;
      setState(() {
        _riskLevelOptions = [];
        _loadingRiskLevel = false;
      });
    }
  }

  void _flattenConfigTree(
    dynamic node,
    List<Map<String, dynamic>> result, {
    String parentPath = '',
  }) {
    if (node is! Map) return;
    final row = Map<String, dynamic>.from(node);
    final label = _pickText(row, [
      'nodeName',
      'configNodeName',
      'configName',
      'structure',
      'componentName',
      'name',
      'config',
    ]);
    final currentPath = parentPath.isEmpty
        ? label
        : (label.isEmpty ? parentPath : '$parentPath/$label');
    final children = row['children'];
    final hasChildren = children is List && children.isNotEmpty;
    final configCode = _asText(row['configCode']).isNotEmpty
        ? _asText(row['configCode'])
        : _asText(row['code']);
    if (!hasChildren && currentPath.isNotEmpty) {
      row['displayText'] = currentPath;
      row['configCode'] = configCode;
      result.add(row);
    }
    if (children is List) {
      for (final child in children) {
        _flattenConfigTree(child, result, parentPath: currentPath);
      }
    }
  }

  Future<void> _loadConfigOptions() async {
    final typeCode = (widget.item.typeCode ?? '').trim();
    if (typeCode.isEmpty) return;
    if (mounted) {
      setState(() => _loadingConfig = true);
    }
    try {
      final r = await JtApi().getAllConfigTreeByCode(
        queryParametrs: {'typeCode': typeCode},
      );
      final options = <Map<String, dynamic>>[];
      final treeData = r is Map ? r['data'] : null;
      if (treeData is List) {
        for (final node in treeData) {
          _flattenConfigTree(node, options);
        }
      }
      if (!mounted) return;
      setState(() {
        _configOptions = options;
        _loadingConfig = false;
      });
    } catch (e) {
      _logger.e('加载关联构型失败: $e');
      if (!mounted) return;
      setState(() {
        _configOptions = [];
        _loadingConfig = false;
      });
    }
  }

  Future<void> _loadTeamsForDept(int deptId) async {
    if (_teamsByDeptId.containsKey(deptId)) return;
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': deptId},
      );
      final teams = <Map<String, dynamic>>[];
      if (res is List && res.isNotEmpty) {
        final children = res.first['children'];
        if (children is List) {
          for (final e in children) {
            if (e is Map) teams.add(Map<String, dynamic>.from(e));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _teamsByDeptId[deptId] = teams;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _teamsByDeptId[deptId] = [];
      });
    }
  }

  Future<void> _loadUsersForDept(int deptId) async {
    if (_usersByDeptId.containsKey(deptId)) return;
    try {
      _logger.i('[修程通知单签收人] 开始加载签收人 deptId=$deptId');
      final res = await ProductApi().getUserListByDeptId(
        queryParametrs: {'deptId': deptId},
      );
      final users = <Map<String, dynamic>>[];
      if (res is Map && res['rows'] is List) {
        for (final e in res['rows']) {
          if (e is Map) users.add(Map<String, dynamic>.from(e));
        }
      } else if (res is List) {
        for (final e in res) {
          if (e is Map) users.add(Map<String, dynamic>.from(e));
        }
      }
      _logger.i('[修程通知单签收人] 页面解析签收人 deptId=$deptId rows=${users.length}');
      if (!mounted) return;
      setState(() {
        _usersByDeptId[deptId] = users;
      });
    } catch (e) {
      _logger.w('[修程通知单签收人] 加载失败 deptId=$deptId error=$e');
      if (!mounted) return;
      setState(() {
        _usersByDeptId[deptId] = [];
      });
    }
  }

  List<String> _splitTextList(dynamic value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value.map((e) => _asText(e)).where((e) => e.isNotEmpty).toList();
    }
    final text = _asText(value);
    if (text.isEmpty) return const <String>[];
    return text
        .split(RegExp(r'[,，]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _findOptionByIdOrName(
    List<Map<String, dynamic>> options, {
    dynamic id,
    List<String> idKeys = const ['deptId', 'userId', 'code'],
    String name = '',
    List<String> nameKeys = const ['deptName', 'nickName', 'userName', 'name'],
  }) {
    final idText = _asText(id);
    if (idText.isNotEmpty) {
      for (final option in options) {
        for (final key in idKeys) {
          if (_asText(option[key]) == idText) {
            return Map<String, dynamic>.from(option);
          }
        }
      }
    }
    final targetName = name.trim();
    if (targetName.isNotEmpty) {
      for (final option in options) {
        for (final key in nameKeys) {
          if (_asText(option[key]) == targetName) {
            return Map<String, dynamic>.from(option);
          }
        }
      }
    }
    return null;
  }

  void _collectRoleIds(dynamic value, Set<int> result) {
    if (value is List) {
      for (final item in value) {
        _collectRoleIds(item, result);
      }
      return;
    }
    if (value is! Map) return;
    final row = Map<String, dynamic>.from(value);
    final roleId = _parseId(row['id']);
    final hasRoleFeature = _asText(row['groupCode']).isNotEmpty ||
        _asText(row['name']).isNotEmpty ||
        row['sort'] != null;
    if (roleId != null && hasRoleFeature) {
      result.add(roleId);
    }
    for (final child in row.values) {
      _collectRoleIds(child, result);
    }
  }

  List<int> _extractRoleIdList(Map<String, dynamic> row) {
    final result = <int>{};
    _collectRoleIds(row, result);
    return result.toList();
  }

  List<Map<String, dynamic>> _normalizeUserRows(dynamic res) {
    final users = <Map<String, dynamic>>[];
    dynamic rows = res;
    if (res is Map) {
      rows = res['rows'] ?? res['data'] ?? res['list'];
    }
    if (rows is List) {
      for (final item in rows) {
        if (item is Map) {
          users.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return users;
  }

  String _receiveGroupCode(Map<String, dynamic>? group) {
    return _pickText(group, ['code', 'groupCode']);
  }

  String _receiveGroupLabel(Map<String, dynamic>? group) {
    return _pickText(group, ['name', 'groupName']);
  }

  Map<int, List<Map<String, dynamic>>> _normalizeRoleUserMap(dynamic data) {
    final result = <int, List<Map<String, dynamic>>>{};
    if (data is! Map) return result;
    data.forEach((key, value) {
      final roleId = _parseId(key);
      if (roleId == null || value is! List) return;
      final users = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is Map) {
          final row = Map<String, dynamic>.from(item);
          row['displayText'] = _pickText(row, ['nickName', 'userName', 'name']);
          users.add(row);
        }
      }
      result[roleId] = users;
    });
    return result;
  }

  Future<Map<String, dynamic>> _resolveSigneeDeptTeam(
    Map<String, dynamic> user,
  ) async {
    if (_deptList.isEmpty) {
      await _loadDepts();
    }
    final userDeptId = _parseId(user['deptId']);
    final deptFullName = _pickText(user, ['deptFullName']);
    final fullNameParts = deptFullName
        .split('/')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final dept in _deptList) {
      final deptId = _parseId(dept['deptId']);
      if (deptId == userDeptId) {
        return {
          'signDept': Map<String, dynamic>.from(dept),
          'signTeam': null,
          'targetDeptId': deptId,
        };
      }
      if (deptId == null) continue;
      await _loadTeamsForDept(deptId);
      final teams = _teamsByDeptId[deptId] ?? const <Map<String, dynamic>>[];
      for (final team in teams) {
        final teamId = _parseId(team['deptId']);
        if (teamId == userDeptId) {
          return {
            'signDept': Map<String, dynamic>.from(dept),
            'signTeam': Map<String, dynamic>.from(team),
            'targetDeptId': teamId,
          };
        }
      }
    }

    final deptName = fullNameParts.isNotEmpty ? fullNameParts.first : '';
    final teamName = fullNameParts.length > 1 ? fullNameParts.last : '';
    final dept = _findOptionByIdOrName(
          _deptList,
          id: userDeptId,
          name: deptName,
          idKeys: const ['deptId'],
          nameKeys: const ['deptName'],
        ) ??
        {
          if (userDeptId != null) 'deptId': userDeptId,
          if (deptName.isNotEmpty) 'deptName': deptName,
        };

    Map<String, dynamic>? team;
    final deptId = _parseId(dept['deptId']);
    if (deptId != null && teamName.isNotEmpty) {
      await _loadTeamsForDept(deptId);
      team = _findOptionByIdOrName(
            _teamsByDeptId[deptId] ?? const <Map<String, dynamic>>[],
            id: userDeptId,
            name: teamName,
            idKeys: const ['deptId'],
            nameKeys: const ['deptName'],
          ) ??
          {
            if (userDeptId != null) 'deptId': userDeptId,
            'deptName': teamName,
          };
    }

    return {
      'signDept': dept.isEmpty ? null : dept,
      'signTeam': team,
      'targetDeptId':
          _parseId(team?['deptId']) ?? _parseId(dept['deptId']) ?? userDeptId,
    };
  }

  Future<void> _applyReceiveGroupToSignees(Map<String, dynamic> group) async {
    final items = _pickList(group, ['shuntingReceiveGroupItemList']);
    final roleIdList =
        items.map((e) => _parseId(e['id'])).whereType<int>().toList();
    _logger.i('[修程通知单签收组] 选中签收组后开始回填 roleIdList=$roleIdList');
    if (roleIdList.isEmpty) {
      return;
    }
    if (_deptList.isEmpty) {
      await _loadDepts();
    }
    final res =
        await ProductApi().getVUserRolePostDetailListByRoleIdList(roleIdList);
    final roleUserMap = _normalizeRoleUserMap(res);
    final nextSignees = <Map<String, dynamic>>[];
    final rowIndexByKey = <String, int>{};
    for (final item in items) {
      final roleId = _parseId(item['id']);
      if (roleId == null) continue;
      final roleUsers = roleUserMap[roleId] ?? const <Map<String, dynamic>>[];
      for (final roleUser in roleUsers) {
        final user = Map<String, dynamic>.from(roleUser);
        _logger.i(
          '[修程通知单签收组] 角色用户 userId=${user['userId']} deptId=${user['deptId']} nickName=${_pickText(user, [
                'nickName',
                'userName',
                'name'
              ])}',
        );
        final relation = await _resolveSigneeDeptTeam(user);
        final signDept = relation['signDept'];
        final signTeam = relation['signTeam'];
        final targetDeptId = relation['targetDeptId'] as int?;
        if (targetDeptId == null) continue;

        await _loadUsersForDept(targetDeptId);
        final userOptions =
            _usersByDeptId[targetDeptId] ?? const <Map<String, dynamic>>[];
        final selectedUser = _findOptionByIdOrName(
              userOptions,
              id: user['userId'],
              name: _pickText(user, ['nickName', 'userName', 'name']),
              idKeys: const ['userId'],
              nameKeys: const ['nickName', 'userName'],
            ) ??
            user;
        _logger.i(
          '[修程通知单签收组] 回写签收人 dept=${signDept is Map ? signDept['deptName'] : ''} team=${signTeam is Map ? signTeam['deptName'] : ''} user=${_pickText(selectedUser, [
                'nickName',
                'userName',
                'name'
              ])}',
        );

        final rowKey =
            '${_asText(signDept is Map ? signDept['deptId'] : '')}_${_asText(signTeam is Map ? signTeam['deptId'] : '')}';
        final existingIndex = rowIndexByKey[rowKey];
        if (existingIndex != null) {
          final existingUsers = nextSignees[existingIndex]['signUsers']
              as List<Map<String, dynamic>>;
          final exists = existingUsers.any(
            (e) => _asText(e['userId']) == _asText(selectedUser['userId']),
          );
          if (!exists) {
            existingUsers.add(Map<String, dynamic>.from(selectedUser));
          }
          continue;
        }

        rowIndexByKey[rowKey] = nextSignees.length;
        nextSignees.add({
          'signDept':
              signDept is Map ? Map<String, dynamic>.from(signDept) : null,
          'signTeam':
              signTeam is Map ? Map<String, dynamic>.from(signTeam) : null,
          'signUsers': <Map<String, dynamic>>[
            Map<String, dynamic>.from(selectedUser)
          ],
        });
      }
    }
    if (!mounted || nextSignees.isEmpty) return;
    setState(() {
      _signeeList
        ..clear()
        ..addAll(nextSignees);
    });
    _logger.i('[修程通知单签收组] 已回写签收人 rows=${nextSignees.length}');
  }

  Future<void> _loadReceiveGroupOptions() async {
    if (_loadingReceiveGroup) return;
    if (mounted) {
      setState(() => _loadingReceiveGroup = true);
    }
    try {
      _logger.i('[修程通知单签收组] 开始查询签收组 shuntingType=13');
      final res = await ProductApi().getShuntingReceiveGroup(
        queryParametrs: {
          'pageNum': 0,
          'pageSize': 0,
          'shuntingType': 13,
        },
      );
      final rows = <Map<String, dynamic>>[];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            final row = Map<String, dynamic>.from(item);
            row['displayText'] = _pickText(row, ['name']);
            rows.add(row);
          }
        }
      } else if (res is Map && res['rows'] is List) {
        for (final item in res['rows']) {
          if (item is Map) {
            final row = Map<String, dynamic>.from(item);
            row['displayText'] = _pickText(row, ['name']);
            rows.add(row);
          }
        }
      }
      _logger.i('[修程通知单签收组] 页面收到签收组 rows=${rows.length}');
      _logger.i('[修程通知单签收组] 签收组原始数据=$rows');
      if (!mounted) return;
      setState(() {
        _receiveGroupOptions = rows;
        _loadingReceiveGroup = false;
      });
    } catch (e) {
      _logger.w('[修程通知单签收组] 加载失败 error=$e');
      if (!mounted) return;
      setState(() {
        _receiveGroupOptions = [];
        _loadingReceiveGroup = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _showSearchableListDialog({
    required String title,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    String valueKey = 'code',
    dynamic selectedValue,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = items.where((e) {
              final label = (e[labelKey] ?? '').toString();
              return label.toLowerCase().contains(query.toLowerCase());
            }).toList();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = selectedValue != null &&
                              _asText(item[valueKey]) == _asText(selectedValue);
                          return ListTile(
                            title: Text((item[labelKey] ?? '').toString()),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showFullScreenSingleSelectPage({
    required String title,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    String valueKey = 'code',
    dynamic selectedValue,
    dynamic selectedLabel,
    List<String> searchKeys = const [],
  }) async {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return _FullScreenSingleSelectPage(
            title: title,
            items: items,
            labelKey: labelKey,
            valueKey: valueKey,
            selectedValue: selectedValue,
            selectedLabel: selectedLabel,
            searchKeys: searchKeys,
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> _showMultiUserDialog({
    required List<Map<String, dynamic>> users,
    required List<dynamic> initialSelectedIds,
  }) async {
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) {
        final selectedIds = Set<dynamic>.from(initialSelectedIds);
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = users.where((user) {
              final name = _pickText(user, ['nickName', 'userName']);
              return name.toLowerCase().contains(query.toLowerCase());
            }).toList();
            return AlertDialog(
              title: const Text('选择签收人'),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final userId = user['userId'];
                          return CheckboxListTile(
                            value: selectedIds.contains(userId),
                            title:
                                Text(_pickText(user, ['nickName', 'userName'])),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedIds.add(userId);
                                } else {
                                  selectedIds.remove(userId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selected = users
                        .where((e) => selectedIds.contains(e['userId']))
                        .toList();
                    Navigator.pop(context, selected);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _signeeUserText(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return '';
    return users
        .map((e) => _pickText(e, ['nickName', 'userName']))
        .where((e) => e.isNotEmpty)
        .join('\n');
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    int maxLines = 1,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade50,
          ),
          child: trailing ??
              Text(
                _requiredText(value),
                maxLines: maxLines,
                overflow: maxLines == 1
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
              ),
        ),
      ],
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required VoidCallback onTap,
    String hintText = '请选择',
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: maxLines == 1
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? hintText : value,
                    maxLines: maxLines,
                    overflow: maxLines == 1
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    softWrap: maxLines != 1,
                    style: TextStyle(
                      color: value.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _textInputField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String hintText = '请输入',
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final user = Global.profile.permissions?.user;
    if (user == null) {
      showToast('未获取到当前用户信息');
      return;
    }
    if (!_validateBeforeSubmit(showError: true)) return;
    final allUsers = <Map<String, dynamic>>[];
    for (final signee in _signeeList) {
      final users = signee['signUsers'];
      if (users is List) {
        for (final e in users) {
          if (e is Map) {
            allUsers.add(Map<String, dynamic>.from(e));
          }
        }
      }
    }
    if (allUsers.isEmpty) {
      showToast('请选择签收人');
      return;
    }

    final noticeCode = _asText(_selectedNotice['code']);
    final workListPayload = <Map<String, dynamic>>[];
    for (final block in _workBlocks) {
      final workItem = Map<String, dynamic>.from(_selectedWork);
      final processingMethodText = block.processingMethodText.trim();
      final riskLevelText = block.riskLevelText.trim();
      final configText = block.configText.trim();
      final outsourceFactoryText = block.outsourceFactoryController.text.trim();
      final repairPlanText = block.repairPlanController.text.trim();
      final techGuideText = block.techGuideController.text.trim();

      if (block.selectedProcessingMethod != null) {
        final selected = block.selectedProcessingMethod!;
        final code = _asText(selected['code']).isNotEmpty
            ? _asText(selected['code'])
            : _asText(selected['dictCode']);
        workItem['requiredProcessingMethod'] = code;
        workItem['requiredProcessingMethodName'] = processingMethodText;
        workItem['processingMethodName'] = processingMethodText;
        workItem['processingMethod'] = processingMethodText;
        workItem['jtDictName'] = processingMethodText;
        workItem['jtDictCode'] = code;
      } else if (processingMethodText.isNotEmpty) {
        workItem['requiredProcessingMethodName'] = processingMethodText;
        workItem['processingMethodName'] = processingMethodText;
        workItem['processingMethod'] = processingMethodText;
        workItem['jtDictName'] = processingMethodText;
      }

      if (block.selectedRiskLevel != null) {
        final selected = block.selectedRiskLevel!;
        workItem['riskLevel'] = riskLevelText;
        workItem['riskLevelName'] = riskLevelText;
        workItem['riskLevelCode'] = selected['dictCode'];
      } else if (riskLevelText.isNotEmpty) {
        workItem['riskLevel'] = riskLevelText;
        workItem['riskLevelName'] = riskLevelText;
      }

      if (block.selectedConfig != null) {
        final selected = block.selectedConfig!;
        final configCode = _asText(selected['configCode']).isNotEmpty
            ? _asText(selected['configCode'])
            : _asText(selected['code']);
        workItem['configCode'] = configCode;
        workItem['configNodeName'] = configText;
        workItem['configName'] = configText;
        workItem['nodeName'] = _pickText(selected, ['nodeName']) == ''
            ? configText
            : _pickText(selected, ['nodeName']);
      } else if (configText.isNotEmpty) {
        workItem['configNodeName'] = configText;
        workItem['configName'] = configText;
        workItem['nodeName'] = configText;
      }

      workItem['outsourcingVendor'] = outsourceFactoryText;
      workItem['repairProcContent'] = repairPlanText;
      workListPayload.add(workItem);
    }
    final masNoticeDeptList = _buildMasNoticeDeptList(
      user: user,
      workListPayload: workListPayload,
    );
    final jt28Code = _pickTextFromSources([
      _selectedJt28,
      _selectedNotice
    ], [
      'jt28Code',
      'code',
      'masSaleInformationCode',
    ]);
    final payload = <String, dynamic>{
      'code': noticeCode,
      'jt28Code': jt28Code,
      'masNoticeDeptList': masNoticeDeptList,
    };

    if (noticeCode.isEmpty) {
      showToast('通知单编码缺失，无法提交');
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ProductApi().saveMasNotice(data: payload);
      final success =
          res != null && (res['code'] == 200 || res['code'] == 'S_T_S003');
      if (!mounted) return;
      if (success) {
        _showRepairProcessSuccessDialog();
      } else {
        showToast('下发失败: ${res?['msg'] ?? '未知错误'}');
      }
    } catch (e) {
      _logger.e('修程通知单下发失败: $e');
      if (!mounted) return;
      showToast('下发失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showRepairProcessSuccessDialog() {
    SmartDialog.show(
      clickMaskDismiss: false,
      builder: (_) {
        return Container(
          height: 150,
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                '修程通知单提报成功',
                style: TextStyle(fontSize: 18),
              ),
              ConstrainedBox(
                constraints:
                    const BoxConstraints.expand(height: 30, width: 160),
                child: ElevatedButton.icon(
                  onPressed: () {
                    SmartDialog.dismiss().then(
                      (_) => Navigator.of(context).pop(true),
                    );
                  },
                  icon: const Icon(Icons.system_security_update_good_sharp),
                  label: const Text('确定'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final faultValue = _jt28Label(_selectedJt28);
    final processNode = _currentProcessNodeName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('修程通知单'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionCard(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _pageTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _selectField(
                label: '故障现象',
                value: faultValue,
                onTap: () async {
                  if (_loadingJt28) {
                    showToast('机统28加载中，请稍后');
                    return;
                  }
                  if (_jt28Options.isEmpty) {
                    showToast('暂无可选机统28');
                    return;
                  }
                  final selected = await _showSearchableListDialog(
                    title: '请选择一条机统28',
                    items: _jt28Options,
                    labelKey: 'jt28DisplayText',
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _selectedJt28 = Map<String, dynamic>.from(selected);
                    _applyDefaultProcessNodeFromActive();
                    _applyDefaultRepairPlanFromJt28();
                    if (_workBlocks.isEmpty) {
                      _workBlocks.add(_createWorkBlock());
                    } else {
                      for (final block in _workBlocks) {
                        _applyDefaultsToWorkBlock(block, overwrite: true);
                      }
                    }
                  });
                  await _loadNoticeDetailByJt28(
                      Map<String, dynamic>.from(selected));
                },
                hintText: _loadingJt28 ? '机统28加载中...' : '请选择一条机统28',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _readOnlyField(
                      label: '工序节点',
                      value: processNode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _stopLocationFuture,
                      builder: (context, snapshot) {
                        return _readOnlyField(
                          label: '停留位置',
                          value: snapshot.data ?? '',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          _sectionCard(
            children: [
              ..._workBlocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                      bottom: index == _workBlocks.length - 1 ? 0 : 16),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: index == _workBlocks.length - 1
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _selectField(
                              label: '加工方法',
                              value: block.processingMethodText,
                              hintText: _loadingProcessingMethod
                                  ? '加工方法加载中...'
                                  : '请选择',
                              onTap: () async {
                                if (_loadingProcessingMethod) {
                                  showToast('加工方法加载中，请稍后');
                                  return;
                                }
                                if (_processingMethodOptions.isEmpty) {
                                  showToast('暂无加工方法可选');
                                  return;
                                }
                                final selected =
                                    await _showSearchableListDialog(
                                  title: '选择加工方法',
                                  items: _processingMethodOptions,
                                  labelKey: 'displayText',
                                );
                                if (selected == null || !mounted) return;
                                setState(() {
                                  block.selectedProcessingMethod =
                                      Map<String, dynamic>.from(selected);
                                  block.processingMethodText =
                                      _processingMethodLabel(
                                          block.selectedProcessingMethod);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectField(
                              label: '风险等级',
                              value: block.riskLevelText,
                              hintText:
                                  _loadingRiskLevel ? '风险等级加载中...' : '请选择',
                              onTap: () async {
                                if (_loadingRiskLevel) {
                                  showToast('风险等级加载中，请稍后');
                                  return;
                                }
                                if (_riskLevelOptions.isEmpty) {
                                  showToast('暂无风险等级可选');
                                  return;
                                }
                                final selected =
                                    await _showSearchableListDialog(
                                  title: '选择风险等级',
                                  items: _riskLevelOptions,
                                  labelKey: 'displayText',
                                );
                                if (selected == null || !mounted) return;
                                setState(() {
                                  block.selectedRiskLevel =
                                      Map<String, dynamic>.from(selected);
                                  block.riskLevelText =
                                      _riskLevelLabel(block.selectedRiskLevel);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _selectField(
                        label: '关联构型',
                        value: block.configText,
                        hintText: _loadingConfig ? '关联构型加载中...' : '请选择',
                        onTap: () async {
                          if (_loadingConfig) {
                            showToast('关联构型加载中，请稍后');
                            return;
                          }
                          if (_configOptions.isEmpty) {
                            showToast('暂无关联构型可选');
                            return;
                          }
                          final selected =
                              await _showFullScreenSingleSelectPage(
                            title: '选择关联构型',
                            items: _configOptions,
                            labelKey: 'displayText',
                            valueKey: 'configCode',
                            selectedValue: block.selectedConfig?['configCode'],
                            selectedLabel: block.configText,
                            searchKeys: const [
                              'displayText',
                              'nodeName',
                              'configNodeName',
                              'configName',
                              'structure',
                              'componentName',
                              'name',
                              'config',
                              'configCode',
                              'code',
                            ],
                          );
                          if (selected == null || !mounted) return;
                          setState(() {
                            block.selectedConfig =
                                Map<String, dynamic>.from(selected);
                            block.configText =
                                _configLabel(block.selectedConfig);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _textInputField(
                        label: '外包厂家',
                        controller: block.outsourceFactoryController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _textInputField(
                        label: '施修方案',
                        controller: block.repairPlanController,
                        maxLines: 4,
                        hintText: '各施修方案请分条填写，涉及到不同部门或不同班组请分条填写。',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            '技术指导',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _workBlocks.add(_createWorkBlock());
                              });
                            },
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue,
                            ),
                          ),
                          if (_workBlocks.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  final removed = _workBlocks.removeAt(index);
                                  removed.dispose();
                                });
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          _sectionCard(
            children: [
              _selectField(
                label: '签收组',
                value: _selectedReceiveGroup == null
                    ? ''
                    : _receiveGroupLabel(_selectedReceiveGroup),
                hintText: _loadingReceiveGroup ? '签收组加载中...' : '请选择签收组',
                onTap: () async {
                  if (_loadingReceiveGroup) {
                    showToast('签收组加载中，请稍后');
                    return;
                  }
                  if (_receiveGroupOptions.isEmpty) {
                    showToast('暂无签收组可选');
                    return;
                  }
                  final selected = await _showSearchableListDialog(
                    title: '选择签收组',
                    items: _receiveGroupOptions,
                    labelKey: 'displayText',
                    valueKey: 'code',
                    selectedValue: _selectedReceiveGroup?['code'],
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _selectedReceiveGroup = Map<String, dynamic>.from(selected);
                  });
                  await _applyReceiveGroupToSignees(
                    Map<String, dynamic>.from(selected),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    '签收人',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_signeeLockedByReceiveGroup) ...[
                    const SizedBox(width: 8),
                    Text(
                      '已由签收组自动回写',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_signeeLockedByReceiveGroup) {
                        showToast('已按签收组自动回写签收人，不能手动新增');
                        return;
                      }
                      setState(() {
                        _signeeList.add({
                          'signDept': null,
                          'signTeam': null,
                          'signUsers': <Map<String, dynamic>>[],
                        });
                      });
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._signeeList.asMap().entries.map((entry) {
                final index = entry.key;
                final signee = entry.value;
                final dept = signee['signDept'];
                final team = signee['signTeam'];
                final deptId = dept is Map ? _parseId(dept['deptId']) : null;
                final teamId = team is Map ? _parseId(team['deptId']) : null;
                final users = (signee['signUsers'] as List?)
                        ?.whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    <Map<String, dynamic>>[];
                final teamOptions = deptId != null
                    ? (_teamsByDeptId[deptId] ?? [])
                    : <Map<String, dynamic>>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _selectField(
                          label: '部门',
                          value: dept is Map
                              ? _pickText(
                                  Map<String, dynamic>.from(dept), ['deptName'])
                              : '',
                          maxLines: 2,
                          onTap: () async {
                            if (_signeeLockedByReceiveGroup) {
                              showToast('签收人已按签收组自动回写，不能手动修改');
                              return;
                            }
                            final selected = await _showSearchableListDialog(
                              title: '选择部门',
                              items: _deptList,
                              labelKey: 'deptName',
                            );
                            if (selected == null || !mounted) return;
                            setState(() {
                              signee['signDept'] = selected;
                              signee['signTeam'] = null;
                              signee['signUsers'] = <Map<String, dynamic>>[];
                            });
                            final nextDeptId = _parseId(selected['deptId']);
                            if (nextDeptId != null) {
                              await _loadTeamsForDept(nextDeptId);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _selectField(
                          label: '班组',
                          value: team is Map
                              ? _pickText(
                                  Map<String, dynamic>.from(team), ['deptName'])
                              : '',
                          maxLines: 2,
                          onTap: () async {
                            if (_signeeLockedByReceiveGroup) {
                              showToast('签收人已按签收组自动回写，不能手动修改');
                              return;
                            }
                            if (deptId == null) {
                              showToast('请先选择部门');
                              return;
                            }
                            final selected = await _showSearchableListDialog(
                              title: '选择班组',
                              items: teamOptions,
                              labelKey: 'deptName',
                            );
                            if (selected == null || !mounted) return;
                            setState(() {
                              signee['signTeam'] = selected;
                              signee['signUsers'] = <Map<String, dynamic>>[];
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _selectField(
                          label: '签收人',
                          value: _signeeUserText(users),
                          hintText: '请选择',
                          maxLines: 6,
                          onTap: () async {
                            if (_signeeLockedByReceiveGroup) {
                              showToast('签收人已按签收组自动回写，不能手动修改');
                              return;
                            }
                            final targetDeptId = teamId ?? deptId;
                            if (targetDeptId == null) {
                              showToast('请先选择部门或班组');
                              return;
                            }
                            await _loadUsersForDept(targetDeptId);
                            final userOptions = _usersByDeptId[targetDeptId] ??
                                <Map<String, dynamic>>[];
                            final selected = await _showMultiUserDialog(
                              users: userOptions,
                              initialSelectedIds:
                                  users.map((e) => e['userId']).toList(),
                            );
                            if (selected == null || !mounted) return;
                            setState(() {
                              signee['signUsers'] = selected;
                            });
                          },
                        ),
                      ),
                      if (_signeeList.length > 1) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            if (_signeeLockedByReceiveGroup) {
                              showToast('已按签收组自动回写签收人，不能手动删除');
                              return;
                            }
                            setState(() {
                              _signeeList.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canConfirm ? _submit : null,
                  child: Text(_submitting ? '提交中...' : '确认'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepairProcessWorkBlock {
  _RepairProcessWorkBlock({
    required this.processingMethodText,
    required this.riskLevelText,
    required this.configText,
    required String outsourceFactoryText,
    required String repairPlanText,
    required String techGuideText,
  })  : outsourceFactoryController =
            TextEditingController(text: outsourceFactoryText),
        repairPlanController = TextEditingController(text: repairPlanText),
        techGuideController = TextEditingController(text: techGuideText);

  String processingMethodText;
  String riskLevelText;
  String configText;
  Map<String, dynamic>? selectedProcessingMethod;
  Map<String, dynamic>? selectedRiskLevel;
  Map<String, dynamic>? selectedConfig;
  final TextEditingController outsourceFactoryController;
  final TextEditingController repairPlanController;
  final TextEditingController techGuideController;

  void dispose() {
    outsourceFactoryController.dispose();
    repairPlanController.dispose();
    techGuideController.dispose();
  }
}

class _FullScreenSingleSelectPage extends StatefulWidget {
  const _FullScreenSingleSelectPage({
    required this.title,
    required this.items,
    required this.labelKey,
    required this.valueKey,
    required this.selectedValue,
    required this.selectedLabel,
    required this.searchKeys,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String labelKey;
  final String valueKey;
  final dynamic selectedValue;
  final dynamic selectedLabel;
  final List<String> searchKeys;

  @override
  State<_FullScreenSingleSelectPage> createState() =>
      _FullScreenSingleSelectPageState();
}

class _FullScreenSingleSelectPageState
    extends State<_FullScreenSingleSelectPage> {
  String _query = '';

  String _safeText(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text == 'null') return '';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _safeText(widget.selectedValue);
    final selectedLabel = _safeText(widget.selectedLabel);
    final normalizedQuery = _query.toLowerCase().trim();
    final filtered = widget.items.where((item) {
      final label = _safeText(item[widget.labelKey]);
      if (normalizedQuery.isEmpty) return true;
      final candidates = <String>{
        label,
        _safeText(item[widget.valueKey]),
        for (final key in widget.searchKeys) _safeText(item[key]),
      };
      for (final candidate in candidates) {
        if (candidate.toLowerCase().contains(normalizedQuery)) {
          return true;
        }
      }
      return false;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final label = _safeText(item[widget.labelKey]);
                final currentValue = _safeText(item[widget.valueKey]);
                final isSelected =
                    (selected.isNotEmpty && currentValue == selected) ||
                        (selected.isEmpty &&
                            selectedLabel.isNotEmpty &&
                            label == selectedLabel);
                return ListTile(
                  title: Text(
                    label.isEmpty ? '-' : label,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
