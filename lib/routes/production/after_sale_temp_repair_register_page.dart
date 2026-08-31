import 'dart:io';

import 'package:wechat_assets_picker/wechat_assets_picker.dart' hide AssetType;

import '../../index.dart';
import '../../services/after_sale_local_service.dart';

class AfterSaleTempRepairRegisterPage extends StatefulWidget {
  const AfterSaleTempRepairRegisterPage({super.key});

  @override
  State<AfterSaleTempRepairRegisterPage> createState() =>
      _AfterSaleTempRepairRegisterPageState();
}

class _AfterSaleTempRepairRegisterPageState
    extends State<AfterSaleTempRepairRegisterPage> {
  static final _localService = AfterSaleLocalService.instance;

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

  final _manualRepairDeptController = TextEditingController();
  final _manualRepairProcController = TextEditingController();
  DateTime? _manualCheckDate;

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
    Future<void>(() async {
      try {
        final n = await _localService.pendingCount();
        if (mounted && n > 0) showToast('本地有待同步的售后登记：$n 条');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _saveDraft();
    _trainNumController.dispose();
    _mileageController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _manualRepairDeptController.dispose();
    _manualRepairProcController.dispose();
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

  Map<String, dynamic> _pickDefault(
    List<Map<String, dynamic>> list,
    Map<String, dynamic>? currentSelected,
    String codeKey,
  ) {
    if (currentSelected != null) {
      final curCode = (currentSelected[codeKey] ?? '').toString();
      if (curCode.isNotEmpty) {
        final hit = list.firstWhere(
          (e) => (e[codeKey] ?? '').toString() == curCode,
          orElse: () => const <String, dynamic>{},
        );
        if (hit.isNotEmpty) return hit;
        return currentSelected;
      }
    }
    return list.first;
  }

  Future<void> _loadDynamicTypes() async {
    const cacheKey = 'dynamicTypes';
    Future<void> applyList(List<Map<String, dynamic>> list, {bool saveCache = false}) async {
      if (saveCache && list.isNotEmpty) {
        await _localService.setDictCache(cacheKey, list);
      }
      if (!mounted || list.isEmpty) return;
      setState(() {
        _dynamicTypes = list;
        if (_selectedDynamicType == null) {
          _selectedDynamicType = _pickDefault(list, null, 'code');
        } else {
          _selectedDynamicType = _pickDefault(list, _selectedDynamicType, 'code');
        }
      });
      final code = (_selectedDynamicType?['code'] ?? '').toString();
      if (code.isNotEmpty) {
        await _loadJcTypes(code);
      }
    }

    try {
      final cached = await _localService.getDictCache(cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        await applyList(cached, saveCache: false);
      }
    } catch (_) {}
    try {
      final data = await ProductApi().getJcDynamicType(
        queryParametrs: {'pageNum': 0, 'pageSize': 0},
      );
      final rows = (data is Map)
          ? data['rows']
          : (data is List
              ? data
              : null);
      final list = rows is List
          ? rows
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (mounted) await applyList(list, saveCache: true);
    } catch (e, stackTrace) {
      _logger.e('加载动力类型字典异常', e, stackTrace);
    }
  }

  Future<void> _loadJcTypes(String? dynamicCode) async {
    if (dynamicCode == null || dynamicCode.trim().isEmpty) return;
    final cacheKey = 'jcTypes:$dynamicCode';
    Future<void> applyList(List<Map<String, dynamic>> list, {bool saveCache = false}) async {
      if (saveCache && list.isNotEmpty) {
        await _localService.setDictCache(cacheKey, list);
      }
      if (!mounted || list.isEmpty) return;
      setState(() {
        _jcTypes = list;
        if (_selectedJcType == null) {
          _selectedJcType = _pickDefault(list, null, 'code');
        } else {
          _selectedJcType = _pickDefault(list, _selectedJcType, 'code');
        }
      });
    }

    try {
      final cached = await _localService.getDictCache(cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        await applyList(cached, saveCache: false);
      }
    } catch (_) {}
    try {
      final r = await ProductApi().getJcType(
        queryParametrs: {
          'dynamicCode': dynamicCode,
          'pageNum': 0,
          'pageSize': 0,
        },
      );
      final list = r.toMapList();
      if (mounted) await applyList(list, saveCache: true);
    } catch (e, stackTrace) {
      _logger.e('加载机型字典异常', e, stackTrace);
    }
  }

  Future<void> _loadFaultCategories() async {
    const cacheKey = 'faultCategories';
    Future<void> applyList(List<Map<String, dynamic>> list, {bool saveCache = false}) async {
      if (saveCache && list.isNotEmpty) {
        await _localService.setDictCache(cacheKey, list);
      }
      if (!mounted || list.isEmpty) return;
      setState(() {
        _faultCategories = list;
        if (_selectedFaultCategory == null) {
          _selectedFaultCategory = _pickDefault(list, null, 'code');
        } else {
          _selectedFaultCategory = _pickDefault(list, _selectedFaultCategory, 'code');
        }
      });
    }

    try {
      final cached = await _localService.getDictCache(cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        await applyList(cached, saveCache: false);
      }
    } catch (_) {}
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
          : (res is Map
              ? [Map<String, dynamic>.from(res)]
              : <Map<String, dynamic>>[]);
      if (mounted) await applyList(list, saveCache: true);
    } catch (e, stackTrace) {
      _logger.e('加载故障类别字典异常', e, stackTrace);
    }
  }

  Future<void> _loadResponsibilityDepts() async {
    const cacheKey = 'responsibilityDepts';
    List<Map<String, dynamic>> _extract(dynamic res) {
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
      return list;
    }

    Future<void> applyList(List<Map<String, dynamic>> list, {bool saveCache = false}) async {
      if (saveCache && list.isNotEmpty) {
        await _localService.setDictCache(cacheKey, list);
      }
      if (!mounted || list.isEmpty) return;
      setState(() {
        if (_selectedResponsibilityDept == null) {
          _selectedResponsibilityDept = _pickDefault(list, null, 'deptId');
        } else {
          _selectedResponsibilityDept = _pickDefault(list, _selectedResponsibilityDept, 'deptId');
        }
      });
    }

    try {
      final cached = await _localService.getDictCache(cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        await applyList(cached, saveCache: false);
      }
    } catch (_) {}
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {
          'parentIdList': 101,
        },
      );
      final list = _extract(res);
      if (mounted) await applyList(list, saveCache: true);
    } catch (e, stackTrace) {
      _logger.e('加载责任车间字典异常', e, stackTrace);
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
            g.attachmentPaths.isNotEmpty;
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
      final groups = <Map<String, dynamic>>[];
      for (int i = 0; i < _faultGroups.length; i++) {
        final g = _faultGroups[i];
        final situation = g.faultSituationController.text.trim();
        final phenomenon = g.faultPhenomenonController.text.trim();
        final paths = List<String>.from(g.attachmentPaths);
        if (situation.isEmpty && phenomenon.isEmpty && paths.isEmpty) continue;
        groups.add(<String, dynamic>{
          'faultSummary': situation,
          'faultInformation': phenomenon,
          'imagePaths': paths,
        });
      }
      if (groups.isEmpty) {
        showToast('请填写故障情况/故障现象或添加附件');
        return;
      }
      final isLogin =
          Global.profile.data?.accessToken?.toString().trim().isNotEmpty ?? false;
      final confirmText = isLogin
          ? '确定要提交吗？'
          : '当前未登录或无网络，将保存到本地，登录后自动上传，确定吗？';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认提交'),
          content: Text(confirmText),
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

      bool submitOk = false;
      String failMsg = '';
      if (isLogin) {
        try {
          final payloadList = <Map<String, dynamic>>[];
          for (int i = 0; i < groups.length; i++) {
            final g = groups[i];
            final paths = (g['imagePaths'] as List? ?? []).cast<String>();
            String fileCode = '';
            if (paths.isNotEmpty) {
              final files = <File>[];
              for (final p in paths) {
                final f = File(p);
                if (await f.exists()) files.add(f);
              }
              if (files.isNotEmpty) {
                final uploadResp =
                    await ProductApi().uploadMasFile(uploadFileList: files);
                final uploaded = _extractUploadData(uploadResp);
                fileCode = _asJsonString(uploaded);
                if (fileCode.trim().isEmpty) {
                  throw Exception('第${i + 1}组附件上传失败');
                }
              }
            }
            final row = Map<String, dynamic>.from(basePayload);
            row['faultSummary'] = g['faultSummary'] ?? '';
            row['faultInformation'] = g['faultInformation'] ?? '';
            row['fileCode'] = fileCode;
            payloadList.add(row);
          }
          final saveResp = await ProductApi().saveMasSaleInformationAll(
            data: payloadList,
          );
          _logger.i(saveResp);
          final msg = _extractResponseMessage(saveResp);
          final lower = msg.toLowerCase();
          final isBad = lower.contains('error') ||
              lower.contains('exception') ||
              lower.contains('parse') ||
              lower.contains('失败');
          if (msg.isNotEmpty && isBad) {
            failMsg = msg;
            submitOk = false;
          } else {
            submitOk = true;
          }
        } catch (e) {
          _logger.e(e);
          failMsg = e.toString();
          submitOk = false;
        }
      }

      if (!submitOk) {
        // 未登录 / 在线提交失败 → 回退写入待同步队列
        await _localService.enqueuePending(
          basePayload: basePayload,
          groups: groups,
        );
        SmartDialog.dismiss();
        await _localService.clearDraft();
        final suffix = isLogin && failMsg.isNotEmpty ? '（$failMsg）' : '';
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: const Text('已保存到本地'),
            content: Text(
                '当前无法联网提交$suffix，已离线保存，登录成功后将自动上传。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      SmartDialog.dismiss();
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
      await _localService.clearDraft();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SmartDialog.dismiss();
      _logger.e(e);
      showToast('保存失败');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _buildDraftJson() {
    return <String, dynamic>{
      'faultDate': _faultDate?.toIso8601String(),
      'dynamicCode': (_selectedDynamicType?['code'] ?? '').toString(),
      'dynamicName': (_selectedDynamicType?['name'] ?? '').toString(),
      'typeCode': (_selectedJcType?['code'] ?? '').toString(),
      'typeName': (_selectedJcType?['name'] ?? '').toString(),
      'trainNum': _trainNumController.text,
      'mileage': _mileageController.text,
      'trainLocation': _locationController.text,
      'phone': _phoneController.text,
      'faultCategoryCode': (_selectedFaultCategory?['code'] ?? '').toString(),
      'faultCategoryName': (_selectedFaultCategory?['name'] ?? '').toString(),
      'deptId': (_selectedResponsibilityDept?['deptId'] ?? '').toString(),
      'deptName': (_selectedResponsibilityDept?['deptName'] ?? '').toString(),
      'jt9Selected':
          _jt9Selected == null ? null : Map<String, dynamic>.from(_jt9Selected!),
      'manualRepairDept': _manualRepairDeptController.text,
      'manualRepairProc': _manualRepairProcController.text,
      'manualCheckDate': _manualCheckDate?.toIso8601String(),
      'faultGroups': _faultGroups
          .map((g) => <String, dynamic>{
                'situation': g.faultSituationController.text,
                'phenomenon': g.faultPhenomenonController.text,
                'imagePaths': List<String>.from(g.attachmentPaths),
              })
          .toList(),
    };
  }

  Future<void> _saveDraft() async {
    try {
      final json = _buildDraftJson();
      await _localService.saveDraft(json);
    } catch (_) {}
  }

  Future<void> _restoreDraft() async {
    try {
      final Map<String, dynamic>? d = await _localService.loadDraft();
      if (d == null) return;
      final faultDateRaw = d['faultDate']?.toString();
      _faultDate =
          (faultDateRaw != null && faultDateRaw.isNotEmpty)
              ? DateTime.tryParse(faultDateRaw)
              : null;
      _trainNumController.text = (d['trainNum'] ?? '').toString();
      _mileageController.text = (d['mileage'] ?? '').toString();
      _locationController.text = (d['trainLocation'] ?? '').toString();
      _phoneController.text = (d['phone'] ?? '').toString();
      final jt9 = d['jt9Selected'];
      _jt9Selected = (jt9 is Map) ? Map<String, dynamic>.from(jt9) : null;
      final dynamicCode = (d['dynamicCode'] ?? '').toString();
      final dynamicName = (d['dynamicName'] ?? '').toString();
      final typeCode = (d['typeCode'] ?? '').toString();
      final typeName = (d['typeName'] ?? '').toString();
      final faultCategoryCode = (d['faultCategoryCode'] ?? '').toString();
      final faultCategoryName = (d['faultCategoryName'] ?? '').toString();
      final deptId = (d['deptId'] ?? '').toString();
      final deptName = (d['deptName'] ?? '').toString();
      if (dynamicCode.isNotEmpty) {
        _selectedDynamicType = <String, dynamic>{
          'code': dynamicCode,
          'name': dynamicName,
        };
      }
      if (typeCode.isNotEmpty) {
        _selectedJcType = <String, dynamic>{'code': typeCode, 'name': typeName};
      }
      if (faultCategoryCode.isNotEmpty) {
        _selectedFaultCategory = <String, dynamic>{
          'code': faultCategoryCode,
          'name': faultCategoryName,
        };
      }
      if (deptId.isNotEmpty) {
        _selectedResponsibilityDept = <String, dynamic>{
          'deptId': deptId,
          'deptName': deptName,
        };
      }
      _faultGroups.clear();
      final fg = d['faultGroups'];
      _manualRepairDeptController.text = (d['manualRepairDept'] ?? '').toString();
      _manualRepairProcController.text = (d['manualRepairProc'] ?? '').toString();
      final manualCheck = d['manualCheckDate']?.toString();
      _manualCheckDate = (manualCheck != null && manualCheck.isNotEmpty)
          ? DateTime.tryParse(manualCheck)
          : null;
      if (fg is List) {
        for (final item in fg) {
          final m = item is Map ? Map<String, dynamic>.from(item) : null;
          if (m == null) continue;
          final c = _FaultGroupControllers();
          c.faultSituationController.text = (m['situation'] ?? '').toString();
          c.faultPhenomenonController.text =
              (m['phenomenon'] ?? '').toString();
          final paths = (m['imagePaths'] as List? ?? []).cast<String>();
          c.attachmentPaths = paths;
          _faultGroups.add(c);
        }
      }
      _expandedFaultGroupIndex =
          _faultGroups.isEmpty ? 0 : _faultGroups.length - 1;
    } catch (e) {
      _logger.e('恢复售后登记草稿失败: $e');
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
    final fromJt9 = _pickText(_jt9Selected, [
      'assignSegmentName',
      'repairDept',
      'repairDeptName',
      'repairSegment',
      'repairSegmentName',
      'maintainDept',
      'maintainDeptName',
    ]);
    if (fromJt9.trim().isNotEmpty) return fromJt9;
    return _manualRepairDeptController.text.trim();
  }

  String get _repairProcSituation {
    final procRaw = _pickText(_jt9Selected, [
      'repairProcName',
      'repairProc',
      'repairProcName',
      'repairProcess',
      'repairProcessName',
    ]);
    final jt9Proc = _beforeDash(procRaw);
    if (jt9Proc.isNotEmpty) return jt9Proc;
    return _beforeDash(_manualRepairProcController.text.trim());
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
    final fromJt9 = _fmtDate(raw);
    if (fromJt9.isNotEmpty) return fromJt9;
    if (_manualCheckDate != null) return _formatOut(_manualCheckDate!);
    return '';
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
        if (selected != null) {
          final rp = _repairProcSituation;
          final rd = _repairDept;
          if (rp.isNotEmpty && _manualRepairProcController.text.trim().isEmpty) {
            _manualRepairProcController.text = rp;
          }
          if (rd.isNotEmpty && _manualRepairDeptController.text.trim().isEmpty) {
            _manualRepairDeptController.text = rd;
          }
        }
      });
    } catch (e) {
      _logger.e(e);
      if (mounted) {
        showToast('无法获取JT9信息，可手填委修段/修程/交验日期');
      }
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
                  child: TextFormField(
                    controller: _manualRepairDeptController,
                    decoration: _denseDecoration('委修段（可手填）'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _manualRepairProcController,
                    decoration: _denseDecoration('修程（可手填）'),
                  ),
                ),
              ],
            ),
            _gap12,
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: '交验日期（可手填）',
                    value: _manualCheckDate,
                    required: false,
                    onTap: () => _pickDate(
                      initial: _manualCheckDate,
                      onPicked: (d) => setState(() => _manualCheckDate = d),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _mileageController,
                    decoration: _denseDecoration('走行公里'),
                    keyboardType: TextInputType.number,
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
  List<String> attachmentPaths = [];

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
                        if (controllers[i].attachmentPaths.isNotEmpty &&
                            i != expandedIndex)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text('附件${controllers[i].attachmentPaths.length}'),
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
                        selectedAssets: const [],
                        callBack: (assets) async {
                          if (assets.isEmpty) return;
                          try {
                            SmartDialog.showLoading(msg: '保存图片中...');
                            final paths = await AfterSaleLocalService.instance
                                .copyAssetsToSandbox(assets);
                            if (paths.isEmpty) {
                              showToast('图片保存失败，请重试');
                              return;
                            }
                            if (paths.length < assets.length) {
                              showToast(
                                  '${assets.length - paths.length} 张图片保存失败，其余已添加');
                            }
                            controllers[i].attachmentPaths = [
                              ...controllers[i].attachmentPaths,
                              ...paths,
                            ];
                            onChanged();
                          } catch (e) {
                            showToast('图片保存失败');
                          } finally {
                            SmartDialog.dismiss(status: SmartStatus.loading);
                          }
                        },
                      ),
                      if (controllers[i].attachmentPaths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '已保存图片（${controllers[i].attachmentPaths.length}）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: controllers[i].attachmentPaths.length,
                          itemBuilder: (_, idx) {
                            final p = controllers[i].attachmentPaths[idx];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(p),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      controllers[i]
                                          .attachmentPaths
                                          .removeAt(idx);
                                      try {
                                        final f = File(p);
                                        if (f.existsSync()) f.deleteSync();
                                      } catch (_) {}
                                      onChanged();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withOpacity(0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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
