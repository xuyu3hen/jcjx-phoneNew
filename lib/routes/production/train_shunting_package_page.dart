import '../../index.dart';
import 'package:intl/intl.dart';

class TrainShuntingPackagePage extends StatefulWidget {
  const TrainShuntingPackagePage({super.key});

  @override
  State<TrainShuntingPackagePage> createState() =>
      _TrainShuntingPackagePageState();
}

class _TrainShuntingPackagePageState extends State<TrainShuntingPackagePage> {
  var logger = AppLogger.logger;

  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      var r = await ProductApi().getTrainShuntingPackage();
      List<Map<String, dynamic>> rows =
          (r as List).map((e) => e as Map<String, dynamic>).toList();
      setState(() {
        _packages = rows;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('加载调车作业包失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SmartDialog.showToast('数据加载失败');
      }
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final ms = int.tryParse(s);
    if (ms != null && ms > 100000000000) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }
    if (s.length >= 19) return s;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchText.isEmpty
        ? _packages
        : _packages.where((pkg) {
            final name = (pkg['packageName'] ?? pkg['name'] ?? '').toString();
            return name.contains(_searchText);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('调车作业包'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '按名称或车号搜索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (v) {
                setState(() => _searchText = v);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: filtered.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final pkg = filtered[index];
                              final name =
                                  (pkg['packageName'] ?? pkg['name'] ?? '')
                                      .toString();
                              return Card(
                                child: ListTile(
                                  title: Text(name),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    final list = (pkg['trainShuntingPlanList']
                                                is List)
                                        ? (pkg['trainShuntingPlanList'] as List)
                                            .where((e) => e is Map)
                                            .map((e) => Map<String, dynamic>.from(
                                                e as Map))
                                            .toList()
                                        : <Map<String, dynamic>>[];
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            TrainShuntingPlanListPage(
                                          title: name,
                                          planList: list,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class TrainShuntingPlanListPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> planList;

  const TrainShuntingPlanListPage({
    super.key,
    required this.title,
    required this.planList,
  });

  String _fmt(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final n = int.tryParse(s);
    if (n != null && n > 100000000000) {
      final dt = DateTime.fromMillisecondsSinceEpoch(n);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: planList.isEmpty
          ? const Center(child: Text('暂无计划'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: planList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = planList[index];
                final ends = (p['ends'] ?? '').toString();
                final startAreaName = (p['startAreaName'] ?? '').toString();
                final startTrackNum = (p['startTrackNum'] ?? '').toString();
                final endAreaName = (p['endAreaName'] ?? '').toString();
                final endTrackNum = (p['endTrackNum'] ?? '').toString();
                final remark = (p['remark'] ?? '').toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('方向: $ends')),
                            Expanded(child: Text('车号: ${p['trainNum'] ?? ''}')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: Text('起始区域: $startAreaName')),
                            Expanded(child: Text('起始股道: $startTrackNum')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: Text('结束区域: $endAreaName')),
                            Expanded(child: Text('结束股道: $endTrackNum')),
                          ],
                        ),
                        if (remark.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('备注: $remark'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
