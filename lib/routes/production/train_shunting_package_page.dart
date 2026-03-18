import '../../index.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
  final Set<String> _receivedPackageCodes = <String>{};
  final Set<String> _receivingPackageCodes = <String>{};

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
                .where((e) => e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map))
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
            : (isReceived ? '已启用' : (stInt == 0 ? '未完成' : '未完成'));

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              if (!canEnter) {
                SmartDialog.showToast('请先启用');
                return;
              }
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
                      child: canEnable
                          ? TextButton(
                              onPressed: () => _receive(code),
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
                            ),
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
    final roleKeys = (Global.profile.permissions?.roles ?? const <String>[])
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
      return rn.contains('接车组') || rk.contains('jieche') || rk.contains('接车');
    })) {
      return true;
    }
    return false;
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      var r = await ProductApi().getTrainShuntingPackage();
      List<Map<String, dynamic>> rows = (r as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
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
            final name = (pkg['packageName'] ?? pkg['name'] ?? '').toString();
            return name.contains(_searchText);
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

  const TrainShuntingPlanListPage({
    super.key,
    required this.title,
    required this.packageCode,
    required this.planList,
  });

  @override
  State<TrainShuntingPlanListPage> createState() =>
      _TrainShuntingPlanListPageState();
}

class _TrainShuntingPlanListPageState extends State<TrainShuntingPlanListPage> {
  late List<Map<String, dynamic>> _planList;
  bool _changed = false;
  final Map<String, XFile?> _slipRemoveImageByPlanCode = <String, XFile?>{};
  final Map<String, XFile?> _slipSetupImageByPlanCode = <String, XFile?>{};
  final ImagePicker _slipImagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _planList =
        widget.planList.map((e) => Map<String, dynamic>.from(e)).toList();
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

  Future<void> _pickSlipCamera(String planCode, {required bool isRemove}) async {
    final XFile? photo = await _slipImagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null || !mounted) return;
    setState(() {
      if (isRemove) {
        _slipRemoveImageByPlanCode[planCode] = photo;
      } else {
        _slipSetupImageByPlanCode[planCode] = photo;
      }
    });
  }

  void _removeSlipImage(String planCode, {required bool isRemove}) {
    setState(() {
      if (isRemove) {
        _slipRemoveImageByPlanCode.remove(planCode);
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
              .where((e) => e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _planList = list;
      });
    } catch (e) {
      if (mounted) {
        SmartDialog.showToast('刷新失败');
      }
    }
  }

  Future<void> _start(int index) async {
    final item = _planList[index];
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '正在开工...');
      final r = await ProductApi().startTrainShuntingPackage(code: code);
      if (r != null) {
        _changed = true;
        await _refresh();
        SmartDialog.dismiss();
        SmartDialog.showToast('开工成功');
      } else {
        SmartDialog.dismiss();
        SmartDialog.showToast('开工失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('开工失败: $e');
    }
  }

  Future<bool> _complete(int index, {List<XFile>? imageFiles}) async {
    final item = _planList[index];
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return false;
    }
    // 先上传图片（必须）
    if (imageFiles == null || imageFiles.length != 2) {
      SmartDialog.showToast('请上传起防溜撤除图片和止防溜设置图片');
      return false;
    }
    SmartDialog.showLoading(msg: '正在上传...');
    try {
      var r = await ProductApi().upSlipImg(
        queryParametrs: {
          "trainEntryCode": item['trainEntryCode'],
          "shuntingPlanCode": item['code'],
        },
        imagedataList: imageFiles.map((xFile) => File(xFile.path)).toList(),
      );
      if (r != 200) {
        SmartDialog.dismiss();
        SmartDialog.showToast('图片上传失败，状态码: $r');
        return false;
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('图片上传失败: $e');
      return false;
    }
    SmartDialog.dismiss();

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
      ),
      body: _planList.isEmpty
          ? const Center(child: Text('暂无计划'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _planList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = _planList[index];
                final planCode = (p['code'] ?? '').toString();
                final executorName = (p['executorName'] ?? '').toString();
                final typeName = (p['typeName'] ?? '').toString();
                final trainNum = (p['trainNum'] ?? '').toString();
                final startAreaName = (p['startAreaName'] ?? '').toString();
                final startTrackNum = (p['startTrackNum'] ?? '').toString();
                final endAreaName = (p['endAreaName'] ?? '').toString();
                final endTrackNum = (p['endTrackNum'] ?? '').toString();
                final remark = (p['remark'] ?? '').toString();
                final startTime = _fmt(p['startTime']);
                final completeTime = _fmt(p['completeTime']);
                final st = p['status'];
                final stInt =
                    st is int ? st : int.tryParse(st?.toString() ?? '');
                final isStarted = stInt == 4;
                final isCompleted = stInt == 2;
                final canStart = stInt == 1;
                final removeImage = planCode.isEmpty
                    ? null
                    : _slipRemoveImageByPlanCode[planCode];
                final setupImage = planCode.isEmpty
                    ? null
                    : _slipSetupImageByPlanCode[planCode];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (typeName.isEmpty && trainNum.isEmpty)
                                    ? '-'
                                    : (typeName.isEmpty
                                        ? trainNum
                                        : (trainNum.isEmpty
                                            ? typeName
                                            : '$typeName-$trainNum')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('处理人: $executorName'),
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
                        const SizedBox(height: 6),
                        Text('开工时间: $startTime'),
                        const SizedBox(height: 6),
                        Text('完成时间: $completeTime'),
                        if (remark.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('备注: $remark'),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '上传防溜资源',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  isCompleted ? null : () => _pickSlipCamera(planCode, isRemove: true),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('拍摄起防溜撤除'),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 74,
                                height: 74,
                                child: removeImage == null
                                    ? const DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF0F0F0),
                                          borderRadius:
                                              BorderRadius.all(Radius.circular(6)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '未上传',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    : Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: _buildXFilePreview(removeImage),
                                            ),
                                          ),
                                          if (!isCompleted)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: GestureDetector(
                                                onTap: () => _removeSlipImage(
                                                  planCode,
                                                  isRemove: true,
                                                ),
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(4),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  removeImage == null
                                      ? '起防溜撤除图片'
                                      : '起防溜撤除图片已上传',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  isCompleted ? null : () => _pickSlipCamera(planCode, isRemove: false),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('拍摄止防溜设置'),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 74,
                                height: 74,
                                child: setupImage == null
                                    ? const DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF0F0F0),
                                          borderRadius:
                                              BorderRadius.all(Radius.circular(6)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '未上传',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    : Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: _buildXFilePreview(setupImage),
                                            ),
                                          ),
                                          if (!isCompleted)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: GestureDetector(
                                                onTap: () => _removeSlipImage(
                                                  planCode,
                                                  isRemove: false,
                                                ),
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(4),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  setupImage == null
                                      ? '止防溜设置图片'
                                      : '止防溜设置图片已上传',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: canStart ? () => _start(index) : null,
                                child: Text(isStarted
                                    ? '已开工'
                                    : (isCompleted ? '已完成' : '开工')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: (isStarted && !isCompleted)
                                    ? () async {
                                        final rImg = planCode.isEmpty
                                            ? null
                                            : _slipRemoveImageByPlanCode[planCode];
                                        final sImg = planCode.isEmpty
                                            ? null
                                            : _slipSetupImageByPlanCode[planCode];
                                        final imgs = <XFile>[
                                          if (rImg != null) rImg,
                                          if (sImg != null) sImg,
                                        ];
                                        final ok = await _complete(
                                          index,
                                          imageFiles: imgs,
                                        );
                                        if (ok &&
                                            mounted &&
                                            planCode.isNotEmpty) {
                                          setState(() {
                                            _slipRemoveImageByPlanCode
                                                .remove(planCode);
                                            _slipSetupImageByPlanCode
                                                .remove(planCode);
                                          });
                                        }
                                      }
                                    : null,
                                child: Text(isCompleted ? '已完成' : '完成'),
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
