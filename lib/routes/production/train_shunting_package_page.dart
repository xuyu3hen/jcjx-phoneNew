import '../../index.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class TrainShuntingPackagePage extends StatefulWidget {
  final bool readOnly;
  const TrainShuntingPackagePage({super.key, this.readOnly = false});

  @override
  State<TrainShuntingPackagePage> createState() =>
      _TrainShuntingPackagePageState();
}

class _TrainShuntingPackagePageState extends State<TrainShuntingPackagePage> {
  var logger = AppLogger.logger;

  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String _searchText = '';
  DateTime? _planDate;
  final Set<String> _receivedPackageCodes = <String>{};
  final Set<String> _receivingPackageCodes = <String>{};

  void _showPackageSearchDialog() {
    final controller = TextEditingController(text: _searchText);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('查询'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '按名称或车号搜索',
            ),
            autofocus: true,
            onSubmitted: (_) {
              setState(() => _searchText = controller.text.trim());
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchText = '');
                Navigator.of(context).pop();
              },
              child: const Text('清空'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _searchText = controller.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('查询'),
            ),
          ],
        );
      },
    );
  }

  bool _packageMatchesKeyword(Map<String, dynamic> pkg, String keyword) {
    final kw = keyword.trim();
    if (kw.isEmpty) return true;
    final name = (pkg['packageName'] ?? pkg['name'] ?? '').toString();
    if (name.contains(kw)) return true;
    final raw = pkg['trainShuntingPlanList'];
    final plans = raw is List ? raw : const <dynamic>[];
    for (final e in plans) {
      if (e is Map) {
        final trainNum = (e['trainNum'] ?? '').toString();
        final ends = formatEndsSuffix(e['ends']);
        final combined = '$trainNum$ends';
        if (trainNum.contains(kw) || combined.contains(kw)) return true;
      }
    }
    return false;
  }

  int? _pkgStatus(Map<String, dynamic> pkg) {
    final st = pkg['status'];
    return st is int ? st : int.tryParse(st?.toString() ?? '');
  }

  bool _isCompletedPkg(Map<String, dynamic> pkg) {
    return _pkgStatus(pkg) == 2;
  }

  bool _isUnreceivedPkg(Map<String, dynamic> pkg) {
    final stInt = _pkgStatus(pkg);
    final code = (pkg['code'] ?? '').toString();
    final localReceived =
        code.isNotEmpty && _receivedPackageCodes.contains(code);
    return (stInt == null || stInt == 0) && !localReceived;
  }

  bool _isReceivedPkg(Map<String, dynamic> pkg) {
    return !_isCompletedPkg(pkg) && !_isUnreceivedPkg(pkg);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _planDateText() {
    final d = _planDate;
    if (d == null) return '选择日期';
    final now = DateTime.now();
    if (_isSameDay(d, now)) return '今天';
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    if (_isSameDay(d, tomorrow)) return '明天';
    return DateFormat('yyyy-MM-dd').format(d);
  }

  Future<void> _pickPlanDate() async {
    final picked = await showBoardDateTimePicker(
      context: context,
      pickerType: DateTimePickerType.date,
      initialDate: _planDate ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _planDate = DateTime(picked.year, picked.month, picked.day));
    await _loadData();
  }

  Future<void> _clearPlanDate() async {
    if (_planDate == null) return;
    setState(() => _planDate = null);
    await _loadData();
  }

  Widget _buildPackageList(List<Map<String, dynamic>> list) {
    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '发布时间',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '名称',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                '位置',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '完成情况',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          buildHeader(),
          const SizedBox(height: 140),
          const Center(child: Text('暂无数据')),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return buildHeader();
        }
        final pkg = list[index - 1];
        final name = (pkg['packageName'] ?? pkg['name'] ?? '').toString();
        final code = (pkg['code'] ?? '').toString();
        final publishTime = _fmtDate(
          pkg['publishTime'] ??
              pkg['publish_time'] ??
              pkg['publishDate'] ??
              pkg['createdTime'],
        );
        final raw = pkg['trainShuntingPlanList'];
        final plans = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];
        final startPlan = plans.isNotEmpty ? plans.first : null;
        final endPlan = plans.isNotEmpty ? plans.last : null;
        final startAreaName =
            (startPlan?['startAreaName'] ?? startPlan?['areaName'] ?? '')
                .toString();
        final startTrackNum = (startPlan?['startTrackNum'] ??
                startPlan?['trackNum'] ??
                '')
            .toString();
        final endAreaName =
            (endPlan?['endAreaName'] ?? endPlan?['areaName'] ?? '').toString();
        final endTrackNum =
            (endPlan?['endTrackNum'] ?? endPlan?['trackNum'] ?? '').toString();
        final locationText = (startAreaName.isEmpty &&
                startTrackNum.isEmpty &&
                endAreaName.isEmpty &&
                endTrackNum.isEmpty)
            ? ''
            : '$startAreaName-$startTrackNum 到 $endAreaName-$endTrackNum';
        final isCompleted = _isCompletedPkg(pkg);
        final isReceived = _isReceivedPkg(pkg);
        final isReceiving =
            code.isNotEmpty && _receivingPackageCodes.contains(code);
        final stInt = _pkgStatus(pkg);
        final canEnter = isReceived || isCompleted;
        final canEnable = !isCompleted && !isReceived && !isReceiving;
        final statusText = isCompleted
            ? '已完成'
            : (isReceived ? '作业中' : (stInt == 0 ? '未完成' : '未完成'));

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              if (!widget.readOnly && !canEnter) {
                SmartDialog.showToast('请先启用');
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (context) => TrainShuntingPlanListPage(
                    title: name,
                    packageCode: code,
                    planList: plans,
                    readOnly: widget.readOnly,
                  ),
                ),
              );
              if (!widget.readOnly) {
                await _loadData();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      publishTime.isEmpty ? '-' : publishTime,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      locationText.isEmpty ? '-' : locationText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
          child: widget.readOnly
              ? Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? Colors.green
                        : (isReceived ? Colors.blue : Colors.black54),
                    fontWeight:
                        isCompleted || isReceived ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : (canEnable
                  ? TextButton(
                      onPressed: () async {
                        if (isReceiving) return;
                        _receive(code);
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                            builder: (context) => TrainShuntingPlanListPage(
                              title: name,
                              packageCode: code,
                              planList: plans,
                            ),
                          ),
                        );
                        if (res == true || res == null) {
                          await _loadData();
                        }
                      },
                      child: const Text('启用'),
                    )
                  : Text(
                      isReceiving ? '启用中' : statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.green
                            : (isReceived
                                ? Colors.blue
                                : Colors.black54),
                        fontWeight: isCompleted || isReceived
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final queryParametrs = <String, dynamic>{};
      if (_planDate != null) {
        queryParametrs['planDate'] =
            DateFormat('yyyy-MM-dd').format(_planDate!);
      }
      final r = widget.readOnly
          ? await ProductApi().getTrainShuntingPackageAll(
              queryParametrs: queryParametrs.isEmpty ? null : queryParametrs,
            )
          : await ProductApi().getTrainShuntingPackage(
              queryParametrs: queryParametrs.isEmpty ? null : queryParametrs,
            );
      List<Map<String, dynamic>> rows = (r as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      for (final pkg in rows) {
        final code = (pkg['code'] ?? '').toString();
        final st = pkg['status'];
        final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
        if (code.isNotEmpty &&
            _receivedPackageCodes.contains(code) &&
            stInt == 0) {
          pkg['status'] = 1;
        }
      }
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

  int _publishEpochMs(Map<String, dynamic> pkg) {
    final v = pkg['publishTime'] ??
        pkg['publish_time'] ??
        pkg['publishDate'] ??
        pkg['createdTime'];
    if (v == null) return 0;

    if (v is int) {
      if (v > 100000000000) return v;
      if (v > 1000000000) return v * 1000;
      return 0;
    }
    if (v is double) {
      final n = v.toInt();
      if (n > 100000000000) return n;
      if (n > 1000000000) return n * 1000;
      return 0;
    }

    final s = v.toString();
    final n = int.tryParse(s);
    if (n != null) {
      if (n > 100000000000) return n;
      if (n > 1000000000) return n * 1000;
    }
    try {
      return DateTime.parse(s).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _receive(String? code) async {
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('代码为空');
      return;
    }
    if (_receivedPackageCodes.contains(code)) {
      SmartDialog.showToast('已领取，无需重复');
      return;
    }
    if (_receivingPackageCodes.contains(code)) {
      return;
    }
    final idx = _packages
        .indexWhere((e) => (e['code']?.toString() ?? '') == (code.toString()));
    if (idx != -1) {
      final st = _packages[idx]['status'];
      final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
      if (stInt == 1) {
        SmartDialog.showToast('已领取，无需重复');
        return;
      }
      if (stInt == 2) {
        SmartDialog.showToast('已完成，无法领取');
        return;
      }
      if (stInt != 0) {
        SmartDialog.showToast('当前状态无法领取');
        return;
      }
    }
    setState(() {
      _receivingPackageCodes.add(code);
    });
    try {
      SmartDialog.showLoading();
      final r = await ProductApi().receiveTrainShuntingPackage(code: code);
      SmartDialog.dismiss();
      if (r != null) {
        _receivedPackageCodes.add(code);
        final localIdx = _packages.indexWhere(
            (e) => (e['code']?.toString() ?? '') == (code.toString()));
        if (localIdx != -1) {
          setState(() {
            _packages[localIdx]['status'] = 1;
          });
        }
        SmartDialog.showToast('领取成功');
        await _loadData();
      } else {
        SmartDialog.showToast('领取失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('领取失败');
    } finally {
      if (mounted) {
        setState(() {
          _receivingPackageCodes.remove(code);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchText.isEmpty
        ? _packages
        : _packages.where((pkg) {
            return _packageMatchesKeyword(pkg, _searchText);
          }).toList();

    final sortedAll = List<Map<String, dynamic>>.from(filtered);
    sortedAll.sort((a, b) {
      final aNeedEnable = _isUnreceivedPkg(a);
      final bNeedEnable = _isUnreceivedPkg(b);
      if (aNeedEnable != bNeedEnable) return aNeedEnable ? -1 : 1;

      final aCompleted = _pkgStatus(a) == 2;
      final bCompleted = _pkgStatus(b) == 2;
      if (aCompleted != bCompleted) return aCompleted ? 1 : -1;

      final at = _publishEpochMs(a);
      final bt = _publishEpochMs(b);
      if (at != bt) return bt.compareTo(at);

      final an = (a['packageName'] ?? a['name'] ?? '').toString();
      final bn = (b['packageName'] ?? b['name'] ?? '').toString();
      return an.compareTo(bn);
    });

    final allList = sortedAll;
    final unfinishedList =
        sortedAll.where((pkg) => _pkgStatus(pkg) == 0).toList(growable: false);
    final completedList =
        sortedAll.where((pkg) => _pkgStatus(pkg) == 2).toList(growable: false);

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('调车作业计划'),
          backgroundColor: Colors.white,
          elevation: 1,
          bottom: const TabBar(
            tabs: [
              Tab(text: '总勾计划'),
              Tab(text: '已完成'),
              Tab(text: '未完成'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showPackageSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: _pickPlanDate,
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'clear_search') {
                  setState(() => _searchText = '');
                  return;
                }
                if (v == 'clear_date') {
                  await _clearPlanDate();
                  return;
                }
                if (v == 'search') {
                  _showPackageSearchDialog();
                  return;
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                items.add(
                  const PopupMenuItem<String>(
                    value: 'search',
                    child: Text('查询'),
                  ),
                );
                if (_searchText.trim().isNotEmpty) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'clear_search',
                      child: Text('清空查询'),
                    ),
                  );
                }
                if (_planDate != null) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'clear_date',
                      child: Text('清空日期'),
                    ),
                  );
                }
                return items;
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildPackageList(allList),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildPackageList(completedList),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildPackageList(unfinishedList),
                  ),
                ],
              ),
      ),
    );
  }
}

class TrainShuntingPlanListPage extends StatefulWidget {
  final String title;
  final String packageCode;
  final List<Map<String, dynamic>> planList;
  final bool readOnly;

  const TrainShuntingPlanListPage({
    super.key,
    required this.title,
    required this.packageCode,
    required this.planList,
    this.readOnly = false,
  });

  @override
  State<TrainShuntingPlanListPage> createState() =>
      _TrainShuntingPlanListPageState();
}

class _TrainShuntingPlanListPageState extends State<TrainShuntingPlanListPage> {
  late List<Map<String, dynamic>> _planList;
  bool _changed = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, XFile?> _slipRemoveImageByPlanCode = <String, XFile?>{};
  final Map<String, XFile?> _slipSetupImageByPlanCode = <String, XFile?>{};
  final Map<String, bool> _slipRemoveUploadedByPlanCode = <String, bool>{};
  final Map<String, Future<Image?>> _previewFutureByUrl = <String, Future<Image?>>{};
  String _trainNumKeyword = '';
  @override
  void initState() {
    super.initState();
    _planList =
        widget.planList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildXFilePreview(XFile f) {
    return FutureBuilder<Uint8List>(
      future: f.readAsBytes(),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return const ColoredBox(color: Color(0xFFE0E0E0));
        }
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }

  Widget _buildRemoteThumb(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const ColoredBox(color: Color(0xFFE0E0E0));
    }
    final f = _previewFutureByUrl.putIfAbsent(
      trimmed,
      () => ProductApi().previewImage(queryParametrs: {'url': trimmed}),
    );
    return FutureBuilder<Image?>(
      future: f,
      builder: (context, snap) {
        final img = snap.data;
        if (img != null) {
          return FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: img,
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const ColoredBox(color: Color(0xFFE0E0E0));
        }
        return Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: Color(0xFFE0E0E0));
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const ColoredBox(color: Color(0xFFE0E0E0));
          },
        );
      },
    );
  }

  void _previewLocalXFile(String title, XFile f) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildXFilePreview(f),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _previewRemoteUrl(String title, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final nav = Navigator.of(context);
    SmartDialog.showLoading(msg: '加载中...');
    Image? image;
    try {
      image = await ProductApi().previewImage(queryParametrs: {'url': trimmed});
    } catch (_) {}
    if (!nav.mounted) {
      SmartDialog.dismiss();
      return;
    }
    SmartDialog.dismiss();
    showDialog<void>(
      context: nav.context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image ??
                  Image.network(
                    trimmed,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('图片加载失败'));
                    },
                  ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showTrainNumSearchDialog() {
    final controller = TextEditingController(text: _trainNumKeyword);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('车号查询'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入车号进行查询',
            ),
            autofocus: true,
            onSubmitted: (_) => _applyTrainNumFilter(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _trainNumKeyword = '');
                Navigator.of(context).pop();
              },
              child: const Text('清空'),
            ),
            TextButton(
              onPressed: () => _applyTrainNumFilter(controller.text),
              child: const Text('查询'),
            ),
          ],
        );
      },
    );
  }

  void _applyTrainNumFilter(String kw) {
    final keyword = kw.trim();
    if (keyword.isEmpty) return;
    final has = _planList.any((p) {
      final trainNum = (p['trainNum'] ?? '').toString();
      final ends = formatEndsSuffix(p['ends']);
      final combined = '$trainNum$ends';
      return trainNum.contains(keyword) || combined.contains(keyword);
    });
    if (!has) {
      SmartDialog.showToast('车号查询为空');
      return;
    }
    setState(() => _trainNumKeyword = keyword);
    Navigator.of(context).pop();
  }

  ///

  List<Map<String, dynamic>> _extractUploadedImageEntries(
      Map<String, dynamic> plan) {
    final out = <Map<String, dynamic>>[];
    void add(dynamic e) {
      if (e == null) return;
      if (e is String) {
        final s = e.trim();
        if (s.isNotEmpty) out.add({'downloadUrl': s});
        return;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final url = (m['downloadUrl'] ?? m['url'] ?? m['path'] ?? '').toString();
        if (url.isEmpty) return;
        final t = m['antiSlipType'] ?? m['type'] ?? m['anti_slip_type'];
        out.add({'downloadUrl': url, if (t != null) 'antiSlipType': t});
      }
    }

    final candidates = <dynamic>[
      plan['antiSlipFileList'],
      plan['fileList'],
      plan['files'],
      plan['downLoadUrlList'],
      plan['downloadUrlList'],
    ];
    for (final c in candidates) {
      if (c is List) {
        for (final e in c) {
          add(e);
        }
      } else {
        add(c);
      }
    }
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final e in out) {
      final url = (e['downloadUrl'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      final t = e['antiSlipType']?.toString().trim() ?? '';
      final key = '$t|$url';
      if (seen.add(key)) result.add(e);
    }
    return result;
  }

  Future<bool> _completeOnly(int index) async {
    final item = _planList[index];
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return false;
    }
    try {
      final r = await ProductApi().completeTrainShuntingPackage(code: code);
      if (r != null) {
        SmartDialog.showToast('完成成功');
        setState(() {
          if (r is Map) {
            final next = Map<String, dynamic>.from(r);
            final old = _planList[index];
            old
              ..clear()
              ..addAll(next);
          }
        });
        _changed = true;
        await _refresh();
        return true;
      } else {
        SmartDialog.showToast('完成失败');
        return false;
      }
    } catch (e) {
      SmartDialog.showToast('完成失败: $e');
      return false;
    }
  }

  int _indexByPlanCode(String planCode) {
    if (planCode.trim().isEmpty) return -1;
    return _planList.indexWhere(
      (e) => (e['code'] ?? '').toString() == planCode,
    );
  }

  bool _isPlanCompleted(Map<String, dynamic> plan) {
    final st = plan['status'];
    final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
    if (stInt == 2) return true;
    final completeTimeFlag = (plan['completeTime'] ?? '').toString().trim();
    if (completeTimeFlag.isNotEmpty) return true;
    return false;
  }

  Future<bool> _uploadSlipImage({
    required Map<String, dynamic> plan,
    List<XFile>? images,
    XFile? image,
    required int antiSlipType,
  }) async {
    try {
      final list = images ?? (image != null ? <XFile>[image] : const <XFile>[]);
      if (list.isEmpty) return false;
      final r = await ProductApi().upShuntingImg(
        queryParametrs: {
          "trainEntryCode": plan['trainEntryCode'],
          "shuntingPlanCode": plan['code'],
          "antiSlipType": antiSlipType,
        },
        imagedataList: list.map((e) => File(e.path)).toList(),
      );
      if (r != 200) {
        SmartDialog.showToast('图片上传失败，状态码: $r');
        return false;
      }
      return true;
    } catch (e) {
      SmartDialog.showToast('图片上传失败: $e');
      return false;
    }
  }

  ///

  Future<bool> _pickSlipCamera(int index, {required bool isRemove}) async {
    final plan = _planList[index];
    final planCode = (plan['code'] ?? '').toString();
    if (planCode.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return false;
    }
    if (isRemove) {
      final photos = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute<List<XFile>>(
          builder: (context) => const _BurstCameraPage(
            title: '起防溜撤除图片',
          ),
        ),
      );
      if (photos == null || photos.isEmpty || !mounted) return false;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => _SlipImagesReviewPage(
            title: '起防溜撤除图片',
            images: photos,
            onBeforeUpload: () async {
              final st = _planList[index]['status'];
              final stInt =
                  st is int ? st : int.tryParse(st?.toString() ?? '');
              final isStarted = stInt == 4;
              final isCompleted = stInt == 2;
              if (isStarted || isCompleted) return true;
              return await _start(index);
            },
            onUpload: (img) => _uploadSlipImage(
              plan: plan,
              image: img,
              antiSlipType: 1,
            ),
            onUploadAll: (imgs) => _uploadSlipImage(
              plan: plan,
              images: imgs,
              antiSlipType: 1,
            ),
          ),
        ),
      );
      if (ok != true || !mounted) return false;
      setState(() {
        _slipRemoveImageByPlanCode[planCode] = photos.first;
        _slipRemoveUploadedByPlanCode[planCode] = true;
      });
      await _refresh();
      return false;
    }
    final photos = await Navigator.of(context).push<List<XFile>>(
      MaterialPageRoute<List<XFile>>(
        builder: (context) => const _BurstCameraPage(
          title: '止防溜设置图片',
        ),
      ),
    );
    if (photos == null || photos.isEmpty || !mounted) return false;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _SlipImagesReviewPage(
          title: '止防溜设置图片',
          images: photos,
          onBeforeUpload: () async {
            final st = _planList[index]['status'];
            final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
            final isStarted = stInt == 4;
            final completeTimeFlag =
                (_planList[index]['completeTime'] ?? '').toString().trim();
            final isCompleted = stInt == 2 || completeTimeFlag.isNotEmpty;
            if (isStarted || isCompleted) return true;
            return await _start(index);
          },
          onUpload: (img) => _uploadSlipImage(
            plan: plan,
            image: img,
            antiSlipType: 0,
          ),
          onUploadAll: (imgs) => _uploadSlipImage(
            plan: plan,
            images: imgs,
            antiSlipType: 0,
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return false;
    setState(() {
      _slipSetupImageByPlanCode[planCode] = photos.first;
    });
    await _refresh();
    final st = plan['status'];
    final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
    final completeTimeFlag = (plan['completeTime'] ?? '').toString().trim();
    final isCompleted = stInt == 2 || completeTimeFlag.isNotEmpty;
    if (isCompleted) {
      return true;
    }
    final completeOk = await _completeOnly(index);
    return completeOk || _isPlanCompleted(_planList[index]);
  }

  void _removeSlipImage(String planCode, {required bool isRemove}) {
    setState(() {
      if (isRemove) {
        _slipRemoveImageByPlanCode.remove(planCode);
        _slipRemoveUploadedByPlanCode.remove(planCode);
      } else {
        _slipSetupImageByPlanCode.remove(planCode);
      }
    });
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

  Future<void> _refresh() async {
    try {
      var r = await ProductApi().getTrainShuntingPackage(queryParametrs: {
        'code': widget.packageCode,
      });
      Map<String, dynamic>? pkg;
      if (r is List && r.isNotEmpty) {
        for (final e in r) {
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            final c = (m['code'] ?? '').toString();
            if (c == widget.packageCode) {
              pkg = m;
              break;
            }
          }
        }
        if (pkg == null) {
          final first = r.first;
          if (first is Map) {
            pkg = Map<String, dynamic>.from(first);
          }
        }
      }
      if (pkg == null) {
        r = await ProductApi().getTrainShuntingPackage();
        if (r is List) {
          for (final e in r) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              final c = (m['code'] ?? '').toString();
              if (c == widget.packageCode) {
                pkg = m;
                break;
              }
            }
          }
        }
      }
      if (pkg == null) return;

      final rawList = pkg['trainShuntingPlanList'];
      final list = rawList is List
          ? rawList
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        final oldByCode = <String, Map<String, dynamic>>{};
        for (final old in _planList) {
          final c = (old['code'] ?? '').toString();
          if (c.isNotEmpty) oldByCode[c] = old;
        }
        final merged = <Map<String, dynamic>>[];
        for (final n in list) {
          final c = (n['code'] ?? '').toString();
          final old = c.isEmpty ? null : oldByCode[c];
          if (old != null) {
            old
              ..clear()
              ..addAll(n);
            merged.add(old);
          } else {
            merged.add(n);
          }
        }
        _planList = merged;
      });
    } catch (e) {
      if (mounted) {
        SmartDialog.showToast('刷新失败');
      }
    }
  }

  Future<bool> _start(int index) async {
    final item = _planList[index];
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return false;
    }
    try {
      SmartDialog.showLoading(msg: '正在开工...');
      final r = await ProductApi().startTrainShuntingPackage(code: code);
      String? errMsg;
      if (r is Map) {
        final inner = r['data'];
        if (inner is Map) {
          final innerCode = inner['code'];
          final innerCodeInt =
              innerCode is int ? innerCode : int.tryParse('$innerCode');
          if (innerCodeInt != null && innerCodeInt != 0 && innerCodeInt != 200) {
            final m = inner['msg'] ?? inner['message'];
            if (m != null) {
              errMsg = m.toString();
            }
          }
        }
      }
      final msg = errMsg?.trim();
      if (msg != null && msg.isNotEmpty) {
        SmartDialog.dismiss();
        SmartDialog.showToast(msg);
        return false;
      }
      if (r != null) {
        _changed = true;
        await _refresh();
        SmartDialog.dismiss();
        SmartDialog.showToast('开工成功');
        return true;
      } else {
        SmartDialog.dismiss();
        SmartDialog.showToast('开工失败');
        return false;
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('开工失败: $e');
      return false;
    }
  }

  Future<bool> _complete(int index, {List<XFile>? imageFiles}) async {
    final item = _planList[index];
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return false;
    }
    final st = item['status'];
    final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
    final isStarted = stInt == 4;

    if (isStarted) {
      if (imageFiles == null || imageFiles.isEmpty) {
        SmartDialog.showToast('请上传止防溜设置图片');
        return false;
      }
      final ok2 = await _uploadSlipImage(
        plan: item,
        image: imageFiles.last,
        antiSlipType: 0,
      );
      if (!ok2) return false;
    } else {
      if (imageFiles == null || imageFiles.length != 2) {
        SmartDialog.showToast('请上传起防溜撤除图片和止防溜设置图片');
        return false;
      }
      final planCode = code;
      final removeUploaded = _slipRemoveUploadedByPlanCode[planCode] == true;
      if (!removeUploaded) {
        final ok1 = await _uploadSlipImage(
          plan: item,
          image: imageFiles[0],
          antiSlipType: 1,
        );
        if (!ok1) return false;
        if (mounted) {
          setState(() {
            _slipRemoveUploadedByPlanCode[planCode] = true;
          });
        }
      }
      final ok2 = await _uploadSlipImage(
        plan: item,
        image: imageFiles[1],
        antiSlipType: 0,
      );
      if (!ok2) return false;
    }

    // 再调用完成接口
    SmartDialog.showLoading(msg: '正在完成...');
    try {
      final r = await ProductApi().completeTrainShuntingPackage(code: code);
      SmartDialog.dismiss();
      if (r != null) {
        SmartDialog.showToast('完成成功');
        setState(() {
          if (r is Map) {
            _planList[index] = Map<String, dynamic>.from(r);
          }
        });
        _changed = true;
        await _refresh();
        return true;
      } else {
        SmartDialog.showToast('完成失败');
        return false;
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('完成失败: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kw = _trainNumKeyword.trim();
    final visibleIndices = kw.isEmpty
        ? List<int>.generate(_planList.length, (i) => i)
        : (() {
            final out = <int>[];
            for (var i = 0; i < _planList.length; i++) {
              final p = _planList[i];
              final trainNum = (p['trainNum'] ?? '').toString();
              final ends = formatEndsSuffix(p['ends']);
              final combined = '$trainNum$ends';
              if (trainNum.contains(kw) || combined.contains(kw)) {
                out.add(i);
              }
            }
            return out;
          })();
    final bodyWidget = _planList.isEmpty
        ? const Center(child: Text('暂无计划'))
        : (visibleIndices.isEmpty
            ? const Center(child: Text('暂无数据'))
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: visibleIndices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final actualIndex = visibleIndices[index];
                  final p = _planList[actualIndex];
                  final planCode = (p['code'] ?? '').toString();
                  final typeName = (p['typeName'] ?? '').toString();
                  final trainNum = (p['trainNum'] ?? '').toString();
                  final startAreaName = (p['startAreaName'] ?? '').toString();
                  final startTrackNum = (p['startTrackNum'] ?? '').toString();
                  final endAreaName = (p['endAreaName'] ?? '').toString();
                  final endTrackNum = (p['endTrackNum'] ?? '').toString();
                  final ends = formatEndsSuffix(p['ends']);
                  final st = p['status'];
                  final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
                  final isStarted = stInt == 4;
                  final isCompleted = stInt == 2;
                  final headerText = (typeName.isEmpty && trainNum.isEmpty)
                      ? '-'
                      : (typeName.isEmpty
                          ? '$trainNum$ends'
                          : (trainNum.isEmpty
                              ? typeName
                              : '$typeName $trainNum$ends'));
                  final startText = '$startAreaName-$startTrackNum';
                  final endText = '$endAreaName-$endTrackNum';

                  return Card(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => _TrainShuntingPlanDetailPage(
                              plan: p,
                              title: headerText,
                              readOnly: widget.readOnly,
                              buildRemoteThumb: _buildRemoteThumb,
                              previewRemoteUrl: _previewRemoteUrl,
                              previewLocalXFile: _previewLocalXFile,
                              buildXFilePreview: _buildXFilePreview,
                            pickRemove: () async {
                              final idx = _indexByPlanCode(planCode);
                              if (idx < 0) {
                                SmartDialog.showToast('数据异常：未找到作业记录');
                                return false;
                              }
                              await _pickSlipCamera(idx, isRemove: true);
                              return false;
                            },
                            pickSetup: () async {
                              final idx = _indexByPlanCode(planCode);
                              if (idx < 0) {
                                SmartDialog.showToast('数据异常：未找到作业记录');
                                return false;
                              }
                              return await _pickSlipCamera(idx, isRemove: false);
                            },
                              removeLocal: (isRemove) => _removeSlipImage(
                                planCode,
                                isRemove: isRemove,
                              ),
                              getLocalRemove: () => planCode.isEmpty
                                  ? null
                                  : _slipRemoveImageByPlanCode[planCode],
                              getLocalSetup: () => planCode.isEmpty
                                  ? null
                                  : _slipSetupImageByPlanCode[planCode],
                              getRemoveUploaded: () =>
                                  _slipRemoveUploadedByPlanCode[planCode] ==
                                  true,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    headerText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.1)
                                        : (isStarted
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.green
                                          : (isStarted
                                              ? Colors.orange
                                              : Colors.grey),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      isCompleted
                                          ? '已完成'
                                          : (isStarted ? '作业中' : '未开工'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isCompleted
                                            ? Colors.green
                                            : (isStarted
                                                ? Colors.orange
                                                : Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '起: $startText',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '止: $endText',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ));
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('调车作业记录'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showTrainNumSearchDialog,
          ),
          if (_trainNumKeyword.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _trainNumKeyword = ''),
            ),
        ],
      ),
      body: bodyWidget,
      ),
    );
  }
}

class _TrainShuntingPlanDetailPage extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String title;
  final bool readOnly;
  final Widget Function(String url) buildRemoteThumb;
  final Future<void> Function(String title, String url) previewRemoteUrl;
  final void Function(String title, XFile f) previewLocalXFile;
  final Widget Function(XFile f) buildXFilePreview;
  final Future<bool> Function() pickRemove;
  final Future<bool> Function() pickSetup;
  final void Function(bool isRemove) removeLocal;
  final XFile? Function() getLocalRemove;
  final XFile? Function() getLocalSetup;
  final bool Function() getRemoveUploaded;

  const _TrainShuntingPlanDetailPage({
    required this.plan,
    required this.title,
    required this.readOnly,
    required this.buildRemoteThumb,
    required this.previewRemoteUrl,
    required this.previewLocalXFile,
    required this.buildXFilePreview,
    required this.pickRemove,
    required this.pickSetup,
    required this.removeLocal,
    required this.getLocalRemove,
    required this.getLocalSetup,
    required this.getRemoveUploaded,
  });

  @override
  State<_TrainShuntingPlanDetailPage> createState() =>
      _TrainShuntingPlanDetailPageState();
}

class _TrainShuntingPlanDetailPageState extends State<_TrainShuntingPlanDetailPage> {
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

  List<Map<String, dynamic>> _extractUploadedImageEntries(Map<String, dynamic> plan) {
    final out = <Map<String, dynamic>>[];
    void add(dynamic e) {
      if (e == null) return;
      if (e is String) {
        final s = e.trim();
        if (s.isNotEmpty) out.add({'downloadUrl': s});
        return;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final url = (m['downloadUrl'] ?? m['url'] ?? m['path'] ?? '').toString();
        if (url.isEmpty) return;
        final t = m['antiSlipType'] ?? m['type'] ?? m['anti_slip_type'];
        out.add({'downloadUrl': url, if (t != null) 'antiSlipType': t});
      }
    }

    final candidates = <dynamic>[
      plan['antiSlipFileList'],
      plan['fileList'],
      plan['files'],
      plan['downLoadUrlList'],
      plan['downloadUrlList'],
    ];
    for (final c in candidates) {
      if (c is List) {
        for (final e in c) {
          add(e);
        }
      } else {
        add(c);
      }
    }
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final e in out) {
      final url = (e['downloadUrl'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      final t = e['antiSlipType']?.toString().trim() ?? '';
      final key = '$t|$url';
      if (seen.add(key)) result.add(e);
    }
    return result;
  }

  Future<void> _pickRemoveAndRefresh() async {
    await widget.pickRemove();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pickSetupAndRefresh() async {
    final completed = await widget.pickSetup();
    if (!mounted) return;
    setState(() {});
    if (completed) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final executorName = (plan['executorName'] ?? '').toString();
    final scheduleNodeName =
        (plan['scheduleNodeName'] ?? plan['nodeName'] ?? '').toString();
    final startAreaName = (plan['startAreaName'] ?? '').toString();
    final startTrackNum = (plan['startTrackNum'] ?? '').toString();
    final endAreaName = (plan['endAreaName'] ?? '').toString();
    final endTrackNum = (plan['endTrackNum'] ?? '').toString();
    final remark = (plan['remark'] ?? '').toString();
    final startTime = _fmt(plan['startTime']);
    final completeTime = _fmt(plan['completeTime']);
    final st = plan['status'];
    final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
    final isStarted = stInt == 4;
    final isCompleted = stInt == 2;

    final remoteEntries = _extractUploadedImageEntries(plan);
    final typed1 = remoteEntries
        .where((e) => (e['antiSlipType']?.toString() ?? '') == '1')
        .toList();
    final typed0 = remoteEntries
        .where((e) => (e['antiSlipType']?.toString() ?? '') == '0')
        .toList();

    final localRemove = widget.getLocalRemove();
    final localSetup = widget.getLocalSetup();
    final removeUploaded = widget.getRemoveUploaded();

    Widget buildRemoteGrid(String gridTitle, List<Map<String, dynamic>> list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gridTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (list.isEmpty)
            const Text(
              '暂无',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list.map((e) {
                final url = (e['downloadUrl'] ?? '').toString();
                if (url.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => widget.previewRemoteUrl(gridTitle, url),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.buildRemoteThumb(url),
                    ),
                  ),
                );
              }).whereType<Widget>().toList(),
            ),
        ],
      );
    }

    Widget buildLocalSection() {
      if (widget.readOnly) return const SizedBox.shrink();
      if (isCompleted) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('上传防溜资源', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (!isStarted && !isCompleted) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickRemoveAndRefresh,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('拍摄起防溜撤除图片'),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: localRemove == null
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Center(
                            child: Text(
                              '未上传',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => widget.previewLocalXFile(
                            '起防溜撤除图片',
                            localRemove,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.buildXFilePreview(localRemove),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    removeUploaded ? '已上传起防溜撤除图片' : '未上传起防溜撤除图片',
                    style: TextStyle(
                      fontSize: 12,
                      color: removeUploaded ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                if (localRemove != null)
                  IconButton(
                    onPressed: () {
                      widget.removeLocal(true);
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _pickSetupAndRefresh,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('拍摄止防溜设置图片'),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: localSetup == null
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Center(
                          child: Text(
                            '未上传',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => widget.previewLocalXFile(
                          '止防溜设置图片',
                          localSetup,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.buildXFilePreview(localSetup),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  localSetup == null ? '未上传止防溜设置图片' : '已上传止防溜设置图片',
                  style: TextStyle(
                    fontSize: 12,
                    color: localSetup == null ? Colors.red : Colors.green,
                  ),
                ),
              ),
              if (localSetup != null)
                IconButton(
                  onPressed: () {
                    widget.removeLocal(false);
                    setState(() {});
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : (isStarted
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isStarted ? Colors.orange : Colors.grey),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    isCompleted ? '已完成' : (isStarted ? '作业中' : '未开工'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? Colors.green
                          : (isStarted ? Colors.orange : Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('处理人: $executorName'),
          if (scheduleNodeName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('节点: $scheduleNodeName'),
          ],
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          Text('开工时间: $startTime'),
          const SizedBox(height: 6),
          Text('完成时间: $completeTime'),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('备注: $remark'),
          ],
          const SizedBox(height: 14),
          buildRemoteGrid('起防溜撤除图片', typed1),
          const SizedBox(height: 12),
          buildRemoteGrid('止防溜设置图片', typed0),
          buildLocalSection(),
        ],
      ),
    );
  }
}

class _BurstCameraPage extends StatefulWidget {
  final String title;
  final List<XFile>? initialImages;

  const _BurstCameraPage({required this.title, this.initialImages});

  @override
  State<_BurstCameraPage> createState() => _BurstCameraPageState();
}

class _BurstCameraPageState extends State<_BurstCameraPage> {
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  final List<XFile> _photos = <XFile>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      _photos.addAll(widget.initialImages!);
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        SmartDialog.showToast('无法打开相机');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_capturing) return;
    try {
      setState(() => _capturing = true);
      final file = await ctrl.takePicture();
      if (!mounted) return;
      setState(() {
        _photos.add(file);
        _capturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      SmartDialog.showToast('拍摄失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: _initializing || ctrl == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: CameraPreview(ctrl)),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _photos.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _LocalGalleryPage(
                                      images: _photos,
                                      initialIndex: _photos.length - 1,
                                    ),
                                  ),
                                );
                              },
                        child: SizedBox(
                          width: 90,
                          height: 56,
                          child: _photos.isEmpty
                              ? const SizedBox.shrink()
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_photos.last.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(36),
                          onTap: _capturing ? null : _takePicture,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: _capturing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _photos.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(_photos),
                        child: Text(
                          '完成',
                          style: TextStyle(
                            color: _photos.isEmpty ? Colors.white54 : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SlipImagesReviewPage extends StatefulWidget {
  final String title;
  final List<XFile> images;
  final Future<bool> Function(XFile image) onUpload;
  final Future<bool> Function(List<XFile> images) onUploadAll;
  final Future<bool> Function()? onBeforeUpload;

  const _SlipImagesReviewPage({
    required this.title,
    required this.images,
    required this.onUpload,
    required this.onUploadAll,
    this.onBeforeUpload,
  });

  @override
  State<_SlipImagesReviewPage> createState() => _SlipImagesReviewPageState();
}

class _SlipImagesReviewPageState extends State<_SlipImagesReviewPage> {
  late List<int> _statuses;
  late List<XFile> _images;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _images = List<XFile>.from(widget.images);
    _statuses = List<int>.filled(_images.length, 0, growable: true);
  }

  ///

  String _statusText(int s) {
    if (s == 0) return '待上传';
    if (s == 1) return '上传中';
    if (s == 2) return '已完成';
    return '失败';
    }

  Color _statusColor(int s) {
    if (s == 1) return Colors.blue;
    if (s == 2) return Colors.green;
    if (s == -1) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _statuses.isNotEmpty && _statuses.every((e) => e == 2);
    return WillPopScope(
      onWillPop: () async {
        await Navigator.of(context).pushReplacement<List<XFile>, List<XFile>>(
          MaterialPageRoute<List<XFile>>(
            builder: (_) => _BurstCameraPage(
              title: widget.title,
              initialImages: _images,
            ),
          ),
        );
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: canFinish ? () => Navigator.of(context).pop(true) : null,
            child: Text(
              '完成',
              style: TextStyle(color: canFinish ? Colors.white : Colors.white54),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final img = _images[index];
          final st = _statuses[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _LocalGalleryPage(
                        images: _images,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(img.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusText(st),
                  style: TextStyle(color: _statusColor(st)),
                ),
              ),
              if (st == 0)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _processing
                      ? null
                      : () {
                          setState(() {
                            _images.removeAt(index);
                            _statuses.removeAt(index);
                          });
                        },
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _processing
                ? null
                : () async {
                    if (_images.isEmpty) {
                      SmartDialog.showToast('无可上传图片');
                      return;
                    }
                    setState(() => _processing = true);
                    if (widget.onBeforeUpload != null) {
                      final okStart = await widget.onBeforeUpload!.call();
                      if (!okStart) {
                        if (mounted) setState(() => _processing = false);
                        return;
                      }
                    }
                    final ok = await widget.onUploadAll(_images);
                    setState(() {
                      for (int i = 0; i < _statuses.length; i++) {
                        _statuses[i] = ok ? 2 : -1;
                      }
                      _processing = false;
                    });
                    if (ok && mounted) Navigator.of(context).pop(true);
                  },
            child: const Text('上传'),
          ),
        ),
      ),
    ),
    );
  }
}

class _LocalGalleryPage extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;

  const _LocalGalleryPage({required this.images, required this.initialIndex});

  @override
  State<_LocalGalleryPage> createState() => _LocalGalleryPageState();
}

class _LocalGalleryPageState extends State<_LocalGalleryPage> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('预览 ${_current + 1}/${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _current = i),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final img = widget.images[index];
          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.file(
                File(img.path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrainShuntingCompletePage extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Future<bool> Function(List<XFile> images) onComplete;

  const TrainShuntingCompletePage({
    super.key,
    required this.plan,
    required this.onComplete,
  });

  @override
  State<TrainShuntingCompletePage> createState() =>
      _TrainShuntingCompletePageState();
}

class _TrainShuntingCompletePageState extends State<TrainShuntingCompletePage> {
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  bool _submitting = false;

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final ms = int.tryParse(s);
    if (ms != null && ms > 100000000000) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }
    try {
      final dt = DateTime.parse(s);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      return s;
    }
  }

  Future<void> _pickCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null || !mounted) return;
    setState(() {
      _images.add(photo);
    });
  }

  Widget _buildXFilePreview(XFile f) {
    return FutureBuilder<Uint8List>(
      future: f.readAsBytes(),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return const ColoredBox(color: Color(0xFFE0E0E0));
        }
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? '无' : value),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_images.isEmpty) {
      SmartDialog.showToast('请先上传图片');
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final ok = await widget.onComplete(_images);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainNum = (widget.plan['trainNum'] ?? '').toString();
    final typeName = (widget.plan['typeName'] ?? '').toString();

    final ends = (widget.plan['ends'] ?? '').toString();
    final executorName = (widget.plan['executorName'] ?? '').toString();
    final startAreaName = (widget.plan['startAreaName'] ?? '').toString();
    final startTrackNum = (widget.plan['startTrackNum'] ?? '').toString();
    final endAreaName = (widget.plan['endAreaName'] ?? '').toString();
    final endTrackNum = (widget.plan['endTrackNum'] ?? '').toString();
    final remark = (widget.plan['remark'] ?? '').toString();
    final startTime = _fmtDate(widget.plan['startTime']);
    final completeTime = _fmtDate(widget.plan['completeTime']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('调车作业'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$typeName $trainNum'.trim(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '调车信息',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _infoRow('机型', typeName),
                    _infoRow('车号', trainNum),
                    _infoRow('方向', ends),
                    _infoRow('处理人', executorName),
                    _infoRow('起始区域', startAreaName),
                    _infoRow('起始股道', startTrackNum),
                    _infoRow('结束区域', endAreaName),
                    _infoRow('结束股道', endTrackNum),
                    _infoRow('开工时间', startTime),
                    _infoRow('完成时间', completeTime),
                    if (remark.isNotEmpty) _infoRow('备注', remark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '上传防溜资源',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    if (_images.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('请拍摄防溜照片', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < _images.length; i++)
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: _buildXFilePreview(_images[i]),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _images.removeAt(i);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('拍照'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '提交中...' : '上传并完成'),
              ),
            ),
          ],
        ),
      ),
    );  
  }
}
