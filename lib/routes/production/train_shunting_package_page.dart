import '../../index.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      var r = await ProductApi().getTrainShuntingPackage();
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
  final Map<String, bool> _slipRemoveUploadedByPlanCode = <String, bool>{};
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
      SmartDialog.showToast('完成失败: $e');
      return false;
    }
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

  Future<void> _pickSlipCamera(int index, {required bool isRemove}) async {
    final plan = _planList[index];
    final planCode = (plan['code'] ?? '').toString();
    if (planCode.isEmpty) {
      SmartDialog.showToast('数据异常：缺少代码');
      return;
    }
    if (isRemove) {
      final photos = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute<List<XFile>>(
          builder: (context) => const _BurstCameraPage(
            title: '起防溜撤除图片',
          ),
        ),
      );
      if (photos == null || photos.isEmpty || !mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => _SlipImagesReviewPage(
            title: '起防溜撤除图片',
            images: photos,
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
      if (ok != true || !mounted) return;
      setState(() {
        _slipRemoveImageByPlanCode[planCode] = photos.first;
        _slipRemoveUploadedByPlanCode[planCode] = true;
      });
      await _start(index);
      return;
    }
    final photos = await Navigator.of(context).push<List<XFile>>(
      MaterialPageRoute<List<XFile>>(
        builder: (context) => const _BurstCameraPage(
          title: '止防溜设置图片',
        ),
      ),
    );
    if (photos == null || photos.isEmpty || !mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _SlipImagesReviewPage(
          title: '止防溜设置图片',
          images: photos,
          onUpload: (img) => _uploadSlipImage(
            plan: plan,
            image: img,
            antiSlipType: 2,
          ),
          onUploadAll: (imgs) => _uploadSlipImage(
            plan: plan,
            images: imgs,
            antiSlipType: 2,
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _slipSetupImageByPlanCode[planCode] = photos.first;
    });
    final st = plan['status'];
    final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
    final isStarted = stInt == 4;
    final isCompleted = stInt == 2;
    if (isStarted && !isCompleted) {
      await _completeOnly(index);
    }
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
        return;
      }
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
        antiSlipType: 2,
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
        antiSlipType: 2,
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
                final scheduleNodeName =
                    (p['scheduleNodeName'] ?? p['nodeName'] ?? '').toString();
                final startAreaName = (p['startAreaName'] ?? '').toString();
                final startTrackNum = (p['startTrackNum'] ?? '').toString();
                final endAreaName = (p['endAreaName'] ?? '').toString();
                final endTrackNum = (p['endTrackNum'] ?? '').toString();
                final remark = (p['remark'] ?? '').toString();
                final startTime = _fmt(p['startTime']);
                final completeTime = _fmt(p['completeTime']);
                final ends = _fmt(p['ends']);
                final st = p['status'];
                final stInt =
                    st is int ? st : int.tryParse(st?.toString() ?? '');
                final isStarted = stInt == 4;
                final isCompleted = stInt == 2;
                final removeImage = planCode.isEmpty
                    ? null
                    : _slipRemoveImageByPlanCode[planCode];
                final setupImage = planCode.isEmpty
                    ? null
                    : _slipSetupImageByPlanCode[planCode];
                final remoteEntries = _extractUploadedImageEntries(p);
                final typed1 = remoteEntries
                    .where((e) => (e['antiSlipType']?.toString() ?? '') == '1')
                    .toList();
                final typed2 = remoteEntries
                    .where((e) => (e['antiSlipType']?.toString() ?? '') == '2')
                    .toList();

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
                                            : '$typeName-$trainNum$ends')),
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
                        if (scheduleNodeName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('节点: $scheduleNodeName'),
                        ],
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
                        if (remoteEntries.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (typed1.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      PhotoPreviewDialog.show2(
                                        context,
                                        typed1,
                                        title: '起防溜撤除',
                                      );
                                    },
                                    child:
                                        Text('起防溜撤除(${typed1.length})'),
                                  ),
                                if (typed2.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      PhotoPreviewDialog.show2(
                                        context,
                                        typed2,
                                        title: '止防溜设置',
                                      );
                                    },
                                    child:
                                        Text('止防溜设置(${typed2.length})'),
                                  ),
                                if (typed1.isEmpty && typed2.isEmpty)
                                  TextButton(
                                    onPressed: () {
                                      PhotoPreviewDialog.show2(
                                        context,
                                        remoteEntries,
                                        title: '防溜图片',
                                      );
                                    },
                                    child: Text(
                                        '查看防溜图片(${remoteEntries.length})'),
                                  ),
                              ],
                            ),
                          ),
                        if (remark.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('备注: $remark'),
                        ],
                        const SizedBox(height: 10),
                        if (!isCompleted)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '上传防溜资源',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (!isStarted) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _pickSlipCamera(
                                      index,
                                      isRemove: true,
                                    ),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('拍摄起防溜撤除图片'),
                                  ),
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
                                                  borderRadius: BorderRadius.all(
                                                    Radius.circular(6),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '未上传',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                      child: _buildXFilePreview(
                                                        removeImage,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () => _removeSlipImage(
                                                        planCode,
                                                        isRemove: true,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(4),
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
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (!isCompleted) ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: isCompleted
                                    ? null
                                    : () => _pickSlipCamera(
                                          index,
                                          isRemove: false,
                                        ),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('拍摄止防溜设置图片'),
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
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(6),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '未上传',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            Positioned.fill(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child:
                                                    _buildXFilePreview(setupImage),
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
                                                    padding:
                                                        const EdgeInsets.all(4),
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
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: (isStarted && !isCompleted)
                                    ? () async {
                                        final sImg = planCode.isEmpty
                                            ? null
                                            : _slipSetupImageByPlanCode[planCode];
                                        if (sImg == null) {
                                          SmartDialog.showToast('请上传止防溜设置图片');
                                          return;
                                        }
                                        final imgs = <XFile>[sImg];
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
                                            _slipRemoveUploadedByPlanCode
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

  const _SlipImagesReviewPage({
    required this.title,
    required this.images,
    required this.onUpload,
    required this.onUploadAll,
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
