import '../../index.dart';
import 'package:intl/intl.dart';

class TrainRepairProgressPage extends StatefulWidget {
  const TrainRepairProgressPage({super.key});

  @override
  State<TrainRepairProgressPage> createState() => _TrainRepairProgressPageState();
}

class _TrainRepairProgressPageState extends State<TrainRepairProgressPage> {
  var logger = AppLogger.logger;
  
  // 检修进度数据
  List<Map<String, dynamic>> repairProgressList = [];
  
  // 是否正在加载
  bool _isLoading = true;
  
  // 当前选中的机车
  Map<String, dynamic>? _selectedLocomotive;
  
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
      var r = await ProductApi().getTrainEntryAndDynamics(queryParametrs);
      
      // 模拟从API获取数据
      // 实际开发中应该调用真实的API接口
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟数据
      List<Map<String, dynamic>> mockData = [
        {
          'trainNum': 'HXD3C 0016',
          'typeName': 'HXD3C',
          'repairProc': 'C4修',
          'startTime': '2023-10-01 08:00:00',
          'planEndTime': '2023-10-20 18:00:00',
          'actualProgress': 65,
          'status': '进行中',
          'mainNodes': [
            {
              'name': '拆解工序',
              'progress': 100,
              'status': '已完成',
              'completeTime': '2023-10-05 15:30:00'
            },
            {
              'name': '清洗工序',
              'progress': 100,
              'status': '已完成',
              'completeTime': '2023-10-08 10:15:00'
            },
            {
              'name': '检测工序',
              'progress': 80,
              'status': '进行中',
              'completeTime': null
            },
            {
              'name': '组装工序',
              'progress': 0,
              'status': '未开始',
              'completeTime': null
            },
            {
              'name': '试验工序',
              'progress': 0,
              'status': '未开始',
              'completeTime': null
            }
          ]
        },
        {
          'trainNum': 'SS4B 0128',
          'typeName': 'SS4B',
          'repairProc': 'C5修',
          'startTime': '2023-09-25 10:00:00',
          'planEndTime': '2023-11-10 18:00:00',
          'actualProgress': 45,
          'status': '进行中',
          'mainNodes': [
            {
              'name': '拆解工序',
              'progress': 100,
              'status': '已完成',
              'completeTime': '2023-09-30 17:45:00'
            },
            {
              'name': '清洗工序',
              'progress': 100,
              'status': '已完成',
              'completeTime': '2023-10-05 14:20:00'
            },
            {
              'name': '检测工序',
              'progress': 30,
              'status': '进行中',
              'completeTime': null
            },
            {
              'name': '修理工序',
              'progress': 0,
              'status': '未开始',
              'completeTime': null
            },
            {
              'name': '组装工序',
              'progress': 0,
              'status': '未开始',
              'completeTime': null
            }
          ]
        }
      ];
      
      if (mounted) {
        setState(() {
          repairProgressList = mockData;
          _isLoading = false;
        });
      }
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: repairProgressList.length,
              itemBuilder: (context, index) {
                final train = repairProgressList[index];
                return _buildTrainProgressCard(train);
              },
            ),
          ),
    );
  }
  
  // 构建机车进度卡片
  Widget _buildTrainProgressCard(Map<String, dynamic> train) {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm");
    final startTime = train['startTime'] != null 
        ? timeFormat.format(DateTime.parse(train['startTime'])) 
        : '未知';
        
    final planEndTime = train['planEndTime'] != null 
        ? timeFormat.format(DateTime.parse(train['planEndTime'])) 
        : '未知';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 机车基本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${train['typeName']} ${train['trainNum']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(train['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    train['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 修程信息
            Text(
              '${train['repairProc']}  进度: ${train['actualProgress']}%',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 时间信息
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '开始: $startTime',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '计划完成: $planEndTime',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 总体进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: train['actualProgress'] / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(train['actualProgress']),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 工序节点进度
            const Text(
              '工序节点进度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ..._buildProcessNodes(train['mainNodes']),
          ],
        ),
      ),
    );
  }
  
  // 构建工序节点列表
  List<Widget> _buildProcessNodes(List<dynamic> nodes) {
    List<Widget> widgets = [];
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm");
    
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 节点状态图标
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getNodeStatusColor(node['status']),
                    ),
                    child: Center(
                      child: _getNodeStatusIcon(node['status']),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 节点名称和进度
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          node['status'],
                          style: TextStyle(
                            fontSize: 14,
                            color: _getNodeStatusTextColor(node['status']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 进度百分比
                  Text(
                    '${node['progress']}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 节点进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: node['progress'] / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getNodeProgressColor(node['progress']),
                  ),
                ),
              ),
              
              // 完成时间
              if (node['completeTime'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 36),
                    Text(
                      '完成时间: ${timeFormat.format(DateTime.parse(node['completeTime']))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
      
      // 添加节点间的连接线（除了最后一个节点）
      if (i < nodes.length - 1) {
        widgets.add(
          Container(
            height: 20,
            alignment: Alignment.center,
            child: Container(
              width: 2,
              height: 20,
              color: Colors.grey[300],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  // 根据状态获取颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case '进行中':
        return Colors.blue;
      case '已完成':
        return Colors.green;
      case '未开始':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  // 根据进度获取颜色
  Color _getProgressColor(int progress) {
    if (progress < 30) return Colors.red;
    if (progress < 70) return Colors.orange;
    return Colors.green;
  }
  
  // 根据节点状态获取颜色
  Color _getNodeStatusColor(String status) {
    switch (status) {
      case '已完成':
        return Colors.green;
      case '进行中':
        return Colors.blue;
      case '未开始':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  // 根据节点状态获取图标
  Widget _getNodeStatusIcon(String status) {
    switch (status) {
      case '已完成':
        return const Icon(Icons.check, size: 16, color: Colors.white);
      case '进行中':
        return const Icon(Icons.play_arrow, size: 16, color: Colors.white);
      case '未开始':
        return Container();
      default:
        return Container();
    }
  }
  
  // 根据节点状态获取文字颜色
  Color _getNodeStatusTextColor(String status) {
    switch (status) {
      case '已完成':
        return Colors.green;
      case '进行中':
        return Colors.blue;
      case '未开始':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  // 根据节点进度获取颜色
  Color _getNodeProgressColor(int progress) {
    if (progress == 0) return Colors.grey;
    if (progress < 50) return Colors.red;
    if (progress < 100) return Colors.orange;
    return Colors.green;
  }
}