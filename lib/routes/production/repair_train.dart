import 'package:intl/intl.dart';
import '../../index.dart';

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
    getRepairingTrainInfo('C4');
    getRepairingTrainInfo('C5');
    getRepairingTrainInfo('临修');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildLocomotiveList(repairMainNodeInfo), // 使用实际的机车数据而不是空数组
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
                    setState(() {
                      _currentTab = 0;
                      repairTrainInfo = [];
                    });
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Center(
                        child: Text(
                          "C4",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _currentTab == 0 ? Colors.black : Colors.grey,
                            fontWeight: _currentTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // 红点提示（动态显示）
                      if (count1 > 0)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 16),
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
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 标签：C5

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab = 1;
                      repairTrainInfo = [];
                    });
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Center(
                        child: Text(
                          "C5",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _currentTab == 1 ? Colors.black : Colors.grey,
                            fontWeight: _currentTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // 红点提示（动态显示）
                      if (count2 > 0)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 16),
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
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab = 2;
                      repairTrainInfo = [];
                    });
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Center(
                        child: Text(
                          "临修",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _currentTab == 2 ? Colors.black : Colors.grey,
                            fontWeight: _currentTab == 2
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // 红点提示（动态显示）
                      if (count3 > 0)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 16),
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
                            ),
                          ),
                        ),
                    ],
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

  /// 构建工序节点标签列表

  Widget _buildProcTagList() {
    List<Map<String, dynamic>> repairMainNodePage = [];
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
                builder: (context) => PreparationDetailPage(locoInfo: repairTrainInfo[index]),
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

class PreparationDetailPage extends StatelessWidget {

  final Map<String, dynamic>? locoInfo;
  const PreparationDetailPage({Key? key, this.locoInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('检修作业-明细'),
     
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
              '任务处理项',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: const [
                TaskCard(
                  title: '待整备',
                  subtitle: '当前机车下未完成项点总数',
                  count: '0/4',
                ),
                TaskCard(
                  title: '待派工',
                  subtitle: '当前机车下需处理的活件总数',
                  count: '1',
                ),
                TaskCard(
                  title: '待销活',
                  subtitle: '当前机车下本人需要销活的活件总数',
                  count: '1',
                ),
                TaskCard(
                  title: '待专互检',
                  subtitle: '当前机车下本人需要专互检的活件总数',
                  count: '1',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ... existing code ...
  Widget _buildTrainInfo() {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${locoInfo?['typeName'] ?? ''} ${locoInfo?['trainNum'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              locoInfo != null && locoInfo!['arrivePlatformTime'] != null
                  ? '入段:${timeFormat.format(DateTime.parse(locoInfo!['arrivePlatformTime']))}'
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
        _InfoItem(label: '停留地点', value: locoInfo?['stopPlace'] != "null-null" 
            ? (locoInfo?['stopPlace'] ?? '无') 
            : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转入时间',
            value: locoInfo != null && locoInfo!['mainNodeChangeTime'] != null
                ? timeFormat.format(DateTime.parse(locoInfo!['mainNodeChangeTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转出时间',
            value: locoInfo != null && locoInfo!['theoreticEndTime'] != null
                ? timeFormat.format(DateTime.parse(locoInfo!['theoreticEndTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(label: '调令查询', value: locoInfo?['dispatchOrder'] ?? '无'),

      ],
    );
  }


  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('查看机车详情'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('报机统28'),
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

  const TaskCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
