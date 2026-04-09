import 'package:wechat_assets_picker/wechat_assets_picker.dart' hide AssetType;

import '../../index.dart';

class AfterSaleTempRepairRegisterPage extends StatefulWidget {
  const AfterSaleTempRepairRegisterPage({super.key});

  @override
  State<AfterSaleTempRepairRegisterPage> createState() =>
      _AfterSaleTempRepairRegisterPageState();
}

class _AfterSaleTempRepairRegisterPageState
    extends State<AfterSaleTempRepairRegisterPage> {
  static _AfterSaleTempRepairDraft? _draft;

  final _formKey = GlobalKey<FormState>();
  final _logger = AppLogger.logger;

  static const _pagePadding = EdgeInsets.all(12);
  static const _gap8 = SizedBox(height: 8);
  static const _gap12 = SizedBox(height: 12);
  static const _denseContentPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 10);

  InputDecoration _denseDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: _denseContentPadding,
    );
  }

  String get _currentUserName {
    final user = Global.profile.permissions?.user;
    final n1 = (user?.nickName ?? '').toString().trim();
    if (n1.isNotEmpty) return n1;
    final n2 = (user?.userName ?? '').toString().trim();
    return n2;
  }

  String get _currentUserPhone {
    final user = Global.profile.permissions?.user;
    final p1 = (user?.phonenumber ?? '').toString().trim();
    if (p1.isNotEmpty) return p1;
    return '';
  }

  DateTime? _faultDate;

  List<Map<String, dynamic>> _dynamicTypes = [];
  Map<String, dynamic>? _selectedDynamicType;
  List<Map<String, dynamic>> _jcTypes = [];
  Map<String, dynamic>? _selectedJcType;
  List<Map<String, dynamic>> _faultCategories = [];
  Map<String, dynamic>? _selectedFaultCategory;
  List<Map<String, dynamic>> _responsibilityDepts = [];
  Map<String, dynamic>? _selectedResponsibilityDept;

  final _trainNumController = TextEditingController();
  final _mileageController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<_FaultGroupControllers> _faultGroups = [];

  List<AssetEntity> _attachments = [];
  bool _jt9Loading = false;
  List<Map<String, dynamic>> _jt9Options = [];
  Map<String, dynamic>? _jt9Selected;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    if (_faultGroups.isEmpty) {
      _faultGroups.add(_FaultGroupControllers());
    }
    _contactController.text = _currentUserName;
    if (_phoneController.text.trim().isEmpty) {
      _phoneController.text = _currentUserPhone;
    }
    _loadDynamicTypes();
    _loadFaultCategories();
    _loadResponsibilityDepts();
  }

  @override
  void dispose() {
    _saveDraft();
    _trainNumController.dispose();
    _mileageController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    for (final g in _faultGroups) {
      g.dispose();
    }
    super.dispose();
  }

  void _addFaultGroup() {
    setState(() {
      _faultGroups.add(_FaultGroupControllers());
    });
  }

  void _removeFaultGroup(int index) {
    if (index < 0 || index >= _faultGroups.length) return;
    if (_faultGroups.length <= 1) return;
    final g = _faultGroups.removeAt(index);
    g.dispose();
    setState(() {});
  }

  Future<void> _loadDynamicTypes() async {
    try {
      final data = await ProductApi().getJcDynamicType(
        queryParametrs: {'pageNum': 0, 'pageSize': 0},
      );
      final rows = (data is Map ? data['rows'] : null);
      final list = rows is List
          ? rows
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _dynamicTypes = list;
      });
      if (_selectedDynamicType == null && list.isNotEmpty) {
        final draftDynamicCode = _draft?.dynamicCode;
        final selected = draftDynamicCode == null || draftDynamicCode.isEmpty
            ? list.first
            : (list.firstWhere(
                (e) => (e['code'] ?? '').toString() == draftDynamicCode,
                orElse: () => list.first,
              ));
        if (!mounted) return;
        setState(() {
          _selectedDynamicType = selected;
        });
        final code = (selected['code'] ?? '').toString();
        await _loadJcTypes(code);
        if (!mounted) return;
        if (_selectedJcType == null && _jcTypes.isNotEmpty) {
          final draftTypeCode = _draft?.typeCode;
          final picked = draftTypeCode == null || draftTypeCode.isEmpty
              ? _jcTypes.first
              : (_jcTypes.firstWhere(
                  (e) => (e['code'] ?? '').toString() == draftTypeCode,
                  orElse: () => _jcTypes.first,
                ));
          setState(() {
            _selectedJcType = picked;
          });
        }
      }
    } catch (e) {
      _logger.e(e);
    }
  }

  Future<void> _loadJcTypes(String? dynamicCode) async {
    if (dynamicCode == null || dynamicCode.trim().isEmpty) return;
    try {
      final r = await ProductApi().getJcType(
        queryParametrs: {
          'dynamicCode': dynamicCode,
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      final list = r.toMapList();
      if (!mounted) return;
      setState(() {
        _jcTypes = list;
      });
    } catch (e) {
      _logger.e(e);
    }
  }

  Future<void> _loadFaultCategories() async {
    try {
      final res = await ProductApi().getJtTypeSelectAll(
        queryParametrs: {
          'repairMainNodNameList': '临修-临修',
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      final list = res is List
          ? res
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _faultCategories = list;
        if (_selectedFaultCategory == null && list.isNotEmpty) {
          final draftCode = _draft?.faultCategoryCode;
          _selectedFaultCategory = draftCode == null || draftCode.isEmpty
              ? list.first
              : list.firstWhere(
                  (e) => (e['code'] ?? '').toString() == draftCode,
                  orElse: () => list.first,
                );
        }
      });
    } catch (e) {
      _logger.e(e);
    }
  }

  Future<void> _loadResponsibilityDepts() async {
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {
          'parentIdList': 101,
        },
      );
      final list = <Map<String, dynamic>>[];
      if (res is List && res.isNotEmpty) {
        final root = res.first;
        final children = root is Map ? root['children'] : null;
        if (children is List) {
          for (final e in children) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      } else if (res is Map) {
        final children = res['children'];
        if (children is List) {
          for (final e in children) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _responsibilityDepts = list;
        if (_selectedResponsibilityDept == null && list.isNotEmpty) {
          final draftDeptId = _draft?.deptId;
          _selectedResponsibilityDept = draftDeptId == null || draftDeptId.isEmpty
              ? list.first
              : list.firstWhere(
                  (e) => (e['deptId'] ?? '').toString() == draftDeptId,
                  orElse: () => list.first,
                );
        }
      });
    } catch (e) {
      _logger.e(e);
    }
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required void Function(DateTime) onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay.fromDateTime(initial)
          : TimeOfDay.now(),
      helpText:
          '选择时间（已选日期：${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}）',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (pickedTime == null || !mounted) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
      0,
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认时间'),
        content: Text(_fmtDate(dateTime.toIso8601String())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    onPicked(dateTime);
  }

  dynamic _extractUploadData(dynamic uploadResponse) {
    dynamic v = uploadResponse;
    if (v is Map && v.containsKey('data')) v = v['data'];
    if (v is Map && v.containsKey('data')) v = v['data'];
    return v;
  }

  String _extractResponseMessage(dynamic resp) {
    final messages = <String>[];
    dynamic v = resp;
    for (int i = 0; i < 6; i++) {
      if (v is Map) {
        final msg = (v['msg'] ?? v['message'] ?? v['error'])?.toString().trim();
        if (msg != null && msg.isNotEmpty) {
          messages.add(msg);
        }
        if (v.containsKey('data')) {
          v = v['data'];
          continue;
        }
      }
      break;
    }
    if (messages.isEmpty) return '';
    return messages.last;
  }

  String _asJsonString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    try {
      return jsonEncode(v);
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() == true;
    if (!ok) return;
    if (_faultDate == null) {
      showToast('请选择故障日期');
      return;
    }
    if (_selectedDynamicType == null) {
      showToast('请选择动力类型');
      return;
    }
    if (_selectedJcType == null) {
      showToast('请选择机型');
      return;
    }
    final groups = _faultGroups
        .map(
          (g) => {
            'faultSituation': g.faultSituationController.text.trim(),
            'faultPhenomenon': g.faultPhenomenonController.text.trim(),
          },
        )
        .where((e) =>
            (e['faultSituation'] ?? '').toString().isNotEmpty ||
            (e['faultPhenomenon'] ?? '').toString().isNotEmpty)
        .toList();
    if (groups.isEmpty) {
      showToast('请填写故障情况或故障现象');
      return;
    }
    final basePayload = <String, dynamic>{
      // 时间与基本信息
      'faultDate': _faultDate != null ? _formatOut(_faultDate!) : null,
      'inspectionDate': _checkDate, // 交验日期（字符串 yyyy-MM-dd HH:mm:ss）
      // 人与部门
      'contactPerson': _contactController.text.trim(),
      'tel': _phoneController.text.trim(),
      'deptId': (_selectedResponsibilityDept?['deptId'] ?? '').toString(),
      'deptName': (_selectedResponsibilityDept?['deptName'] ?? '').toString(),
      // 故障分类与描述
      'failureCategory': (_selectedFaultCategory?['name'] ?? '').toString(),
      'failureCategoryCode': (_selectedFaultCategory?['code'] ?? '').toString(),
      // 机型与车号
      'model': (_selectedJcType?['name'] ?? _selectedJcType?['trainType'] ?? '').toString(),
      'modelCode': (_selectedJcType?['code'] ?? '').toString(),
      'serialNumber': _trainNumController.text.trim(),
      // 修程与委修段（从 JT9）
      'repairStatus': _repairProcSituation, // 修程（只取“-”前）
      'repairTimes': (_jt9Selected?['repairTimes'] ?? _jt9Selected?['repairTime'] ?? '').toString(),
      'maintenanceSection': _repairDept,
      'maintenanceSectionCode': (_jt9Selected?['assignSegmentCode'] ?? _jt9Selected?['repairSegmentCode'] ?? '').toString(),
      // 其它
      'kilometersTravelled': _mileageController.text.trim(),
      'trainLocation': _locationController.text.trim(),
      'status': '0',
    };
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认提交'),
          content: const Text('确定要提交吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      SmartDialog.showLoading();
      final files = <File>[];
      for (final a in _attachments) {
        final f = await a.file;
        if (f != null) files.add(f);
      }
      final fileCode = files.isNotEmpty
          ? _asJsonString(
              _extractUploadData(
                await ProductApi().uploadMasFile(uploadFileList: files),
              ),
            )
          : '';

      final payloadList = groups.map((g) {
        final row = Map<String, dynamic>.from(basePayload);
        row['faultSummary'] = (g['faultSituation'] ?? '').toString();
        row['faultInformation'] = (g['faultPhenomenon'] ?? '').toString();
        row['fileCode'] = fileCode;
        return row;
      }).toList();

      if (files.isNotEmpty) {
        if (fileCode.trim().isEmpty) {
          SmartDialog.dismiss();
          showToast('附件上传失败');
          return;
        }
      }
      final saveResp = await ProductApi().saveMasSaleInformationAll(
        data: payloadList,
      );
      SmartDialog.dismiss();
      _logger.i(saveResp);
      final msg = _extractResponseMessage(saveResp);
      final lower = msg.toLowerCase();
      final isBad = lower.contains('error') ||
          lower.contains('exception') ||
          lower.contains('parse') ||
          lower.contains('失败');
      if (msg.isNotEmpty && isBad) {
        showToast(msg);
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('提交成功'),
          content: const Text('提交成功'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      _saveDraft();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SmartDialog.dismiss();
      _logger.e(e);
      showToast('提交失败');
    }
  }

  void _saveDraft() {
    _draft = _AfterSaleTempRepairDraft(
      faultDate: _faultDate,
      dynamicCode: (_selectedDynamicType?['code'] ?? '').toString(),
      typeCode: (_selectedJcType?['code'] ?? '').toString(),
      trainNum: _trainNumController.text,
      mileage: _mileageController.text,
      trainLocation: _locationController.text,
      phone: _phoneController.text,
      faultCategoryCode: (_selectedFaultCategory?['code'] ?? '').toString(),
      deptId: (_selectedResponsibilityDept?['deptId'] ?? '').toString(),
      deptName: (_selectedResponsibilityDept?['deptName'] ?? '').toString(),
      jt9Selected: _jt9Selected == null ? null : Map<String, dynamic>.from(_jt9Selected!),
      faultGroups: _faultGroups
          .map((g) => _AfterSaleTempRepairFaultGroupDraft(
                situation: g.faultSituationController.text,
                phenomenon: g.faultPhenomenonController.text,
              ))
          .toList(),
      attachments: _attachments,
    );
  }

  void _restoreDraft() {
    final d = _draft;
    if (d == null) return;
    _faultDate = d.faultDate;
    _trainNumController.text = d.trainNum;
    _mileageController.text = d.mileage;
    _locationController.text = d.trainLocation;
    _phoneController.text = d.phone;
    _jt9Selected = d.jt9Selected == null ? null : Map<String, dynamic>.from(d.jt9Selected!);
    _attachments = List<AssetEntity>.from(d.attachments);
    _faultGroups.clear();
    for (final g in d.faultGroups) {
      final c = _FaultGroupControllers();
      c.faultSituationController.text = g.situation;
      c.faultPhenomenonController.text = g.phenomenon;
      _faultGroups.add(c);
    }
  }

  String _pickText(Map<String, dynamic>? map, List<String> keys) {
    final m = map ?? const <String, dynamic>{};
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return '';
  }

  String _beforeDash(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';
    final separators = <String>['-', '－', '—'];
    for (final sep in separators) {
      final idx = t.indexOf(sep);
      if (idx > 0) return t.substring(0, idx).trim();
    }
    return t;
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    if (raw is int) {
      final ms = raw > 1000000000000 ? raw : raw * 1000;
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    }
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return '';
    if (s.length >= 19) return s.substring(0, 19);
    if (s.length >= 10) return s;
    return s;
  }

  String _formatOut(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String get _repairDept {
    return _pickText(_jt9Selected, [
      'assignSegmentName',
      'repairDept',
      'repairDeptName',
      'repairSegment',
      'repairSegmentName',
      'maintainDept',
      'maintainDeptName',
    ]);
  }

  String get _repairProcSituation {
    final procRaw = _pickText(_jt9Selected, [
      'repairProcName',
      'repairProc',
      'repairProcName',
      'repairProcess',
      'repairProcessName',
    ]);
    return _beforeDash(procRaw);
  }

  String get _checkDate {
    final raw = _jt9Selected?['repairEndTime'] ??
        _jt9Selected?['checkDate'] ??
        _jt9Selected?['checkTime'] ??
        _jt9Selected?['deliverTrainTime'] ??
        _jt9Selected?['inspectDate'] ??
        _jt9Selected?['inspectionDate'] ??
        _jt9Selected?['verifyDate'] ??
        _jt9Selected?['acceptanceDate'];
    return _fmtDate(raw);
  }

  Future<void> _openJt9Selector() async {
    if (_jt9Options.isEmpty) return;
    if (_jt9Options.length == 1) {
      setState(() => _jt9Selected = _jt9Options.first);
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final options = List<Map<String, dynamic>>.from(_jt9Options);
        options.sort((a, b) {
          final sa = _pickText(a, ['assignSegmentName']);
          final sb = _pickText(b, ['assignSegmentName']);
          final pa = _pickText(a, ['repairProcName']);
          final pb = _pickText(b, ['repairProcName']);
          final ea = _pickText(a, ['repairEndTime']);
          final eb = _pickText(b, ['repairEndTime']);
          final c1 = sa.compareTo(sb);
          if (c1 != 0) return c1;
          final c2 = pa.compareTo(pb);
          if (c2 != 0) return c2;
          return ea.compareTo(eb);
        });

        String labelOf(Map<String, dynamic> e) {
          final seg = _pickText(e, ['assignSegmentName']);
          final proc = _beforeDash(_pickText(e, ['repairProcName']));
          final end = _fmtDate(_pickText(e, ['repairEndTime']));
          final left = [seg, proc].where((s) => s.trim().isNotEmpty).join('-');
          final endText = end.trim().isEmpty ? '' : '交验日期$end';
          if (left.isEmpty) return endText.isEmpty ? '-' : endText;
          if (endText.isEmpty) return left;
          return '$left-$endText';
        }

        final maxWidth = MediaQuery.of(context).size.width * 0.9;
        final maxHeight = MediaQuery.of(context).size.height * 0.6;

        return Dialog(
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '选择信息',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final e = options[index];
                      final text = labelOf(e);
                      final isSelected = identical(e, _jt9Selected) ||
                          (_jt9Selected != null &&
                              _pickText(e, ['assignSegmentCode', 'assignSegmentName']) ==
                                  _pickText(_jt9Selected, ['assignSegmentCode', 'assignSegmentName']) &&
                              _pickText(e, ['repairProcName']) ==
                                  _pickText(_jt9Selected, ['repairProcName']) &&
                              _pickText(e, ['repairEndTime']) ==
                                  _pickText(_jt9Selected, ['repairEndTime']));
                      return ListTile(
                        dense: true,
                        title: Text(text),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.of(context).pop(e),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() => _jt9Selected = selected);
    }
  }

  Future<void> _loadJt9() async {
    final dynamicCode = _selectedDynamicType?['code']?.toString().trim();
    final typeCode = _selectedJcType?['code']?.toString().trim();
    final trainNum = _trainNumController.text.trim();
    if (dynamicCode == null ||
        dynamicCode.isEmpty ||
        typeCode == null ||
        typeCode.isEmpty ||
        trainNum.isEmpty) {
      return;
    }
    if (_jt9Loading) return;
    setState(() => _jt9Loading = true);
    try {
      final res = await ProductApi().getJT9(
        queryParametrs: {
          'dynamicCode': dynamicCode,
          'trainNum': trainNum,
          'typeCode': typeCode,
        },
      );
      if (!mounted) return;
      final options = <Map<String, dynamic>>[];
      if (res is List) {
        for (final e in res) {
          if (e is Map) options.add(Map<String, dynamic>.from(e));
        }
      } else if (res is Map) {
        options.add(Map<String, dynamic>.from(res));
      }
      setState(() {
        _jt9Options = options;
        _jt9Selected = options.isNotEmpty ? options.first : null;
      });
    } catch (e) {
      _logger.e(e);
    } finally {
      if (mounted) setState(() => _jt9Loading = false);
    }
  }

  Future<void> _handleJt9Tap() async {
    final dynamicCode = _selectedDynamicType?['code']?.toString().trim();
    final typeCode = _selectedJcType?['code']?.toString().trim();
    final trainNum = _trainNumController.text.trim();
    if (dynamicCode == null ||
        dynamicCode.isEmpty ||
        typeCode == null ||
        typeCode.isEmpty ||
        trainNum.isEmpty) {
      showToast('请先选择动力类型、机型并填写车号');
      return;
    }
    await _loadJt9();
    if (!mounted) return;
    if (_jt9Options.isEmpty) {
      showToast('未查询到信息');
      return;
    }
    await _openJt9Selector();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('机车登记')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: _pagePadding,
            children: [
            _DateField(
              label: '故障日期',
              value: _faultDate,
              required: true,
              onTap: () => _pickDate(
                initial: _faultDate,
                onPicked: (d) => setState(() => _faultDate = d),
              ),
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedDynamicType,
                    decoration: _denseDecoration('动力类型'),
                    items: _dynamicTypes
                        .map(
                          (e) => DropdownMenuItem<Map<String, dynamic>>(
                            value: e,
                            child: Text(
                              (e['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _selectedDynamicType = v;
                        _selectedJcType = null;
                        _jcTypes = [];
                        _jt9Options = [];
                        _jt9Selected = null;
                      });
                      await _loadJcTypes(v?['code']?.toString());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedJcType,
                    decoration: _denseDecoration('机型'),
                    items: _jcTypes
                        .map(
                          (e) => DropdownMenuItem<Map<String, dynamic>>(
                            value: e,
                            child: Text(
                              (e['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedJcType = v;
                        _jt9Options = [];
                        _jt9Selected = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _trainNumController,
                    decoration: InputDecoration(
                      labelText: '车号',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: _denseContentPadding,
                      suffixIcon: _jt9Loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      return t.isEmpty ? '车号不能为空' : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadonlyInfoField(
                    label: '维修段',
                    value: _repairDept,
                    onTap: _handleJt9Tap,
                  ),
                ),
              ],
            ),
            _gap8,
            Row(
              children: [
                Expanded(
                  child: _ReadonlyInfoField(
                    label: '修程',
                    value: _repairProcSituation,
                    onTap: _jt9Options.isNotEmpty ? _openJt9Selector : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadonlyInfoField(
                    label: '交验日期',
                    value: _checkDate,
                    onTap: _jt9Options.isNotEmpty ? _openJt9Selector : null,
                  ),
                ),
              ],
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedFaultCategory,
                    decoration: _denseDecoration('故障类别'),
                    items: _faultCategories
                        .map(
                          (e) => DropdownMenuItem<Map<String, dynamic>>(
                            value: e,
                            child: Text(
                              (e['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _faultCategories.isEmpty
                        ? null
                        : (v) => setState(() => _selectedFaultCategory = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    decoration: _denseDecoration('走行公里'),
                  ),
                ),
              ],
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactController,
                    decoration: _denseDecoration('联系人'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _denseDecoration('联系电话'),
                  ),
                ),
              ],
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: _denseDecoration('机车所在地'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedResponsibilityDept,
                    decoration: _denseDecoration('责任车间'),
                    items: _responsibilityDepts
                        .map(
                          (e) => DropdownMenuItem<Map<String, dynamic>>(
                            value: e,
                            child: Text(
                              (e['deptName'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _responsibilityDepts.isEmpty
                        ? null
                        : (v) =>
                            setState(() => _selectedResponsibilityDept = v),
                  ),
                ),
              ],
            ),
            _gap12,
            _FaultGroupsSection(
              controllers: _faultGroups,
              onAdd: _addFaultGroup,
              onRemove: _removeFaultGroup,
            ),
            _gap12,
            const Text('附件'),
            const SizedBox(height: 4),
            ZjcAssetPicker(
              assetType: AssetType.imageAndVideo,
              lineCount: 4,
              itemSpace: 4,
              selectedAssets: _attachments,
              callBack: (assets) {
                setState(() => _attachments = List<AssetEntity>.from(assets));
              },
            ),
            _gap12,
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('提交'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaultGroupControllers {
  final faultSituationController = TextEditingController();
  final faultPhenomenonController = TextEditingController();

  void dispose() {
    faultSituationController.dispose();
    faultPhenomenonController.dispose();
  }
}

class _FaultGroupsSection extends StatelessWidget {
  final List<_FaultGroupControllers> controllers;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _FaultGroupsSection({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 2),
        for (int i = 0; i < controllers.length; i++) ...[
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('故障情况')),
                        IconButton(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add),
                          tooltip: '新增一条',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controllers[i].faultSituationController,
                      maxLines: 3,
                      maxLength: 500,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: '故障情况',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controllers[i].faultPhenomenonController,
                      maxLines: 3,
                      maxLength: 500,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: '故障现象',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controllers.length > 1 ? () => onRemove(i) : null,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除这一组',
                ),
              ),
            ],
          ),
          if (i != controllers.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReadonlyInfoField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ReadonlyInfoField({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    final child = InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixIcon: onTap == null ? null : const Icon(Icons.arrow_drop_down),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool required;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.required,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}:${value!.second.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label（必填）' : label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        child: Text(text.isEmpty ? '请选择' : text),
      ),
    );
  }
}

class _AfterSaleTempRepairFaultGroupDraft {
  final String situation;
  final String phenomenon;

  const _AfterSaleTempRepairFaultGroupDraft({
    required this.situation,
    required this.phenomenon,
  });
}

class _AfterSaleTempRepairDraft {
  final DateTime? faultDate;
  final String dynamicCode;
  final String typeCode;
  final String trainNum;
  final String mileage;
  final String trainLocation;
  final String phone;
  final String faultCategoryCode;
  final String deptId;
  final String deptName;
  final Map<String, dynamic>? jt9Selected;
  final List<_AfterSaleTempRepairFaultGroupDraft> faultGroups;
  final List<AssetEntity> attachments;

  const _AfterSaleTempRepairDraft({
    required this.faultDate,
    required this.dynamicCode,
    required this.typeCode,
    required this.trainNum,
    required this.mileage,
    required this.trainLocation,
    required this.phone,
    required this.faultCategoryCode,
    required this.deptId,
    required this.deptName,
    required this.jt9Selected,
    required this.faultGroups,
    required this.attachments,
  });
}
