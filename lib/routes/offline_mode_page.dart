import '../index.dart';
import '../services/after_sale_local_service.dart';
import '../widgets/feature_container.dart';
import 'production/after_sale_temp_repair_register_page.dart';

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  State<OfflineModePage> createState() => _OfflineModePageState();
}

class _OfflineModePageState extends State<OfflineModePage> {
  final AfterSaleLocalService _localService = AfterSaleLocalService.instance;

  List<Map<String, dynamic>> _pendingList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await _localService.loadPendingQueue();
      setState(() {
        _pendingList = list
            .where((e) => e['status'] != 'synced')
            .toList()
            .cast<Map<String, dynamic>>();
      });
    } catch (_) {
      setState(() => _pendingList = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _pendingCount => _pendingList.length;

  Widget _buildFeatureItem(Icon icon, VoidCallback onTap, String title, {int? num}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: SizedBox(
        height: screenWidth / 4,
        child: FeatureContainer(
          icon,
          onTap,
          title,
          width: screenWidth,
          height: screenWidth,
          num: num,
        ),
      ),
    );
  }

  Widget _buildFeaturePlaceholder() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(child: SizedBox(height: screenWidth / 4));
  }

  Widget _buildFeatureRows(List<Widget> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final rowChildren = items.skip(i).take(3).toList();
      while (rowChildren.length < 3) rowChildren.add(_buildFeaturePlaceholder());
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: rowChildren,
      ));
    }
    return Column(children: rows);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'failed':
        return Colors.redAccent;
      case 'syncing':
        return Colors.blueAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'failed':
        return '同步失败';
      case 'syncing':
        return '同步中';
      default:
        return '待同步';
    }
  }

  String _formatTime(int? ms) {
    if (ms == null || ms <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d $h:$min';
  }

  Future<void> _deleteItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后该离线单据将无法恢复，确认删除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _localService.removePending(id);
      showToast('已删除');
      await _loadData();
    } catch (e) {
      showToast('删除失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('离线模式'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade100, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.lightBlue.shade200),
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 36,
                    color: Colors.lightBlue.shade400,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '离线作业中心',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '无网络或未登录时也可提报单据，登录后自动同步到服务端',
                        style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('常用功能', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem(
                  Icon(Icons.assignment_outlined, color: Colors.blue[200]),
                  () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AfterSaleTempRepairRegisterPage(),
                    ));
                    if (mounted) await _loadData();
                  },
                  '售后登记',
                ),
                _buildFeaturePlaceholder(),
                _buildFeaturePlaceholder(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('待同步单据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _pendingList.isEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('暂无待同步单据', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _pendingList.map((item) {
                          final id = item['id']?.toString() ?? '';
                          final status = item['status']?.toString();
                          final savedAt = item['savedAt'] as int?;
                          final base = item['basePayload'] is Map ? item['basePayload'] as Map : {};
                          final trainCode = (base['trainCode'] ?? base['trainNumber'] ?? '-').toString();
                          final groups = item['groups'] is List ? (item['groups'] as List).length : 0;
                          final failReason = item['failReason']?.toString();
                          final retry = item['retryCount'] as int? ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '车号 $trainCode',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _statusText(status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _statusColor(status),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '故障组数：$groups'
                                          '${retry > 0 ? '  ·  重试次数：$retry' : ''}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '保存时间：${_formatTime(savedAt)}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.black54),
                                        ),
                                        if (failReason != null && failReason.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '失败原因：$failReason',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.shade700,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteItem(id),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.black45, size: 22),
                                    tooltip: '删除',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
