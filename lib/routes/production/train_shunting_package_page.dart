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
    if (!_canSeeShunting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SmartDialog.showToast('无权限查看');
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return;
    }
    _loadData();
  }

  bool get _canSeeShunting {
    final deptName =
        Global.profile.permissions?.user.dept?.deptName?.toString() ?? '';
    final parentDeptName = Global.parentDeptName?.toString() ?? '';
    final roleKeys =
        (Global.profile.permissions?.roles ?? const <String>[])
            .map((e) => e.toString())
            .toList();
    final roleObjs =
        (Global.profile.permissions?.user.roles ?? const <dynamic>[])
            .map((e) => e)
            .toList();

    if (deptName.contains('接车组') || parentDeptName.contains('接车组')) {
      return true;
    }
    if (roleKeys.any((r) => r.contains('jieche') || r.contains('接车'))) {
      return true;
    }
    if (roleObjs.any((r) {
      final rn = (r?.roleName ?? r?['roleName'] ?? '').toString();
      final rk = (r?.roleKey ?? r?['roleKey'] ?? '').toString();
      return rn.contains('接车组') ||
          rk.contains('jieche') ||
          rk.contains('接车');
    })) {
      return true;
    }
    return false;
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

  Future<void> _receive(String? code) async {
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('代码为空');
      return;
    }
    final idx = _packages.indexWhere(
        (e) => (e['code']?.toString() ?? '') == (code.toString()));
    if (idx != -1) {
      final st = _packages[idx]['status'];
      final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
      if (stInt == 1) {
        SmartDialog.showToast('已领取，无需重复');
        return;
      }
    }
    try {
      SmartDialog.showLoading();
      final r = await ProductApi().receiveTrainShuntingPackage(code: code);
      SmartDialog.dismiss();
      if (r != null) {
        SmartDialog.showToast('领取成功');
        await _loadData();
      } else {
        SmartDialog.showToast('领取失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('领取失败');
    }
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
                              final code = (pkg['code'] ?? '').toString();
                              final st = pkg['status'];
                              final stInt =
                                  st is int ? st : int.tryParse(st?.toString() ?? '');
                              return Card(
                                child: ListTile(
                                  title: Text(name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: (stInt == 1)
                                            ? null
                                            : () => _receive(code),
                                        child: Text(stInt == 1 ? '已领取' : '领取'),
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                    ],
                                  ),
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

class TrainShuntingPlanListPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> planList;

  const TrainShuntingPlanListPage({
    super.key,
    required this.title,
    required this.planList,
  });

  @override
  State<TrainShuntingPlanListPage> createState() =>
      _TrainShuntingPlanListPageState();
}

class _TrainShuntingPlanListPageState extends State<TrainShuntingPlanListPage> {
  late List<Map<String, dynamic>> _planList;
  @override
  void initState() {
    super.initState();
    _planList = widget.planList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

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

  void _start(int index) {
    SmartDialog.showToast('开工成功');
  }

  void _complete(int index) {
    SmartDialog.showToast('完成成功');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _planList.isEmpty
          ? const Center(child: Text('暂无计划'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _planList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = _planList[index];
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _start(index),
                                child: const Text('开工'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _complete(index),
                                child: const Text('完成'),
                              ),
                            ),
                          ],
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
