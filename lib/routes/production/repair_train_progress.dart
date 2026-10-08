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
  // Map<String, dynamic>? _selectedLocomotive;

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
  final Map<int, bool> _groupExpansionStates = {};
  // 分组结果缓存：按 RepairGroup 在 repairGroups 中的 index 缓存
  // _groupItemsByProcAndSchedule 的结果。setState rebuild 时折叠的卡片不重算、
  // 展开的卡片直接复用缓存，避免机车数量多时点开一张卡片拖慢整页
  final Map<int, List<Map<String, dynamic>>> _procGroupsCache = {};
  // 工序节点分组的展开状态：key = "${groupIndex}_${procIndex}"
  final Map<String, bool> _procExpansionStates = {};
  // 排程节点分组的展开状态：key = "${groupIndex}_${procIndex}_${schedIndex}"
  final Map<String, bool> _schedExpansionStates = {};

  // 搜索文本
  String _searchText = '';

  String _procScheduleKey(String procCode, String scheduleName) =>
      '${procCode}_$scheduleName';

  // 获取 RepairItem 的工序节点名称（优先 repairMainNodeName，再 stateDetailList 当前 state）
  String _repairMainNodeNameOf(RepairItem item) {
    final nested = (item.trainRepairScheduleReal?.repairMainNodeName ?? '')
        .toString()
        .trim();
    if (nested.isNotEmpty) return nested;
    final direct = (item.repairMainNodeName ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final stateList = item.stateDetailList ?? const <StateDetail>[];
    for (final s in stateList) {
      if (s.state == null) continue;
    }
    if (stateList.isNotEmpty) {
      StateDetail? active;
      for (final s in stateList) {
        final st = (s.state ?? '').toString().trim();
        if (st == '进行中' || st == '已开工' || st == '作业中') {
          active = s;
          break;
        }
      }
      active ??= stateList.last;
      final name = (active.repairMainNodeName ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    }
    return '未分工序';
  }

  String _repairMainNodeCodeOf(RepairItem item) {
    final nested = (item.trainRepairScheduleReal?.repairMainNodeCode ?? '')
        .toString()
        .trim();
    if (nested.isNotEmpty) return nested;
    final direct = (item.repairMainNodeCode ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final stateList = item.stateDetailList ?? const <StateDetail>[];
    if (stateList.isNotEmpty) {
      StateDetail? active;
      for (final s in stateList) {
        final st = (s.state ?? '').toString().trim();
        if (st == '进行中' || st == '已开工' || st == '作业中') {
          active = s;
          break;
        }
      }
      active ??= stateList.last;
      return (active.repairMainNodeCode ?? '').toString().trim();
    }
    return '';
  }

  String _scheduleNodeNameOf(RepairItem item) {
    final sName = (item.trainRepairScheduleReal?.scheduleNodeName ??
            item.scheduleNodeName ??
            item.currentScheduleNodeName ??
            '')
        .toString()
        .trim();
    return sName.isEmpty ? '未排程' : sName;
  }

  int _scheduleSortOf(RepairItem item) {
    final nested = item.trainRepairScheduleReal?.sort;
    if (nested != null) return nested;
    final s1 = item.scheduleNodeSort;
    if (s1 != null) return s1;
    final s2 = item.scheduleSort;
    if (s2 != null) return s2;
    return 9999;
  }

  /// 将一组 RepairItem 按「工序节点 → 排程节点」两层分组
  List<Map<String, dynamic>> _groupItemsByProcAndSchedule(
      List<RepairItem> items) {
    // 1. 先按工序节点分组
    final Map<String, Map<String, dynamic>> procMap = {};
    for (final it in items) {
      final procName = _repairMainNodeNameOf(it);
      final procCode = _repairMainNodeCodeOf(it);
      final key = procCode.isEmpty ? procName : procCode;
      if (!procMap.containsKey(key)) {
        procMap[key] = {
          'repairMainNodeName': procName,
          'repairMainNodeCode': procCode,
          'count': 0,
          '_items': <RepairItem>[],
        };
      }
      procMap[key]!['count'] = (procMap[key]!['count'] as int) + 1;
      (procMap[key]!['_items'] as List<RepairItem>).add(it);
    }
    // 2. 每个工序节点下按排程节点分组
    final procList = procMap.values.toList();
    for (final proc in procList) {
      final List<RepairItem> pItems = proc['_items'] as List<RepairItem>;
      final Map<String, Map<String, dynamic>> sMap = {};
      for (final it in pItems) {
        final sName = _scheduleNodeNameOf(it);
        final sCode = (it.scheduleNodeCode ?? '').toString().trim();
        final sSort = _scheduleSortOf(it);
        if (!sMap.containsKey(sName)) {
          sMap[sName] = {
            'scheduleNodeName': sName,
            'scheduleNodeCode': sCode,
            'sort': sSort,
            'count': 0,
            '_items': <RepairItem>[],
          };
        }
        sMap[sName]!['count'] = (sMap[sName]!['count'] as int) + 1;
        final bestSort = _scheduleSortOf(it);
        final curSort = sMap[sName]!['sort'] as int;
        if (bestSort < curSort) sMap[sName]!['sort'] = bestSort;
        (sMap[sName]!['_items'] as List<RepairItem>).add(it);
      }
      final sList = sMap.values.toList();
      sList.sort((a, b) {
        final sa = a['sort'] as int;
        final sb = b['sort'] as int;
        if (sa != sb) return sa.compareTo(sb);
        return (a['scheduleNodeName'] as String)
            .compareTo(b['scheduleNodeName'] as String);
      });
      proc['_scheduleGroups'] = sList;
    }
    return procList;
  }

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
              _applySearch(controller.text.trim());
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _applySearch('');
                Navigator.of(context).pop();
              },
              child: const Text('清空'),
            ),
            TextButton(
              onPressed: () {
                _applySearch(controller.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('查询'),
            ),
          ],
        );
      },
    );
  }

  /// 应用搜索关键字：清空旧的缓存/展开状态（避免 index 错位），
  /// 过滤数据后逐级展开到匹配机车所在的最底层
  /// （修程卡片 → 工序节点 → 排程节点 → 机车卡片）
  void _applySearch(String kw) {
    // 清空旧分组缓存和展开状态：搜索后 filteredGroups 顺序会变，
    // 旧的 index 缓存会错位导致"下拉内容没改变"
    _procGroupsCache.clear();
    _procExpansionStates.clear();
    _schedExpansionStates.clear();
    _groupExpansionStates.clear();
    setState(() {
      _searchText = kw;
    });
    if (kw.isEmpty) return;

    // 用与 _buildRepairList 完全一致的方式构造过滤后的 group
    final filtered = <RepairGroup>[];
    for (final g in repairGroups) {
      final hitChildren = (g.children ?? const <RepairItem>[])
          .where((it) => _itemMatchesKeyword(it, kw))
          .toList();
      if (hitChildren.isEmpty) continue;
      filtered.add(RepairGroup(
        children: hitChildren,
        repairProcCode: g.repairProcCode,
        repairProcName: g.repairProcName,
        sort: g.sort,
      ));
    }
    if (filtered.isEmpty) {
      SmartDialog.showToast('车号查询为空');
      return;
    }

    // 逐级展开：只展开真正包含匹配机车的工序/排程节点
    for (int gi = 0; gi < filtered.length; gi++) {
      final children = filtered[gi].children ?? const <RepairItem>[];
      _groupExpansionStates[gi] = true;
      // 算好分组写入缓存，build 时复用不重算
      final procGroups = _groupItemsByProcAndSchedule(children);
      _procGroupsCache[gi] = procGroups;
      for (int pi = 0; pi < procGroups.length; pi++) {
        final pItems = procGroups[pi]['_items'] as List<RepairItem>;
        if (!pItems.any((it) => _itemMatchesKeyword(it, kw))) continue;
        _procExpansionStates['${gi}_$pi'] = true;
        final schedGroups =
            procGroups[pi]['_scheduleGroups'] as List<Map<String, dynamic>>;
        for (int si = 0; si < schedGroups.length; si++) {
          final sItems = schedGroups[si]['_items'] as List<RepairItem>;
          if (sItems.any((it) => _itemMatchesKeyword(it, kw))) {
            _schedExpansionStates['${gi}_${pi}_$si'] = true;
          }
        }
      }
    }
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
    20: 'jt28提报单',
    22: '机车入段通知书',
    25: '机车检修过程故障处置单',
  };

  // 首次数据加载后是否需要按 initialSearchText 逐级展开
  bool _initialExpandDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchText != null) {
      _searchText = widget.initialSearchText!;
    }
    _loadRepairProgressData();
  }

  /// 数据加载完成后，若有初始搜索文本（从机车详情页"检修调令"跳入），
  /// 执行一次逐级展开，定位到对应车号+端位的机车
  void _applyInitialExpandIfNeeded() {
    if (_initialExpandDone) return;
    if (_searchText.isEmpty) {
      _initialExpandDone = true;
      return;
    }
    _initialExpandDone = true;
    _applySearch(_searchText);
  }

  // 加载检修进度数据
  Future<void> _loadRepairProgressData({bool forceRefresh = false}) async {
    try {
      // 只要缓存里有数据就直接用，退出再进入不重新查询；
      // 需要最新数据时由用户下拉刷新（forceRefresh=true）主动触发
      final cacheValid = !forceRefresh &&
          Global.isRepairProgressDataLoaded &&
          Global.cachedRepairProgressData.isNotEmpty;

      if (!mounted) return;
      if (cacheValid) {
        setState(() {
          repairGroups = Global.cachedRepairProgressData;
          _procGroupsCache.clear();
          _procExpansionStates.clear();
          _schedExpansionStates.clear();
          _isLoading = false;
        });
        // 从机车详情"检修调令"跳入：数据就绪后逐级展开到对应车号
        _applyInitialExpandIfNeeded();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // 优先复用登录后正在进行的预加载 Future，避免页面进入时重复请求
      // forceRefresh 时不复用，强制重新拉取最新数据
      List<RepairGroup> r;
      final preloadFuture =
          forceRefresh ? null : Global.awaitRepairProgressPreload();
      if (preloadFuture != null) {
        // 预加载正在进行中，await 同一个 Future，登录时已发的请求结果直接复用
        r = await preloadFuture;
        // 预加载失败（isRepairProgressDataLoaded 仍为 false）时回退到主动请求
        if (!Global.isRepairProgressDataLoaded) {
          Map<String, dynamic> queryParametrs = {};
          r = await ProductApi().getTrainEntryAndDynamics(queryParametrs);
        }
      } else {
        // 没有正在进行的预加载，主动请求
        Map<String, dynamic> queryParametrs = {};
        r = await ProductApi().getTrainEntryAndDynamics(queryParametrs);
      }

      // 更新缓存
      Global.cachedRepairProgressData = r;
      Global.isRepairProgressDataLoaded = true;
      Global.repairProgressDataLoadTime = DateTime.now();

      if (!mounted) return;
      setState(() {
        repairGroups = r;
        _procGroupsCache.clear();
        _procExpansionStates.clear();
        _schedExpansionStates.clear();
        if (r.isNotEmpty) {
          logger.i(r[0].repairProcCode);
        }
        _isLoading = false;
      });
      // 数据就绪后逐级展开到对应车号
      _applyInitialExpandIfNeeded();
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
                      children: const [
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
            ?.where((item) => _itemMatchesKeyword(item, _searchText))
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
        if (_itemMatchesKeyword(it, kw)) return true;
      }
    }
    return false;
  }

  /// 判断某台机车是否匹配搜索关键字（同时支持车号与端位）。
  /// - 搜 "5068"：车号匹配，5068A/5068B 都显示
  /// - 搜 "5068A"：按车号+端位匹配，只显示 5068A，不再串出 5068B
  bool _itemMatchesKeyword(RepairItem item, String keyword) {
    final kw = keyword.trim().toUpperCase();
    if (kw.isEmpty) return true;
    final tn = (item.trainNum ?? '').toString().trim();
    if (tn.isEmpty) return false;
    final suffix = formatEndsSuffix(item.ends);
    final fullLabel = suffix.isEmpty ? tn : '$tn$suffix';
    // 完整标签（车号+端位）匹配：处理 5068A 这种带端位的搜索
    if (fullLabel.toUpperCase().contains(kw)) return true;
    // 纯车号匹配：搜索内容不带端位时，A/B 两端都显示
    if (tn.toUpperCase().contains(kw)) return true;
    return false;
  }

  // 构建维修组卡片

  Widget _buildRepairGroupCard(RepairGroup group, int index) {
    bool isExpanded = _groupExpansionStates[index] ?? false;
    final children = group.children ?? const <RepairItem>[];
    // 懒计算 + 缓存：折叠时不分组（不展示也用不到），展开时算一次后复用
    final procGroups = isExpanded
        ? (_procGroupsCache[index] ??= _groupItemsByProcAndSchedule(children))
        : const <Map<String, dynamic>>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 组标题
          GestureDetector(
            onTap: () {
              setState(() {
                _groupExpansionStates[index] = !isExpanded;
              });
            },
            child: Container(
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
                    '${group.repairProcName} (${children.length})',
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
          ),
          // 子项列表：按 工序节点 → 排程节点 → 机车 层级展示
          // 工序节点和排程节点都支持点击下拉展开/折叠，默认折叠，
          // 避免一次渲染全部机车卡片导致展开卡顿
          if (isExpanded)
            ...procGroups.asMap().entries.map((procEntry) {
              final procIndex = procEntry.key;
              final proc = procEntry.value;
              final procName = (proc['repairMainNodeName'] ?? '').toString();
              final procCount = proc['count'] is int ? proc['count'] as int : 0;
              final sGroups =
                  (proc['_scheduleGroups'] as List<Map<String, dynamic>>?) ??
                      [];
              final procKey = '${index}_$procIndex';
              final procExpanded = _procExpansionStates[procKey] ?? false;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 工序节点标题（可点击展开/折叠）
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _procExpansionStates[procKey] = !procExpanded;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              procExpanded
                                  ? Icons.arrow_drop_down
                                  : Icons.arrow_right,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            Icon(
                              Icons.list_alt,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                procName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (procCount != 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(
                                    minWidth: 20, minHeight: 20),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$procCount',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
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
                    ),
                    // 排程节点组（只在工序节点展开时渲染）
                    if (procExpanded)
                      ...sGroups.asMap().entries.map((schedEntry) {
                        final schedIndex = schedEntry.key;
                        final sched = schedEntry.value;
                        final sName =
                            (sched['scheduleNodeName'] ?? '').toString();
                        final sCount =
                            sched['count'] is int ? sched['count'] as int : 0;
                        final sItems =
                            (sched['_items'] as List<RepairItem>?) ?? [];
                        final schedKey = '${index}_${procIndex}_$schedIndex';
                        final schedExpanded =
                            _schedExpansionStates[schedKey] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: Colors.amber.shade400, width: 2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 排程节点标题（可点击展开/折叠）
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _schedExpansionStates[schedKey] =
                                        !schedExpanded;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        schedExpanded
                                            ? Icons.arrow_drop_down
                                            : Icons.arrow_right,
                                        size: 16,
                                        color: Colors.amber.shade800,
                                      ),
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.amber.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          sName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (sCount != 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          constraints: const BoxConstraints(
                                              minWidth: 18, minHeight: 18),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          child: Text(
                                            '$sCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // 机车卡片列表（只在排程节点展开时渲染）
                              if (schedExpanded)
                                ...sItems
                                    .map((item) => _buildRepairItem(item))
                                    .toList(),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              );
            }).toList(),
        ],
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
                const SizedBox(height: 2),
                Text(
                  '工序节点：${_repairMainNodeNameOf(item)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '排程节点：${_scheduleNodeNameOf(item)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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

      if (!mounted) return;
      setState(() {
        investigateList = rows;
        logger.i(investigateList);
      });
    } catch (e) {
      logger.e('获取调查清单失败: $e');
      if (mounted) showToast('获取数据失败');
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

      if (!mounted) return;
      setState(() {
        masSaleList = rows;
        logger.i(masSaleList);
      });
    } catch (e) {
      logger.e('获取调查清单失败: $e');
      if (mounted) showToast('获取数据失败');
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
                // 选项较多时可上下滚动，避免在小屏手持机上内容溢出，
                // 所有通知单类型都能完整展示并选择
                child: SingleChildScrollView(
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
                      const Divider(),
                      ListTile(
                        leading: Radio<int>(
                          value: 6,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value ?? -1;
                            });
                          },
                        ),
                        title: const Text('检修过程故障处置单'),
                        onTap: () {
                          setState(() {
                            selectedOption = 6;
                          });
                        },
                      ),
// ... existing code ...
                    ],
                  ),
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
                            case 6: // 检修过程故障处置单
                              // 权限以登录时的预查结果为准
                              // （getInfo 与 shuntingRole/selectAll?shuntingType=25 比对）。
                              // 预查未完成则 await 同一个请求，不重复发请求
                              if (!Global.faultHandlePermissionChecked) {
                                await Global.preloadFaultHandlePermission();
                              }
                              if (!Global.hasFaultHandlePermission) {
                                showToast('当前账号无检修过程故障处置单操作权限');
                                return;
                              }
                              await getMasSale(item);
                              if (!mounted) return;
                              final faultCandidates = masSaleList.isNotEmpty
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
                              // 故障明细通过 _loadJt28Options 里的
                              // queryRepairProcessFaultDetailsForManualDispatch
                              // 接口异步加载，masSaleList 是否为空不影响明细展示，
                              // 不应在这里提示"未查询到"，会误导用户
                              await Navigator.push(
                                rootContext,
                                MaterialPageRoute(
                                  builder: (context) => RepairProcessNoticePage(
                                    item: item,
                                    noticeCandidates: faultCandidates,
                                    noticeType: 22,
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
  // final bool _pushToCommandCenter = true;
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
    // final TextEditingController contentController = TextEditingController();
    // final TextEditingController resultController = TextEditingController();
    final masInvestigateList = investigateItem['masInvestigateListList'] ?? [];
    final shuntingNoticeList = investigateItem['shuntingNoticeList'] ?? [];
    List<Map<String, dynamic>> mappedList = [];
    List<Map<String, dynamic>> shuntingMappedList = [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .whereType<Map>()
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    if (shuntingNoticeList is List) {
      shuntingMappedList = shuntingNoticeList
          .whereType<Map>()
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
    // final TextEditingController contentController = TextEditingController(
    //     text: investigateItem['investigateContent'] as String? ?? '');
    final TextEditingController resultController = TextEditingController(
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
                  controller: resultController,
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
                  'investigateResult': resultController.text,
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
    final TextEditingController reasonController = TextEditingController();
    // final TextEditingController locationController = TextEditingController();
    // String? selectedType;
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
          'remark': reasonController.text,
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
                      title: '工序节点',
                      text: repairMainNodeSelected['name'] ?? '',
                      hintText: repairMainNodeLoading ? '加载中...' : '请选择',
                      clickCallBack: () {
                        if (repairMainNodeLoading) return;
                        if (repairMainNodeList.isEmpty) {
                          showToast('无工序节点可选择');
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: repairMainNodeList,
                            labelKey: 'name',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: '选择工序节点',
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
                      title: '排程节点',
                      text: scheduleNodeSelected['name'] ?? '',
                      hintText: scheduleNodeLoading ? '加载中...' : '请选择',
                      clickCallBack: () {
                        if (scheduleNodeLoading) return;
                        if (scheduleNodePickerList.isEmpty) {
                          showToast('无排程节点可选择');
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: scheduleNodePickerList,
                            labelKey: 'name',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: '选择排程节点',
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
                        title: '端',
                        text: directionSelected['name'] ?? '',
                        hintText: item.doubleCarriage == true ? '请选择' : '无需选择',
                        clickCallBack: () {
                          if (item.doubleCarriage != true) {
                            showToast('非重联无需选择端');
                            return;
                          }
                          if (directionList.isEmpty) {
                            showToast('无端可选择');
                          } else {
                            ZjcCascadeTreePicker.show(
                              context,
                              data: directionList,
                              labelKey: 'name',
                              valueKey: 'value',
                              childrenKey: 'children',
                              title: '选择端',
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
                      title: '起始位置',
                      text: stopLocationSelected['realLocation'],
                      hintText: '请选择',
                      clickCallBack: () {
                        if (startStopLocationList.isEmpty) {
                          showToast('无检修地点可选择');
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: startStopLocationList,
                            labelKey: 'realLocation',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: '选择检修地点',
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                logger.i(selectArr);
                                stopLocationSelected['code'] =
                                    selectItem['code'];
                                stopLocationSelected['realLocation'] =
                                    selectItem['realLocation'];
                                stopLocationSelected['areaName'] =
                                    selectItem['areaName'];
                                stopLocationSelected['trackNum'] =
                                    selectItem['trackNum'];
                              });
                            },
                          );
                        }
                      },
                    ),
                    ZjcFormSelectCell(
                      title: '终点位置',
                      text: stopLocationSelectedEnd['realLocation'],
                      hintText: '请选择',
                      clickCallBack: () {
                        if (stopLocationList.isEmpty) {
                          showToast('无检修地点可选择');
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: stopLocationList,
                            labelKey: 'realLocation',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: '选择检修地点',
                            clickCallBack: (selectItem, selectArr) {
                              setState(() {
                                logger.i(selectArr);
                                stopLocationSelectedEnd['code'] =
                                    selectItem['code'];
                                stopLocationSelectedEnd['realLocation'] =
                                    selectItem['realLocation'];
                                stopLocationSelectedEnd['areaName'] =
                                    selectItem['areaName'];
                                stopLocationSelectedEnd['trackNum'] =
                                    selectItem['trackNum'];
                              });
                            },
                          );
                        }
                      },
                    ),
                    TextFormField(
                      controller: reasonController,
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
                      showToast('请选择工序节点');
                      return;
                    }
                    final scheduleCode =
                        (scheduleNodeSelected['code'] ?? '').toString().trim();
                    if (scheduleCode.isEmpty) {
                      showToast('请选择排程节点');
                      return;
                    }
                    final endCode = (stopLocationSelectedEnd['code'] ?? '')
                        .toString()
                        .trim();
                    if (endCode.isEmpty) {
                      showToast('请选择终点位置');
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
    DateTime? planDateSelected;
    List<Map<String, dynamic>> repairMainNodeList = [];
    bool repairMainNodeRequested = false;
    bool repairMainNodeLoading = false;

    bool dynamicTypeRequested = false;
    bool dynamicTypeLoading = false;
    List<Map<String, dynamic>> globalDynamicTypeList = [];

    Future<void> loadJcType(StateSetter setState, _ShuntingFormData fd) async {
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

    Future<void> loadTrainNum(
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
            (raw is List ? raw : const <dynamic>[]).whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
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

    Future<void> loadScheduleNodes(
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
        final planStart = planDateSelected ?? DateTime.now();
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

        // var r =
        await ProductApi()
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
                      await loadScheduleNodes(setState, fd);
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
                      await loadJcType(setState, fd);
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
                        await loadTrainNum(setState, fd);
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
                            // 该表单由检修进度里选中的机车带入（车号+端位），
                            // 车号列表只保留对应的那一台，点车号时不再
                            // 看到另一端（如选 5068A 不会再看到 5068B）。
                            // "+" 新增的独立表单不经过这里，仍可选全部车号
                            fd.trainNumList = [
                              Map<String, dynamic>.from(trainMatch)
                            ];
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
                              title: '动力类型',
                              text: fd.dynamicTypeSelected['name'] ?? '',
                              hintText: dynamicTypeLoading ? '加载中...' : '请选择',
                              clickCallBack: () {
                                if (dynamicTypeLoading) return;
                                if (globalDynamicTypeList.isEmpty) {
                                  showToast('无动力类型可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: globalDynamicTypeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择动力类型',
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.dynamicTypeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                        };
                                      });
                                      loadJcType(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            // 新增: 机型
                            ZjcFormSelectCell(
                              title: '机型',
                              text: fd.jcTypeSelected['name'] ?? '',
                              hintText: fd.jcTypeLoading ? '加载中...' : '请选择',
                              clickCallBack: () {
                                if (fd.jcTypeLoading) return;
                                if (fd.jcTypeList.isEmpty) {
                                  showToast('无机型可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.jcTypeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择机型',
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        fd.jcTypeSelected = {
                                          'name': selectItem['name'],
                                          'code': selectItem['code'],
                                        };
                                      });
                                      loadTrainNum(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            // 新增: 车号
                            ZjcFormSelectCell(
                              title: '车号',
                              text: (fd.trainNumSelected['displayTrainNum'] ??
                                      fd.trainNumSelected['trainNum'] ??
                                      '')
                                  .toString(),
                              hintText: fd.trainNumLoading ? '加载中...' : '请选择',
                              clickCallBack: () {
                                if (fd.trainNumLoading) return;
                                if (fd.trainNumList.isEmpty) {
                                  showToast('无车号可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.trainNumList,
                                    labelKey: 'displayTrainNum',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择车号',
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
                              title: '工序节点',
                              text: fd.repairMainNodeSelected['name'] ?? '',
                              hintText:
                                  repairMainNodeLoading ? '加载中...' : '请选择',
                              clickCallBack: () {
                                if (repairMainNodeLoading) return;
                                if (repairMainNodeList.isEmpty) {
                                  showToast('无工序节点可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: repairMainNodeList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择工序节点',
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
                                      loadScheduleNodes(setState, fd);
                                    },
                                  );
                                }
                              },
                            ),
                            ZjcFormSelectCell(
                              title: '排程节点',
                              text: fd.scheduleNodeSelected['name'] ?? '',
                              hintText:
                                  fd.scheduleNodeLoading ? '加载中...' : '请选择',
                              clickCallBack: () {
                                if (fd.scheduleNodeLoading) return;
                                if (fd.scheduleNodePickerList.isEmpty) {
                                  showToast('无排程节点可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: fd.scheduleNodePickerList,
                                    labelKey: 'name',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择排程节点',
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
                                title: '端',
                                text: fd.directionSelected['name'] ?? '',
                                hintText: item.doubleCarriage == true
                                    ? '请选择'
                                    : '无需选择',
                                clickCallBack: () {
                                  if (item.doubleCarriage != true) {
                                    showToast('非重联无需选择端');
                                    return;
                                  }
                                  if (directionList.isEmpty) {
                                    showToast('无端可选择');
                                  } else {
                                    ZjcCascadeTreePicker.show(
                                      context,
                                      data: directionList,
                                      labelKey: 'name',
                                      valueKey: 'value',
                                      childrenKey: 'children',
                                      title: '选择端',
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
                              title: '起始位置',
                              text: fd.stopLocationSelected['realLocation'],
                              hintText: '请选择',
                              clickCallBack: () {
                                if (stopLocationList.isEmpty) {
                                  showToast('无检修地点可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: stopLocationList,
                                    labelKey: 'realLocation',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择检修地点',
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        logger.i(selectArr);
                                        fd.stopLocationSelected['code'] =
                                            selectItem['code'];
                                        fd.stopLocationSelected[
                                                'realLocation'] =
                                            selectItem['realLocation'];
                                        fd.stopLocationSelected['areaName'] =
                                            selectItem['areaName'];
                                        fd.stopLocationSelected['trackNum'] =
                                            selectItem['trackNum'];
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            ZjcFormSelectCell(
                              title: '终点位置',
                              text: fd.stopLocationSelectedEnd['realLocation'],
                              hintText: '请选择',
                              clickCallBack: () {
                                if (stopLocationList.isEmpty) {
                                  showToast('无检修地点可选择');
                                } else {
                                  ZjcCascadeTreePicker.show(
                                    context,
                                    data: stopLocationList,
                                    labelKey: 'realLocation',
                                    valueKey: 'code',
                                    childrenKey: 'children',
                                    title: '选择检修地点',
                                    clickCallBack: (selectItem, selectArr) {
                                      setState(() {
                                        logger.i(selectArr);
                                        fd.stopLocationSelectedEnd['code'] =
                                            selectItem['code'];
                                        fd.stopLocationSelectedEnd[
                                                'realLocation'] =
                                            selectItem['realLocation'];
                                        fd.stopLocationSelectedEnd['areaName'] =
                                            selectItem['areaName'];
                                        fd.stopLocationSelectedEnd['trackNum'] =
                                            selectItem['trackNum'];
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
                        showToast('作业单 ${i + 1}: 请选择动力类型');
                        return;
                      }

                      final typeCode =
                          (fd.jcTypeSelected['code'] ?? '').toString().trim();
                      if (typeCode.isEmpty) {
                        showToast('作业单 ${i + 1}: 请选择机型');
                        return;
                      }

                      final trainCode =
                          (fd.trainNumSelected['code'] ?? '').toString().trim();
                      if (trainCode.isEmpty) {
                        showToast('作业单 ${i + 1}: 请选择车号');
                        return;
                      }

                      final nodeCode = (fd.repairMainNodeSelected['code'] ?? '')
                          .toString()
                          .trim();
                      if (nodeCode.isEmpty) {
                        showToast('作业单 ${i + 1}: 请选择工序节点');
                        return;
                      }
                      final scheduleCode =
                          (fd.scheduleNodeSelected['code'] ?? '')
                              .toString()
                              .trim();
                      if (scheduleCode.isEmpty) {
                        showToast('作业单 ${i + 1}: 请选择排程节点');
                        return;
                      }
                      final endCode = (fd.stopLocationSelectedEnd['code'] ?? '')
                          .toString()
                          .trim();
                      if (endCode.isEmpty) {
                        showToast('作业单 ${i + 1}: 请选择终点位置');
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
  final int noticeType;

  /// 回填模式：传入故障处置单主表 code（shuntingCode），页面改用 selectAll
  /// 回查完整单据进行展示/填写，而不是按机统28逐条提报。
  final String? fillNoticeCode;

  /// 回填模式是否只读：true=仅查看明细（消息中心详情），false=可填写建议施修方案并发送
  final bool fillReadOnly;

  const RepairProcessNoticePage({
    super.key,
    required this.item,
    required this.noticeCandidates,
    this.noticeType = 13,
    this.fillNoticeCode,
    this.fillReadOnly = false,
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
  // Map<String, dynamic>? _selectedProcessingMethod;
  // Map<String, dynamic>? _selectedRiskLevel;
  // Map<String, dynamic>? _selectedConfig;
  late Map<String, dynamic> _selectedNotice;
  late Future<String> _stopLocationFuture;
  String _stopLocationDisplay = '';
  bool _loadingNoticeDetail = false;
  bool _loadingDept = false;
  List<Map<String, dynamic>> _repairMainNodeOptions = [];
  List<Map<String, dynamic>> _scheduleNodeOptions = [];
  bool _loadingRepairMainNode = false;
  bool _loadingScheduleNode = false;
  bool _loadingJt28 = false;
  bool _loadingProcessingMethod = false;
  bool _loadingRiskLevel = false;
  bool _loadingConfig = false;
  bool _loadingReceiveGroup = false;
  bool _submitting = false;
  final Set<int> _faultCardExpanded = <int>{};

  // ---- 回填模式（消息中心：详情/填写建议施修方案） ----
  bool get _isFillMode =>
      widget.fillNoticeCode != null && widget.fillNoticeCode!.trim().isNotEmpty;
  Map<String, dynamic> _fillHeader = <String, dynamic>{};
  bool _loadingFillNotice = false;

  /// 阶段0（总成）建议施修方案输入控制器：写入 vjtWebSearch.repairScheme
  final Map<int, TextEditingController> _fillSchemeControllers = {};

  /// 阶段1（技术科）施修方案输入控制器：写入 maintenanceNotice
  final Map<int, TextEditingController> _fillPlanControllers = {};

  /// 阶段2（安指）每行选中：责任部门/工序节点/排程节点的 code、name（UI展示与校验用）
  final Map<int, Map<String, String>> _fillStage2Sel = {};

  /// 阶段2每行选中的完整对象：key 为 'dept'/'main'/'sched'，
  /// 提交时按 Web 端结构写入 responsibleDept/repairMainNode/scheduleNode 嵌套对象
  final Map<int, Map<String, dynamic>> _fillStage2Raw = {};

  /// 阶段2排程节点选项缓存：key=工序节点code
  final Map<String, List<Map<String, dynamic>>> _schedNodeCacheByMain = {};

  /// 回填模式下是否只读：加载后若 fillStatus=0（未处理）自动切为 false
  bool _fillEditable = false;

  /// 当前填写阶段：0=填写建议施修方案（fillStatus=0），1=填写施修方案（fillStatus=1）
  int _activeFillStage = 0;

  /// 只读详情页底部动作按钮名称：fillStatus=2（安全生产指挥中心）为「派工」，其余为「填写」
  String get _fillActionButtonLabel =>
      _asText(_fillHeader['fillStatus']) == '2' ? '派工' : '填写';

  /// fillStatus=0或1时显示填写按钮
  bool _showFillButton = true;
  bool get _fillReadOnly => widget.fillReadOnly && !_fillEditable;

  @override
  void initState() {
    super.initState();
    _selectedNotice = widget.noticeCandidates.isNotEmpty
        ? Map<String, dynamic>.from(widget.noticeCandidates.first)
        : <String, dynamic>{};
    if (_isFillMode) {
      // 只回查单据本身；签收组仅在进入填写模式后才懒加载
      _loadFillNotice();
      return;
    }
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
    for (final controller in _fillSchemeControllers.values) {
      controller.dispose();
    }
    for (final controller in _fillPlanControllers.values) {
      controller.dispose();
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

  Map<String, dynamic>? _extractVjt(Map<String, dynamic>? item) {
    if (item == null) return null;
    final v = item['vjtWebSearch'];
    if (v is Map) return Map<String, dynamic>.from(v);
    final v1 = item['vjtWebSearchs'];
    if (v1 is Map) return Map<String, dynamic>.from(v1);
    final v2 = item['jtWebSearch'];
    if (v2 is Map) return Map<String, dynamic>.from(v2);
    final v3 = item['detailWebSearch'];
    if (v3 is Map) return Map<String, dynamic>.from(v3);
    return null;
  }

  String _pickFromItem(
    Map<String, dynamic>? item,
    List<String> keys,
  ) {
    final vjt = _extractVjt(item);
    if (vjt != null) {
      final direct = _pickText(vjt, keys);
      if (direct.isNotEmpty) return direct;
    }
    return _pickText(item, keys);
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
    return _pickFromItem(item, [
      'faultDescription',
      'faultInformation',
      'faultDesc',
      'faultPhenomenon',
      'jt28DisplayText',
      'faultComponentName',
      'faultPartName',
      'componentName',
    ]);
  }

  String _processingMethodLabel(Map<String, dynamic>? item) {
    return _pickFromItem(item, [
      'processMethodName',
      'requiredProcessingMethodName',
      'processMainNode',
      'dictName',
      'jtDictName',
      'processingMethodName',
      'processingMethod',
      'requiredProcessingMethod',
      'methodName',
      'processingMethodDictName',
      'techProcessingMethod',
      'processType',
      'machineSystemName',
    ]);
  }

  String _riskLevelLabel(Map<String, dynamic>? item) {
    return _pickFromItem(item, [
      'riskLevelName',
      'riskLevel',
      'name',
      'dictLabel',
      'riskCode',
      'riskLevelCode',
      'techRiskLevel',
      'riskGrade',
    ]);
  }

  String _suggestedRepairSchemeLabel(Map<String, dynamic>? item) {
    if (item == null) return '';
    return _pickFromItem(item, [
      'repairScheme',
      'suggestRepairScheme',
      'suggestScheme',
      'proposedScheme',
      'repairSchemeShort',
      'repairSchemeCode',
      'repairProcName',
      'shortRepairScheme',
      'repairSuggestion',
      'suggestSchemeCode',
      'suggestRepairSchemeCode',
      'repairPlanCode',
      'recommendedScheme',
      'proposalCode',
    ]);
  }

  String _reporterLabel(Map<String, dynamic>? item) {
    if (item == null) return '';
    final namePrimary = _pickFromItem(item, [
      'reporterName',
      'createName',
      'reportPersonName',
      'reportUserName',
      'createBy',
      'discoverName',
      'submitter',
      'submitName',
      'workerName',
      'findUserName',
      'finderName',
      'submitterName',
    ]);
    if (namePrimary.isNotEmpty) return namePrimary;
    final codeOnly = _pickFromItem(item, ['reporter']);
    if (codeOnly.isEmpty) return '';
    if (_looksLikeCode(codeOnly)) {
      return '提报人$codeOnly';
    }
    return codeOnly;
  }

  String _reportTimeLabel(Map<String, dynamic>? item) {
    if (item == null) return '';
    final raw = _pickFromItem(item, [
      'reportDate',
      'createTime',
      'reportTime',
      'reportShowDate',
      'createDate',
      'submitTime',
      'discoverTime',
      'reportingTime',
      'findTime',
      'submitDate',
      'faultReportTime',
    ]);
    if (raw.isEmpty) return '';
    if (raw.length > 16) return raw.substring(0, 16);
    return raw;
  }

  String _repairPictureGroupId(Map<String, dynamic>? item) {
    if (item == null) return '';
    return _pickFromItem(item, [
      'repairPicture',
      'repairEndPicture',
      'mutualInspectionPicture',
      'reportPicture',
      'reportPicGroupId',
      'pictureGroupId',
      'imgGroupId',
      'picGroupId',
      'imageGroupId',
      'attachment',
      'attachGroupId',
      'faultPicGroupId',
      'faultImageGroupId',
      'mediaGroupId',
    ]);
  }

  String _longRepairSchemeLabel(Map<String, dynamic>? item) {
    if (item == null) return '';
    return _pickFromItem(item, [
      'maintenanceNotice',
      'repairContent',
      'repairProcContent',
      'repairPlan',
      'repairProgram',
      'repairPlanContent',
      'workContent',
      'repairScheme',
      'faultInformation',
      'repairContentDetail',
      'repairLongContent',
      'disposalScheme',
      'disposalContent',
      'repairPlanDetail',
      'maintenanceScheme',
      'repairMeasure',
    ]);
  }

  String _workpieceCoefficientLabel(Map<String, dynamic>? item) {
    if (item == null) return '';
    // 后端明细里 workpieceCoefficient 字段当前返回 null（字段在 vjtWebSearch 里，
    // 与 reporterName、deptName 同层级）。实际有数值的是同层级的 workHourFactor。
    // 优先 workpieceCoefficient，为空则回退 workHourFactor，保证 UI 能展示数值。
    final primary = _pickFromItem(item, ['workpieceCoefficient']);
    if (primary.isNotEmpty) return primary;
    return _pickFromItem(item, ['workHourFactor']);
  }

  String _resolveCodeFromOptions(
    List<Map<String, dynamic>> options,
    String? codeOrName,
    List<String> codeKeys,
    List<String> nameKeys,
  ) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return '';
    final key = codeOrName.trim();
    final byName = _findOptionByIdOrName(
      options,
      id: key,
      idKeys: codeKeys,
      name: key,
      nameKeys: nameKeys,
    );
    if (byName != null) {
      final n = _pickText(byName, nameKeys);
      if (n.isNotEmpty) return n;
    }
    return key;
  }

  String _processingMethodByCode(Map<String, dynamic>? item) {
    if (item == null) return '';
    final rawName = _pickFromItem(item, [
      'processMethodName',
      'requiredProcessingMethodName',
      'processMainNode',
      'processingMethodName',
      'dictName',
      'jtDictName',
    ]);
    if (rawName.isNotEmpty && !_looksLikeCode(rawName)) return rawName;
    final rawCode = _pickFromItem(item, [
      'processingMethod',
      'requiredProcessingMethod',
      'jtDictCode',
      'jtDictName',
      'processMethodCode',
      'processingMethodCode',
      'processingMethodDictCode',
      'machineSystemCode',
    ]);
    if (rawCode.isEmpty) return rawName;
    final resolved = _resolveCodeFromOptions(
      _processingMethodOptions,
      rawCode,
      [
        'code',
        'dictCode',
        'jtDictCode',
        'processingMethodCode',
      ],
      [
        'dictName',
        'jtDictName',
        'name',
        'displayText',
        'processingMethodName',
      ],
    );
    return resolved.isEmpty ? rawName : resolved;
  }

  String _faultConfigByCode(Map<String, dynamic>? item) {
    if (item == null) return '';
    final directName = _pickFromItem(item, [
      'jcNodeName',
      'configNodeName',
      'faultyComponent',
      'faultComponentName',
      'mutualName',
      'componentName',
      'structureName',
      'partName',
    ]);
    if (directName.isNotEmpty && !_looksLikeCode(directName)) {
      return directName;
    }
    final rawCode = _pickFromItem(item, [
      'jcNodeCode',
      'configCode',
      'configNodeCode',
      'nodeCode',
      'configId',
      'faultComponentCode',
      'faultPartCode',
      'componentCode',
      'partCode',
      'structureCode',
      'faultConfigCode',
    ]);
    if (rawCode.isEmpty) return directName;
    final resolved = _resolveCodeFromOptions(
      _configOptions,
      rawCode,
      [
        'jcNodeCode',
        'configCode',
        'configNodeCode',
        'code',
        'nodeCode',
        'configId',
        'id',
      ],
      [
        'jcNodeName',
        'displayText',
        'nodeName',
        'configNodeName',
        'configName',
        'structure',
        'componentName',
        'name',
      ],
    );
    return resolved.isEmpty ? directName : resolved;
  }

  String _responsibleDeptByCode(Map<String, dynamic>? item) {
    if (item == null) return '';
    final rawName = _pickFromItem(item, [
      'deptName',
      'teamName',
      'disposeDeptName',
      'responsibleDeptName',
      'responsibleDept',
      'dutyDeptName',
      'handleDeptName',
      'assignDeptName',
    ]);
    if (rawName.isNotEmpty && !_looksLikeCode(rawName)) return rawName;
    final rawCode = _pickFromItem(item, [
      'deptId',
      'deptCode',
      'team',
      'teamId',
      'teamCode',
      'disposeDeptId',
      'disposeDepartId',
      'responsibleDeptCode',
      'responsibleDept',
      'deptNameCode',
      'dutyDeptCode',
      'dutyDept',
      'handleDeptCode',
      'handleDept',
      'assignDeptCode',
      'assignDept',
    ]);
    if (rawCode.isEmpty) return rawName;
    final resolved = _resolveCodeFromOptions(
      _deptList,
      rawCode,
      [
        'deptCode',
        'code',
        'deptId',
        'id',
        'teamId',
        'teamCode',
      ],
      [
        'deptName',
        'name',
        'teamName',
        'displayText',
        'fullName',
        'label',
      ],
    );
    return resolved.isEmpty ? rawName : resolved;
  }

  String _completeProcessByCode(Map<String, dynamic>? item) {
    if (item == null) return '';
    final rawName = _pickFromItem(item, [
      'processMainNode',
      'repairMainNodeName',
      'originalRepairMainNodeName',
      'completeProcessName',
      'completedProcessName',
      'finishProcessName',
      'repairProcessName',
      'processName',
      'repairProcName',
      'currentProcessName',
      'processingNodeName',
    ]);
    if (rawName.isNotEmpty && !_looksLikeCode(rawName)) return rawName;
    final rawCode = _pickFromItem(item, [
      'processMainNodeCode',
      'mainProcessPoint',
      'repairMainNodeCode',
      'originalRepairMainNodeCode',
      'completeProcessCode',
      'completedProcessCode',
      'finishProcessCode',
      'repairProcCode',
      'processCode',
      'repairProcessCode',
      'currentProcessCode',
    ]);
    if (rawCode.isEmpty) return rawName;
    final resolved = _resolveCodeFromOptions(
      _repairMainNodeOptions,
      rawCode,
      [
        'processMainNodeCode',
        'repairMainNodeCode',
        'repairProcCode',
        'procCode',
        'processCode',
        'code',
        'id',
      ],
      [
        'processMainNode',
        'repairMainNodeName',
        'repairProcName',
        'repairProcessName',
        'processName',
        'name',
        'displayText',
        'nodeName',
      ],
    );
    return resolved.isEmpty ? rawName : resolved;
  }

  String _scheduleNodeByCode(Map<String, dynamic>? item) {
    if (item == null) return '';
    // 完成排程节点只认 scheduleNodeName（vjtWebSearch 优先），
    // 不用 originalScheduleNodeName——那是来源节点（如"入段"），不是完成节点
    final rawName = _pickFromItem(item, const [
      'scheduleNodeName',
      'schedleNodeName',
    ]);
    if (rawName.isNotEmpty && !_looksLikeCode(rawName)) return rawName;
    final rawCode = _pickFromItem(item, const [
      'scheduleNodeCode',
      'schedleNodeCode',
    ]);
    if (rawCode.isEmpty) return rawName;
    // 反查选项：发布模式选项 + 阶段2按工序缓存的排程选项合并查找
    final allOptions = <Map<String, dynamic>>[
      ..._scheduleNodeOptions,
      for (final l in _schedNodeCacheByMain.values) ...l,
    ];
    final resolved = _resolveCodeFromOptions(
      allOptions,
      rawCode,
      const [
        'scheduleNodeCode',
        'code',
        'nodeCode',
        'id',
      ],
      const [
        'scheduleNodeName',
        'name',
        'displayText',
        'nodeName',
      ],
    );
    return resolved.isEmpty ? rawName : resolved;
  }

  bool _looksLikeCode(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (t.length > 40) return false;
    final hasChinese = t.contains(RegExp(r'[\u4e00-\u9fa5]'));
    if (hasChinese) return false;
    if (RegExp(r'^[0-9A-Fa-f\-]{8,}$').hasMatch(t)) return true;
    if (RegExp(r'^[A-Z]{2,}\d{2,}$').hasMatch(t)) return true;
    if (RegExp(r'^\d{8,}$').hasMatch(t)) return true;
    return false;
  }

  Color _riskChipColor(String riskText) {
    final t = riskText.trim().toUpperCase();
    if (t.isEmpty) return const Color(0xFFE5E7EB);
    if (t.startsWith('A')) return const Color(0xFFFEE2E2);
    if (t.startsWith('B')) return const Color(0xFFFFEDD5);
    if (t.startsWith('C')) return const Color(0xFFDBEAFE);
    if (t.startsWith('D') || t == '低') return const Color(0xFFDCFCE7);
    return const Color(0xFFF3E8FF);
  }

  Color _riskChipTextColor(String riskText) {
    final t = riskText.trim().toUpperCase();
    if (t.isEmpty) return const Color(0xFF6B7280);
    if (t.startsWith('A')) return const Color(0xFFB91C1C);
    if (t.startsWith('B')) return const Color(0xFFC2410C);
    if (t.startsWith('C')) return const Color(0xFF1D4ED8);
    if (t.startsWith('D') || t == '低') return const Color(0xFF047857);
    return const Color(0xFF6D28D9);
  }

  Color _processingChipColor(String pText) {
    if (pText.trim().isEmpty) return const Color(0xFFE0F2FE);
    final t = pText.trim();
    if (t.contains('清洁') || t.contains('保养')) return const Color(0xFFDCFCE7);
    if (t.contains('紧固')) return const Color(0xFFFFF3CD);
    if (t.contains('更换') || t.contains('更换')) return const Color(0xFFDBEAFE);
    return const Color(0xFFF3E8FF);
  }

  Color _processingChipTextColor(String pText) {
    final t = pText.trim();
    if (t.isEmpty) return const Color(0xFF0369A1);
    if (t.contains('清洁') || t.contains('保养')) return const Color(0xFF065F46);
    if (t.contains('紧固')) return const Color(0xFF92400E);
    if (t.contains('更换') || t.contains('更换')) return const Color(0xFF1E3A8A);
    return const Color(0xFF5B21B6);
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
    if (widget.noticeType == 22) {
      if (_jt28Options.isEmpty) {
        error = '暂无故障明细，无法下发';
      }
      // 故障处置单不需要全局工序节点/停留位置校验，
      // 每条 detailList 自带 repairMainNodeName/scheduleNodeName
    } else {
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
            error = '$prefix请选择加工方法';
            break;
          }
          if (block.riskLevelText.trim().isEmpty) {
            error = '$prefix请选择风险等级';
            break;
          }
          if (block.configText.trim().isEmpty) {
            error = '$prefix请选择关联构型';
            break;
          }
          if (block.outsourceFactoryController.text.trim().isEmpty) {
            error = '$prefix请输入外包厂家';
            break;
          }
          if (block.repairPlanController.text.trim().isEmpty) {
            error = '$prefix请输入施修方案';
            break;
          }
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
          if (widget.noticeType == 22)
            'shuntingType': 22
          else
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
    // final activeStateDetail = _activeStateDetail;
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
    final suffix = widget.noticeType == 22 ? '下发检修过程故障处置单' : '下发修程通知单';
    return prefix.isEmpty ? suffix : '$prefix-$suffix';
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
    if (mounted) {
      setState(() => _loadingJt28 = true);
    }
    try {
      dynamic res;
      List<Map<String, dynamic>> list;
      if (widget.noticeType == 22) {
        _logger.i('[检修过程故障处置单JT28] 开始查询故障明细 trainEntryCode=$trainEntryCode');
        res =
            await ProductApi().queryRepairProcessFaultDetailsForManualDispatch(
          queryParametrs: {
            'trainEntryCode': trainEntryCode,
          },
        );
        list = <Map<String, dynamic>>[];
        dynamic rows = res;
        if (res is Map) {
          final outer = res['data'];
          final inner = outer is Map ? outer['data'] : null;
          final d1 = inner is Map ? inner['detailList'] : null;
          final d2 = outer is Map ? outer['detailList'] : null;
          final d3 = res['detailList'];
          final candidate = d1 ?? d2 ?? d3;
          rows = candidate ??
              (res['rows'] ??
                  (inner is List
                      ? inner
                      : (outer is List ? outer : res['list'])));
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
        _logger.i('[检修过程故障处置单JT28] 页面收到故障明细 rows=${list.length}');
        _loadRepairProcDictForFault();
      } else {
        _logger.i('[修程通知单JT28] 进入修程通知单，开始查询 trainEntryCode=$trainEntryCode');
        res = await ProductApi().getJt28SelectAll(
          queryParametrs: {
            'trainEntryCode': trainEntryCode,
            'derived': false,
            'pageNum': 0,
            'pageSize': 0,
            'status': 0,
          },
        );
        list = <Map<String, dynamic>>[];
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
      }
    } catch (e) {
      if (widget.noticeType == 22) {
        _logger.e('[检修过程故障处置单JT28] 加载故障明细失败: $e');
      } else {
        _logger.e('[修程通知单JT28] 加载机统28故障现象失败: $e');
      }
      if (!mounted) return;
      setState(() {
        _jt28Options = [];
        _selectedJt28 = null;
        _loadingJt28 = false;
      });
    }
  }

  /// 回填模式：按处置单 code 用 selectAll 回查完整单据，回填表头与故障明细。
  Future<void> _loadFillNotice() async {
    final code = widget.fillNoticeCode!.trim();
    setState(() => _loadingFillNotice = true);
    try {
      _logger.i('[故障处置单回填] 开始回查 code=$code');
      final res = await ProductApi().getRepairProcessFaultShuntingSelectAll(
        queryParametrs: {
          'code': code,
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      dynamic rows = res;
      if (res is Map) {
        final outer = res['data'];
        final inner = outer is Map ? outer['data'] : null;
        rows = res['rows'] ??
            (inner is Map ? inner['rows'] : null) ??
            (outer is Map ? outer['rows'] : null) ??
            (inner is List ? inner : (outer is List ? outer : res['list']));
      }
      final headerRows = <Map<String, dynamic>>[];
      if (rows is List) {
        for (final e in rows) {
          if (e is Map) {
            headerRows.add(Map<String, dynamic>.from(e));
          }
        }
      }
      if (headerRows.isEmpty) {
        _logger.w('[故障处置单回填] 未查询到单据 code=$code');
        if (!mounted) return;
        setState(() => _loadingFillNotice = false);
        showToast('未查询到该故障处置单');
        return;
      }
      final header = headerRows.first;
      final detailRows = <Map<String, dynamic>>[];
      final details = header['detailList'];
      if (details is List) {
        for (final e in details) {
          if (e is Map) {
            final row = Map<String, dynamic>.from(e);
            row['jt28DisplayText'] = _jt28Label(row);
            detailRows.add(row);
          }
        }
      }
      // 重建两套输入控制器：阶段0建议施修方案（vjtWebSearch.repairScheme）、
      // 阶段1施修方案（maintenanceNotice）
      for (final c in _fillSchemeControllers.values) {
        c.dispose();
      }
      _fillSchemeControllers.clear();
      for (final c in _fillPlanControllers.values) {
        c.dispose();
      }
      _fillPlanControllers.clear();
      for (int i = 0; i < detailRows.length; i++) {
        _fillSchemeControllers[i] = TextEditingController(
          text: _suggestedRepairSchemeLabel(detailRows[i]),
        );
        _fillPlanControllers[i] = TextEditingController(
          text: _pickFromItem(detailRows[i], ['maintenanceNotice']),
        );
      }
      // 加载映射：嵌套对象 → vjtWebSearch（与 Web 展示逻辑一致），再重建选中值
      _syncStage2VjtFromDetail(detailRows);
      _rebuildStage2Selections(detailRows);
      if (!mounted) return;
      setState(() {
        _fillHeader = header;
        _jt28Options = detailRows;
        _applyFillNoticeSignees(header);
        _loadingFillNotice = false;
      });
      _logger.i(
          '[故障处置单回填] 回填成功 明细=${detailRows.length}条 表单=${_asText(header['formName'])}');
      _logger.i('[故障处置单回填] header字段开始');
      for (final key in header.keys) {
        _logger.i('  $key: ${header[key]}');
      }
      _logger.i('[故障处置单回填] header字段结束');
      if (detailRows.isNotEmpty) {
        _logger.i('[故障处置单回填] detailList[0]字段开始');
        for (final key in detailRows.first.keys) {
          _logger.i('  $key: ${detailRows.first[key]}');
        }
        _logger.i('[故障处置单回填] detailList[0]字段结束');
      }
      // fillStatus=0/1/2 分别对应三个填写阶段，显示填写按钮
      final fs = _asText(header['fillStatus']);
      setState(() {
        _showFillButton = fs == '0' || fs == '1' || fs == '2' || fs.isEmpty;
      });
      // 只有 code 没有 name 时，按工序节点反查排程名称补全（异步，不阻塞详情展示）
      await _backfillStage2SchedNames();
    } catch (e) {
      _logger.e('[故障处置单回填] 回查失败: $e');
      if (!mounted) return;
      setState(() => _loadingFillNotice = false);
    }
  }

  /// 阶段2加载映射（对齐 Web 端源码）：后端返回的嵌套对象
  /// responsibleDept/repairMainNode/scheduleNode 在展示前同步进 vjtWebSearch
  /// 标量字段，表格展示与后续填写全部走 vjtWebSearch：
  ///   vjt.deptId/deptName                       ← responsibleDept
  ///   vjt.mainProcessPoint/processMainNode      ← repairMainNode.code/name
  ///   vjt.scheduleNodeCode/scheduleNodeName     ← scheduleNode
  /// vjt 已有非空值时保留，避免覆盖已保存内容
  void _syncStage2VjtFromDetail(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      var vjt = row['vjtWebSearch'];
      if (vjt is! Map) {
        vjt = <String, dynamic>{};
        row['vjtWebSearch'] = vjt;
      }
      void putIfEmpty(String key, String value) {
        if (value.isEmpty) return;
        final cur = vjt[key];
        if (cur == null || cur.toString().trim().isEmpty) vjt[key] = value;
      }

      final dept = row['responsibleDept'];
      if (dept is Map) {
        final m = Map<String, dynamic>.from(dept);
        putIfEmpty('deptId', _firstText(m, ['deptId']));
        putIfEmpty('deptName', _firstText(m, ['deptName']));
      }
      final main = row['repairMainNode'];
      if (main is Map) {
        final m = Map<String, dynamic>.from(main);
        putIfEmpty('processMainNode', _firstText(m, ['name']));
        putIfEmpty('mainProcessPoint', _firstText(m, ['code']));
      }
      final sched = row['scheduleNode'];
      if (sched is Map) {
        final m = Map<String, dynamic>.from(sched);
        // 完成排程节点只认 vjtWebSearch 的 scheduleNodeName/scheduleNodeCode
        putIfEmpty('scheduleNodeName', _firstText(m, ['scheduleNodeName']));
        putIfEmpty('scheduleNodeCode', _firstText(m, ['scheduleNodeCode']));
      }
    }
  }

  /// 从明细 vjtWebSearch 重建阶段2每行的责任部门/完成工序节点/完成排程节点
  /// 选中值（展示与赋值统一在 vjtWebSearch，字段名以 Web 源码为准）
  void _rebuildStage2Selections(List<Map<String, dynamic>> rows) {
    _fillStage2Sel.clear();
    _fillStage2Raw.clear();
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      // 保留嵌套对象副本（提交时按 Web payload 反向组装）
      final deptObj = row['responsibleDept'] is Map
          ? Map<String, dynamic>.from(row['responsibleDept'] as Map)
          : null;
      final mainObj = row['repairMainNode'] is Map
          ? Map<String, dynamic>.from(row['repairMainNode'] as Map)
          : null;
      final schedObj = row['scheduleNode'] is Map
          ? Map<String, dynamic>.from(row['scheduleNode'] as Map)
          : null;
      _fillStage2Raw[i] = <String, dynamic>{
        if (deptObj != null) 'dept': deptObj,
        if (mainObj != null) 'main': mainObj,
        if (schedObj != null) 'sched': schedObj,
      };
      _fillStage2Sel[i] = <String, String>{
        // 责任部门：vjt.deptId/deptName
        'deptCode': _pickFromItem(row, ['deptId']),
        'deptName': _pickFromItem(row, ['deptName']),
        // 完成工序节点：vjt.mainProcessPoint(编码)/processMainNode(名称)
        'mainNodeCode': _pickFromItem(row, const ['mainProcessPoint']),
        'mainNodeName': _pickFromItem(row, const ['processMainNode']),
        // 完成排程节点：vjt.scheduleNodeCode/scheduleNodeName
        'schedNodeCode': _pickFromItem(row, const ['scheduleNodeCode']),
        'schedNodeName': _pickFromItem(row, const ['scheduleNodeName']),
      };
    }
  }

  /// 阶段2详情回查后，若某行 vjtWebSearch 只有 scheduleNodeCode 没有
  /// scheduleNodeName（后端偶发不回写名称），按该行工序节点拉取排程选项，
  /// 用 code 反查出名称并回填 vjtWebSearch 与选中值，保证展示的是名称
  Future<void> _backfillStage2SchedNames() async {
    final pending = <int>[];
    for (int i = 0; i < _jt28Options.length; i++) {
      final vjt = _jt28Options[i]['vjtWebSearch'];
      if (vjt is! Map) continue;
      final code = _asText(vjt['scheduleNodeCode']);
      final name = _asText(vjt['scheduleNodeName']);
      if (code.isNotEmpty && (name.isEmpty || _looksLikeCode(name))) {
        pending.add(i);
      }
    }
    if (pending.isEmpty) return;
    final trainEntryCode = _pickText(_fillHeader, ['trainEntryCode']);
    bool changed = false;
    for (final i in pending) {
      final vjt = _jt28Options[i]['vjtWebSearch'] as Map;
      final mainCode = _asText(vjt['mainProcessPoint']);
      final schedCode = _asText(vjt['scheduleNodeCode']);
      if (mainCode.isEmpty) continue;
      var list = _schedNodeCacheByMain[mainCode];
      list ??= await _fetchSchedNodeOptions(mainCode, trainEntryCode);
      _schedNodeCacheByMain[mainCode] = list;
      String hit = '';
      for (final e in list) {
        if (_asText(e['code']) == schedCode) {
          hit = _asText(e['displayName']);
          break;
        }
      }
      if (hit.isNotEmpty) {
        vjt['scheduleNodeName'] = hit;
        _fillStage2Sel[i]?['schedNodeName'] = hit;
        changed = true;
        _logger.i(
            '[故障处置单排程反查] 行: ${i + 1} scheduleNodeCode: $schedCode → scheduleNodeName: $hit');
      }
    }
    if (changed && mounted) setState(() {});
  }

  /// 阶段2进入时确保选项就绪：部门 + 工序节点（修程编码取自 header），并行加载
  Future<void> _ensureStage2Options() async {
    final needDept = _deptList.isEmpty && !_loadingDept;
    final needMainNode =
        _repairMainNodeOptions.isEmpty && !_loadingRepairMainNode;
    await Future.wait([
      if (needDept) _loadDepts(),
      if (needMainNode) _loadFillMainNodeOptions(),
    ]);
  }

  /// 回填模式：按 header.repairProcCode 加载工序节点选项（归一化 displayName/code）
  Future<void> _loadFillMainNodeOptions() async {
    setState(() => _loadingRepairMainNode = true);
    try {
      final procCode =
          _pickText(_fillHeader, ['repairProcCode', 'procCode', 'repairProc']);
      final r = await ProductApi().getRepairMainNode(queryParameters: {
        'pageNum': 0,
        'pageSize': 0,
        if (procCode.isNotEmpty) 'repairProcCode': procCode,
      });
      final list = <Map<String, dynamic>>[];
      for (final e in r) {
        final m = Map<String, dynamic>.from(e);
        final name = _firstText(m, [
          'repairMainNodeName',
          'nodeName',
          'name',
          'displayText',
        ]);
        final code = _firstText(m, [
          'repairMainNodeCode',
          'code',
          'id',
        ]);
        m['displayName'] = name;
        m['code'] = code;
        list.add(m);
      }
      if (!mounted) return;
      setState(() {
        _repairMainNodeOptions = list;
        _loadingRepairMainNode = false;
      });
    } catch (e) {
      _logger.e('[故障处置单阶段2] 加载工序节点失败: $e');
      if (!mounted) return;
      setState(() => _loadingRepairMainNode = false);
    }
  }

  /// 取第一个非空字段文本
  String _firstText(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  /// 阶段2：选择责任部门
  Future<void> _pickStage2Dept(int i) async {
    if (_deptList.isEmpty) {
      await _loadDepts();
    }
    if (!mounted) return;
    final picked = await _showSearchableListDialog(
      title: '选择责任部门',
      items: _deptList,
      labelKey: 'deptName',
    );
    if (picked != null && mounted) {
      setState(() {
        _fillStage2Sel[i]!['deptCode'] =
            _firstText(picked, ['deptId', 'deptCode', 'code', 'id']);
        _fillStage2Sel[i]!['deptName'] =
            _firstText(picked, ['deptName', 'name']);
        // 保存完整部门对象，提交时写入 responsibleDept
        _fillStage2Raw.putIfAbsent(i, () => <String, dynamic>{})['dept'] =
            Map<String, dynamic>.from(picked);
      });
    }
  }

  /// 阶段2：选择工序节点（选后清空该行已选排程节点）
  Future<void> _pickStage2MainNode(int i) async {
    if (_repairMainNodeOptions.isEmpty) {
      await _loadFillMainNodeOptions();
    }
    if (!mounted) return;
    final picked = await _showSearchableListDialog(
      title: '选择工序节点',
      items: _repairMainNodeOptions,
      labelKey: 'displayName',
    );
    if (picked != null && mounted) {
      setState(() {
        _fillStage2Sel[i]!['mainNodeCode'] = (picked['code'] ?? '').toString();
        _fillStage2Sel[i]!['mainNodeName'] =
            (picked['displayName'] ?? '').toString();
        // 工序节点变了，排程节点需重新选择
        _fillStage2Sel[i]!['schedNodeCode'] = '';
        _fillStage2Sel[i]!['schedNodeName'] = '';
        // 保存完整工序节点对象，提交时写入 repairMainNode（去掉UI临时字段）
        final mainRaw = Map<String, dynamic>.from(picked)
          ..remove('displayName');
        _fillStage2Raw.putIfAbsent(i, () => <String, dynamic>{})['main'] =
            mainRaw;
        _fillStage2Raw[i]!.remove('sched');
      });
    }
  }

  /// 拉取某工序节点下的排程节点选项并归一化为 displayName/code。
  /// GET /dispatch/mainNodeScheduleNode/selectAll
  Future<List<Map<String, dynamic>>> _fetchSchedNodeOptions(
    String mainCode,
    String trainEntryCode,
  ) async {
    final r = await ProductApi().getMainNodeSchedleNodeAll(
      queryParametrs: {
        'pageNum': 0,
        'pageSize': 0,
        'repairMainNodeCode': mainCode,
        if (trainEntryCode.isNotEmpty) 'trainEntryCode': trainEntryCode,
      },
    );
    // 返回为分页对象，剥出 rows
    dynamic raw = r;
    if (raw is Map) {
      raw = raw['rows'] ?? raw['records'] ?? raw['data'] ?? raw['list'] ?? raw;
      if (raw is Map) {
        final lists = raw.values.whereType<List>().toList();
        if (lists.length == 1) raw = lists.first;
      }
    }
    final rows =
        raw is List ? raw.whereType<Map>().toList(growable: false) : const [];
    final list = <Map<String, dynamic>>[];
    for (final e in rows) {
      final m = Map<String, dynamic>.from(e);
      // 排程名称/编码严格以接口字段 scheduleNodeName/scheduleNodeCode 为准
      String findByKeys(List<String> keys) {
        var s = _firstText(m, keys);
        if (s.isNotEmpty) return s;
        // 兼容一层嵌套：个别后端把节点属性包在子对象内
        for (final v in m.values) {
          if (v is Map) {
            s = _firstText(Map<String, dynamic>.from(v), keys);
            if (s.isNotEmpty) return s;
          }
        }
        return '';
      }

      final name = findByKeys(const [
        'scheduleNodeName',
        'schedleNodeName',
        'mainNodeSchedleNodeName',
        'nodeName',
        'name',
        'displayText',
      ]);
      final code = findByKeys(const [
        'scheduleNodeCode',
        'mainNodeSchedleNodeCode',
        'mainNodeScheduleNodeCode',
        'schedleNodeCode',
        'code',
        'id',
      ]);
      // 名称与编码都为空的行丢弃，避免选中后只提交了 code/空值
      if (name.isEmpty && code.isEmpty) continue;
      m['displayName'] = name;
      m['code'] = code;
      list.add(m);
    }
    _logger.i('[故障处置单排程选项] scheduleMainCode: $mainCode rows: ${list.length}');
    for (final e in list) {
      _logger.i(
          '  scheduleNodeCode: ${e['code']} | scheduleNodeName: ${e['displayName']}');
    }
    return list;
  }

  /// 阶段2：选择排程节点（按该行工序节点联动，结果按工序节点code缓存）。
  /// 与 Web 端一致：GET /dispatch/mainNodeScheduleNode/selectAll，
  /// 参数 pageNum/pageSize/repairMainNodeCode/trainEntryCode
  Future<void> _pickStage2SchedNode(int i) async {
    final sel = _fillStage2Sel[i]!;
    final mainCode = sel['mainNodeCode'] ?? '';
    if (mainCode.isEmpty) {
      showToast('请先选择工序节点');
      return;
    }
    var list = _schedNodeCacheByMain[mainCode];
    if (list == null) {
      final trainEntryCode = _pickText(_fillHeader, ['trainEntryCode']);
      list = await _fetchSchedNodeOptions(mainCode, trainEntryCode);
      _schedNodeCacheByMain[mainCode] = list;
    }
    if (!mounted) return;
    if (list.isEmpty) {
      showToast('该工序节点下暂无可选排程节点');
      return;
    }
    final picked = await _showSearchableListDialog(
      title: '选择排程节点',
      items: list,
      labelKey: 'displayName',
    );
    if (picked != null && mounted) {
      setState(() {
        sel['schedNodeCode'] = (picked['code'] ?? '').toString();
        sel['schedNodeName'] = (picked['displayName'] ?? '').toString();
        // 保存完整排程节点对象，提交时写入 scheduleNode（去掉UI临时字段）
        final schedRaw = Map<String, dynamic>.from(picked)
          ..remove('displayName');
        _fillStage2Raw.putIfAbsent(i, () => <String, dynamic>{})['sched'] =
            schedRaw;
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

  Future<void> _loadRepairProcDictForFault() async {
    if (!mounted) return;
    final repairProcCode = (widget.item.repairProcCode ?? '').toString().trim();
    final repairMainNodeCode = _pickTextFromSources([
      {
        'repairMainNodeCode':
            widget.item.trainRepairScheduleReal?.repairMainNodeCode ?? '',
      },
      {
        'repairMainNodeCode': widget.item.repairMainNodeCode ?? '',
      },
    ], [
      'repairMainNodeCode',
    ]);
    final permissions = Global.profile.permissions;
    final userDept = permissions?.user.dept;
    final allDeptParentId = userDept?.parentId ?? 0;

    await Future.wait(<Future<void>>[
      () async {
        if (_deptList.isNotEmpty || _loadingDept) return;
        if (!mounted) return;
        setState(() => _loadingDept = true);
        try {
          final r = await ProductApi().getDeptTreeByParentIdList(
            queryParametrs: {
              'parentIdList': allDeptParentId,
            },
          );
          final flat = <Map<String, dynamic>>[];
          void walk(dynamic node) {
            if (node is! Map) return;
            flat.add(Map<String, dynamic>.from(node));
            final children = node['children'];
            if (children is List) {
              for (final c in children) {
                walk(c);
              }
            }
          }

          if (r is List) {
            for (final e in r) {
              walk(e);
            }
          } else if (r is Map) {
            final rows = r['rows'] ?? r['data'] ?? r['list'];
            if (rows is List) {
              for (final e in rows) {
                walk(e);
              }
            } else {
              walk(r);
            }
          }
          if (!mounted) return;
          setState(() {
            _deptList = flat;
            _loadingDept = false;
          });
        } catch (e) {
          _logger.e('[检修过程故障处置单] 加载责任部门字典失败: $e');
          if (!mounted) return;
          setState(() {
            _deptList = [];
            _loadingDept = false;
          });
        }
      }(),
      () async {
        if (_repairMainNodeOptions.isNotEmpty || _loadingRepairMainNode) {
          return;
        }
        if (!mounted) return;
        setState(() => _loadingRepairMainNode = true);
        try {
          final r = await ProductApi().getRepairMainNodeAll(
            queryParametrs: repairProcCode.isEmpty
                ? const {
                    'pageNum': 0,
                    'pageSize': 0,
                  }
                : {
                    'pageNum': 0,
                    'pageSize': 0,
                    'repairProcCode': repairProcCode,
                  },
          );
          var rawList = r.toMapList();
          if (repairProcCode.isNotEmpty) {
            rawList = rawList.where((e) {
              final v = (e['repairProcCode'] ?? '').toString().trim();
              return v.isEmpty || v == repairProcCode;
            }).toList();
          }
          final list = <Map<String, dynamic>>[];
          for (final e in rawList) {
            list.add(Map<String, dynamic>.from(e));
          }
          if (!mounted) return;
          setState(() {
            _repairMainNodeOptions = list;
            _loadingRepairMainNode = false;
          });
        } catch (e) {
          _logger.e('[检修过程故障处置单] 加载完成工序字典失败: $e');
          if (!mounted) return;
          setState(() {
            _repairMainNodeOptions = [];
            _loadingRepairMainNode = false;
          });
        }
      }(),
      () async {
        if (_scheduleNodeOptions.isNotEmpty || _loadingScheduleNode) return;
        if (!mounted) return;
        setState(() => _loadingScheduleNode = true);
        try {
          final q = <String, dynamic>{
            'pageNum': 0,
            'pageSize': 0,
          };
          if (repairProcCode.isNotEmpty) {
            q['procCode'] = repairProcCode;
            q['repairProcCode'] = repairProcCode;
          }
          if (repairMainNodeCode.isNotEmpty) {
            q['repairMainNodeCode'] = repairMainNodeCode;
          }
          final r1 =
              await ProductApi().getTemplateNodeByProcCodeAndMainNodeCode(
            queryParametrs: q,
          );
          final list = <Map<String, dynamic>>[];
          for (final e in r1) {
            list.add(Map<String, dynamic>.from(e));
          }
          if (list.isEmpty && repairProcCode.isNotEmpty) {
            try {
              final r2 = await ProductApi().getMainNodeSchedleNodeAll(
                queryParametrs: {
                  'pageNum': 0,
                  'pageSize': 0,
                  'repairProcCode': repairProcCode,
                  if (repairMainNodeCode.isNotEmpty)
                    'repairMainNodeCode': repairMainNodeCode,
                },
              );
              dynamic rows2 = r2;
              if (r2 is Map) {
                rows2 = r2['rows'] ?? r2['data'] ?? r2['list'];
              }
              if (rows2 is List) {
                for (final e in rows2) {
                  if (e is Map) {
                    list.add(Map<String, dynamic>.from(e));
                  }
                }
              }
            } catch (_) {}
          }
          if (!mounted) return;
          setState(() {
            _scheduleNodeOptions = list;
            _loadingScheduleNode = false;
          });
        } catch (e) {
          _logger.e('[检修过程故障处置单] 加载排程节点字典失败: $e');
          if (!mounted) return;
          setState(() {
            _scheduleNodeOptions = [];
            _loadingScheduleNode = false;
          });
        }
      }(),
    ]);
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
      Map<String, dynamic> receiveGroupQuery;
      if (widget.noticeType == 22) {
        _logger.i('[检修过程故障处置单签收组] 开始查询签收组 shuntingType=25');
        receiveGroupQuery = const {
          'pageNum': 0,
          'pageSize': 0,
          'shuntingType': 25,
        };
      } else {
        _logger.i('[修程通知单签收组] 开始查询签收组 shuntingType=13');
        receiveGroupQuery = const {
          'pageNum': 0,
          'pageSize': 0,
          'shuntingType': 13,
        };
      }
      final res = await ProductApi().getShuntingReceiveGroup(
        queryParametrs: receiveGroupQuery,
      );
      final rows = <Map<String, dynamic>>[];
      void acceptRow(Map<String, dynamic> row) {
        final name = _pickText(row, [
          'name',
          'displayText',
          'groupName',
          'receiveGroupName',
          'shuntingGroupName',
        ]);
        final displayName = name;
        row['displayText'] = displayName;
        rows.add(row);
      }

      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            acceptRow(Map<String, dynamic>.from(item));
          }
        }
      } else if (res is Map) {
        final resMap = Map<String, dynamic>.from(res);
        final innerRows = _pickList(
          resMap,
          ['rows', 'list', 'dataList', 'items', 'records'],
        );
        for (final item in innerRows) {
          acceptRow(Map<String, dynamic>.from(item));
        }
        if (rows.isEmpty && resMap['code'] == 200) {
          // 极端情况：返回 {code:200,data:{code:"S_F_S000",data:{rows:[...]}}} 已经被 API 层拆成最内层 rows 了
          // 但如果这里收到外层 Map，再兜底找一次
          final outer = res;
          final d1 = outer['data'];
          final d2 = d1 is Map ? d1['data'] : null;
          final d3 = d2 is Map ? d2['data'] : null;
          for (final candidate in [d3, d2, d1]) {
            if (candidate is Map && candidate['rows'] is List) {
              for (final item in candidate['rows']) {
                if (item is Map) {
                  acceptRow(Map<String, dynamic>.from(item));
                }
              }
              break;
            }
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
      // 自动选中默认签收组（按当前填写阶段）
      await _applyDefaultReceiveGroupIfNeeded(rows);
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

  Widget _buildFaultDisposalCard(Map<String, dynamic> item, int index) {
    final seq = index + 1;
    final faultPhenomenon = _jt28Label(item);
    final suggestScheme = _suggestedRepairSchemeLabel(item);
    final reporter = _reporterLabel(item);
    final reportTime = _reportTimeLabel(item);
    final repairPicGroup = _repairPictureGroupId(item);
    final longRepairScheme = _longRepairSchemeLabel(item);
    final riskLevel = _riskLevelLabel(item);
    final processingByDict = _processingMethodByCode(item);
    final configByDict = _faultConfigByCode(item);
    final deptByDict = _responsibleDeptByCode(item);
    final completeProcByDict = _completeProcessByCode(item);
    final scheduleByDict = _scheduleNodeByCode(item);
    final workpieceCoeff = _workpieceCoefficientLabel(item);

    final hasPic = repairPicGroup.trim().isNotEmpty;
    final hasLongScheme = longRepairScheme.trim().isNotEmpty;
    final isExpanded = _faultCardExpanded.contains(index);

    Widget kvChip({
      required String label,
      required String value,
      required Color bg,
      required Color fg,
      IconData? icon,
    }) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '$label：$value',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ],
        ),
      );
    }

    Widget kvRow({
      required String label,
      required String value,
      IconData? icon,
      Color? labelColor,
      bool alwaysShow = false,
    }) {
      // alwaysShow=true 时即使值为空也展示一行，显示 "-"（用于活检系数等必显字段）
      final displayValue = value.isEmpty && alwaysShow ? '-' : value;
      if (displayValue.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 12, color: labelColor ?? const Color(0xFF64748B)),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      );
    }

    Widget mainCell({
      required String label,
      required String value,
      required Color labelBg,
      required Color labelFg,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelFg,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value.isEmpty
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF0F172A),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? const Color(0xFF3B82F6).withOpacity(0.10)
                : const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: isExpanded ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _faultCardExpanded.remove(index);
                } else {
                  _faultCardExpanded.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1D4ED8),
                              Color(0xFF2563EB),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$seq',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faultPhenomenon.isEmpty
                                  ? '（未填写故障现象）'
                                  : faultPhenomenon,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                mainCell(
                                  label: '处置车间',
                                  value: deptByDict,
                                  labelBg: const Color(0xFFDBEAFE),
                                  labelFg: const Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 10),
                                mainCell(
                                  label: '完成节点',
                                  value: completeProcByDict,
                                  labelBg: const Color(0xFFFFEDD5),
                                  labelFg: const Color(0xFF9A3412),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isExpanded
                                              ? const Color(0xFFEFF6FF)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.keyboard_arrow_up_rounded,
                                          size: 20,
                                          color: isExpanded
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reporter.isEmpty ? '匿名' : reporter,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reportTime.isEmpty ? '—' : reportTime,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (suggestScheme.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFBD38D),
                          width: 1,
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: '建议施修方案：',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A3412),
                          ),
                          children: [
                            TextSpan(
                              text: suggestScheme,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7C2D12),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (hasLongScheme) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '施修方案',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            longRepairScheme,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: hasPic
                            ? () {
                                PhotoPreviewDialog.show(
                                  context,
                                  repairPicGroup,
                                  ProductApi().getFaultVideoAndImage,
                                );
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: hasPic
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          foregroundColor: hasPic
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.image_outlined, size: 15),
                        label: Text(
                          hasPic ? '查看报修图片' : '暂无报修图片',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      if (riskLevel.isNotEmpty)
                        kvChip(
                          label: '风险等级',
                          value: riskLevel,
                          bg: _riskChipColor(riskLevel),
                          fg: _riskChipTextColor(riskLevel),
                        ),
                      if (processingByDict.isNotEmpty)
                        kvChip(
                          label: '加工方法',
                          value: processingByDict,
                          bg: _processingChipColor(processingByDict),
                          fg: _processingChipTextColor(processingByDict),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        kvRow(
                          label: '提报人',
                          value: reporter,
                          icon: Icons.person_rounded,
                          labelColor: const Color(0xFF7C3AED),
                        ),
                        kvRow(
                          label: '提报时间',
                          value: reportTime,
                          icon: Icons.access_time_rounded,
                          labelColor: const Color(0xFF7C3AED),
                        ),
                        kvRow(
                          label: '加工方法',
                          value: processingByDict,
                          icon: Icons.build_circle_outlined,
                        ),
                        kvRow(
                          label: '故障构型',
                          value: configByDict,
                          icon: Icons.settings_input_component_outlined,
                        ),
                        kvRow(
                          label: '责任部门',
                          value: deptByDict,
                          icon: Icons.account_tree_outlined,
                        ),
                        kvRow(
                          label: '活检系数',
                          value: workpieceCoeff,
                          icon: Icons.straighten_rounded,
                          labelColor: const Color(0xFF0F766E),
                          alwaysShow: true,
                        ),
                        kvRow(
                          label: '完成工序',
                          value: completeProcByDict,
                          icon: Icons.rule_outlined,
                        ),
                        kvRow(
                          label: '完成节点',
                          value: scheduleByDict,
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
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

  // ==================== 回填模式（消息中心详情/填写） ====================

  /// 将主表 shuntingNoticeList（已有签收记录）转换为 _signeeList 结构，
  /// 供只读详情页展示签收部门/班组/人员。按签收人去重。
  void _applyFillNoticeSignees(Map<String, dynamic> header) {
    final rawList = header['shuntingNoticeList'];
    final rows = <Map<String, dynamic>>[];
    final seenUserIds = <dynamic>{};
    if (rawList is List) {
      for (final e in rawList) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final userId = m['auditUserId'];
        if (userId != null && _asText(userId).isNotEmpty) {
          if (!seenUserIds.add(userId)) continue;
        }
        rows.add({
          'signDept': _asText(m['auditDeptId']).isNotEmpty
              ? {
                  'deptId': m['auditDeptId'],
                  'deptName': m['auditDeptName'],
                }
              : null,
          'signTeam': _asText(m['auditTeamId']).isNotEmpty
              ? {
                  'deptId': m['auditTeamId'],
                  'deptName': m['auditTeamName'],
                }
              : null,
          'signUsers': _asText(userId).isNotEmpty
              ? [
                  {
                    'userId': userId,
                    'nickName': m['auditUserName'],
                  }
                ]
              : <Map<String, dynamic>>[],
        });
      }
    }
    if (rows.isEmpty) {
      rows.add({
        'signDept': null,
        'signTeam': null,
        'signUsers': <Map<String, dynamic>>[],
      });
    }
    _signeeList
      ..clear()
      ..addAll(rows);
  }

  /// 只读详情页签收组字段文本：签收部门去重拼接
  String _fillSignDeptText() {
    final names = <String>[];
    for (final signee in _signeeList) {
      final dept = signee['signDept'];
      if (dept is Map) {
        final name = _pickText(
          Map<String, dynamic>.from(dept),
          ['deptName'],
        );
        if (name.isNotEmpty && !names.contains(name)) names.add(name);
      }
    }
    return names.join('、');
  }

  /// 处理状态文本
  String _fillStatusText(dynamic fillStatus) {
    switch (_asText(fillStatus)) {
      case '0':
        return '待总成填写建议维修方案';
      case '1':
        return '待技术科填写维修方案';
      case '2':
        return '待安指填写完成节点与车间';
      case '3':
        return '已下发';
      default:
        return '待总成填写建议维修方案';
    }
  }

  /// 回填表头信息卡：机型/车号/修程修次/工序节点/排程节点/处理状态/发布时间
  Widget _buildFillHeaderInfoCard() {
    String timeText(dynamic v) {
      final s = _asText(v);
      if (s.isEmpty) return '';
      final ms = int.tryParse(s);
      if (ms != null) {
        final d = DateTime.fromMillisecondsSinceEpoch(ms);
        String two(int x) => x.toString().padLeft(2, '0');
        return '${d.year}-${two(d.month)}-${two(d.day)} '
            '${two(d.hour)}:${two(d.minute)}';
      }
      return s;
    }

    final repairName = _pickText(_fillHeader, ['repairProcName']);
    final repairTimes = _pickText(_fillHeader, ['repairTimes']);
    final items = <List<String>>[
      [
        '机型',
        _pickText(_fillHeader, ['typeName'])
      ],
      [
        '车号',
        _pickText(_fillHeader, ['trainNum'])
      ],
      ['修程修次', '$repairName $repairTimes'.trim()],
      [
        '工序节点',
        _pickText(_fillHeader, ['repairMainNodeName'])
      ],
      [
        '排程节点',
        _pickText(_fillHeader, ['scheduleNodeName'])
      ],
      ['处理状态', _fillStatusText(_fillHeader['fillStatus'])],
      ['发布时间', timeText(_fillHeader['createdTime'])],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _sectionCard(
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: items.map((e) {
              final hasValue = e[1].isNotEmpty;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${e[0]}：',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                  Text(hasValue ? e[1] : '—',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasValue
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      )),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 只读详情页点「填写」：切为可编辑模式（不跳页面，直接改状态）
  /// stage=0 建议施修方案（fillStatus=0）；stage=1 施修方案（fillStatus=1）；
  /// stage=2 编辑责任部门/完成节点（fillStatus=2）
  void _gotoFillEditable(int stage) {
    setState(() {
      _activeFillStage = stage;
      _fillEditable = true;
      // 重置签收组与签收人，按新阶段重新选择默认组
      _selectedReceiveGroup = null;
      _applyFillNoticeSignees(_fillHeader);
    });
    if (stage == 2) {
      // 阶段2额外准备：责任部门 + 工序节点选项
      _ensureStage2Options();
    }
    if (_receiveGroupOptions.isEmpty) {
      // 首次进入：懒加载签收组（加载完自动选默认组）
      _loadReceiveGroupOptions();
    } else {
      // 已加载过：直接按新阶段选默认组
      _applyDefaultReceiveGroupIfNeeded(_receiveGroupOptions);
    }
  }

  /// 默认签收组：发布模式选第一个；填写阶段0选第二个（总成流转至技术科），
  /// 阶段1选第三个（技术科流转至安指），阶段2选第四个（安指下发）
  Map<String, dynamic>? _defaultReceiveGroup(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    if (!_isFillMode) return rows[0];
    final idx = _activeFillStage + 1;
    return rows.length > idx ? rows[idx] : rows[rows.length - 1];
  }

  /// 选中并回写默认签收组（仅当前未选时）
  Future<void> _applyDefaultReceiveGroupIfNeeded(
      List<Map<String, dynamic>> rows) async {
    final g = _defaultReceiveGroup(rows);
    if (g != null && _selectedReceiveGroup == null) {
      await _applyReceiveGroupToSignees(g);
      if (!mounted) return;
      setState(() {
        _selectedReceiveGroup = g;
      });
    }
  }

  /// 只读详情页点「已读」：将消息中心通知条目标记已读
  Future<void> _markFillNoticeRead() async {
    if (_submitting) return;
    if (widget.noticeCandidates.isEmpty) {
      showToast('未获取到通知信息');
      return;
    }
    setState(() => _submitting = true);
    try {
      final params = Map<String, dynamic>.from(widget.noticeCandidates.first);
      params['status'] = 1;
      final res = await ProductApi().updateShuntingNotice([params]);
      if (!mounted) return;
      if (res != null) {
        showToast('已读');
        Navigator.of(context).pop(true);
      } else {
        showToast('操作失败');
      }
    } catch (e) {
      _logger.e('故障处置单标记已读失败: $e');
      if (!mounted) return;
      showToast('操作失败');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 可编辑模式「发送」：收集建议施修方案 + 下一签收人，调 manualPublish。
  /// send=false 时仅保存明细（保存接口待确认后启用）。
  Future<void> _submitFill({required bool send}) async {
    if (_submitting) return;

    // 确认弹窗防止误触
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(send ? '确认发送' : '确认保存'),
        content: Text(send ? '确认发送该故障处置单？发送后不可撤回。' : '确认保存当前填写内容？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: send ? Colors.blue : Colors.orange,
            ),
            child: Text(send ? '发送' : '保存'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = Global.profile.permissions?.user;
    if (user == null) {
      showToast('未获取到当前用户信息');
      return;
    }

    // 0. 提交前回查，确认 fillStatus 仍为当前阶段（防止其他端已处理导致覆盖）
    final expectedFs = _activeFillStage;
    setState(() => _submitting = true);
    try {
      final latest = await ProductApi().getRepairProcessFaultShuntingSelectAll(
        queryParametrs: {
          'code': widget.fillNoticeCode!.trim(),
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      // 剥层取 rows
      List? latestRows;
      if (latest is Map) {
        latestRows = latest['rows'] is List ? latest['rows'] as List : null;
      }
      final latestHeader = (latestRows != null &&
              latestRows.isNotEmpty &&
              latestRows.first is Map)
          ? Map<String, dynamic>.from(latestRows.first as Map)
          : null;
      final latestFs = _asText(latestHeader?['fillStatus']);
      if (latestHeader != null &&
          latestFs != '$expectedFs' &&
          latestFs.isNotEmpty) {
        if (!mounted) return;
        showToast('该单据已被其他端处理（${_fillStatusText(latestFs)}），已自动刷新');
        // 用最新数据重新加载只读详情
        final detailRows = <Map<String, dynamic>>[];
        final details = latestHeader['detailList'];
        if (details is List) {
          for (final e in details) {
            if (e is Map) {
              final row = Map<String, dynamic>.from(e);
              row['jt28DisplayText'] = _jt28Label(row);
              detailRows.add(row);
            }
          }
        }
        // 重建两套控制器
        for (final c in _fillSchemeControllers.values) {
          c.dispose();
        }
        _fillSchemeControllers.clear();
        for (final c in _fillPlanControllers.values) {
          c.dispose();
        }
        _fillPlanControllers.clear();
        for (int i = 0; i < detailRows.length; i++) {
          _fillSchemeControllers[i] = TextEditingController(
            text: _suggestedRepairSchemeLabel(detailRows[i]),
          );
          _fillPlanControllers[i] = TextEditingController(
            text: _pickFromItem(detailRows[i], ['maintenanceNotice']),
          );
        }
        // 加载映射后重建阶段2每行的责任部门/工序节点/排程节点选中值
        _syncStage2VjtFromDetail(detailRows);
        _rebuildStage2Selections(detailRows);
        final newFs = _asText(latestHeader['fillStatus']);
        setState(() {
          _fillHeader = Map<String, dynamic>.from(latestHeader);
          _jt28Options = detailRows;
          _applyFillNoticeSignees(_fillHeader);
          _fillEditable = false;
          _showFillButton =
              newFs == '0' || newFs == '1' || newFs == '2' || newFs.isEmpty;
          _submitting = false;
        });
        return;
      }
    } catch (e) {
      _logger.w('[故障处置单提交前回查] 失败，继续提交: $e');
    } finally {
      if (mounted && _submitting) {
        setState(() => _submitting = false);
      }
    }

    // 1. 将输入框/选择内容写回明细：
    //    阶段0 → vjtWebSearch.repairScheme；
    //    阶段1 → vjtWebSearch.maintenanceNotice；
    //    阶段2 → responsibleDept/repairMainNode/scheduleNode 嵌套对象
    //            + repairMainNodeCode/Name、scheduleNodeName 标量
    // 阶段2必填校验：每行责任部门/工序节点/排程节点缺一拦截
    if (_activeFillStage == 2) {
      for (int i = 0; i < _jt28Options.length; i++) {
        final sel = _fillStage2Sel[i];
        if (sel == null) {
          showToast('第${i + 1}行数据异常，请重新进入页面');
          return;
        }
        if ((sel['deptCode'] ?? '').isEmpty ||
            (sel['deptName'] ?? '').isEmpty) {
          showToast('第${i + 1}行请选择责任部门');
          return;
        }
        if ((sel['mainNodeCode'] ?? '').isEmpty ||
            (sel['mainNodeName'] ?? '').isEmpty) {
          showToast('第${i + 1}行请选择工序节点');
          return;
        }
        if ((sel['schedNodeCode'] ?? '').isEmpty ||
            (sel['schedNodeName'] ?? '').isEmpty) {
          showToast('第${i + 1}行请选择排程节点');
          return;
        }
      }
    }
    for (int i = 0; i < _jt28Options.length; i++) {
      if (_activeFillStage == 0) {
        final schemeText = _fillSchemeControllers[i]?.text.trim() ?? '';
        var vjt = _jt28Options[i]['vjtWebSearch'];
        if (vjt is! Map) {
          vjt = <String, dynamic>{};
          _jt28Options[i]['vjtWebSearch'] = vjt;
        }
        vjt['repairScheme'] = schemeText;
      } else if (_activeFillStage == 1) {
        var vjt = _jt28Options[i]['vjtWebSearch'];
        if (vjt is! Map) {
          vjt = <String, dynamic>{};
          _jt28Options[i]['vjtWebSearch'] = vjt;
        }
        vjt['maintenanceNotice'] = _fillPlanControllers[i]?.text.trim() ?? '';
      } else {
        // 阶段2：所有展示和填写都在 vjtWebSearch（字段名以 Web 源码为准）
        final sel = _fillStage2Sel[i]!;
        final raw = _fillStage2Raw[i] ?? <String, dynamic>{};
        final row = _jt28Options[i];
        var vjt = row['vjtWebSearch'];
        if (vjt is! Map) {
          vjt = <String, dynamic>{};
          row['vjtWebSearch'] = vjt;
        }
        // 责任部门
        vjt['deptId'] = sel['deptCode'];
        vjt['deptName'] = sel['deptName'];
        // 完成工序节点：mainProcessPoint=编码，processMainNode=名称
        vjt['mainProcessPoint'] = sel['mainNodeCode'];
        vjt['processMainNode'] = sel['mainNodeName'];
        // 完成排程节点
        vjt['scheduleNodeCode'] = sel['schedNodeCode'];
        vjt['scheduleNodeName'] = sel['schedNodeName'];

        // 反向组装 Web 保存 payload 中的嵌套对象（与此前 Network 截图一致）：
        // responsibleDept
        if (raw['dept'] is Map) {
          row['responsibleDept'] = raw['dept'];
        } else {
          row['responsibleDept'] = <String, dynamic>{
            'deptId': sel['deptCode'],
            'deptName': sel['deptName'],
          };
        }
        // repairMainNode + 顶层 repairMainNodeCode/Name
        if (raw['main'] is Map) {
          row['repairMainNode'] = raw['main'];
        } else {
          row['repairMainNode'] = <String, dynamic>{
            'code': sel['mainNodeCode'],
            'name': sel['mainNodeName'],
          };
        }
        row['repairMainNodeCode'] = sel['mainNodeCode'];
        row['repairMainNodeName'] = sel['mainNodeName'];
        // scheduleNode + scheduleNodeDialog + 顶层 scheduleNodeName
        final Map<String, dynamic> schedObj = raw['sched'] is Map
            ? Map<String, dynamic>.from(raw['sched'] as Map)
            : <String, dynamic>{};
        schedObj['scheduleNodeCode'] = sel['schedNodeCode'];
        schedObj['scheduleNodeName'] = sel['schedNodeName'];
        row['scheduleNode'] = schedObj;
        row['scheduleNodeDialog'] = [schedObj];
        row['scheduleNodeName'] = sel['schedNodeName'];
        // 顶层不发送这三个标量（Web payload 中没有）
        row.remove('deptId');
        row.remove('deptName');
        row.remove('scheduleNodeCode');
      }
    }

    final trainEntryCode = _pickText(_fillHeader, ['trainEntryCode']);

    // 2. detailList：移除临时字段后整体提交
    final detailList = <Map<String, dynamic>>[];
    for (final row in _jt28Options) {
      final cleaned = Map<String, dynamic>.from(row);
      cleaned.remove('jt28DisplayText');
      detailList.add(cleaned);
    }

    // 3. 发送时校验并组装下一签收人
    final shuntingNoticeList = <Map<String, dynamic>>[];
    if (send) {
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
      for (final signee in _signeeList) {
        final dept = signee['signDept'];
        final users = signee['signUsers'];
        final deptMap = dept is Map ? Map<String, dynamic>.from(dept) : null;
        final deptId = deptMap?['deptId'];
        final deptName = _pickText(deptMap, ['deptName']);
        if (users is! List) continue;
        for (final u in users) {
          if (u is! Map) continue;
          final userMap = Map<String, dynamic>.from(u);
          final auditUserId = userMap['userId'];
          final auditUserName =
              _pickText(userMap, ['nickName', 'userName', 'name']);
          if (auditUserId == null || _asText(auditUserId).isEmpty) continue;
          shuntingNoticeList.add({
            'applyUserId': user.userId,
            'applyUserName':
                ((user.nickName ?? user.userName) ?? '').toString(),
            'auditDeptId': deptId,
            'auditDeptName': deptName,
            'auditUserId': auditUserId,
            'auditUserName': auditUserName,
            'shuntingType': 25,
            'status': 0,
            if (trainEntryCode.isNotEmpty) 'trainEntryCode': trainEntryCode,
          });
        }
      }
    }

    final encode = _pickText(_fillHeader, ['encode']);

    final payload = <String, dynamic>{
      'code': widget.fillNoticeCode!.trim(),
      'detailList': detailList,
      'encode': encode,
      if (trainEntryCode.isNotEmpty) 'trainEntryCode': trainEntryCode,
      // 保存保持当前阶段；发送进入下一阶段
      'fillStatus': send ? _activeFillStage + 1 : _activeFillStage,
      if (send) 'shuntingNoticeList': shuntingNoticeList,
    };

    setState(() => _submitting = true);
    try {
      _logger.i('[故障处置单${send ? '发送' : '保存'}] payload开始');
      for (final entry in payload.entries) {
        _logger.i('  ${entry.key}: ${entry.value}');
      }
      _logger.i('[故障处置单${send ? '发送' : '保存'}] payload结束');
      // 填写模式保存和发送都走 update（操作的是已存在单据，不能走
      // manualPublish 的 INSERT，否则主键冲突 ORA-00001）；
      // 发送时 payload 已带 shuntingNoticeList + fillStatus:1
      final res =
          await ProductApi().updateRepairProcessFaultShunting(data: payload);
      final code = res is Map ? res['code'] : null;
      final innerCode =
          res is Map && res['data'] is Map ? res['data']['code'] : null;
      final success = code == 200 ||
          code == 'S_T_S003' ||
          innerCode == 200 ||
          innerCode == 'S_T_S003';
      if (!mounted) return;
      if (success) {
        showToast(send ? '发送成功' : '保存成功');
        Navigator.of(context).pop(true);
      } else {
        showToast(
            '${send ? '发送' : '保存'}失败: ${res?['message'] ?? res?['msg'] ?? '未知错误'}');
      }
    } catch (e) {
      _logger.e('故障处置单回填提交失败: $e');
      if (!mounted) return;
      showToast('提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

    if (widget.noticeType == 22) {
      final trainEntryCode =
          (widget.item.code ?? widget.item.c4c5ledger?.trainEntryCode ?? '')
              .toString()
              .trim();

      // detailList：直接使用 _jt28Options 原始数据（含 vjtWebSearch 嵌套），
      // 只移除 Flutter 端临时字段
      final detailList = <Map<String, dynamic>>[];
      for (final row in _jt28Options) {
        final cleaned = Map<String, dynamic>.from(row);
        cleaned.remove('jt28DisplayText');
        detailList.add(cleaned);
      }

      // shuntingNoticeList：签收人列表，shuntingType=25
      final shuntingNoticeList = <Map<String, dynamic>>[];
      for (final signee in _signeeList) {
        final dept = signee['signDept'];
        final users = signee['signUsers'];
        final deptMap = dept is Map ? Map<String, dynamic>.from(dept) : null;
        final deptId = deptMap?['deptId'];
        final deptName = _pickText(deptMap, ['deptName']);
        if (users is! List) continue;
        for (final u in users) {
          if (u is! Map) continue;
          final userMap = Map<String, dynamic>.from(u);
          final auditUserId = userMap['userId'];
          final auditUserName =
              _pickText(userMap, ['nickName', 'userName', 'name']);
          if (auditUserId == null || _asText(auditUserId).isEmpty) continue;
          shuntingNoticeList.add({
            'applyUserId': user.userId,
            'applyUserName':
                ((user.nickName ?? user.userName) ?? '').toString(),
            'auditDeptId': deptId,
            'auditDeptName': deptName,
            'auditUserId': auditUserId,
            'auditUserName': auditUserName,
            'shuntingType': 25,
            'status': 0,
            if (trainEntryCode.isNotEmpty) 'trainEntryCode': trainEntryCode,
          });
        }
      }

      final faultPayload = <String, dynamic>{
        'detailList': detailList,
        'shuntingNoticeList': shuntingNoticeList,
        'fillStatus': 0,
        'formCode': null,
        if (trainEntryCode.isNotEmpty) 'trainEntryCode': trainEntryCode,
      };

      setState(() => _submitting = true);
      try {
        final res = await ProductApi()
            .publishRepairProcessFaultShunting(data: faultPayload);
        final code = res is Map ? res['code'] : null;
        final innerCode =
            res is Map && res['data'] is Map ? res['data']['code'] : null;
        final success = code == 200 ||
            code == 'S_T_S003' ||
            innerCode == 200 ||
            innerCode == 'S_T_S003';
        if (!mounted) return;
        if (success) {
          showToast('提报成功');
          Navigator.of(context).pop();
        } else {
          showToast('故障处置单下发失败: ${res?['message'] ?? res?['msg'] ?? '未知错误'}');
        }
      } catch (e) {
        _logger.e('检修过程故障处置单下发失败: $e');
        if (!mounted) return;
        showToast('下发失败，请稍后重试');
      } finally {
        if (mounted) {
          setState(() => _submitting = false);
        }
      }
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
      // final techGuideText = block.techGuideController.text.trim();

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
      dynamic res;
      if (widget.noticeType == 22) {
        res = await ProductApi().saveFaultDisposalNotice(data: payload);
      } else {
        res = await ProductApi().saveMasNotice(data: payload);
      }
      final success =
          res != null && (res['code'] == 200 || res['code'] == 'S_T_S003');
      if (!mounted) return;
      if (success) {
        _showRepairProcessSuccessDialog();
      } else {
        final errorMsg = widget.noticeType == 22
            ? '故障处置单下发失败: ${res?['msg'] ?? '未知错误'}'
            : '下发失败: ${res?['msg'] ?? '未知错误'}';
        showToast(errorMsg);
      }
    } catch (e) {
      if (widget.noticeType == 22) {
        _logger.e('检修过程故障处置单下发失败: $e');
      } else {
        _logger.e('修程通知单下发失败: $e');
      }
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
              Text(
                widget.noticeType == 22 ? '检修过程故障处置单提报成功' : '修程通知单提报成功',
                style: const TextStyle(fontSize: 18),
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

  /// 阶段2：逐条卡片（序号/故障现象 + 施修方案只读 +
  /// 风险/加工/构型只读 + 责任部门/工序节点/排程节点三个选择行）
  List<Widget> _buildStage2Cards() {
    final cards = <Widget>[];
    for (int i = 0; i < _jt28Options.length; i++) {
      final item = _jt28Options[i];
      final sel = _fillStage2Sel[i]!;
      final fault = _jt28Label(item);
      final plan = _pickFromItem(item, ['maintenanceNotice']);
      final risk = _riskLevelLabel(item);
      final processing = _processingMethodByCode(item);
      final config = _faultConfigByCode(item);

      cards.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fault.isEmpty ? '（未填写故障现象）' : fault,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (plan.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(
                          text: '施修方案：',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        TextSpan(text: plan),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (risk.isNotEmpty)
                    _stage2MiniChip('风险', risk, const Color(0xFFDC2626)),
                  if (processing.isNotEmpty)
                    _stage2MiniChip('加工', processing, const Color(0xFF2563EB)),
                  if (config.isNotEmpty)
                    _stage2MiniChip('构型', config, const Color(0xFF7C3AED)),
                ],
              ),
            ),
            const Divider(height: 22, color: Color(0xFFE5E7EB)),
            // 待填写区块标题：标明下面三项是本次需要填写的内容
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '待填写信息',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '责任部门 / 工序节点 / 排程节点',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _stage2PickRow(
                    label: '责任部门',
                    value: sel['deptName'] ?? '',
                    hint: '请选择责任部门',
                    onTap: () => _pickStage2Dept(i),
                  ),
                  const SizedBox(height: 8),
                  _stage2PickRow(
                    label: '工序节点',
                    value: sel['mainNodeName'] ?? '',
                    hint: '请选择工序节点',
                    onTap: () => _pickStage2MainNode(i),
                  ),
                  const SizedBox(height: 8),
                  _stage2PickRow(
                    label: '排程节点',
                    value: sel['schedNodeName'] ?? '',
                    hint: '请选择排程节点',
                    onTap: () => _pickStage2SchedNode(i),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return cards;
  }

  /// 阶段2卡片里的只读小标签
  Widget _stage2MiniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 阶段2卡片里的选择行（右侧带状态徽标：未选=待填写，已选=已填写）
  Widget _stage2PickRow({
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final filled = value.isNotEmpty;
    return InkWell(
      onTap: _submitting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  filled ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
          borderRadius: BorderRadius.circular(8),
          color: filled ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 8),
            // 状态徽标：待填写 / 已填写
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    filled ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filled ? '已填写' : '待填写',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: filled
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: value.isEmpty
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                  fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noticeType == 22) {
      const thColW = 70.0;
      const seqW = 56.0;
      const pheW = 1.3;
      const schW = 1.1;
      const depW = 1.0;
      const nodW = 1.0;
      Widget th(String title, {double flex = 1.0, double? width}) {
        const style = TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        );
        if (width != null) {
          return SizedBox(
            width: width,
            child: Text(title,
                style: style,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          );
        }
        return Expanded(
          flex: (flex * 10).round(),
          child: Text(title,
              style: style,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
        );
      }

      Widget tdCell(Widget child,
          {double flex = 1.0,
          double? width,
          AlignmentGeometry align = Alignment.center}) {
        Widget c = align == Alignment.center
            ? Center(child: child)
            : Align(alignment: align, child: child);
        if (width != null) return SizedBox(width: width, child: c);
        return Expanded(flex: (flex * 10).round(), child: c);
      }

      Widget tdText(String s,
          {double flex = 1.0,
          double? width,
          AlignmentGeometry align = Alignment.center,
          int maxLines = 2,
          Color color = const Color(0xFF0F172A),
          FontWeight fontWeight = FontWeight.w500}) {
        return tdCell(
            Text(
              s,
              textAlign:
                  align == Alignment.center ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: fontWeight,
                height: 1.35,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: maxLines,
            ),
            flex: flex,
            width: width,
            align: align);
      }

      // 回填模式且非只读时=填写建议施修方案：仅三列（序号/故障现象/建议施修方案输入框）
      final editableScheme = _isFillMode && !_fillReadOnly;

      final header = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: editableScheme
                ? [
                    th('序号', width: seqW),
                    th('故障现象', flex: pheW),
                    th(_activeFillStage == 0 ? '建议施修方案' : '施修方案', flex: 2.2),
                  ]
                : [
                    th('序号', width: seqW),
                    th('故障现象', flex: pheW),
                    th('施修方案', flex: schW),
                    th('责任车间', flex: depW),
                    th('完成节点', flex: nodW),
                    const SizedBox(width: thColW - 16),
                  ],
          ),
        ),
      );

      final rows = <Widget>[];
      for (int i = 0; i < _jt28Options.length; i++) {
        final item = _jt28Options[i];
        final seq = i + 1;
        final fault = _jt28Label(item);
        final scheme = _suggestedRepairSchemeLabel(item);
        final dept = _responsibleDeptByCode(item);
        final completeProc = _completeProcessByCode(item);
        final node = _scheduleNodeByCode(item);
        final isExpand = _faultCardExpanded.contains(i);

        final rowHeader = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: editableScheme
              ? null
              : () {
                  setState(() {
                    if (isExpand) {
                      _faultCardExpanded.remove(i);
                    } else {
                      _faultCardExpanded.add(i);
                    }
                  });
                },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isExpand
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
              borderRadius:
                  isExpand ? BorderRadius.zero : BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isExpand
                      ? const Color(0xFF3B82F6).withOpacity(0.10)
                      : const Color(0xFF0F172A).withOpacity(0.03),
                  blurRadius: isExpand ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: seqW,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1D4ED8),
                              Color(0xFF2563EB),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withOpacity(0.24),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$seq',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  tdText(fault.isEmpty ? '—' : fault,
                      flex: pheW,
                      align: Alignment.centerLeft,
                      maxLines: 3,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A)),
                  if (editableScheme)
                    tdCell(
                      TextField(
                        controller: _activeFillStage == 0
                            ? _fillSchemeControllers[i]
                            : _fillPlanControllers[i],
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText:
                              _activeFillStage == 0 ? '请输入建议施修方案' : '请输入施修方案',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFBFDBFE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                      flex: 2.2,
                      align: Alignment.centerLeft,
                    )
                  else
                    tdText(scheme.isEmpty ? '—' : scheme,
                        flex: schW,
                        align: Alignment.centerLeft,
                        maxLines: 3,
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600),
                  if (!editableScheme) ...[
                    tdText(dept.isEmpty ? '—' : dept,
                        flex: depW,
                        align: Alignment.center,
                        maxLines: 2,
                        color: dept.isEmpty
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600),
                    tdText(node.isEmpty ? '—' : node,
                        flex: nodW,
                        align: Alignment.center,
                        maxLines: 2,
                        color: node.isEmpty
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF9A3412),
                        fontWeight: FontWeight.w600),
                    SizedBox(
                      width: thColW - 16,
                      child: Center(
                        child: AnimatedRotation(
                          turns: isExpand ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isExpand
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 20,
                              color: isExpand
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        Widget expandBody = const SizedBox.shrink();
        if (isExpand) {
          final reporter = _reporterLabel(item);
          final reportTime = _reportTimeLabel(item);
          final repairPicGroup = _repairPictureGroupId(item);
          final longRepairScheme = _longRepairSchemeLabel(item);
          final riskLevel = _riskLevelLabel(item);
          final processing = _processingMethodByCode(item);
          final config = _faultConfigByCode(item);
          final workpieceCoeff = _workpieceCoefficientLabel(item);
          final hasPic = repairPicGroup.trim().isNotEmpty;
          final hasLong = longRepairScheme.trim().isNotEmpty;

          Widget kvRowL({
            required String label,
            required String value,
            IconData? icon,
            Color? labelColor,
          }) {
            if (value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              size: 12,
                              color: labelColor ?? const Color(0xFF64748B)),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: labelColor ?? const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget chip({
            required String label,
            required String value,
            required Color bg,
            required Color fg,
            IconData? icon,
          }) {
            if (value.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: fg),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      '$label：$value',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          }

          expandBody = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              border: Border.all(
                color: const Color(0xFF93C5FD),
                width: 1,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade500),
                    Text(
                      reporter.isEmpty ? '匿名' : reporter,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey.shade500),
                    Text(
                      reportTime.isEmpty ? '—' : reportTime,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      onPressed: hasPic
                          ? () {
                              PhotoPreviewDialog.show(
                                context,
                                repairPicGroup,
                                ProductApi().getFaultVideoAndImage,
                              );
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: hasPic
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        foregroundColor: hasPic
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.image_outlined, size: 15),
                      label: Text(
                        hasPic ? '查看报修图片' : '暂无报修图片',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    if (riskLevel.isNotEmpty)
                      chip(
                        label: '风险等级',
                        value: riskLevel,
                        bg: _riskChipColor(riskLevel),
                        fg: _riskChipTextColor(riskLevel),
                      ),
                    if (processing.isNotEmpty)
                      chip(
                        label: '加工方法',
                        value: processing,
                        bg: _processingChipColor(processing),
                        fg: _processingChipTextColor(processing),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (hasLong) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '施修方案长文本',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          longRepairScheme,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kvRowL(
                        label: '提报人',
                        value: reporter,
                        icon: Icons.person_rounded,
                        labelColor: const Color(0xFF7C3AED),
                      ),
                      kvRowL(
                        label: '提报时间',
                        value: reportTime,
                        icon: Icons.access_time_rounded,
                        labelColor: const Color(0xFF7C3AED),
                      ),
                      kvRowL(
                        label: '加工方法',
                        value: processing,
                        icon: Icons.build_circle_outlined,
                      ),
                      kvRowL(
                        label: '故障构型',
                        value: config,
                        icon: Icons.settings_input_component_outlined,
                      ),
                      kvRowL(
                        label: '责任部门',
                        value: dept,
                        icon: Icons.account_tree_outlined,
                      ),
                      kvRowL(
                        label: '完成工序',
                        value: completeProc,
                        icon: Icons.rule_outlined,
                      ),
                      kvRowL(
                        label: '完成节点',
                        value: node,
                        icon: Icons.schedule_outlined,
                      ),
                      kvRowL(
                        label: '活检系数',
                        value: workpieceCoeff,
                        icon: Icons.straighten_rounded,
                        labelColor: const Color(0xFF0F766E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rowHeader,
              expandBody,
            ],
          ),
        ));
      }

      return WillPopScope(
        onWillPop: () async {
          // 编辑模式（含阶段2编辑责任部门/完成节点）物理返回：
          // 只退回故障处置单详情（只读），恢复签收组为查询结果，不退出页面
          if (_isFillMode && !_fillReadOnly) {
            setState(() {
              _fillEditable = false;
              _selectedReceiveGroup = null;
              _applyFillNoticeSignees(_fillHeader);
            });
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isFillMode
                ? (_fillReadOnly
                    ? '故障处置单详情'
                    : (_activeFillStage == 0
                        ? '填写建议施修方案'
                        : (_activeFillStage == 1 ? '填写施修方案' : '编辑责任部门/完成节点')))
                : '检修过程故障处置单'),
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
                        _isFillMode
                            ? _pickText(_fillHeader, ['formName'])
                            : _pageTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '故障明细',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '共 ${_jt28Options.length} 条',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 机型/车号等信息卡仅只读详情展示；填写页直接显示故障现象表格
              if (_isFillMode && _fillReadOnly) _buildFillHeaderInfoCard(),
              if (_loadingJt28 || _loadingFillNotice)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_jt28Options.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      '暂无故障数据',
                      style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else if (_isFillMode &&
                  !_fillReadOnly &&
                  _activeFillStage == 2) ...[
                // 阶段2：卡片式逐条编辑责任部门/工序节点/排程节点
                ..._buildStage2Cards(),
              ] else ...[
                header,
                ...rows,
              ],
              // 签收组/签收人：提报模式与回填模式都显示；回填只读时禁用编辑
              _sectionCard(
                children: [
                  _selectField(
                    label: '签收组',
                    value: _isFillMode && _fillReadOnly
                        ? _fillSignDeptText()
                        : (_selectedReceiveGroup == null
                            ? ''
                            : _receiveGroupLabel(_selectedReceiveGroup)),
                    hintText: _loadingReceiveGroup ? '签收组加载中...' : '请选择签收组',
                    onTap: () async {
                      if (_isFillMode && _fillReadOnly) {
                        showToast('请点「$_fillActionButtonLabel」后再选择签收组');
                        return;
                      }
                      if (_loadingReceiveGroup) {
                        showToast('签收组加载中，请稍后');
                        return;
                      }
                      // 懒加载：填写页初始未加载签收组，首次点击时拉取
                      if (_receiveGroupOptions.isEmpty) {
                        await _loadReceiveGroupOptions();
                        if (!mounted) return;
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
                        _selectedReceiveGroup =
                            Map<String, dynamic>.from(selected);
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (_signeeLockedByReceiveGroup) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '已由签收组自动回写',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (!(_isFillMode && _fillReadOnly))
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
                    final deptId =
                        dept is Map ? _parseId(dept['deptId']) : null;
                    final teamId =
                        team is Map ? _parseId(team['deptId']) : null;
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
                                      Map<String, dynamic>.from(dept),
                                      ['deptName'],
                                    )
                                  : '',
                              maxLines: 2,
                              onTap: () async {
                                if (_isFillMode && _fillReadOnly) {
                                  showToast(
                                      '请点「$_fillActionButtonLabel」后再选择签收人');
                                  return;
                                }
                                if (_signeeLockedByReceiveGroup) {
                                  showToast(
                                    '签收人已按签收组自动回写，不能手动修改',
                                  );
                                  return;
                                }
                                // 懒加载部门列表
                                if (_deptList.isEmpty) {
                                  await _loadDepts();
                                  if (!mounted) return;
                                }
                                final selected =
                                    await _showSearchableListDialog(
                                  title: '选择部门',
                                  items: _deptList,
                                  labelKey: 'deptName',
                                );
                                if (selected == null || !mounted) return;
                                setState(() {
                                  signee['signDept'] = selected;
                                  signee['signTeam'] = null;
                                  signee['signUsers'] =
                                      <Map<String, dynamic>>[];
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
                                      Map<String, dynamic>.from(team),
                                      ['deptName'],
                                    )
                                  : '',
                              maxLines: 2,
                              onTap: () async {
                                if (_isFillMode && _fillReadOnly) {
                                  showToast(
                                      '请点「$_fillActionButtonLabel」后再选择签收人');
                                  return;
                                }
                                if (_signeeLockedByReceiveGroup) {
                                  showToast(
                                    '签收人已按签收组自动回写，不能手动修改',
                                  );
                                  return;
                                }
                                if (deptId == null) {
                                  showToast('请先选择部门');
                                  return;
                                }
                                final selected =
                                    await _showSearchableListDialog(
                                  title: '选择班组',
                                  items: teamOptions,
                                  labelKey: 'deptName',
                                );
                                if (selected == null || !mounted) return;
                                setState(() {
                                  signee['signTeam'] = selected;
                                  signee['signUsers'] =
                                      <Map<String, dynamic>>[];
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
                                if (_isFillMode && _fillReadOnly) {
                                  showToast(
                                      '请点「$_fillActionButtonLabel」后再选择签收人');
                                  return;
                                }
                                if (_signeeLockedByReceiveGroup) {
                                  showToast(
                                    '签收人已按签收组自动回写，不能手动修改',
                                  );
                                  return;
                                }
                                final targetDeptId = teamId ?? deptId;
                                if (targetDeptId == null) {
                                  showToast('请先选择部门或班组');
                                  return;
                                }
                                await _loadUsersForDept(targetDeptId);
                                final userOptions =
                                    _usersByDeptId[targetDeptId] ??
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
                          if (_signeeList.length > 1 &&
                              !(_isFillMode && _fillReadOnly)) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                if (_signeeLockedByReceiveGroup) {
                                  showToast(
                                    '已按签收组自动回写签收人，不能手动删除',
                                  );
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
              child: _isFillMode
                  ? (_fillReadOnly
                      ? Row(
                          children: [
                            if (_showFillButton) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () {
                                          // 按当前处理状态进入对应填写阶段：
                                          // 0=建议施修方案 1=施修方案
                                          // 2=责任部门/完成节点（安指派工）
                                          final fs = _asText(
                                              _fillHeader['fillStatus']);
                                          _gotoFillEditable(fs == '2'
                                              ? 2
                                              : (fs == '1' ? 1 : 0));
                                        },
                                  // 安全生产指挥中心（fillStatus=2）按钮显示「派工」
                                  child: Text(_fillActionButtonLabel),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        // 取消填写：回到只读详情，不退出页面；
                                        // 恢复签收组/签收人为查询结果
                                        setState(() {
                                          _fillEditable = false;
                                          _selectedReceiveGroup = null;
                                          _applyFillNoticeSignees(_fillHeader);
                                        });
                                      },
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                onPressed: _submitting
                                    ? null
                                    : () => _submitFill(send: false),
                                child: Text(_submitting ? '保存中...' : '保存'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _submitFill(send: true),
                                child: Text(_submitting ? '发送中...' : '发送'),
                              ),
                            ),
                          ],
                        ))
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _canConfirm ? _submit : null,
                            child: Text(_submitting ? '提报中...' : '提报'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    final faultValue = _jt28Label(_selectedJt28);
    final oldProcessNode = _currentProcessNodeName;

    return WillPopScope(
      onWillPop: () async {
        if (_isFillMode && !_fillReadOnly) {
          setState(() {
            _fillEditable = false;
            _selectedReceiveGroup = null;
            _applyFillNoticeSignees(_fillHeader);
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.noticeType == 22 ? '检修过程故障处置单' : '修程通知单',
          ),
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
                        value: oldProcessNode,
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
                                    block.riskLevelText = _riskLevelLabel(
                                        block.selectedRiskLevel);
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
                              selectedValue:
                                  block.selectedConfig?['configCode'],
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
                      _selectedReceiveGroup =
                          Map<String, dynamic>.from(selected);
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (_signeeLockedByReceiveGroup) ...[
                      const SizedBox(width: 8),
                      const Text(
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
                                ? _pickText(Map<String, dynamic>.from(dept),
                                    ['deptName'])
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
                                ? _pickText(Map<String, dynamic>.from(team),
                                    ['deptName'])
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
                              final userOptions =
                                  _usersByDeptId[targetDeptId] ??
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
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
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
