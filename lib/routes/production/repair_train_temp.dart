import 'package:intl/intl.dart';
import 'package:jcjx_phone/routes/production/jt_assign.dart';
import 'package:jcjx_phone/routes/production/jt_assign_team.dart';
import 'package:jcjx_phone/routes/production/mutual_assign.dart';
import 'package:jcjx_phone/routes/production/special_assign.dart';
import '../../../index.dart';

class TrainRepairTempManage extends StatefulWidget {
  const TrainRepairTempManage({super.key});

  @override
  State<TrainRepairTempManage> createState() => _TrainRepairTempManageState();
}

class _TrainRepairTempManageState extends State<TrainRepairTempManage> {
  int _currentTab = 0; // 0: 在整机车，1: 已整机车

  // 创建 Logger 实例
  var logger = AppLogger.logger;

  int num = 0;

  int count1 = 0;

  int count2 = 0;

  int count3 = 0;

  String _currentProcTag = '';

  List<Map<String, dynamic>> repairTrainInfo = [];

  bool _isLoading = true; // 添加加载状态标识

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 初始化数据加载，使用异步并行加载提高速度
  Future<void> _loadInitialData() async {
    try {
      // 并行加载所有数据以提高速度
      await Future.wait([
        getRepairingTrainInfo('C4'),
        getRepairingTrainInfo('C5'),
        getRepairingTrainInfo('临修'),
      ]);

      // 数据加载完成后，自动加载第一个标签的第一个工序节点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFirstProcessNode(0); // 默认加载C4的第一个工序节点
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //C4
  List<Map<String, dynamic>> repairMainNodeInfo = [];

  //C5
  List<Map<String, dynamic>> repairMainNodeInfo1 = [];

  //临修
  List<Map<String, dynamic>> repairMainNodeInfo2 = [];

  Future<void> getRepairingTrainInfo(String repairMainNode) async {
    try {
      String repairProcCode1 = '';
      Global.repairProcInfo.forEach((element) {
        if (element['name'] == repairMainNode) {
          repairProcCode1 = element['code'];
        }
      });
      Map<String, dynamic> params = {
        // 'userId': Global.profile.permissions?.user.userId,
        'repairProcCode': repairProcCode1
      };
      logger.i('params: $params');
      var response = await ProductApi()
          .getRepairingAllTrainEntryByRepairProcCode(queryParametrs: params);

      if (mounted) {
        setState(() {
          if (response is List) {
            if (repairMainNode == 'C4') {
              repairMainNodeInfo = response
                  .map((e) => e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map))
                  .toList();
              for (Map<String, dynamic> element in repairMainNodeInfo) {
                count1 = count1 + (element['count'] as int? ?? 0);
              }
            }
            if (repairMainNode == 'C5') {
              repairMainNodeInfo1 = response
                  .map((e) => e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map))
                  .toList();
              for (Map<String, dynamic> element in repairMainNodeInfo1) {
                logger.i(element);
                count2 = count2 + (element['count'] as int? ?? 0);
              }
            }
            if (repairMainNode == '临修') {
              repairMainNodeInfo2 = response
                  .map((e) => e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map))
                  .toList();
              for (Map<String, dynamic> element in repairMainNodeInfo2) {
                count3 = count3 + (element['count'] as int? ?? 0);
              }
            }
          } else {
            repairMainNodeInfo = [];
          }
          logger.i('repairMainNodeInfo: $repairMainNodeInfo');
        });
      }
    } catch (e) {
      logger.i(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLocomotiveList(repairMainNodeInfo), // 使用实际的机车数据而不是空数组
    );
  }

  /// 构建顶部导航栏（含标签切换+红点提示）

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '检修进度',
        style: TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        TextButton.icon(
          onPressed: _showTrainSearchDialog,
          icon: const Icon(Icons.search, color: Colors.black),
          label: const Text(
            '车号搜索',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: Row(
            children: [
              // 标签：C4（带红点）
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentTab != 0) {
                      setState(() {
                        _currentTab = 0;
                      });
                      // 延迟加载第一个工序节点的内容，提高响应速度
                      Future.microtask(() => _loadFirstProcessNode(0));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _currentTab == 0
                              ? Colors.blue
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: Text(
                            "C4",
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _currentTab == 0 ? Colors.blue : Colors.grey,
                              fontWeight: _currentTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // 红点提示（动态显示）
                        if (count1 > 0)
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 12, top: 2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$count1",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // 标签：C5
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentTab != 1) {
                      setState(() {
                        _currentTab = 1;
                      });
                      // 延迟加载第一个工序节点的内容，提高响应速度
                      Future.microtask(() => _loadFirstProcessNode(1));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _currentTab == 1
                              ? Colors.green
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: Text(
                            "C5",
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _currentTab == 1 ? Colors.green : Colors.grey,
                              fontWeight: _currentTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // 红点提示（动态显示）
                        if (count2 > 0)
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 12, top: 2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$count2",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentTab != 2) {
                      setState(() {
                        _currentTab = 2;
                      });
                      // 延迟加载第一个工序节点的内容，提高响应速度
                      Future.microtask(() => _loadFirstProcessNode(2));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _currentTab == 2
                              ? Colors.orange
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: Text(
                            "临修",
                            style: TextStyle(
                              fontSize: 18,
                              color: _currentTab == 2
                                  ? Colors.orange
                                  : Colors.grey,
                              fontWeight: _currentTab == 2
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // 红点提示（动态显示）
                        if (count3 > 0)
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 12, top: 2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$count3",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 加载指定标签的第一个工序节点内容
  void _loadFirstProcessNode(int tabIndex) {
    // 根据标签索引选择对应的工序节点数据
    List<Map<String, dynamic>> procList = [];
    if (tabIndex == 0) {
      procList = repairMainNodeInfo;
    } else if (tabIndex == 1) {
      procList = repairMainNodeInfo1;
    } else if (tabIndex == 2) {
      procList = repairMainNodeInfo2;
    }

    // 更新工序节点页面数据
    repairMainNodePage = procList;

    // 如果工序节点列表不为空，自动选择第一个
    if (procList.isNotEmpty) {
      final firstProc = procList[0];
      _currentProcTag = firstProc['repairMainNodeCode'];
      repairTrainInfo = (firstProc['trainEntryList'] as List<dynamic>)
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map))
          .toList();
    } else {
      // 如果没有工序节点，清空相关数据
      _currentProcTag = '';
      repairTrainInfo = [];
    }
  }

  Widget _buildLocomotiveList(List<Map<String, dynamic>> repairTrain) {
    //纵向修改信息
    return Row(
      children: [
        Container(
          width: 100,
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: _buildProcTagList(),
        ),
        // 右侧机车详细信息
        Expanded(
          child: _buildLocomotiveDetailList(),
        ),
      ],
    );
  }

  /// 构建工序节点标签列表
  List<Map<String, dynamic>> repairMainNodePage = [];
  Widget _buildProcTagList() {
    if (_currentTab == 0) {
      repairMainNodePage = repairMainNodeInfo;
    } else if (_currentTab == 1) {
      repairMainNodePage = repairMainNodeInfo1;
    } else if (_currentTab == 2) {
      repairMainNodePage = repairMainNodeInfo2;
    }
    return ListView.builder(
      itemCount: repairMainNodePage.length,
      itemBuilder: (context, index) {
        final proc = repairMainNodePage[index];
        final count = proc['count'] is int ? proc['count'] as int : 0;

        return GestureDetector(
          onTap: () {
            // 处理标签点击事件
            _onProcTagTap(proc);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
              color: _currentProcTag == proc['repairMainNodeCode']
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    proc['repairMainNodeName'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentProcTag == proc['repairMainNodeCode']
                          ? Colors.blue
                          : Colors.black,
                      fontWeight: _currentProcTag == proc['repairMainNodeCode']
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ), 
                if (count != 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 工序标签点击事件
  void _onProcTagTap(Map<String, dynamic> proc) {
    setState(() {
      _currentProcTag = proc['repairMainNodeCode'];
      repairTrainInfo = (proc['trainEntryList'] as List<dynamic>)
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map))
          .toList();
    });
    // 可以在这里添加获取对应工序数据的逻辑
    showToast('切换到工序: ${proc['repairMainNodeName']}');
  }

  void _showTrainSearchDialog() {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('车号查询'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: "请输入车号",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                String trainNum = _controller.text.trim();
                if (trainNum.isNotEmpty) {
                  _searchTrainByNum(trainNum);
                  Navigator.of(context).pop();
                } else {
                  showToast('请输入车号');
                }
              },
              child: const Text('查询'),
            ),
          ],
        );
      },
    );
  }

  /// 根据车号搜索机车
  void _searchTrainByNum(String trainNum) {
    // 查找包含该车号的机车信息
    List<Map<String, dynamic>> foundTrains = [];

    // 遍历所有工序下的机车数据
    void searchInNodeList(List<Map<String, dynamic>> nodeList) {
      for (var node in nodeList) {
        if (node['trainEntryList'] is List) {
          for (var train in node['trainEntryList']) {
            if (train is Map<String, dynamic> &&
                (train['trainNum']?.toString().contains(trainNum) ?? false)) {
              foundTrains.add(train);
            }
          }
        }
      }
    }

    // 在所有三个标签页中搜索
    searchInNodeList(repairMainNodeInfo);
    searchInNodeList(repairMainNodeInfo1);
    searchInNodeList(repairMainNodeInfo2);

    if (foundTrains.isNotEmpty) {
      setState(() {
        repairTrainInfo = foundTrains;
      });
      showToast('找到 ${foundTrains.length} 条记录');
    } else {
      showToast('未找到相关车号');
    }
  }

  /// 构建机车详细信息列表
  Widget _buildLocomotiveDetailList() {
    if (repairTrainInfo.isEmpty) {
      return const Center(
        child: Text("暂无机车数据", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: repairTrainInfo.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final loco = repairTrainInfo[index];
        final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        return GestureDetector(
          onTap: () {
            if (repairTrainInfo.isNotEmpty && index < repairTrainInfo.length) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PreparationDetailPage(locoInfo: repairTrainInfo[index]),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 机车编号 + 入段时间
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loco['typeName'] ?? ''}-${loco['trainNum'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (loco['arrivePlatformTime'] != null)
                        Text(
                          "入段时间: ${timeFormat.format(DateTime.parse(loco['arrivePlatformTime']))}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                          "停留机车地点：${loco['stopPlace'] != "null-null" ? loco['stopPlace'] : ''}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Text(
                          "工序节点：${loco['repairMainNodeName'] != '' ? loco['repairMainNodeName'] : ''}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Text(
                          "工序转入时间：${loco['mainNodeChangeTime'] != null ? timeFormat.format(DateTime.parse(loco['mainNodeChangeTime'])) : ''}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Text(
                          "计划转出时间：${loco['theoreticEndTime'] != null ? timeFormat.format(DateTime.parse(loco['theoreticEndTime'])) : ''}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 自检、互检、专检信息展示
                  Row(
                    children: [
                      _buildInspectionItem("自检",
                          loco['taskCertainPackageCount']?.toString() ?? '0'),
                      const SizedBox(width: 16),
                      _buildInspectionItem("互检",
                          loco['mutualInspectionCount']?.toString() ?? '0'),
                      const SizedBox(width: 16),
                      _buildInspectionItem("专检",
                          loco['specialInspectionCount']?.toString() ?? '0'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 辅助方法：构建待办任务项（标签+数值）
  Widget _buildTodoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 辅助方法：构建检查项（标签+数值）
  Widget _buildInspectionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 辅助方法：构建信息项（标签+值）
Widget _buildInfoItem(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

/// 辅助方法：构建待办任务项（标签+数值）
Widget _buildTodoItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

//机车派工详情
class PreparationDetailPage extends StatefulWidget {
  //主流程节点主键
  final String? repairMainCode;
  //机车信息
  final Map<String, dynamic>? locoInfo;

  const PreparationDetailPage({Key? key, this.locoInfo, this.repairMainCode})
      : super(key: key);

  @override
  _PreparationDetailPageState createState() => _PreparationDetailPageState();
}

class _PreparationDetailPageState extends State<PreparationDetailPage> {
  Map<String, dynamic> numberInfo = {};

  //获取待作业数量
  void getNumber() async {
    Map<String, dynamic> params = {
      "trainEntryCode": widget.locoInfo?['code'],
      "userId": Global.profile.permissions?.user.userId
    };
    try {
      var r =
          await ProductApi().getTaskDistributionStatus(queryParametrs: params);
      if (mounted) {
        setState(() {
          if (r is Map) {
            numberInfo = Map<String, dynamic>.from(r);
          } else if (r is Map<String, dynamic>) {
            numberInfo = r;
          }
        });
      }
    } catch (e) {
      // 处理错误情况
      print('Error fetching package and inspection statistics: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('检修作业-明细（派工）'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 机车基本信息区
            _buildTrainInfo(),
            const SizedBox(height: 16),

            // 操作按钮区
            _buildActionButtons(),
            const SizedBox(height: 24),

            // 任务统计区
            const Text(
              '作业清单',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Column( 
              children: [
                TaskCard(
                  title: '范围作业派工',
                  subtitle: '工序节点范围作业包清单',
                  count:
                      '${numberInfo['hasDispatchedPackageCount'] ?? 0}/${numberInfo['totalPackageCount'] ?? 0}',
                  locoInfo: widget.locoInfo, 
                  // 将locoInfo传递给TaskCard
                  onTap: () async {
                    if (Global.profile.permissions!.roles
                        .contains('gongzhang')) {
                      // 在这里处理待作业的点击事件 
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PackageArrangeInfo(locoInfo: widget.locoInfo)),
                      );
                      // 如果从派工页面返回了true，则刷新当前页面
                      if (result == true) {
                        getNumber(); // 重新获取数据
                      }
                    } else {
                      showToast('只有工长有范围派工权限');
                    }
                  },
                ),
                TaskCard(
                  title: '机统28作业派工',
                  subtitle: '机车机统28作业清单',
                  count:
                      '${numberInfo['hasDispatchedJt28Count'] ?? 0}/${numberInfo['totalJt28Count'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    List<String>? roles = Global.profile.permissions?.roles;
                    if (roles!.contains("chejianzhuren")) {
                      // 在这里处理待作业的点击事件
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => JtWorkAssignTeam(
                                  trainNum: widget.locoInfo?['trainNum'] ?? '',
                                  trainNumCode:
                                      widget.locoInfo?['trainNumCode'] ?? '',
                                  typeName: widget.locoInfo?['typeName'] ?? '',
                                  typeCode: widget.locoInfo?['typeCode'] ?? '',
                                  trainEntryCode:
                                      widget.locoInfo?['code'] ?? '',
                                )),
                      );
                    } else if (roles.contains("gongzhang")) {
                      // 在这里处理待作业的点击事件
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => JtWorkAssign(
                                  trainNum: widget.locoInfo?['trainNum'] ?? '',
                                  trainNumCode:
                                      widget.locoInfo?['trainNumCode'] ?? '',
                                  typeName: widget.locoInfo?['typeName'] ?? '',
                                  typeCode: widget.locoInfo?['typeCode'] ?? '',
                                  trainEntryCode:
                                      widget.locoInfo?['code'] ?? '',
                                )),
                      );
                    }
                  },
                ),
                TaskCard(
                  title: '互检作业派工',
                  subtitle: '工序互检作业清单',
                  count:
                      '${numberInfo['hasDispatchedMutualInspectionCount'] ?? 0}/${numberInfo['totalMutualInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MutualAssign(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    );
                  },
                ),
                TaskCard(
                  title: '专检作业派工',
                  subtitle: '工序专检作业清单',
                  count:
                      '${numberInfo['hasDispatchedSpecialInspectionCount'] ?? 0}/${numberInfo['totalMutualInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpecialAssign(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainInfo() {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.locoInfo?['typeName'] ?? ''} ${widget.locoInfo?['trainNum'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.locoInfo != null &&
                      widget.locoInfo!['arrivePlatformTime'] != null
                  ? '入段:${timeFormat.format(DateTime.parse(widget.locoInfo!['arrivePlatformTime']))}'
                  : '入段:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 每一项单独一行显示
        _InfoItem(
            label: '停留地点',
            value: widget.locoInfo?['stopPlace'] != "null-null"
                ? (widget.locoInfo?['stopPlace'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        // 每一项单独一行显示
        _InfoItem(
            label: '工序节点',
            value: widget.locoInfo?['repairMainNodeName'] != ''
                ? (widget.locoInfo?['repairMainNodeName'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转入时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['mainNodeChangeTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['mainNodeChangeTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转出时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['theoreticEndTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['theoreticEndTime']))
                : '无'),
      ],
    );
  }

// ... existing code ...
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: () {},
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.tealAccent.shade700,
        //       foregroundColor: Colors.white,
        //     ),
        //     child: const Text('机车详情查询'),
        //   ),
        // ),
        // const SizedBox(width: 8),
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: () {},
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.blue,
        //       foregroundColor: Colors.white,
        //     ),
        //     child: const Text('检修调度命令'),
        //   ),
        // ),
        // const SizedBox(width: 8),
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => const Vehicle28Form(),
        //         ),
        //       );
        //     },
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.redAccent,
        //       foregroundColor: Colors.white,
        //     ),
        //     child: const Text('机统28提报'),
        //   ),
        // ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// ... existing code ...
class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;
  final Map<String, dynamic>? locoInfo;
  final VoidCallback? onTap;

  const TaskCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.locoInfo,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: const Text('派工'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PackageArrangeInfo extends StatefulWidget {
  //机车信息
  final Map<String, dynamic>? locoInfo;

  const PackageArrangeInfo({
    Key? key,
    this.locoInfo,
  }) : super(key: key);
  @override
  State<PackageArrangeInfo> createState() => _PackageArrangeInfoState();
}

class _PackageArrangeInfoState extends State<PackageArrangeInfo> {
  var logger = AppLogger.logger;

  List<Map<String, dynamic>> packageList = [];

  @override
  void initState() {
    super.initState();
    getPackageManage();
    logger.i(widget.locoInfo);
  }

  void getPackageManage() async {
    Map<String, dynamic> params = {"trainEntryCode": widget.locoInfo?['code']};
    logger.i(params);
    var r = await ProductApi().getAssignPackage(params);
    if (mounted) {
      setState(() {
        packageList = (r as List<dynamic>)
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        logger.i(packageList);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InspectionPackagePage(
      locoInfo: widget.locoInfo,
      packageList: packageList,
    );
  }
}

/// 机车信息模型
class Locomotive {
  final String id; // 机车编号（如 HXD3C 0016）
  final DateTime inTime; // 入段时间
  final String track; // 股道
  final String planTrain; // 计划车次
  final String planOut; // 计划出库
  final String status; // 整备状态（如“整备中”）

  Locomotive({
    required this.id,
    required this.inTime,
    required this.track,
    required this.planTrain,
    required this.planOut,
    required this.status,
  });
}

/// 作业项模型（如车内2、车底等）
class TaskItem {
  final String name; // 作业名称（如“车内2”）
  final int completed; // 已完成数量（如 0）
  final int total; // 总数量（如 16）
  final String userStatus; // 领用人状态（如“未申领”）

  TaskItem({
    required this.name,
    required this.completed,
    required this.total,
    required this.userStatus,
  });
}

class InspectionPackagePage extends StatefulWidget {
  final List<Map<String, dynamic>> packageList;
  final Map<String, dynamic>? locoInfo;

  const InspectionPackagePage(
      {super.key, this.locoInfo, required this.packageList});

  @override
  State<InspectionPackagePage> createState() => _InspectionPackagePageState();
}

class _InspectionPackagePageState extends State<InspectionPackagePage> {
  List<Map<String, dynamic>> packageList = [];
  var logger = AppLogger.logger;
  // 模拟机车数据
  final Locomotive _locomotive = Locomotive(
    id: "HXD3C 0016",
    inTime: DateTime(2023, 2, 24, 14, 58, 15),
    track: "J2道机",
    planTrain: "无",
    planOut: "无",
    status: "整备中",
  );

  // 模拟作业项数据
  final List<TaskItem> _tasks = [
    TaskItem(name: "车内2", completed: 0, total: 16, userStatus: "未申领"),
    TaskItem(name: "车底", completed: 0, total: 8, userStatus: "未申领"),
    TaskItem(name: "车外", completed: 0, total: 15, userStatus: "未申领"),
    TaskItem(name: "车顶", completed: 0, total: 12, userStatus: "未申领"),
  ];

  @override
  void initState() {
    super.initState();
    getPackageManage();
  }

  void getPackageManage() async {
    Map<String, dynamic> params = {"trainEntryCode": widget.locoInfo?['code']};
    logger.i(params);
    var r = await ProductApi().getAssignPackage(params);
    if (mounted) {
      setState(() {
        packageList = (r as List<dynamic>)
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        logger.i(packageList);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss"); // 时间格式化
    // ... existing code ...
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () async {
            if (Navigator.canPop(context)) {
              // 返回前刷新界面
              Navigator.pop(context, true); // 传递true表示需要刷新
            } else {
              // 如果无法pop，尝试使用maybePop或者给出提示
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text("检修作业-作业包(派工)"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // 支持滚动（防止内容溢出）
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机车基本信息
            _buildTrainInfo(),
            const SizedBox(height: 16),

            // 2. 作业项列表
            ...packageList.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建机车基本信息区域
  Widget _buildTrainInfo() {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.locoInfo?['typeName'] ?? ''} ${widget.locoInfo?['trainNum'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.locoInfo != null &&
                      widget.locoInfo!['arrivePlatformTime'] != null
                  ? '入段:${timeFormat.format(DateTime.parse(widget.locoInfo!['arrivePlatformTime']))}'
                  : '入段:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 每一项单独一行显示
        _InfoItem(
            label: '停留地点',
            value: widget.locoInfo?['stopPlace'] != "null-null"
                ? (widget.locoInfo?['stopPlace'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序节点',
            value: widget.locoInfo?['repairMainNodeName'] != ''
                ? (widget.locoInfo?['repairMainNodeName'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转入时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['mainNodeChangeTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['mainNodeChangeTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转出时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['theoreticEndTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['theoreticEndTime']))
                : '无'),
      ],
    );
  }

  /// 辅助方法：信息项（标签+值）
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建单个作业项（如车内2、车底）
  Widget _buildTaskItem(Map<String, dynamic> task) {
    // final progress =
    //     task['total'] == 0 ? 0.0 : task['completeCount'] / task['total'];

    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => InspectionVertexPage(
        //       locoInfo: widget.locoInfo,
        //       packageInfo: task,
        //     ),
        //   ),
        // );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        // ... existing code ...
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 文件夹图标
              Icon(
                Icons.folder,
                color: Colors.yellow.shade700,
                size: 32,
              ),
              const SizedBox(width: 12),

              // 作业名称 + 进度文本 + 进度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称 + 进度（如"车内2 0/16"）
                    Text(
                      "${task['name']} ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 主修人和辅修人信息
              // ... existing code ...
              // 主修人和辅修人信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主修
                  Text(
                    "主修人：${task['executorName'] ?? '未指定'}",
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "主修人列表：${task['repairPersonnelNameList'] ?? '未指定'}",
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 辅修
                  Text(
                    "辅修人：${task['assistantName'] ?? '未指定'}",
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "辅修人列表：${task['assistantNameList'] ?? '未指定'}",
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
// ... existing code ...
              const SizedBox(width: 12),

              // 作业人员查询按钮
              ElevatedButton(
                onPressed: () async {
                  // 作业人员查询按钮点击事件
                  // _onWorkerQueryPressed(task);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RollCallPage(packageCode: task['code']),
                    ),
                  );
                  // 如果从派工页面返回了true，则刷新当前页面
                  if (result == true) {
                    getPackageManage(); // 重新获取数据
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(60, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('作业\n人员\n查询', textAlign: TextAlign.center),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// 班组模型
class Team {
  String name; // 班组名（如“北折一组”）
  late List<Member> members; // 成员列表
  Team(this.name, this.members);
}

/// 成员模型
class Member {
  final String name; // 姓名（如“曹阳”）
  final int id; // 工号（如“3368”）
  Member(this.name, this.id);
}

/// 检修项模型
class InspectionItem {
  final String name; // 项名称（如“车底”）
  bool isChecked; // 是否勾选
  InspectionItem(this.name, this.isChecked);
}

class RollCallPage extends StatefulWidget {
  final String packageCode;
  final Function()? onRefresh;
  const RollCallPage({super.key, required this.packageCode, this.onRefresh});

  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

// ... existing code ...
class _RollCallPageState extends State<RollCallPage> {
  String? deptName = Global.profile.permissions?.user.dept?.deptName;

  // 班组数据（模拟）
  late Team _team;

  // 当前选中的成员（默认选第一个）
  late Member _selectedMember;

  // 机型选项（模拟下拉）
  final List<String> _modelOptions = ['HXD3CA', 'HXD3C', 'HXD1D'];
  String _selectedModel = 'HXD3CA';

  // 检修项列表（模拟状态）
  final List<InspectionItem> _inspectionItems = [
    InspectionItem('主修', false),
    InspectionItem('辅修', false),
  ];

  // 添加搜索控制器和过滤后的成员列表
  final TextEditingController _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  var logger = AppLogger.logger;

  void getUserList() async {
    Map<String, dynamic> params = {
      "deptId": Global.profile.permissions?.user.dept?.deptId,
      "pageNum": 0,
      "pageSize": 0,
    };
    try {
      var response = await ProductApi().getTeamUser(queryParametrs: params);

      if (response is List) {
        // 将List<dynamic>转换为List<Map<String, dynamic>>
        List<Map<String, dynamic>> userList = response
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        print(userList);
        // 根据获取的用户列表更新_team.members
        if (userList.isNotEmpty) {
          List<Member> members = userList.map((user) {
            return Member(
              user['nickName'] ?? '未知用户',
              user['userId'] ?? '未知ID',
            );
          }).toList();

          setState(() {
            _team.members = members;
            _filteredMembers = members; // 同时更新过滤列表
            if (members.isNotEmpty) {
              _selectedMember = members[0]; // 更新选中的成员为第一个
            }
          });
        }
      }
    } catch (e) {
      // 错误处理
      print('获取用户列表失败: $e');
    }
  }

  // 添加过滤成员的方法
  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _team.members;
      } else {
        _filteredMembers = _team.members
            .where((member) =>
                member.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始化团队数据
    _team = Team(deptName ?? '默认班组', []);
    // 监听搜索框输入
    _searchController.addListener(() {
      _filterMembers(_searchController.text);
    });
    getUserList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void setRepairInfo() async {
    Map<String, dynamic> params = {
      "code": widget.packageCode,
    };
    if (_inspectionItems[0].isChecked) {
      params['executorId'] = _selectedMember.id;
      params['executorName'] = _selectedMember.name;
    }
    if (_inspectionItems[1].isChecked) {
      params['assistantId'] = _selectedMember.id;
      params['assistantName'] = _selectedMember.name;
    }
    try {
      logger.i(params);
      var response = await ProductApi()
          .updateTaskInstructPackageRepairInfo(queryParametrs: params);

      if (response is List) {
        // 将List<dynamic>转换为List<Map<String, dynamic>>
      }
      if (response['code'] == 200) {
        showToast("确认成功");
      }
    } catch (e) {
      // 错误处理
      print('获取用户列表失败: $e');
    }
  }

  int _selectedInspectionIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (Navigator.canPop(context)) {
              // 返回前刷新界面
              Navigator.pop(context, true); // 传递true表示需要刷新
            } else {
              // 如果无法pop，尝试使用maybePop或者给出提示
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('开工点名(检修)'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Row(
        children: [
          // 左侧：人员列表
          Container(
            width: 160,
            color: Colors.white,
            child: Column(
              children: [
                // 班组名称
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    _team.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 添加搜索框（固定在顶部）
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索用户...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                // 成员列表（可滚动部分）
                Expanded(
                  child: ListView(
                    children: [
                      // 成员列表
                      ..._filteredMembers.map((member) {
                        final isSelected = member == _selectedMember;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMember = member;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: isSelected ? Colors.green : Colors.white,
                            child: Text(
                              '${member.name}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16, // 增大字体
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal, // 选中时加粗
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右侧：详情区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // 检修项列表
                  Column(
                    children: _inspectionItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      InspectionItem item = entry.value;
                      return RadioListTile<int>(
                        title: Text(item.name),
                        value: idx,
                        groupValue: _selectedInspectionIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedInspectionIndex = value ?? -1;
                            // 重置所有项的选中状态
                            for (int i = 0; i < _inspectionItems.length; i++) {
                              _inspectionItems[i].isChecked =
                                  (i == _selectedInspectionIndex);
                            }
                          });
                        },
                        activeColor: Colors.green,
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  // 底部按钮：固定检修项
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 可扩展：提交检修项逻辑
                        setRepairInfo();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        '确认',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
