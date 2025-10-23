import 'package:intl/intl.dart';
import 'package:jcjx_phone/routes/production/apply_page.dart';
import 'package:jcjx_phone/routes/production/jt_work.dart';
import 'package:jcjx_phone/routes/production/package_complete.dart';
import 'package:jcjx_phone/routes/production/package_mutual.dart';
import 'package:jcjx_phone/routes/production/package_special.dart';
import 'package:jcjx_phone/routes/production/special_work.dart';
import '../../index.dart';
import '../vehicle28/submit28_manage.dart';
import 'mutual_work.dart';
import 'package:path/path.dart' as path;

/// 主页面：机车检修
class TrainRepairPage extends StatefulWidget {
  const TrainRepairPage({super.key});

  @override
  State<TrainRepairPage> createState() => _TrainRepairPageState();
}

class _TrainRepairPageState extends State<TrainRepairPage> {
  int _currentTab = 0; // 0: 在整机车，1: 已整机车

  // 创建 Logger 实例
  var logger = AppLogger.logger;

  int num = 0;

  int count1 = 0;

  int count2 = 0;

  int count3 = 0;

  String _currentProcTag = '';

  List<Map<String, dynamic>> repairTrainInfo = [];

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
        'userId': Global.profile.permissions?.user.userId,
        'repairProcCode': repairProcCode1
      };
      logger.i('params: $params');
      var response = await ProductApi()
          .getRepairingTrainEntryByUserIdAndRepairProcCode(
              queryParametrs: params);

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
              logger.i('count1: $count1');
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
              logger.i('count2: $count2');
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
              logger.i('count3: $count3');
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

  bool _isLoading = true; // 添加加载状态标识
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
        "检修作业-机车",
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

  List<Map<String, dynamic>> repairMainNodePage = [];

  /// 构建工序节点标签列表

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PreparationDetailPage(locoInfo: repairTrainInfo[index]),
              ),
            );
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
      var r = await ProductApi()
          .getPackageAndInspectionStatistics(queryParametrs: params);
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
        title: const Text('检修作业-明细'),
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
                  title: '待范围作业',
                  subtitle: '工序节点范围作业包清单',
                  count:
                      '${numberInfo['completePackageCount'] ?? 0}/${numberInfo['totalPackageCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PackageInfo(locoInfo: widget.locoInfo)),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
                  },
                ),
                // TaskCard(
                //   title: '待派工',
                //   subtitle: '当前机车下需处理的活件总数',
                //   count: '1',
                // ),
                // TaskCard(
                //   title: '待销活',
                //   subtitle: '当前机车下本人需要销活的活件总数',
                //   count: '1',
                // ),
                TaskCard(
                  title: '待机统28作业内容',
                  subtitle: '机车机统28作业清单',
                  count:
                      '${numberInfo['completeJt28Count'] ?? 0}/${numberInfo['totalJt28Count'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              // MutualPackageList(
                              //       trainNum: widget.locoInfo?['trainNum'] ?? '',
                              //       trainNumCode:
                              //           widget.locoInfo?['trainNumCode'] ?? '',
                              //       typeName: widget.locoInfo?['typeName'] ?? '',
                              //       typeCode: widget.locoInfo?['typeCode'] ?? '',
                              //       trainEntryCode: widget.locoInfo?['code'] ?? '',
                              //     )
                              JtWorkList(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode:
                                    widget.locoInfo?['trainEntryCode'] ??
                                        widget.locoInfo?['code'] ??
                                        '',
                              )),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
                  },
                ),
                TaskCard(
                  title: '待范围互检作业',
                  subtitle: '工序互检作业清单',
                  count: '${numberInfo['needToMutualInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () async {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MutualPackageList(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
                  },
                ),
                TaskCard(
                  title: '待范围专检作业',
                  subtitle: '工序专检作业清单',
                  count: '${numberInfo['needToSpecialInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpecialPackageList(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
                  },
                ),
                TaskCard(
                  title: '待机统28互检作业',
                  subtitle: '工序互检作业清单',
                  count:
                      '${numberInfo['jt28NeedToMutualInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MutualWorkList(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
                  },
                ),
                TaskCard(
                  title: '待机统28专检作业',
                  subtitle: '工序专检作业清单',
                  count:
                      '${numberInfo['jt28NeedToSpecialInspectionCount'] ?? 0}',
                  locoInfo: widget.locoInfo, // 将locoInfo传递给TaskCard
                  onTap: () {
                    // 在这里处理待作业的点击事件
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpecialWorkList(
                                trainNum: widget.locoInfo?['trainNum'] ?? '',
                                trainNumCode:
                                    widget.locoInfo?['trainNumCode'] ?? '',
                                typeName: widget.locoInfo?['typeName'] ?? '',
                                typeCode: widget.locoInfo?['typeCode'] ?? '',
                                trainEntryCode: widget.locoInfo?['code'] ?? '',
                              )),
                    ).then((value) {
                      // 只有当返回值为true时才刷新数据
                      if (value == true) {
                        getNumber();
                      }
                    });
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
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // 跳转到ApplyList页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyList(
                    trainNum: widget.locoInfo?['trainNum'] ?? '',
                    trainNumCode: widget.locoInfo?['trainNumCode'] ?? '',
                    typeName: widget.locoInfo?['typeName'] ?? '',
                    typeCode: widget.locoInfo?['typeCode'] ?? '',
                    trainEntryCode: widget.locoInfo?['code'] ?? '',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('检修调度命令'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Vehicle28Form(
                    locoInfo: widget.locoInfo,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('机统28提报'),
          ),
        ),
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
      onTap: onTap ??
          () {
            // 默认的点击处理逻辑
            if (title == '待作业') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PackageInfo()),
              );
            }
          },
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
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//待范围作业
class PackageInfo extends StatefulWidget {
  //机车信息
  final Map<String, dynamic>? locoInfo;

  const PackageInfo({
    Key? key,
    this.locoInfo,
  }) : super(key: key);
  @override
  State<PackageInfo> createState() => _PackageInfoState();
}

class _PackageInfoState extends State<PackageInfo> {
  var logger = AppLogger.logger;

  List<Map<String, dynamic>> packageList = [];

  void initState() {
    // getWorkPackage();
  }

  void getWorkPackage() async {
    Map<String, dynamic> params = {
      "trainEntryCode": widget.locoInfo?['code'],
      "userId": Global.profile.permissions?.user.userId
    };
    logger.i(params);
    var r = await ProductApi().getPersonalWorkPackage(queryParametrs: params);
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

  var logger = AppLogger.logger;

  List<Map<String, dynamic>> packageList = [];

  // 在状态类中添加变量
  List<Map<String, dynamic>> pendingUploadData = [];
  bool isUploading = false;

// 添加方法用于加载本地待上传数据
  Future<void> _loadPendingUploadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? pendingDataString = prefs.getString('pending_upload_data');
      if (pendingDataString != null) {
        List<dynamic> pendingDataList = json.decode(pendingDataString);
        setState(() {
          pendingUploadData = pendingDataList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      logger.e('加载待上传数据失败: $e');
    }
  }

// 添加方法用于清除已上传的数据
  Future<void> _clearUploadedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_upload_data');
      setState(() {
        pendingUploadData = [];
      });
      SmartDialog.showToast('已上传数据已清除');
    } catch (e) {
      logger.e('清除已上传数据失败: $e');
    }
  }

// 添加方法用于上传所有待上传的数据
// 修改上传方法以处理视频
  Future<void> _uploadAllPendingData() async {
    if (pendingUploadData.isEmpty) {
      SmartDialog.showToast('没有需要上传的数据');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      List<Map<String, dynamic>> failedUploads = [];

      for (int i = 0; i < pendingUploadData.length; i++) {
        var data = pendingUploadData[i];

        try {
          SmartDialog.showLoading(msg: '正在上传第${i + 1}项数据...');

          // 1. 上传图片和视频
          List<File> imageFiles = [];
          List<File> videoFiles = [];

          // 处理所有媒体文件
          if (data['allMedia'] != null && data['allMedia'] is List) {
            for (var media in data['allMedia']) {
              if (media is Map<String, dynamic>) {
                File file = File(media['path']);
                if (media['type'] == 'video') {
                  videoFiles.add(file);
                } else {
                  imageFiles.add(file);
                }
              }
            }
          }

          // 上传图片
          if (imageFiles.isNotEmpty) {
            await ProductApi().uploadCertainPackageImg(
              queryParametrs: {
                'certainPackageCodeList': data['packageCode'],
              },
              imagedatas: imageFiles,
            );
          }

          // 上传视频（需要后端支持）
          if (videoFiles.isNotEmpty) {
            await ProductApi().uploadCertainPackageImg(
              queryParametrs: {
                'certainPackageCodeList': data['packageCode'],
              },
              imagedatas: videoFiles,
            );
            logger.i('视频文件待上传: ${videoFiles.length}个');
          }

          // 2. 保存作业项数据
          if (data['taskContentItems'] != null &&
              data['taskContentItems'] is List) {
            List<Map<String, dynamic>> taskContentItems =
                (data['taskContentItems'] as List)
                    .map((item) => item as Map<String, dynamic>)
                    .toList();

            if (taskContentItems.isNotEmpty) {
              await ProductApi().saveOrUpdateTaskContentItem(taskContentItems);
            }
          }

          // 3. 完成包装
          List<Map<String, dynamic>> completeParams = [
            {
              'code': data['packageCode'],
              'completeTime': data['completeTime'],
            }
          ];

          await ProductApi().finishCertainPackage(completeParams);

          SmartDialog.dismiss();
          SmartDialog.showToast('第${i + 1}项数据上传成功');
        } catch (e) {
          SmartDialog.dismiss();
          logger.e('上传第${i + 1}项数据失败: $e');
          SmartDialog.showToast('第${i + 1}项数据上传失败');
          failedUploads.add(data);
        }
      }

      if (failedUploads.isEmpty) {
        // 所有数据上传成功，清除本地存储
        await _clearUploadedData();
        SmartDialog.showToast('所有数据上传完成');
      } else {
        // 部分数据上传失败，保存失败的数据
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String failedDataString = json.encode(failedUploads);
        await prefs.setString('pending_upload_data', failedDataString);

        setState(() {
          pendingUploadData = failedUploads;
        });

        SmartDialog.showToast('部分数据上传失败，已保存失败项');
      }
    } catch (e) {
      SmartDialog.dismiss();
      logger.e('上传数据过程中发生错误: $e');
      SmartDialog.showToast('上传失败，请重试');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

// 在页面构建中添加显示待上传数据的UI组件
  Widget _buildPendingUploadSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '待上传数据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (pendingUploadData.isEmpty)
              const Center(
                child: Text('暂无待上传数据'),
              )
            else ...[
              Text('共 ${pendingUploadData.length} 项数据待上传'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: pendingUploadData.length,
                  itemBuilder: (context, index) {
                    var data = pendingUploadData[index];
                    return Card(
                      child: ListTile(
                        title: Text(data['packageName']?.toString() ?? '未知项点'),
                        subtitle: Text(
                            '照片或视频: ${data['photos'] != null ? (data['photos'] as List).length : 0}张'),
                        trailing: Text(
                          DateFormat('MM-dd HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  data['timestamp'] ??
                                      DateTime.now().millisecondsSinceEpoch)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUploading ? null : _uploadAllPendingData,
                      child: isUploading
                          ? const Text('上传中...')
                          : const Text('上传所有数据'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isUploading ? null : _clearUploadedData,
                      child: const Text('清除已上传数据'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void initState() {
    getWorkPackage();
    _loadPendingUploadData();
  }

  void getWorkPackage() async {
    Map<String, dynamic> params = {
      "trainEntryCode": widget.locoInfo?['code'],
      "userId": Global.profile.permissions?.user.userId
    };
    logger.i(params);
    var r = await ProductApi().getPersonalWorkPackage(queryParametrs: params);
    if (mounted) {
      setState(() {
        Global.packageList = (r as List<dynamic>)
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        for (var item in Global.packageList) {
          int i = 0;
          // item['taskCertainPackageList']
          for (var v in item['taskCertainPackageList']) {
            if (v['complete'] == 0) {}
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss"); // 时间格式化
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            } else {
              // 如果无法pop，尝试使用maybePop或者给出提示
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text("检修作业-作业包"),
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
            _buildPendingUploadSection(),

            // 2. 作业项列表
            ...Global.packageList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> task = entry.value;
              return _buildTaskItem(task, index);
            }).toList(),
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

  // 构建单个作业项（如车内2、车底）
  Widget _buildTaskItem(Map<String, dynamic> task, [int? index]) {
    final progress =
        task['total'] == 0 ? 0.0 : task['completeCount'] / task['total'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
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
                  Text(
                    "${index != null ? '${index + 1}. ' : ''}${task['name']} ${task['completeCount']}/${task['total']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 进度条
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            // 开工按钮
            const SizedBox(width: 12),

            // 开工按钮 - 仅在任务未完成时显示
            if (task['completeCount'] == 0 && task['wholePackage'] == true)
              ElevatedButton(
                onPressed: () async {
                  task['startTime'] = DateTime.now().toString();
                  List<Map<String, dynamic>> queryParametrs = [task];
                  ProductApi().startWork(queryParametrs);
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InspectionVertexPage(
                        locoInfo: widget.locoInfo,
                        packageInfo: task,
                        count: 0,
                        index: index,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadPendingUploadData();
                    // getWorkPackage();
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 背景色设为绿色
                  foregroundColor: Colors.white, // 文字颜色设为白色
                ),
                child: const Text('开工'),
              )
            else if (task['completeCount'] < task['total'] &&
                task['wholePackage'] == true)
              ElevatedButton(
                onPressed: () async {
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InspectionVertexPage(
                        locoInfo: widget.locoInfo,
                        packageInfo: task,
                        count: task['completeCount'],
                        index: index,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                    _loadPendingUploadData();
                    // getWorkPackage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 背景色设为绿色
                  foregroundColor: Colors.white, // 文字颜色设为白色
                ),
                child: const Text('继续作业'),
              )
            else if (task['completeCount'] < task['total'] &&
                task['wholePackage'] == false)
              ElevatedButton(
                onPressed: () async {
                  task['startTime'] = DateTime.now().toString();

                  List<Map<String, dynamic>> queryParametrs = [task];
                  ProductApi().startWork(queryParametrs);

                  List<Map<String, dynamic>> taskList =
                      task['taskCertainPackageList'] != null
                          ? (task['taskCertainPackageList'] as List<dynamic>)
                              .map((item) => item is Map<String, dynamic>
                                  ? item
                                  : Map<String, dynamic>.from(item as Map))
                              .toList()
                          : [];
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackagePartInfo(
                        locoInfo: widget.locoInfo,
                        taskInstructContentList: taskList,
                      ),
                    ),
                  );
                  if (result == true) {
                    getWorkPackage();
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 背景色设为绿色
                  foregroundColor: Colors.white, // 文字颜色设为白色
                ),
                child: const Text('分包'),
              )
            else if (task['completeCount'] == task['total'])
              //展示已完成按钮
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已完成',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class InspectionVertexPage extends StatefulWidget {
  Map<String, dynamic>? packageInfo = {};
  Map<String, dynamic>? locoInfo = {};
  //index代表第几个作业包
  int? index;
  //count代表完成的第几个
  int count;

  InspectionVertexPage(
      {super.key,
      required this.packageInfo,
      required this.locoInfo,
      required this.index,
      required this.count});

  @override
  State<InspectionVertexPage> createState() => _InspectionVertexPageState();
}

class _InspectionVertexPageState extends State<InspectionVertexPage> {
  // 模拟已采集的照片（可扩展为文件路径列表）
  var logger = AppLogger.logger;

  final List<String> _photos = ["photo_1"]; // 示例：存储照片标识
  //展示照片文件
  final List<XFile> _files = [];
  int _currentIndex = 0;

  Map<String, dynamic>? currentPackage;

  //作业项点内容
  List<Map<String, dynamic>> packagePoints = [];

  Map<String, dynamic> currentPackagePoint = {};

  List<Map<String, dynamic>> taskContentItemList = [];

  List<Map<String, dynamic>> taskInstructContentList = [];

// 新增的变量和方法
  List<Map<String, dynamic>> pendingUploadData = [];

  @override
  void initState() {
    if (widget.packageInfo?["taskCertainPackageList"] is List) {
      packagePoints = (widget.packageInfo?["taskCertainPackageList"] as List)
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map))
          .toList();
    }

    _currentIndex = widget.count;

    if (packagePoints.isNotEmpty) {
      if (_currentIndex < packagePoints.length) {
        currentPackagePoint = packagePoints[_currentIndex];
      }
    }

    // 重新构建taskContentItemList，确保它始终基于当前项点的内容
    taskContentItemList = [];

    if (currentPackagePoint['taskInstructContentList'] != null &&
        currentPackagePoint['taskInstructContentList'] is List) {
      taskInstructContentList =
          (currentPackagePoint['taskInstructContentList'] as List)
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();
    }
    for (Map<String, dynamic> item in taskInstructContentList) {
      if (item['taskContentItemList'] != null &&
          item['taskContentItemList'] is List) {
        taskContentItemList.addAll((item['taskContentItemList'] as List)
            .where((item) => item is Map<String, dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList());
      }
    }
    logger.i(packagePoints);
    _loadPendingUploadData();
  }

  // 从本地存储加载待上传数据
  Future<void> _loadPendingUploadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? pendingDataString = prefs.getString('pending_upload_data');
      if (pendingDataString != null) {
        List<dynamic> pendingDataList = json.decode(pendingDataString);
        setState(() {
          pendingUploadData = pendingDataList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      logger.e('加载待上传数据失败: $e');
    }
  }

// 保存待上传数据到本地
  Future<void> _savePendingUploadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String pendingDataString = json.encode(pendingUploadData);
      await prefs.setString('pending_upload_data', pendingDataString);
    } catch (e) {
      logger.e('保存待上传数据失败: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    int number = packagePoints.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text("检修作业-项点"),
        backgroundColor: Colors.white,
        actions: [

        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机车基本信息
            _buildTrainInfo(),
            const SizedBox(height: 16),

            // 2. 整备进度条
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / number,
                    color: Colors.green,
                    backgroundColor: Colors.grey[300],
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_currentIndex + 1}/$number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. 作业区域标题（车外 + 第二工位）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      currentPackagePoint['name']?.toString() ?? '未知项点',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _gotoSecondStation(taskInstructContentList),
                  child: const Text(
                    "作业内容",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 8),

            // // 4. 作业项：3右轴箱组装检查（红色强调）
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     // 红色竖线标记
            //     Container(
            //       width: 4,
            //       height: 24,
            //       color: Colors.red,
            //     ),
            //     const SizedBox(width: 8),
            //     const Text(
            //       "$",
            //       style: TextStyle(
            //         color: Colors.red,
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 16),

            // 5. 照片采集区（必须采集 + 拍照/删除功能）
            Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.grey[300],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "必须采集",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _pickMedia, // 拍照逻辑（可扩展）
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 照片列表（模拟展示）

                  if (_files.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _files.map((media) {
                        bool isVideo = _videos.contains(media);

                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: isVideo
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // 视频缩略图或默认背景
                                          Container(
                                            color: Colors.black12,
                                            child: const Icon(
                                              Icons.video_library,
                                              size: 30,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          // 播放图标
                                          const Icon(
                                            Icons.play_circle_fill,
                                            size: 30,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      )
                                    : Image.file(
                                        File(media.path),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            // 删除按钮
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () => _deleteMedia(media),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                            // 视频标识
                            if (isVideo)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Text(
                                    '视频',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 展示taskContentItemList
            taskContentItemList.isEmpty
                ? const Center(
                    child: Text(''),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taskContentItemList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '数据名称:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['name'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '最小值可等于:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitMin'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '最大值可等于:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitMax'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '单位'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitUnit'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        subtitle: TextField(
                          decoration: const InputDecoration(
                            hintText: '请输入实际数值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // 在这里处理输入值的变化
                            // 你可以将值保存到 taskContentItemList[index] 的某个字段中
                            taskContentItemList[index]['realValue'] = value;
                          },
                        ),
                      );
                    }),
            const SizedBox(height: 20),
            // 6. 导航按钮区域
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    children: [
                      // 下一项/完成按钮
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            // 替换原有的 onPressed 方法中的代码
                            onPressed: _files.isEmpty
                                ? null
                                : () async {
                                    // ... existing code ...
                                    int i = widget.index ?? 0;
                                    Global.packageList[i]['completeCount'] =
                                        _currentIndex + 1;
                                    // 将数据保存到本地待上传列表而不是立即上传
                                    await _saveDataLocally();

                                    // 将图片清空
                                    _files.clear();
                                    _photos.clear();
                                    _videos.clear();
                                    if (packagePoints != null &&
                                        _currentIndex <
                                            packagePoints!.length - 1) {
                                      // 如果还有下一项，则更新索引以显示下一项
                                      setState(() {
                                        _currentIndex++;
                                        // 更新当前项点
                                        if (_currentIndex < packagePoints.length) {
                                          currentPackagePoint = packagePoints[_currentIndex];
                                        }
                                        
                                        // 重新构建taskContentItemList，确保它始终基于当前项点的内容
                                        taskContentItemList = [];
                                        taskInstructContentList = [];

                                        if (currentPackagePoint['taskInstructContentList'] != null &&
                                            currentPackagePoint['taskInstructContentList'] is List) {
                                          taskInstructContentList =
                                              (currentPackagePoint['taskInstructContentList'] as List)
                                                  .where((item) => item is Map<String, dynamic>)
                                                  .map((item) => item as Map<String, dynamic>)
                                                  .toList();
                                        }

                                        for (Map<String, dynamic> item in taskInstructContentList) {
                                          if (item['taskContentItemList'] != null &&
                                              item['taskContentItemList'] is List) {
                                            taskContentItemList.addAll((item['taskContentItemList'] as List)
                                                .where((item) => item is Map<String, dynamic>)
                                                .map((item) => item as Map<String, dynamic>)
                                                .toList());
                                          }
                                        }
                                      });
                                    } else {
                                      debugPrint("已完成所有项");
                                      Navigator.pop(context, true);
                                    }

                                  }, // 当没有图片时禁用按钮
                            child: _currentIndex < packagePoints.length - 1
                                ? const Text("进入下一项")
                                : const Text("完成"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 在状态类中添加以下代码

// 添加视频相关变量
  final List<XFile> _videos = []; // 存储视频文件

// 修改_takePhoto方法，重命名为_pickMedia以支持图片和视频选择
  void _pickMedia() async {
    // 显示选择对话框
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text('录像'),
                onTap: () {
                  Navigator.pop(context);
                  _recordVideo();
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.photo_library),
              //   title: const Text('从相册选择'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _pickFromGallery();
              //   },
              // ),
              const Divider(),
              ListTile(
                title: const Text('取消'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

// 拍照方法
  void _takePhoto() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _photos.add(photo.path);
        _files.add(photo);
      });
    }
  }

// 录像方法
  void _recordVideo() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1), // 限制录像时长为1分钟
    );

    if (video != null) {
      setState(() {
        _videos.add(video);
        _files.add(video);
      });
    }
  }

// 从相册选择图片或视频
  void _pickFromGallery() async {
    final ImagePicker _picker = ImagePicker();

    // 允许同时选择图片和视频
    final List<XFile>? media = await _picker.pickMultipleMedia();

    if (media != null && media.isNotEmpty) {
      setState(() {
        for (var file in media) {
          _files.add(file);
          // 根据文件扩展名判断是图片还是视频
// 添加导入语句以使用 path.extension
          String extension = path.extension(file.path);
          if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.mkv']
              .contains(extension)) {
            _videos.add(file);
          } else {
            _photos.add(file.path);
          }
        }
      });
    }
  }

// 修改删除方法以处理视频
  void _deleteMedia(XFile media) {
    setState(() {
      _files.remove(media);
      _photos.remove(media.path);
      _videos.remove(media);
    });
  }

// 修改保存到本地的方法以处理视频
  Future<void> _saveDataLocally() async {
    try {
      // 创建待上传数据项
      Map<String, dynamic> uploadItem = {
        'packageCode': currentPackagePoint['code'],
        'packageName': currentPackagePoint['name'],
        'completeTime':
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'photos': _photos, // 图片路径列表
        'videos': _videos.map((video) => video.path).toList(), // 视频路径列表
        'allMedia': _files
            .map((file) => {
                  'path': file.path,
                  'type': _videos.contains(file) ? 'video' : 'image' // 标记文件类型
                })
            .toList(),
        'taskContentItems': taskContentItemList,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 添加到待上传列表
      setState(() {
        pendingUploadData.add(uploadItem);
      });

      // 保存到本地存储
      await _savePendingUploadData();

      logger.i('数据已保存到本地待上传列表');
      SmartDialog.showToast('数据已保存');
    } catch (e) {
      logger.e('保存数据到本地失败: $e');
      SmartDialog.showToast('保存失败');
    }
  }

  // ---------------------- 交互逻辑（可扩展） ----------------------
  void _reportJT6() {
    // 报JT6的业务逻辑（如提交数据、跳转页面）
    debugPrint("报JT6功能触发");
  }

// ... existing code ...
  _gotoSecondStation(List<Map<String, dynamic>> taskInstructContentList) {
    logger.i(taskInstructContentList);

    // 构建显示内容
    StringBuffer contentBuffer = StringBuffer();
    for (var i = 0; i < taskInstructContentList.length; i++) {
      final item = taskInstructContentList[i];
      final name = item['name'] ?? '无名称';
      final workContent = item['workContent'] ?? '无工作内容';

      contentBuffer.writeln('名称: $name');
      contentBuffer.writeln('工作内容: $workContent');
      if (i < taskInstructContentList.length - 1) {
        contentBuffer.writeln('-------------------');
      }
    }

    // 如果列表为空，显示提示信息
    if (taskInstructContentList.isEmpty) {
      contentBuffer.writeln('暂无作业内容');
    }

    // 使用WidgetsBinding.instance.addPostFrameCallback延迟显示弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('作业内容'),
            content: SingleChildScrollView(
              child: Text(contentBuffer.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    });
  }

  // void _takePhoto() async {
  //   // 调用相机采集照片（可结合image_picker库实现）
  //   debugPrint("拍照功能触发");

  //   final ImagePicker _picker = ImagePicker();
  //   final XFile? photo = await _picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 80,
  //   );

  //   if (photo != null) {
  //     setState(() {
  //       _photos.add(photo.path);
  //       _files.add(photo);
  //     });
  //   }
  // }

  void _deletePhoto(XFile photo) {
    // 删除照片逻辑
    debugPrint("删除照片：$photo");
    setState(() {
      _files.remove(photo);
    });
  }

  void _gotoNextItem() {
    // 检查是否上传了必须采集的图片
    if (_files.isEmpty) {
      // 如果没有图片，显示提示信息并返回
      SmartDialog.showToast('请上传"必须采集"的照片');
      return;
    }
    // 进入下一项的业务逻辑（如校验照片、跳转步骤）
    upLoadFileList();
    saveContentItem();
    completePackage();
    // 将图片清空
    _files.clear();
    if (packagePoints != null && _currentIndex < packagePoints!.length - 1) {
      // 如果还有下一项，则更新索引以显示下一项
      setState(() {
        _currentIndex++;
      });
    } else {
      debugPrint("已完成所有项");
      Navigator.pop(context, true);
    }
  }

  Future<void> upLoadFileList() async {
    try {
      List<File> files = _files.map((xFile) => File(xFile.path)).toList();
      var r = await ProductApi().uploadCertainPackageImg(queryParametrs: {
        'certainPackageCodeList': currentPackagePoint['code'],
      }, imagedatas: files);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> completePackage() async {
    try {
      List<Map<String, dynamic>> queryParameters = [];
      Map<String, dynamic> taskCertainPackageList = {
        'code': currentPackagePoint['code'],
        'completeTime':
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      };
      queryParameters.add(taskCertainPackageList);
      var r = await ProductApi().finishCertainPackage(queryParameters);
      logger.i(r);
    } catch (e) {
      logger.e(e);
    }
  }

  //保存作业项数据
  Future<void> saveContentItem() async {
    try {
      var r =
          await ProductApi().saveOrUpdateTaskContentItem(taskContentItemList);
      logger.i(r);
    } catch (e) {
      logger.e(e);
    }
  }

  // ---------------------- 辅助方法：机车信息展示 ----------------------
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
}
