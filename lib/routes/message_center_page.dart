import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jcjx_phone/routes/production/jt28_dispatch_page.dart';
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
    final isAfterSaleService = st == 17 || st == '17';
    final isRepairProc = st == 13 || st == '13';
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
    if (isAfterSaleService && shuntingCode != null && shuntingCode.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AfterSaleServiceNoticePage(shuntingCode: shuntingCode),
        ),
      );
      await _fetchMessageData();
      return;
    }
    if (isRepairProc) {
      // 修程通知单不响应跳转
      return;
    }
    if (st == 0 || st == '0') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const TrainShuntingPackagePage(),
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
        // 'type': [21],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onViewShunting(itemMap),
        borderRadius: BorderRadius.circular(12),
        child: _shuntingNoticeCard(itemMap),
      ),
    );
  }

  Future<void> _onViewShunting(Map<String, dynamic> itemMap) async {
    final st = itemMap['shuntingType'];
    final isInvestigate = st == 4 || st == '4';
    final isAfterSaleService = st == 17 || st == '17';
    final isAfterSaleFault = st == 21 || st == '21';
    final isChangeMainNode = st == 8 || st == '8';
    final isRepairProc = st == 13 || st == '13';
    final shuntingCode = itemMap['shuntingCode']?.toString() ?? itemMap['code']?.toString();

    if (isRepairProc && shuntingCode?.isNotEmpty == true) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => RepairProcessNoticeDetailPage(
            shuntingCode: shuntingCode ?? '',
            noticeItem: itemMap,
          ),
        ),
      );
      if (changed == true) {
        await _loadShuntingNotice();
        await _loadShuntingCounts();
        if (mounted) {
          final state = context.findAncestorStateOfType<_MessageCenterPageState>();
          if (state != null) {
            state._fetchMessageData();
          }
        }
      }
      return;
    }

    if (isInvestigate && shuntingCode != null && shuntingCode.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PlanListPage(
            repairItem: RepairItem(),
            shuntingItem: {'shuntingCode': shuntingCode},
          ),
        ),
      );
      return;
    }
    if (isAfterSaleService && shuntingCode != null && shuntingCode.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AfterSaleServiceNoticePage(shuntingCode: shuntingCode),
        ),
      );
      return;
    }
    if (isAfterSaleFault && shuntingCode?.isNotEmpty == true) {
      final changed = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AfterSaleFaultNoticePage(
            shuntingCode: shuntingCode ?? '',
            noticeItem: itemMap,
          ),
        ),
      );
      if (changed == true) {
        await _loadShuntingNotice();
        await _loadShuntingCounts();
        if (mounted) {
          final state = context.findAncestorStateOfType<_MessageCenterPageState>();
          if (state != null) {
            state._fetchMessageData();
          }
        }
      }
      return;
    }
    if (isChangeMainNode && shuntingCode != null && shuntingCode.isNotEmpty) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => ChangeMainNodeShuntingPage(
            shuntingCode: shuntingCode,
            noticeItem: itemMap,
          ),
        ),
      );
      if (changed == true) {
        await _loadShuntingNotice();
        await _loadShuntingCounts();
        if (mounted) {
          final state = context.findAncestorStateOfType<_MessageCenterPageState>();
          if (state != null) {
            state._fetchMessageData();
          }
        }
      }
      return;
    }
    if (st == 0 || st == '0') {
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
    'auditTime': '签收时间',
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
    'auditTime',
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
    'auditTime',
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

class ChangeMainNodeShuntingPage extends StatefulWidget {
  final String shuntingCode;
  final Map<String, dynamic> noticeItem;

  const ChangeMainNodeShuntingPage({
    super.key,
    this.shuntingCode = '',
    this.noticeItem = const <String, dynamic>{},
  });

  @override
  State<ChangeMainNodeShuntingPage> createState() => _ChangeMainNodeShuntingPageState();
}

class _ChangeMainNodeShuntingPageState extends State<ChangeMainNodeShuntingPage> {
  final _logger = AppLogger.logger;
  bool _loading = true;
  bool _markingRead = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _rows = [];
    });
    try {
      final rows = await ProductApi().getChangeMainNodeShunting(
        queryParametrs: {'code': widget.shuntingCode},
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rows = [];
      });
      showToast('获取转序通知单失败');
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = _text(map[key]);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _requiredText(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _binaryStatusText(String value) {
    final v = value.trim();
    if (v == '1') return '已下发';
    if (v == '0') return '未下发';
    return v;
  }

  String _trainDisplay(Map<String, dynamic> row) {
    final trainName = _pickText(row, ['trainName', 'trainNum', 'trainNo', 'serialNumber']);
    final ends = _pickText(row, ['ends', 'end', 'trainEnd']);
    return _requiredText('$trainName$ends');
  }

  String _statusText(Map<String, dynamic> row) {
    final raw = _pickText(row, ['statusName', 'statusLabel', 'status']);
    switch (raw) {
      case '0':
        return '未下发';
      case '1':
        return '已下发';
      case '2':
        return '已签收';
      default:
        return raw;
    }
  }

  Future<void> _markAsRead() async {
    if (_markingRead) return;
    try {
      setState(() => _markingRead = true);
      final params = Map<String, dynamic>.from(widget.noticeItem);
      params['status'] = 1;
      final res = await ProductApi().updateShuntingNotice([params]);
      if (!mounted) return;
      if (res != null) {
        showToast('已读');
        Navigator.of(context).pop(true);
      } else {
        showToast('操作失败');
        setState(() => _markingRead = false);
      }
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() => _markingRead = false);
      showToast('操作失败');
    }
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _requiredText(value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_rows.isEmpty) {
      return const Center(child: Text('暂无转序通知单数据'));
    }

    return Column(
      children: _rows.asMap().entries.map((entry) {
        final row = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoItem('车号', _trainDisplay(row)),
                _infoItem('机型', _pickText(row, ['typeName', 'trainType', 'model'])),
                _infoItem(
                  '初始工序节点',
                  _pickText(row, [
                    'currentRepairMainNodeName',
                    'currentMainNodeName',
                    'beforeMainNodeName',
                    'mainNodeName',
                  ]),
                ),
                _infoItem(
                  '初始排程节点',
                  _pickText(row, [
                    'currentScheduleNodeName',
                    'currentMainNodeScheduleNodeName',
                    'beforeScheduleNodeName',
                  ]),
                ),
                _infoItem(
                  '转入工序节点',
                  _pickText(row, [
                    'changeRepairMainNodeName',
                    'nextMainNodeName',
                    'targetMainNodeName',
                    'transferMainNodeName',
                  ]),
                ),
                _infoItem(
                  '转入排程节点',
                  _pickText(row, ['scheduleNodeName']),
                ),
                _infoItem(
                  '计划转入时间',
                  _pickText(row, ['planStartTime']),
                ),
                _infoItem(
                  '发布时间',
                  _pickText(row, ['applyTime', 'publishTime', 'createdTime']),
                ),
                _infoItem('状态', _statusText(row)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('转序通知单'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildList(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _markingRead ? null : _markAsRead,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_markingRead ? '处理中...' : '已读'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AfterSaleFaultNoticePage extends StatefulWidget {
  final String shuntingCode;
  final Map<String, dynamic> noticeItem;

  const AfterSaleFaultNoticePage({
    super.key,
    required this.shuntingCode,
    required this.noticeItem,
  });

  @override
  State<AfterSaleFaultNoticePage> createState() => _AfterSaleFaultNoticePageState();
}

class _AfterSaleFaultNoticePageState extends State<AfterSaleFaultNoticePage> {
  final _logger = AppLogger.logger;
  bool _loading = true;
  bool _markingRead = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _rows = [];
    });
    try {
      final rows = await ProductApi().getMasSaleInformationList(
        queryParametrs: {
          'code': widget.shuntingCode,
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
      showToast('获取售后故障录入通知失败');
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = _text(map[key]);
      if (v.isNotEmpty && v != 'null') return v;
    }
    return '';
  }

  String _requiredText(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _binaryStatusText(String value) {
    final v = value.trim();
    if (v == '1') return '已下发';
    if (v == '0') return '未下发';
    return v;
  }

  Future<void> _markAsRead() async {
    if (_markingRead) return;
    try {
      setState(() => _markingRead = true);
      final params = Map<String, dynamic>.from(widget.noticeItem);
      params['status'] = 1;
      final res = await ProductApi().updateShuntingNotice([params]);
      if (!mounted) return;
      if (res != null) {
        showToast('已读');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _markingRead = false);
        showToast('操作失败');
      }
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() => _markingRead = false);
      showToast('操作失败');
    }
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _requiredText(value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_rows.isEmpty) {
      return const Center(child: Text('暂无售后故障录入通知数据'));
    }

    return Column(
      children: _rows.map((row) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoItem('故障日期', _pickText(row, ['faultDate'])),
                _infoItem('填报日期', _pickText(row, ['createdTime', 'reportTime'])),
                _infoItem('机型', _pickText(row, ['model', 'typeName', 'trainType'])),
                _infoItem('车号', _pickText(row, ['serialNumber', 'trainNum', 'trainName'])),
                _infoItem('交验日期', _pickText(row, ['inspectionDate'])),
                _infoItem('维修段', _pickText(row, ['maintenanceSection', 'deptName', 'deptNmeString'])),
                _infoItem('修程情况', _pickText(row, ['repairStatus'])),
                _infoItem('故障类别', _pickText(row, ['failureCategory', 'failureCategoryName'])),
                _infoItem('走行公里', _pickText(row, ['kilometersTravelled', 'kilometer', 'mileage'])),
                _infoItem('故障现象', _pickText(row, ['faultInformation', 'faultPhenomenon'])),
                _infoItem('故障情况', _pickText(row, ['faultSummary', 'faultSituation'])),
                _infoItem('责任车间', _pickText(row, ['deptNmeString', 'deptName', 'responsibleDeptName', 'workshop'])),
                _infoItem('联系人', _pickText(row, ['contactPerson'])),
                _infoItem('联系电话', _pickText(row, ['tel'])),
                _infoItem('机车所在地', _pickText(row, ['trainLocation', 'parkingLocation', 'stopLocation'])),
                _infoItem('附件', _pickText(row, ['fileCode', 'attachment', 'fileList'])),
                _infoItem('填报人', _pickText(row, ['createdBy'])),
                _infoItem('故障状态', _binaryStatusText(_pickText(row, ['status']))),
                _infoItem(
                  '调查清单',
                  _binaryStatusText(
                    _pickText(row, ['investigateStatus']),
                  ),
                ),
                _infoItem(
                  '修程通知单',
                  _binaryStatusText(
                    _pickText(row, ['masNoticeStatus']),
                  ),
                ),
                _infoItem(
                  '售后服务通知单',
                  _binaryStatusText(
                    _pickText(row, ['afterSaleStatus']),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('售后故障录入通知'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildList(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _markingRead ? null : _markAsRead,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_markingRead ? '处理中...' : '已读'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AfterSaleServiceNoticePage extends StatefulWidget {
  final String shuntingCode;

  const AfterSaleServiceNoticePage({super.key, required this.shuntingCode});

  @override
  State<AfterSaleServiceNoticePage> createState() => _AfterSaleServiceNoticePageState();
}

class RepairProcessNoticeDetailPage extends StatefulWidget {
  final String shuntingCode;
  final Map<String, dynamic> noticeItem;

  const RepairProcessNoticeDetailPage({
    super.key,
    required this.shuntingCode,
    required this.noticeItem,
  });

  @override
  State<RepairProcessNoticeDetailPage> createState() =>
      _RepairProcessNoticeDetailPageState();
}

class _RepairProcessNoticeDetailPageState
    extends State<RepairProcessNoticeDetailPage> {
  final _logger = AppLogger.logger;
  bool _loading = true;
  bool _markingRead = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _rows = [];
    });
    try {
      final res = await ProductApi().getMasNoticeSelectAll(
        queryParametrs: {
          'code': widget.shuntingCode,
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      final rows = _parseList(res);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
      showToast('获取修程通知单失败');
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _text(map[key]);
      if (value.isNotEmpty) return value;
    }
    for (final value in map.values) {
      if (value is Map) {
        final text = _pickText(Map<String, dynamic>.from(value), keys);
        if (text.isNotEmpty) return text;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final text = _pickText(Map<String, dynamic>.from(item), keys);
            if (text.isNotEmpty) return text;
          }
        }
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _parseList(dynamic value) {
    dynamic raw = value;
    if (raw is Map) {
      raw = raw['rows'] ?? raw['records'] ?? raw['data'] ?? raw['list'] ?? raw;
      if (raw is Map) {
        final lists = raw.values.whereType<List>().toList();
        if (lists.length == 1) raw = lists.first;
      }
    }
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _pickList(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final parsed = _parseList(map[key]);
      if (parsed.isNotEmpty) return parsed;
    }
    for (final value in map.values) {
      if (value is Map) {
        final parsed = _pickList(Map<String, dynamic>.from(value), keys);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return <Map<String, dynamic>>[];
  }

  String _requiredText(String value) => value.trim().isEmpty ? '-' : value.trim();

  Future<void> _markAsRead() async {
    if (_markingRead) return;
    try {
      setState(() => _markingRead = true);
      final params = Map<String, dynamic>.from(widget.noticeItem);
      params['status'] = 1;
      final res = await ProductApi().updateShuntingNotice([params]);
      if (!mounted) return;
      if (res != null) {
        showToast('已读');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _markingRead = false);
        showToast('操作失败');
      }
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() => _markingRead = false);
      showToast('操作失败');
    }
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _requiredText(value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataTable({
    required List<Map<String, dynamic>> rows,
    required List<MapEntry<String, List<String>>> columns,
  }) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('暂无数据'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns
              .map(
                (c) => DataColumn(
                  label: Text(
                    c.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: columns
                      .map(
                        (c) => DataCell(
                          Text(
                            _requiredText(_pickText(row, c.value)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_rows.isEmpty) {
      return const Center(child: Text('暂无修程通知单数据'));
    }
    return Column(
      children: _rows.map((row) {
        final workRows = _pickList(row, ['masNoticeDeptList', 'masAfterSaleWorkList']);
        final signRows = _pickList(row, ['shuntingNoticeList', 'masAfterSaleAuditList']);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoItem('通知单编码', _pickText(row, ['encode', 'noticeCode', 'code'])),
                _infoItem('故障现象', _pickText(row, ['faultDescription', 'faultInformation'])),
                _infoItem('工序节点', _pickText(row, ['repairMainNodeName'])),
                _infoItem('停留位置', _pickText(row, ['stoppingPlace', 'trainLocation', 'parkingLocation', 'stopLocation'])),
                _infoItem('车号', _pickText(row, ['trainNum', 'trainName'])),
                _infoItem('机型', _pickText(row, ['typeName', 'model'])),
                _infoItem('填报人', _pickText(row, ['reportUserName', 'applyUserName'])),
                _infoItem('填报部门', _pickText(row, ['reportDeptName'])),
                _infoItem('发布时间', _pickText(row, ['createdTime', 'applyTime'])),
                const SizedBox(height: 8),
                const Text(
                  '工艺信息',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
                _dataTable(
                  rows: workRows.isEmpty ? <Map<String, dynamic>>[row] : workRows,
                  columns: [
                    MapEntry('关联构型', ['configNodeName', 'configName', 'nodeName']),
                    MapEntry('加工方法', ['jtDictName', 'processingMethodName', 'requiredProcessingMethodName']),
                    MapEntry('风险等级', ['riskLevel', 'riskLevelName']),
                    MapEntry('外包厂家', ['outsourcingVendor', 'outSourcingFactory', 'outsourcingFactory']),
                    MapEntry('施修方案', ['repairProcContent', 'maintenanceNotice', 'repairScheme', 'repairPlan']),
                    MapEntry('技术指导', ['techGuideName', 'technicalGuidance', 'guide', 'techGuide']),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '签收情况',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
                _dataTable(
                  rows: signRows.isEmpty ? <Map<String, dynamic>>[row] : signRows,
                  columns: [
                    MapEntry('发布人', ['applyUserName']),
                    MapEntry('签收部门', ['auditDeptName']),
                    MapEntry('签收班组', ['auditTeamName']),
                    MapEntry('签收人', ['auditUserName']),
                    MapEntry('签收时间', ['auditTime']),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修程通知单'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildList(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _markingRead ? null : _markAsRead,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_markingRead ? '处理中...' : '已读'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AfterSaleServiceNoticePageState extends State<AfterSaleServiceNoticePage> {
  final _logger = AppLogger.logger;
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  int _selectedIndex = 0;
  final Map<int, Map<String, dynamic>> _masSaleInfoByIndex = {};
  final Set<int> _masSaleInfoLoading = {};
  final Set<int> _masSaleInfoAttempted = {};
  final _jsonEncoder = const JsonEncoder.withIndent('  ');
  static const String _jt28AndPeopleHint =
      '第一个班组中的第一位自动成为主修，第一个班组中的其他人自动为辅修。后续班组及人员仅记录。';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _prettyJson(dynamic v) {
    try {
      if (v == null) return 'null';
      if (v is String) return v;
      return _jsonEncoder.convert(v);
    } catch (_) {
      return v?.toString() ?? 'null';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _rows = [];
      _selectedIndex = 0;
      _masSaleInfoByIndex.clear();
      _masSaleInfoLoading.clear();
      _masSaleInfoAttempted.clear();
    });
    try {
      final queryParametrs = {
        'code': widget.shuntingCode,
        'pageNum': 0,
        'pageSize': 0,
      };
      if (kDebugMode) {
        _logger.i('getMasAfterSaleShunting query: ${_prettyJson(queryParametrs)}');
      }
      final res = await ProductApi().getMasAfterSaleShunting(
        queryParametrs: queryParametrs,
      );
      if (kDebugMode) {
        _logger.i('getMasAfterSaleShunting resp: ${_prettyJson(res)}');
      }
      final rows = res is List
          ? res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _selectedIndex = 0;
      });
      if (rows.isNotEmpty) {
        Future(() => _ensureMasSaleInfoLoaded(0));
      }
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rows = [];
        _selectedIndex = 0;
        _masSaleInfoByIndex.clear();
        _masSaleInfoLoading.clear();
        _masSaleInfoAttempted.clear();
      });
      showToast('获取数据失败');
    }
  }

  String _asText(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      final t = _asText(v);
      if (t.isNotEmpty) return t;
    }
    for (final v in map.values) {
      if (v is Map) {
        final t = _pickText(Map<String, dynamic>.from(v), keys);
        if (t.isNotEmpty) return t;
      } else if (v is List) {
        for (final item in v) {
          if (item is Map) {
            final t = _pickText(Map<String, dynamic>.from(item), keys);
            if (t.isNotEmpty) return t;
          }
        }
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _pickList(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      final parsed = _parseList(v);
      if (parsed.isNotEmpty) return parsed;
    }
    for (final v in map.values) {
      if (v is Map) {
        final parsed = _pickList(Map<String, dynamic>.from(v), keys);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _parseList(dynamic v) {
    dynamic raw = v;
    if (raw is Map) {
      raw = raw['rows'] ?? raw['records'] ?? raw['data'] ?? raw['list'] ?? raw['result'] ?? raw;
      if (raw is Map) {
        final lists = raw.values.whereType<List>().toList();
        if (lists.length == 1) raw = lists.first;
      }
    }
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _ensureMasSaleInfoLoaded(int index) async {
    if (index < 0 || index >= _rows.length) return;
    if (_masSaleInfoAttempted.contains(index)) return;
    _masSaleInfoAttempted.add(index);

    final row = _rows[index];
    final jt28Code = _pickText(row, [
      'jt28Code',
      'jt28CodeList',
      'sys28Code',
      'repairSys28Code',
      'masSaleInformationCode',
      'jt28',
      'sys28',
    ]);
    if (jt28Code.trim().isEmpty) return;

    if (mounted) {
      setState(() => _masSaleInfoLoading.add(index));
    }
    try {
      final queryParametrs = {'jt28Code': jt28Code};
      if (kDebugMode) {
        _logger.i('getMasSaleInformation query: ${_prettyJson(queryParametrs)}');
      }
      final res = await ProductApi().getMasSaleInformation(queryParametrs);
      if (kDebugMode) {
        _logger.i('getMasSaleInformation resp: ${_prettyJson(res)}');
      }
      Map<String, dynamic> info = {};
      dynamic raw = res;
      if (raw is Map && raw['data'] is Map) {
        raw = raw['data'];
      }
      if (raw is Map) {
        info = Map<String, dynamic>.from(raw);
      }
      if (!mounted) return;
      setState(() {
        if (info.isNotEmpty) {
          _masSaleInfoByIndex[index] = info;
        }
        _masSaleInfoLoading.remove(index);
      });
    } catch (e) {
      _logger.e(e);
      if (!mounted) return;
      setState(() => _masSaleInfoLoading.remove(index));
    }
  }

  String _requiredText(String s) => s.trim().isEmpty ? '-' : s.trim();

  String _joinUniqueLines(Iterable<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final v in values) {
      final t = v.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out.join('\n');
  }

  String _formatAsLines(dynamic v) {
    if (v == null) return '';
    if (v is List) {
      final parts = <String>[];
      for (final e in v) {
        final t = _asText(e);
        if (t.isNotEmpty) parts.add(t);
      }
      return _joinUniqueLines(parts);
    }
    final s = _asText(v);
    if (s.isEmpty) return '';
    if (s.contains('\n')) return s;
    final normalized = s.replaceAll('，', ',');
    if (normalized.contains(',')) {
      final parts = normalized
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length > 1) return _joinUniqueLines(parts);
    }
    return s;
  }

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _infoGrid(Map<String, dynamic> item) {
    final noticeNo = _pickText(item, [
      'encode',
      'noticeCode',
      'noticeNo',
      'shuntingEncode',
      'afterSaleShuntingCode',
      'code',
    ]);
    final model = _pickText(item, ['typeName', 'trainType', 'model', 'machineModel']);
    final trainNum = _pickText(item, ['trainNum', 'serialNumber']);
    final depot = _pickText(item, ['assignSegmentName', 'maintenanceSection', 'depotName']);
    final repairStatus = _pickText(item, ['repairStatus', 'repairProcName', 'repairTimes']);
    final contact = _pickText(item, ['customerContact', 'contactPerson']);
    final phone = _pickText(item, ['tel', 'customerPhone', 'contactPhone', 'phone', 'phoneNumber']);
    final location = _pickText(item, ['trainLocation', 'parkingLocation', 'stopLocation']);
    final faultCategory = _pickText(item, ['failureCategory', 'faultCategory', 'faultType']);
    final faultTime = _pickText(item, ['faultTime', 'reportTime', 'createdTime', 'applyTime']);
    final faultDesc = _pickText(item, ['faultInformation', 'faultDesc', 'faultPhenomenon']);
    final faultSituation = _pickText(item, ['faultSituation', 'faultSummary']);

    TableRow row3(String l1, String v1, String l2, String v2, String l3, String v3) {
      final headerStyle = TextStyle(color: Colors.grey[700], fontSize: 13);
      final valueStyle = const TextStyle(fontSize: 13);
      Widget cell(String text, TextStyle? style, {bool header = false}) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          color: header ? Colors.grey[100] : null,
          child: Text(text, style: style),
        );
      }

      return TableRow(
        children: [
          cell(l1, headerStyle, header: true),
          cell(_requiredText(v1), valueStyle),
          cell(l2, headerStyle, header: true),
          cell(_requiredText(v2), valueStyle),
          cell(l3, headerStyle, header: true),
          cell(_requiredText(v3), valueStyle),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '通知单编号：${_requiredText(noticeNo.isEmpty ? widget.shuntingCode : noticeNo)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(110),
                    1: FixedColumnWidth(220),
                    2: FixedColumnWidth(110),
                    3: FixedColumnWidth(220),
                    4: FixedColumnWidth(110),
                    5: FixedColumnWidth(220),
                  },
                  children: [
                    row3('故障机型', model, '故障车号', trainNum, '配属段', depot),
                    row3('客户联系人', contact, '联系电话', phone, '修程/修次', repairStatus),
                    row3('机车停留地点', location, '故障类别', faultCategory, '故障时间', faultTime),
                    row3('故障现象', faultDesc, '故障概况', faultSituation, '处置方案', _pickText(item, ['disposalPlan', 'repairScheme'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataTable({
    required List<Map<String, dynamic>> rows,
    required List<MapEntry<String, List<String>>> columns,
    double headingRowHeight = 38,
    double dataRowMinHeight = 40,
    double dataRowMaxHeight = 80,
  }) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('暂无数据'),
      );
    }

    String cellValue(Map<String, dynamic> row, List<String> keys) {
      for (final k in keys) {
        final t = _asText(row[k]);
        if (t.isNotEmpty) return t;
      }
      return '';
    }

    final dataColumns = columns
        .map(
          (c) => DataColumn(
            label: Text(
              c.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        )
        .toList();

    final dataRows = rows.map((r) {
      return DataRow(
        cells: columns.map((c) {
          return DataCell(Text(_requiredText(cellValue(r, c.value))));
        }).toList(),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: headingRowHeight,
          dataRowMinHeight: dataRowMinHeight,
          dataRowMaxHeight: dataRowMaxHeight,
          columns: dataColumns,
          rows: dataRows,
        ),
      ),
    );
  }

  Widget _jt28Section(Map<String, dynamic> item) {
    final rows = _pickList(item, [
      'masAfterSaleWorkList',
    ]);
    final displayRows = rows.map((r) {
      final mapped = Map<String, dynamic>.from(r);
      final deptRows = _pickList(r, [
        'masAfterSaleWorkDeptList',
        'workDeptList',
        'deptList',
      ]);

      String deptDisplay = '';
      String teamDisplay = '';
      String peopleDisplay = '';

      if (deptRows.isNotEmpty) {
        deptDisplay = _joinUniqueLines(
          deptRows.map(
            (e) => _pickText(
              e,
              ['deptName', 'responsibleDeptName', 'workshop', 'workDeptName'],
            ),
          ),
        );

        teamDisplay = _joinUniqueLines(
          deptRows.map(
            (e) => _pickText(
              e,
              ['teamName', 'responsibleTeamName', 'team', 'responsibilityTeamName'],
            ),
          ),
        );

        final peopleLines = <String>[];
        for (final d in deptRows) {
          final rawPeople = d['userNameList'] ??
              d['userNameListStr'] ??
              d['repairPersonnelNameList'] ??
              d['userList'] ??
              d['users'];
          final formatted = _formatAsLines(rawPeople);
          if (formatted.isEmpty) continue;
          peopleLines.addAll(
            formatted
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
        }
        peopleDisplay = _joinUniqueLines(peopleLines);
      }

      mapped['responsibleDeptNameDisplay'] = deptDisplay;
      mapped['responsibleTeamNameDisplay'] = teamDisplay;
      mapped['repairPersonnelDisplay'] = peopleDisplay;
      return mapped;
    }).toList();
    final hasTeam = displayRows.any((r) => _pickText(r, ['responsibleTeamNameDisplay']).isNotEmpty);
    final hasPeople = displayRows.any((r) => _pickText(r, ['repairPersonnelDisplay']).isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'JT28信息',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _jt28AndPeopleHint,
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
        _dataTable(
          rows: displayRows,
          dataRowMaxHeight: 120,
          columns: [
            MapEntry('构型', ['configNodeName', 'structure', 'configName', 'componentName', 'nodeName', 'config']),
            MapEntry('加工方法', ['jtDictName', 'jtDictCode', 'processingMethod', 'processingMethodName', 'requiredProcessingMethodName', 'requiredProcessingMethod']),
            MapEntry('施修方案', ['repairProcContent', 'repairScheme', 'repairProgram', 'repairPlan', 'repairStatus', 'maintenanceNotice']),
            MapEntry('风险等级', ['riskLevel', 'riskLevelName']),
            MapEntry('外包厂家', ['outsourcingVendor', 'outSourcingFactory', 'outsourcingFactory']),
            MapEntry('责任车间', ['responsibleDeptNameDisplay']),
            if (hasTeam) MapEntry('责任班组', ['responsibleTeamNameDisplay']),
            if (hasPeople) MapEntry('施修人', ['repairPersonnelDisplay']),
          ],
        ),
      ],
    );
  }

  Widget _partsSection(Map<String, dynamic> item) {
    final rows = _pickList(item, [
      'masAfterSaleSubpartList',
    ]);
    final displayRows = rows.map((r) {
      final mapped = Map<String, dynamic>.from(r);
      final raw = _pickText(r, ['recycleType', 'disposalType', 'disposalWay']).trim();
      String label;
      if (raw == '0') {
        label = '配送';
      } else if (raw == '1') {
        label = '回收';
      } else {
        label = raw;
      }
      mapped['disposalTypeDisplay'] = label.isEmpty ? '-' : label;
      return mapped;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('配件信息'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '配件周转要求：${_pickText(item, ['subpartTurnoverRequirements', 'subpartTurnoverReqirements', 'turnoverRequirements'])}',
            style: const TextStyle(fontSize: 13, color: Colors.green),
          ),
        ),
        _dataTable(
          rows: displayRows,
          columns: [
            MapEntry('配件名称', ['configName', 'configNodeName', 'materialName', 'partsName', 'accessoryName', 'name']),
            MapEntry('规格型号', ['modelInfoName', 'modelInfoCode', 'spec', 'specification', 'model', 'materialModel']),
            MapEntry('发货时间', ['deliveryTime', 'sendTime', 'materialDeliveryTime']),
            MapEntry('数量', ['quantity', 'count', 'num']),
            MapEntry('发货方式', ['deliveryMethod', 'sendWay', 'deliveryWay', 'sendType']),
            MapEntry('处置方式', ['disposalTypeDisplay', 'recycleType', 'disposalWay', 'disposalType', 'disposalPlan']),
            MapEntry('责任车间', ['responsibleDeptName', 'deptName', 'workshop', 'responsibilityDeptName']),
            MapEntry('责任班组', ['responsibleTeamName', 'teamName', 'team', 'responsibilityTeamName']),
            MapEntry('责任人', ['responsibleUserName', 'responsibilityUserName', 'userName', 'nickName', 'responsibilityUser']),
          ],
        ),
      ],
    );
  }

  Widget _peopleSection(Map<String, dynamic> item) {
    final rows = _pickList(item, [
      'peopleList',
      'personList',
      'staffList',
      'memberList',
      'personnelList',
      'userList',
      'masAfterSaleUserList',
    ]);
    final peopleCount = _pickText(item, ['personnelNumber', 'peopleCount', 'personCount', 'count']);
    final startTime = _pickText(item, ['personnelDepartureTime', 'departureTime', 'startTime', 'outTime']);
    final remark = _pickText(item, ['personnelRemark', 'remark']);
    
    final displayRows = rows.map((r) {
      final mapped = Map<String, dynamic>.from(r);
      final identityRaw = _pickText(
        r,
        ['identity', 'userType', 'roleName', 'typeName', 'postName', 'dutyName'],
      ).trim();
      if (identityRaw == '1') {
        mapped['personTypeDisplay'] = '队长';
      } else if (identityRaw == '2') {
        mapped['personTypeDisplay'] = '带队干部';
      } else if (identityRaw == '0') {
        mapped['personTypeDisplay'] = '队员';
      } else if (identityRaw.isNotEmpty &&
          (identityRaw.contains('队长') || identityRaw.contains('队员') || identityRaw.contains('带队干部'))) {
        mapped['personTypeDisplay'] = identityRaw;
      } else {
        mapped['personTypeDisplay'] = '-';
      }
      final tel = _pickText(r, ['tel', 'phoneNumber', 'phone', 'mobile']);
      mapped['phoneDisplay'] = tel.isEmpty ? '-' : tel;
      return mapped;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('人员信息'),
        if (peopleCount.isNotEmpty || startTime.isNotEmpty || remark.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 16,
              runSpacing: 4,
              children: [
                if (peopleCount.isNotEmpty)
                  Text('人数：$peopleCount', style: const TextStyle(fontSize: 13, color: Colors.blue)),
                if (startTime.isNotEmpty)
                  Text('出发时间：$startTime', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (remark.isNotEmpty)
                  Text('备注：$remark', style: const TextStyle(fontSize: 13, color: Colors.green)),
              ],
            ),
          ),
        _dataTable(
          rows: displayRows,
          columns: [
            MapEntry('车间', ['deptName', 'workshop', 'teamDeptName']),
            MapEntry('班组', ['teamName', 'team', 'groupName']),
            MapEntry('人员', ['userName', 'nickName', 'name', 'personName']),
            MapEntry('人员类型', ['personTypeDisplay']),
            MapEntry('电话', ['phoneDisplay']),
          ],
        ),
      ],
    );
  }

  Widget _safetySection(Map<String, dynamic> item) {
    const common =
        '1.服务人员经安全培训合格，熟知电气化区段作业安全注意事项。'
        '2.作业过程穿戴合格劳动防护用品，用品符合放蚀处置标准。'
        '3.禁止单岗作业，必须两人及以上同行，一人做好安全防护工作。'
        '4.必须严格人身安全“十不准”的要求。'
        '5.禁止做与本工作无关的其它事项。';
    final otherSafetyTips = _pickText(item, ['safetyTips', 'saftyTips', 'otherSafetyTips']);
    if (otherSafetyTips.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('安全提示'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('常规安全提示：${_requiredText(common)}'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('其他安全提示：-'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('安全提示'),
        if (common.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('常规安全提示：${_requiredText(common)}'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text('其他安全提示：${_requiredText(otherSafetyTips)}'),
        ),
      ],
    );
  }

  Widget _signSection(Map<String, dynamic> item) {
    final rows = _pickList(item, [
      'signList',
      'auditList',
      'receiptList',
      'acceptList',
      'shuntingNoticeList',
      'masAfterSaleAuditList',
    ]);
    final normalized = rows.isEmpty ? <Map<String, dynamic>>[item] : rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('签收情况'),
        _dataTable(
          rows: normalized,
          columns: [
            MapEntry('调令发布人', ['applyUserName', 'sendUserName', 'createdByName']),
            MapEntry('发布时间', ['applyTime', 'createdTime', 'publishTime']),
            MapEntry('签收部门', ['auditDeptName', 'deptName']),
            MapEntry('签收人', ['auditUserName', 'receiveUserName']),
            MapEntry('签收时间', ['auditTime']),
          ],
        ),
      ],
    );
  }

  Widget _detailBody(Map<String, dynamic> item) {
    final idx = _rows.indexOf(item);
    final extra = idx >= 0 ? _masSaleInfoByIndex[idx] : null;
    final merged = Map<String, dynamic>.from(item);
    if (extra != null && extra.isNotEmpty) {
      merged['masSaleInformation'] = extra;
      final extraRows = _parseList(extra);
      if (extraRows.isNotEmpty) {
        for (final k in extraRows.first.keys) {
          if (!merged.containsKey(k) || merged[k] == null) {
            merged[k] = extraRows.first[k];
          }
        }
      }
    }
    return ListView(
      children: [
        if (idx >= 0 && _masSaleInfoLoading.contains(idx))
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _infoGrid(merged),
        _jt28Section(merged),
        _partsSection(merged),
        _peopleSection(merged),
        _safetySection(merged),
        _signSection(merged),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? debugItem;
    if (_rows.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < _rows.length) {
      final base = _rows[_selectedIndex];
      final extra = _masSaleInfoByIndex[_selectedIndex];
      final merged = Map<String, dynamic>.from(base);
      if (extra != null && extra.isNotEmpty) {
        merged['masSaleInformation'] = extra;
        final extraRows = _parseList(extra);
        if (extraRows.isNotEmpty) {
          for (final k in extraRows.first.keys) {
            if (!merged.containsKey(k) || merged[k] == null) {
              merged[k] = extraRows.first[k];
            }
          }
        }
      }
      debugItem = merged;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('售后服务通知单'),
        actions: [
          if (debugItem != null && _pickList(debugItem!, ['masAfterSaleWorkList']).isNotEmpty)
            TextButton(
              onPressed: () async {
                final rows = _pickList(debugItem!, ['masAfterSaleWorkList']);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Jt28DispatchPage(
                      noticeItem: debugItem!,
                      workList: rows,
                    ),
                  ),
                );
                if (result == true) {
                  _load();
                }
              },
              child: const Text('派工', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('暂无数据'))
              : _rows.length == 1
                  ? _detailBody(_rows.first)
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          alignment: Alignment.centerLeft,
                          child: DropdownButton<int>(
                            value: _selectedIndex,
                            isExpanded: true,
                            items: List.generate(_rows.length, (i) {
                              final item = _rows[i];
                              final code = _pickText(item, [
                                'encode',
                                'noticeCode',
                                'noticeNo',
                                'shuntingEncode',
                                'afterSaleShuntingCode',
                                'code',
                              ]);
                              final title = code.isEmpty ? '记录 ${i + 1}' : code;
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Text(title),
                              );
                            }),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _selectedIndex = v);
                              _ensureMasSaleInfoLoaded(v);
                            },
                          ),
                        ),
                        Expanded(child: _detailBody(_rows[_selectedIndex])),
                      ],
                    ),
    );
  }
}
