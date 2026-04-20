import 'package:jcjx_phone/routes/production/train_shunting_package_page.dart';

import '../index.dart';
import '../models/progress.dart';
import 'production/investigateInfo.dart';

abstract class ShuntingNoticeApi {
  Future<dynamic> getShuntingNotice({Map<String, dynamic>? queryParametrs});
  Future<dynamic> updateShuntingNotice(List<dynamic> queryParametrs);
}

class DefaultShuntingNoticeApi implements ShuntingNoticeApi {
  final ProductApi _api;
  DefaultShuntingNoticeApi([ProductApi? api]) : _api = api ?? ProductApi();

  @override
  Future<dynamic> getShuntingNotice({Map<String, dynamic>? queryParametrs}) {
    return _api.getShuntingNotice(queryParametrs: queryParametrs);
  }

  @override
  Future<dynamic> updateShuntingNotice(List<dynamic> queryParametrs) {
    return _api.updateShuntingNotice(queryParametrs);
  }
}

/// 消息中心页面
class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({Key? key, this.onMessageCountChanged}) : super(key: key);

  /// 消息列表刷新后回调，用于更新底部角标数量
  final void Function(int count)? onMessageCountChanged;

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  bool _loading = true;
  List<dynamic> _list = [];

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    _fetchMessageData();
  }

  /// 一次性获取全部消息（不分页）
  Future<void> _fetchMessageData() async {
    setState(() {
      _loading = true;
      _list = [];
    });
    try {
      final res = await ProductApi().getMessageInfo(
        queryParametrs: {
          'type': [8, 21], // 包含调令与售后故障录入通知
          'auditDTO': {},
        },
      );
      final data = res is Map ? res : <String, dynamic>{};
      final list = data['sysMessageVO'] is List
          ? List<dynamic>.from(data['sysMessageVO'] as List)
          : <dynamic>[];
      final messageCount = (data['count'] as num?)?.toInt() ?? list.length;
      
      // 获取未读调车通知的数量 (status: 0 代表未读)
      int shuntingUnreadCount = 0;
      if (Global.profile.permissions == null) {
        final p = await LoginApi().getpermissions();
        if (p.code == 200 && mounted) {
          Global.profile.permissions = p;
        }
      }
      final user = Global.profile.permissions?.user;
      final resShunting = await DefaultShuntingNoticeApi().getShuntingNotice(
        queryParametrs: {
          'auditUserName': user?.nickName ?? user?.userName ?? '',
          'auditUserId': user?.userId ?? '',
          'status': 0,
          'pageNum': 1,
          'pageSize': 1, // 只需要 total，不需要拉取具体列表
        },
      );
      final dataShunting = resShunting is Map ? resShunting as Map : <String, dynamic>{};
      final shuntingTotal = dataShunting['total'];
      if (shuntingTotal is num) {
        shuntingUnreadCount = shuntingTotal.toInt();
      } else {
        shuntingUnreadCount = int.tryParse(shuntingTotal?.toString() ?? '') ?? 0;
      }

      final totalCount = shuntingUnreadCount > 0 ? shuntingUnreadCount : messageCount;

      if (mounted) {
        setState(() {
          _loading = false;
          _list = list;
        });
        widget.onMessageCountChanged?.call(totalCount);
      }
    } catch (e) {
      logger.e(e);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _onTapMessage(Map<String, dynamic> message) async {
    final st = message['shuntingType'];
    final isInvestigate = st == 4 || st == '4';
    final shuntingCode = message['shuntingCode']?.toString() ?? message['code']?.toString();
    if (isInvestigate && shuntingCode != null && shuntingCode.isNotEmpty) {
      final shuntingItem = {'shuntingCode': shuntingCode};
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PlanListPage(
            repairItem: RepairItem(),
            shuntingItem: shuntingItem,
          ),
        ),
      );
      await _fetchMessageData();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MessageDetailPage(message: message),
      ),
    );
    await _fetchMessageData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('消息中心'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMessageData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_list.isEmpty && !_loading)
                    const SliverFillRemaining(
                      child: Center(child: Text('暂无消息')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _list[index];
                            final map = item is Map
                                ? Map<String, dynamic>.from(
                                    (item as Map).map(
                                      (k, v) => MapEntry(k.toString(), v),
                                    ),
                                  )
                                : <String, dynamic>{};
                            final content = map['model'] ??
                                map['messageContent'] ??
                                map['content'] ??
                                '';
                            final number = map['number2'] ??
                                map['number'] ??
                                map['createTime'] ??
                                '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 1,
                                shadowColor: Colors.black26,
                                child: InkWell(
                                  onTap: () => _onTapMessage(map),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none,
                                            color: Colors.lightBlue,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                content.toString().isEmpty
                                                    ? '消息 ${index + 1}'
                                                    : content.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (number
                                                  .toString()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  number.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _list.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 消息详情页（点击卡片跳转），并展示调车通知 getShuntingNotice 结果
class MessageDetailPage extends StatefulWidget {
  final Map<String, dynamic> message;
  final ShuntingNoticeApi? shuntingNoticeApi;

  const MessageDetailPage({
    Key? key,
    required this.message,
    this.shuntingNoticeApi,
  }) : super(key: key);

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  static const int _pageSize = 10;
  bool _shuntingLoading = true;
  bool _shuntingLoadingMore = false;
  int _shuntingPageNum = 1;
  int? _shuntingTotal;
  List<dynamic> _shuntingRows = [];
  int _shuntingStatus = 0;
  int? _shuntingUnreadTotal;
  int? _shuntingReadTotal;
  late final ShuntingNoticeApi _shuntingApi;

  @override
  void initState() {
    super.initState();
    _shuntingApi = widget.shuntingNoticeApi ?? DefaultShuntingNoticeApi();
    _loadShuntingNotice();
    _loadShuntingCounts();
  }

  var logger = AppLogger.logger;

  Future<void> _setShuntingStatus(int status) async {
    if (_shuntingStatus == status) return;
    setState(() {
      _shuntingStatus = status;
      _shuntingLoading = true;
      _shuntingLoadingMore = false;
      _shuntingPageNum = 1;
      _shuntingTotal = null;
      _shuntingRows = [];
    });
    await _loadShuntingNotice();
  }

  Future<void> _loadShuntingCounts() async {
    try {
      if (Global.profile.permissions == null) {
        final p = await LoginApi().getpermissions();
        if (p.code == 200 && mounted) {
          Global.profile.permissions = p;
        }
      }
      final user = Global.profile.permissions?.user;
      final base = {
        'auditUserName': user?.nickName ?? user?.userName ?? '',
        'auditUserId': user?.userId ?? '',
        'pageNum': 1,
        'pageSize': 1,
      };
      final results = await Future.wait([
        _shuntingApi.getShuntingNotice(
          queryParametrs: {...base, 'status': 0, 'type': [21]},
        ),
        _shuntingApi.getShuntingNotice(
          queryParametrs: {...base, 'status': 1, 'type': [21]},
        ),
      ]);
      if (!mounted) return;
      int? parseTotal(dynamic res) {
        final data = res is Map ? res as Map : <String, dynamic>{};
        final total = data['total'];
        if (total is num) return total.toInt();
        return int.tryParse(total?.toString() ?? '');
      }

      setState(() {
        _shuntingUnreadTotal = parseTotal(results[0]);
        _shuntingReadTotal = parseTotal(results[1]);
      });
    } catch (_) {}
  }

  Future<void> _loadShuntingNotice() async {
    try {
      if (Global.profile.permissions == null) {
        final p = await LoginApi().getpermissions();
        if (p.code == 200 && mounted) {
          Global.profile.permissions = p;
        }
      }
      final user = Global.profile.permissions?.user;
      final queryParametrs = {
        'auditUserName': user?.nickName ?? user?.userName ?? '',
        'auditUserId': user?.userId ?? '',
        'status': _shuntingStatus,
        'type': [21],
        'pageNum': 1,
        'pageSize': _pageSize,
      };
      logger.i(queryParametrs);
      final res = await _shuntingApi.getShuntingNotice(
        queryParametrs: queryParametrs,
      );
      if (mounted) {
        final data = res is Map ? res as Map : <String, dynamic>{};
        final rows = data['rows'];
        final total = data['total'];
        setState(() {
          _shuntingLoading = false;
          _shuntingPageNum = 1;
          _shuntingRows = rows is List ? List<dynamic>.from(rows) : [];
          _shuntingTotal = total is num ? total.toInt() : int.tryParse(total?.toString() ?? '');
          if (_shuntingStatus == 0) {
            _shuntingUnreadTotal = _shuntingTotal;
          } else if (_shuntingStatus == 1) {
            _shuntingReadTotal = _shuntingTotal;
          }
        });
      }
    } catch (e) {
      AppLogger.logger.e(e);
      if (mounted) {
        setState(() {
          _shuntingLoading = false;
          _shuntingRows = [];
          _shuntingTotal = null;
        });
      }
    }
  }

  Future<void> _loadShuntingNoticeMore() async {
    if (_shuntingLoadingMore ||
        _shuntingTotal == null ||
        _shuntingRows.length >= _shuntingTotal!) return;
    try {
      setState(() => _shuntingLoadingMore = true);
      final user = Global.profile.permissions?.user;
      final nextPage = _shuntingPageNum + 1;
      final queryParametrs = {
        'auditUserName': user?.nickName ?? user?.userName ?? '',
        'auditUserId': user?.userId ?? '',
        'status': _shuntingStatus,
        'type': [21],
        'pageNum': nextPage,
        'pageSize': _pageSize,
      };
      final res = await _shuntingApi.getShuntingNotice(
        queryParametrs: queryParametrs,
      );
      if (mounted) {
        final data = res is Map ? res as Map : <String, dynamic>{};
        final rows = data['rows'];
        final newRows = rows is List ? List<dynamic>.from(rows) : <dynamic>[];
        setState(() {
          _shuntingLoadingMore = false;
          _shuntingPageNum = nextPage;
          _shuntingRows = [..._shuntingRows, ...newRows];
        });
      }
    } catch (e) {
      AppLogger.logger.e(e);
      if (mounted) {
        setState(() => _shuntingLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final title = message['model'] ??
        message['messageTitle'] ??
        message['title'] ??
        '消息详情';

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            _buildShuntingNoticeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildShuntingNoticeSection() {
    if (_shuntingLoading) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_shuntingRows.isEmpty && _shuntingTotal == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无调车通知数据',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }
    final totalNum = _shuntingTotal ?? 0;
    final hasMore = totalNum > _shuntingRows.length;
    final unreadText = _shuntingUnreadTotal == null
        ? '未读'
        : '未读(${_shuntingUnreadTotal ?? 0})';
    final readText =
        _shuntingReadTotal == null ? '已读' : '已读(${_shuntingReadTotal ?? 0})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(unreadText),
                  selected: _shuntingStatus == 0,
                  onSelected: (_) => _setShuntingStatus(0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(readText),
                  selected: _shuntingStatus == 1,
                  onSelected: (_) => _setShuntingStatus(1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_shuntingRows.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _shuntingStatus == 0 ? '暂无未读通知' : '暂无已读通知',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          )
        else
          Column(
            children: List.generate(_shuntingRows.length, (index) {
              final item = _shuntingRows[index];
              final itemMap = item is Map
                  ? Map<String, dynamic>.from(
                      (item as Map).map((k, v) => MapEntry(k.toString(), v)),
                    )
                  : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildShuntingCardWithTap(itemMap),
              );
            }),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _shuntingLoadingMore ? null : _loadShuntingNoticeMore,
                child: _shuntingLoadingMore
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('加载更多'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShuntingCardWithTap(Map<String, dynamic> itemMap) {
    final st = itemMap['shuntingType'];
    final isInvestigate = st == 4 || st == '4';
    final shuntingCode = itemMap['shuntingCode']?.toString() ?? itemMap['code']?.toString();
    if (isInvestigate && shuntingCode != null && shuntingCode.isNotEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onViewShunting(itemMap),
          borderRadius: BorderRadius.circular(12),
          child: _shuntingNoticeCard(itemMap),
        ),
      );
    }
    return _shuntingNoticeCard(itemMap);
  }

  void _onViewShunting(Map<String, dynamic> itemMap) {
    final st = itemMap['shuntingType'];
    final isInvestigate = st == 4 || st == '4';
    final shuntingCode = itemMap['shuntingCode']?.toString() ?? itemMap['code']?.toString();
    if (isInvestigate && shuntingCode != null && shuntingCode.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PlanListPage(
            repairItem: RepairItem(),
            shuntingItem: {'shuntingCode': shuntingCode},
          ),
        ),
      );
    }
    if (st == 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const TrainShuntingPackagePage(),
        ),
      );
    }
  }

  Future<void> _onCompleteShunting(Map<String, dynamic> itemMap) async {
    try {
      final params = Map<String, dynamic>.from(itemMap);
      params['status'] = 1;
      final res = await _shuntingApi.updateShuntingNotice([params]);
      if (mounted) {
        showToast(res != null ? '已读' : '操作失败');
        if (res != null) {
          await _loadShuntingNotice();
          await _loadShuntingCounts(); // 更新详情页内部数字
          
          // 通知外层重新计算并更新总消息数量（含桌面角标）
          if (mounted) {
            final state = context.findAncestorStateOfType<_MessageCenterPageState>();
            if (state != null) {
              state._fetchMessageData();
            }
          }
        }
      }
    } catch (e) {
      logger.e(e);
      if (mounted) showToast('操作失败');
    }
  }

  static const Map<String, String> _shuntingFieldLabels = {
    'content': '调令内容',
    'applyTime': '发布时间',
    'applyUserName': '调令发布人',
    'auditUserName': '签收人',
    'auditDeptName': '签收部门',
    'status': '状态',
    'shuntingType': '通知单类型',
    'trainNum': '车号',
    'typeName': '机型',
    'auditResult': '评审意见',
    // 新增售后故障录入通知专属字段
    'faultPhenomenon': '故障现象',
    'reportUser': '提报人',
    'reportTime': '提报时间',
  };

  static const List<String> _shuntingFieldOrder = [
    'content',
    'faultPhenomenon', // 故障现象
    'applyTime',
    'reportTime', // 提报时间
    'applyUserName',
    'reportUser', // 提报人
    'auditUserName',
    'auditDeptName',
    'trainNum',
    'typeName',
    'status',
    'shuntingType',
    'auditResult',
  ];

  /// 以下字段即使值为空也显示名称
  static const Set<String> _shuntingAlwaysShowFields = {
    'trainNum',
    'typeName',
    'auditResult',
  };

  static const Set<String> _shuntingTimeFields = {
    'createdTime',
    'updatedTime',
    'applyTime',
    'reportTime', // 将新增的提报时间也加入时间格式化列表
  };

  /// 调车类型数字与中文对应（与后台通知单类型一致）
  static const Map<String, String> _shuntingTypeLabels = {
    '0': '调车通知单',
    '1': '检修计划',
    '2': '临修通知单',
    '3': '机车配置签收',
    '4': '调查清单',
    '5': '机车入段通知单',
    '6': '作业包下发通知单',
    '7': '作业人员修改通知单',
    '8': '转序通知单',
    '9': '轮径修改通知单',
    '10': '轮径尺寸通知单',
    '11': '轮径能通知单',
    '12': '修改派工通知单',
    '13': '修程通知单',
    '14': '旅行通知单',
    '15': '旅行申请单',
    '16': '计划排产通知单',
    '17': '售后服务通知单',
    '18': '人员变更',
    '19': '物料变更',
    '20': '机统28提报',
    '21': '售后故障录入通知',
  };

  String _formatShuntingValue(String key, dynamic v) {
    final isEmpty = v == null || v.toString().trim().isEmpty;
    if (isEmpty && _shuntingAlwaysShowFields.contains(key)) return '-';
    if (v == null) return '';
    if (_shuntingTimeFields.contains(key)) {
      final str = v.toString();
      final ms = int.tryParse(str);
      if (ms != null && ms > 1000000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      }
      if (str.length >= 19) return str;
      return str;
    }
    if (key == 'status') {
      const statusMap = {'0': '未完成', '1': '已通过', '2': '已驳回'};
      return statusMap[v.toString()] ?? v.toString();
    }
    if (key == 'shuntingType') {
      return _shuntingTypeLabels[v.toString()] ?? v.toString();
    }
    return v.toString();
  }

  Widget _shuntingNoticeCard(Map<String, dynamic> map) {
    final entries = <String, dynamic>{};
    for (final k in map.keys) {
      final v = map[k];
      if (v != null && v.toString().isNotEmpty) {
        entries[k.toString()] = v;
      }
    }
    for (final k in _shuntingAlwaysShowFields) {
      if (!entries.containsKey(k)) {
        entries[k] = null;
      }
    }
    if (entries.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                map.toString(),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _onViewShunting(map),
                    child: const Text('查看'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _shuntingStatus == 0
                        ? () => _confirmCompleteShunting(map)
                        : null,
                    child: const Text('已读'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final orderedKeys = <String>[];
    for (final k in _shuntingFieldOrder) {
      if (entries.containsKey(k)) orderedKeys.add(k);
    }
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...orderedKeys.map<Widget>((k) {
              final label = _shuntingFieldLabels[k] ?? k;
              final value = _formatShuntingValue(k, entries[k]);
              final rawVal = entries[k]?.toString() ?? '';
              Color? valueColor;
              if (k == 'status') {
                if (rawVal == '0') valueColor = Colors.orange;
                else if (rawVal == '1') valueColor = Colors.green;
                else if (rawVal == '2') valueColor = Colors.red;
              } else if (k == 'shuntingType') {
                valueColor = Colors.blue;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: valueColor ?? Colors.black87,
                          height: 1.4,
                          fontWeight: valueColor != null ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _onViewShunting(map),
                  child: const Text('查看'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _shuntingStatus == 0
                      ? () => _confirmCompleteShunting(map)
                      : null,
                  child: const Text('已读'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCompleteShunting(Map<String, dynamic> itemMap) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认已读'),
            content: const Text('是否确认将该通知单标记为已读？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _onCompleteShunting(itemMap);
  }
}
