import '../../index.dart';
import 'package:jcjx_phone/models/progress.dart';

/// 作业进度展示页面
class WorkProgressPage extends StatefulWidget {
  final Map<String, dynamic>? trainInfo;
  const WorkProgressPage({super.key, this.trainInfo});

  @override
  State<WorkProgressPage> createState() => _WorkProgressPageState();
}

class _WorkProgressPageState extends State<WorkProgressPage> {
  var logger = AppLogger.logger;

  // 部门进度数据
  List<DeptProgress> deptProgressList = [];

  // 是否正在加载部门进度
  bool _isLoadingDeptProgress = false;

  // 用于追踪部门进度展开状态
  Map<int, bool> _deptExpansionStates = {};


  @override
  void initState() {
    super.initState();
  
    getWorkProgress();
  }

  void getWorkProgress() async {
    try {
      setState(() {
        _isLoadingDeptProgress = true;
      });
      logger.i(widget.trainInfo.toString());
      Map<String, dynamic> queryParametrs = {};
      queryParametrs['deptIdList'] = [230,231,232,233,234,235,236,237];
      queryParametrs['repairProcCode'] = widget.trainInfo?['repairProcCode'];
      queryParametrs['trainEntryCode'] = widget.trainInfo?['code'];
      queryParametrs['trainNum'] = widget.trainInfo?['trainNum'];
      queryParametrs['typeCode'] = widget.trainInfo?['typeCode'];
      queryParametrs['workShop'] = true;
      var r = await ProductApi().getWorkProgress(queryParametrs: queryParametrs);
      
      // 解析返回的数据
      if (r != null && r is List) {
        List<DeptProgress> deptList = [];
        for (var item in r) {
          if (item is Map<String, dynamic>) {
            try {
              deptList.add(DeptProgress.fromJson(item));
            } catch (e) {
              logger.e('解析部门进度数据失败: $e');
            }
          }
        }
        if (mounted) {
          setState(() {
            deptProgressList = deptList;
            _isLoadingDeptProgress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDeptProgress = false;
          });
        }
      }
    } catch (e) {
      logger.e('获取作业进度数据失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingDeptProgress = false;
        });
      }
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    getWorkProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作业进度'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
    );
  }

  // 构建内容
  Widget _buildContent() {
    if (_isLoadingDeptProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deptProgressList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无部门进度数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Text(
            '部门进度',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ...deptProgressList.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDeptProgressCard(entry.value, entry.key),
          );
        }).toList(),
      ],
    );
  }


  // 构建部门进度卡片
  Widget _buildDeptProgressCard(DeptProgress dept, int index) {
    bool isExpanded = _deptExpansionStates[index] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 部门标题栏
          InkWell(
            onTap: () {
              setState(() {
                _deptExpansionStates[index] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.deptName ?? '未知部门',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dept.repairMainNodeProgressList?.length ?? 0} 个主节点',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // 展开的主节点列表
          if (isExpanded && dept.repairMainNodeProgressList != null)
            ...dept.repairMainNodeProgressList!.map((node) => _buildMainNodeItem(node)).toList(),
        ],
      ),
    );
  }

  // 构建主节点项
  Widget _buildMainNodeItem(RepairMainNodeProgress node) {
    // 自检进度
    int selfComplete = node.completeSelfInspectionCount ?? 0;
    int selfTotal = node.totalSelfInspectionCount ?? 0;
    double selfProgress = selfTotal > 0 ? selfComplete / selfTotal : 0.0;

    // 互检进度
    int mutualComplete = node.completeMutualInspectionCount ?? 0;
    int mutualTotal = node.totalMutualInspectionCount ?? 0;
    double mutualProgress = mutualTotal > 0 ? mutualComplete / mutualTotal : 0.0;

    // 机统28进度
    int jt28Complete = node.completeJt28Count ?? 0;
    int jt28Total = node.totalJt28Count ?? 0;
    double jt28Progress = jt28Total > 0 ? jt28Complete / jt28Total : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主节点名称
          Text(
            node.repairMainNodeName ?? '未知主节点',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 自检进度
          if (selfTotal > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    const Text(
                      '自检',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$selfComplete/$selfTotal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: selfProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  selfProgress == 1.0 ? Colors.green : Colors.blue,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 互检进度
          if (mutualTotal > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    const Text(
                      '互检',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$mutualComplete/$mutualTotal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mutualProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  mutualProgress == 1.0 ? Colors.green : Colors.orange,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 机统28进度
          if (jt28Total > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_outlined, size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 4),
                    const Text(
                      '机统28',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$jt28Complete/$jt28Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: jt28Progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  jt28Progress == 1.0 ? Colors.green : Colors.purple,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

}

