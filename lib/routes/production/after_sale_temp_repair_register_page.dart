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
  static const _cardPadding = EdgeInsets.all(8);
  static const _cardInnerGap = SizedBox(height: 6);
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
  Map<String, dynamic>? _selectedResponsibilityDept;

  final _trainNumController = TextEditingController();
  final _mileageController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<_FaultGroupControllers> _faultGroups = [];
  int _expandedFaultGroupIndex = -1;
  bool _submitting = false;

  bool _jt9Loading = false;
  Map<String, dynamic>? _jt9Selected;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    if (_faultGroups.isEmpty) {
      _faultGroups.add(_FaultGroupControllers());
      _expandedFaultGroupIndex = 0;
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
      _expandedFaultGroupIndex = _faultGroups.length - 1;
    });
  }

  void _removeFaultGroup(int index) {
    if (index < 0 || index >= _faultGroups.length) return;
    if (_faultGroups.length <= 1) return;
    final g = _faultGroups.removeAt(index);
    g.dispose();
    setState(() {
      if (_faultGroups.isEmpty) {
        _expandedFaultGroupIndex = -1;
        return;
      }
      if (_expandedFaultGroupIndex == index) {
        _expandedFaultGroupIndex = index - 1;
        if (_expandedFaultGroupIndex < 0) _expandedFaultGroupIndex = 0;
        if (_expandedFaultGroupIndex >= _faultGroups.length) {
          _expandedFaultGroupIndex = _faultGroups.length - 1;
        }
        return;
      }
      if (_expandedFaultGroupIndex > index) {
        _expandedFaultGroupIndex -= 1;
      }
      if (_expandedFaultGroupIndex >= _faultGroups.length) {
        _expandedFaultGroupIndex = _faultGroups.length - 1;
      }
    });
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
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      FocusScope.of(context).unfocus();
      if (_trainNumController.text.trim().isEmpty) {
        showToast('请输入车号');
        return;
      }
      final ok = _formKey.currentState?.validate() == true;
      if (!ok) {
        showToast('请完善必填项');
        return;
      }
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
    final hasAnyGroup = _faultGroups.any((g) {
      return g.faultSituationController.text.trim().isNotEmpty ||
          g.faultPhenomenonController.text.trim().isNotEmpty ||
          g.attachments.isNotEmpty;
    });
    if (!hasAnyGroup) {
      showToast('请填写故障情况/故障现象或添加附件');
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
      final payloadList = <Map<String, dynamic>>[];
      for (int i = 0; i < _faultGroups.length; i++) {
        final g = _faultGroups[i];
        final situation = g.faultSituationController.text.trim();
        final phenomenon = g.faultPhenomenonController.text.trim();
        final hasFiles = g.attachments.isNotEmpty;
        if (situation.isEmpty && phenomenon.isEmpty && !hasFiles) continue;

        String fileCode = '';
        if (hasFiles) {
          final files = <File>[];
          for (final a in g.attachments) {
            final f = await a.file;
            if (f != null) files.add(f);
          }
          if (files.isEmpty) {
            SmartDialog.dismiss();
            showToast('第${i + 1}组附件读取失败');
            return;
          }
          final uploadResp =
              await ProductApi().uploadMasFile(uploadFileList: files);
          final uploaded = _extractUploadData(uploadResp);
          fileCode = _asJsonString(uploaded);
          if (fileCode.trim().isEmpty) {
            SmartDialog.dismiss();
            showToast('第${i + 1}组附件上传失败');
            return;
          }
        }

        final row = Map<String, dynamic>.from(basePayload);
        row['faultSummary'] = situation;
        row['faultInformation'] = phenomenon;
        row['fileCode'] = fileCode;
        payloadList.add(row);
      }
      if (payloadList.isEmpty) {
        SmartDialog.dismiss();
        showToast('请填写故障情况/故障现象或添加附件');
        return;
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
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                attachments: List<AssetEntity>.from(g.attachments),
              ))
          .toList(),
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
    _faultGroups.clear();
    for (final g in d.faultGroups) {
      final c = _FaultGroupControllers();
      c.faultSituationController.text = g.situation;
      c.faultPhenomenonController.text = g.phenomenon;
      c.attachments = List<AssetEntity>.from(g.attachments);
      _faultGroups.add(c);
    }
    _expandedFaultGroupIndex =
        _faultGroups.isEmpty ? 0 : _faultGroups.length - 1;
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
      Map<String, dynamic>? selected;
      if (res is List && res.isNotEmpty) {
        final first = res.first;
        if (first is Map) selected = Map<String, dynamic>.from(first);
      } else if (res is Map) {
        selected = Map<String, dynamic>.from(res);
      }
      setState(() {
        _jt9Selected = selected;
      });
    } catch (e) {
      _logger.e(e);
    } finally {
      if (mounted) setState(() => _jt9Loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('售后临修机车登记')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: _pagePadding,
            children: [
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: '故障日期',
                    value: _faultDate,
                    required: true,
                    onTap: () => _pickDate(
                      initial: _faultDate,
                      onPicked: (d) => setState(() => _faultDate = d),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: _denseDecoration('机车所在地'),
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
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      _loadJt9();
                    },
                    onFieldSubmitted: (_) => _loadJt9(),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      return t.isEmpty ? '车号不能为空' : null;
                    },
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
          
            _FaultGroupsSection(
              controllers: _faultGroups,
              expandedIndex: _expandedFaultGroupIndex,
              onAddAt: (_) => _addFaultGroup(),
              onToggle: (i) => setState(() {
                _expandedFaultGroupIndex =
                    _expandedFaultGroupIndex == i ? -1 : i;
              }),
              onRemove: _removeFaultGroup,
              onChanged: () => setState(() {}),
            ),
            _gap12,
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '提交中…' : '提交'),
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
  List<AssetEntity> attachments = [];

  void dispose() {
    faultSituationController.dispose();
    faultPhenomenonController.dispose();
  }
}

class _FaultGroupsSection extends StatelessWidget {
  final List<_FaultGroupControllers> controllers;
  final int expandedIndex;
  final void Function(int index) onAddAt;
  final void Function(int index) onToggle;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;
  static const _cardDecoration = InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );

  const _FaultGroupsSection({
    required this.controllers,
    required this.expandedIndex,
    required this.onAddAt,
    required this.onToggle,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      
        for (int i = 0; i < controllers.length; i++) ...[
          Stack(
            children: [
              Container(
                padding: _AfterSaleTempRepairRegisterPageState._cardPadding,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onToggle(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 6,
                              ),
                              child: Text(
                                i == expandedIndex
                                    ? '故障情况/故障现象'
                                    : (controllers[i]
                                            .faultPhenomenonController
                                            .text
                                            .trim()
                                            .isEmpty
                                        ? '故障现象：-'
                                        : '故障现象：${controllers[i].faultPhenomenonController.text.trim()}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onToggle(i),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          tooltip: i == expandedIndex ? '折叠' : '展开',
                        ),
                        if (controllers[i].attachments.isNotEmpty &&
                            i != expandedIndex)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text('附件${controllers[i].attachments.length}'),
                          ),
                        TextButton(
                          onPressed: () => onAddAt(i),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('新增'),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: controllers.length > 1
                              ? () => onRemove(i)
                              : null,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                    if (i == expandedIndex) ...[
                      TextFormField(
                        controller: controllers[i].faultSituationController,
                        maxLines: 2,
                        maxLength: 500,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).nextFocus(),
                        decoration:
                            _cardDecoration.copyWith(labelText: '故障情况'),
                      ),
                      _AfterSaleTempRepairRegisterPageState._cardInnerGap,
                      TextFormField(
                        controller: controllers[i].faultPhenomenonController,
                        maxLines: 2,
                        maxLength: 500,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        decoration:
                            _cardDecoration.copyWith(labelText: '故障现象'),
                      ),
                      _AfterSaleTempRepairRegisterPageState._cardInnerGap,
                      ZjcAssetPicker(
                        assetType: AssetType.imageAndVideo,
                        lineCount: 4,
                        itemSpace: 4,
                        selectedAssets: controllers[i].attachments,
                        callBack: (assets) {
                          controllers[i].attachments =
                              List<AssetEntity>.from(assets);
                          onChanged();
                        },
                      ),
                    ],
                  ],
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
  final List<AssetEntity> attachments;

  const _AfterSaleTempRepairFaultGroupDraft({
    required this.situation,
    required this.phenomenon,
    required this.attachments,
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
  });
}
