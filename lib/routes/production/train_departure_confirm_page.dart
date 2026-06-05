import 'package:wechat_assets_picker/wechat_assets_picker.dart' hide AssetType;
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../index.dart';
import '../../zjc_common/utils/zjc_device_utils.dart';
import '../../zjc_common/utils/zjc_permission_utils.dart';

class TrainDepartureConfirmPage extends StatefulWidget {
  const TrainDepartureConfirmPage({super.key});

  @override
  State<TrainDepartureConfirmPage> createState() =>
      _TrainDepartureConfirmPageState();
}

class _TrainDepartureConfirmPageState extends State<TrainDepartureConfirmPage> {
  final _logger = AppLogger.logger;
  bool _loadingList = false;
  bool _submitting = false;

  List<Map<String, dynamic>> _pendingTrains = [];
  Map<String, dynamic>? _selectedTrain;

  final List<AssetEntity> _assets = [];
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_canOperate) {
        showToast('无权限');
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await _loadPendingTrainList();
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  bool get _canOperate {
    final user = Global.profile.permissions?.user;
    final deptName = (user?.dept?.deptName ?? '').toString();
    final parentDeptName = (Global.parentDeptName ?? '').toString();
    final combinedDept = '$deptName $parentDeptName';
    if (combinedDept.contains('总成车间') && combinedDept.contains('接车')) {
      return true;
    }
    final roleKeys =
        (Global.profile.permissions?.roles ?? const <String>[])
            .map((e) => e.toString())
            .toList();
    if (roleKeys.any((r) => r.contains('总成') && r.contains('接车'))) {
      return true;
    }
    final roleObjs =
        (Global.profile.permissions?.user.roles ?? const <dynamic>[])
            .map((e) => e)
            .toList();
    if (roleObjs.any((r) {
      final rn = (r?.roleName ?? r?['roleName'] ?? '').toString();
      final rk = (r?.roleKey ?? r?['roleKey'] ?? '').toString();
      final s = '$rn $rk';
      return s.contains('总成') && s.contains('接车');
    })) {
      return true;
    }
    return false;
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

  String get _trainDisplay {
    final t = _selectedTrain;
    if (t == null) return '';
    final typeName = _pickText(t, ['typeName', 'model', 'type']);
    final trainNum = _pickText(t, ['trainNum', 'trainNo', 'trainNumber']);
    final ends = _pickText(t, ['ends']);
    final suffix = ends.isEmpty ? '' : ends;
    final joined = '$typeName $trainNum$suffix'.trim();
    return joined;
  }

  Future<void> _loadPendingTrainList() async {
    if (_loadingList) return;
    setState(() => _loadingList = true);
    try {
      _logger.i({
        'action': 'loadReadyToLeaveList',
        'pageNum': 0,
        'pageSize': 0,
      });
      final list = await ProductApi().getReadyToLeaveTrainList(
        queryParameters: {'pageNum': 0, 'pageSize': 0},
      );
      if (!mounted) return;
      setState(() {
        _pendingTrains = list;
      });
      _logger.i({
        'action': 'loadReadyToLeaveList',
        'count': _pendingTrains.length,
      });
    } catch (e) {
      _logger.e(e);
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _showTrainPicker() async {
    if (_loadingList) return;
    if (_pendingTrains.isEmpty) {
      await _loadPendingTrainList();
    }
    if (!mounted) return;
    if (_pendingTrains.isEmpty) {
      showToast('暂无待离段车号');
      return;
    }

    var endsFilter = '';
    var keyword = '';
    _keywordController.clear();

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String norm(String s) {
              return s
                  .replaceAll(' ', '')
                  .replaceAll('(', '')
                  .replaceAll(')', '')
                  .trim();
            }

            final list = _pendingTrains.where((item) {
              final trainNum =
                  _pickText(item, ['trainNum', 'trainNo', 'trainNumber']);
              final ends = _pickText(item, ['ends']);
              if (endsFilter.isNotEmpty && ends != endsFilter) return false;
              if (keyword.isEmpty) return true;
              final typeName = _pickText(item, ['typeName', 'model', 'type']);
              final display = '$typeName$trainNum$ends';
              final k = norm(keyword);
              if (k.isEmpty) return true;
              return norm(display).contains(k);
            }).toList();

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: TextField(
                      controller: _keywordController,
                      decoration: InputDecoration(
                        hintText: '输入车号筛选',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: keyword.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _keywordController.clear();
                                  setState(() => keyword = '');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      onChanged: (v) => setState(() => keyword = v.trim()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('全部'),
                          selected: endsFilter.isEmpty,
                          onSelected: (_) => setState(() => endsFilter = ''),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('A端'),
                          selected: endsFilter == 'A',
                          onSelected: (_) => setState(() => endsFilter = 'A'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('B端'),
                          selected: endsFilter == 'B',
                          onSelected: (_) => setState(() => endsFilter = 'B'),
                        ),
                        const Spacer(),
                        Text('共 ${list.length} 台'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final typeName =
                            _pickText(item, ['typeName', 'model', 'type']);
                        final trainNum = _pickText(
                            item, ['trainNum', 'trainNo', 'trainNumber']);
                        final ends = _pickText(item, ['ends']);
                        final suffix = ends.isEmpty ? '' : ends;
                        final title = '$typeName $trainNum$suffix'.trim();
                        return ListTile(
                          title: Text(title.isEmpty ? '未命名' : title),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;
    if (!mounted) return;
    setState(() {
      _selectedTrain = Map<String, dynamic>.from(selected);
    });
  }

  Future<void> _openCamera() async {
    if (!ZjcDeviceUtils.isMobile) {
      showToast('当前平台暂不支持');
      return;
    }
    final okCamera = await ZjcPermissionUtils.camera();
    if (!okCamera) return;
    final okPhotos = await ZjcPermissionUtils.photos();
    if (!okPhotos) return;
    if (!mounted) return;
    try {
      final result = await CameraPicker.pickFromCamera(
        context,
        pickerConfig: const CameraPickerConfig(enableRecording: false),
      );
      if (result == null) return;
      if (!mounted) return;
      setState(() {
        _assets.add(result);
      });
    } catch (_) {
      showToast('无法打开相机，请检查权限设置');
    }
  }

  Future<void> _previewAsset(int index) async {
    if (index < 0 || index >= _assets.length) return;
    await AssetPickerViewer.pushToViewer(
      context,
      currentIndex: index,
      previewAssets: _assets,
      themeData: AssetPicker.themeData(Theme.of(context).primaryColor),
    );
  }

  void _deleteAsset(int index) {
    if (index < 0 || index >= _assets.length) return;
    setState(() {
      _assets.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedTrain == null) {
      showToast('请选择待离段车号');
      return;
    }
    if (_assets.isEmpty) {
      showToast('请上传离段照片');
      return;
    }
    final trainEntryCode =
        _pickText(_selectedTrain, ['trainEntryCode', 'code', 'id']);
    if (trainEntryCode.isEmpty) {
      showToast('车号数据异常，请重新选择');
      return;
    }

    setState(() => _submitting = true);
    SmartDialog.showLoading();
    try {
      _logger.i({
        'action': 'departureConfirmSubmit',
        'trainEntryCode': trainEntryCode,
        'train': _trainDisplay,
        'assetCount': _assets.length,
      });

      final files = <File>[];
      for (final a in _assets) {
        final f = await a.file;
        if (f != null) files.add(f);
      }
      if (files.isEmpty) {
        SmartDialog.dismiss();
        showToast('离段照片读取失败');
        return;
      }

      final repairEndTime =
          formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);
      final uploadResp = await ProductApi()
          .uploadTrainLeavePlatformFile(
            trainEntryCode: trainEntryCode,
            uploadFileList: files,
          )
          .timeout(
            const Duration(seconds: 95),
            onTimeout: () => null,
          );
      final uploadOk = _isResponseOk(uploadResp);
      if (!uploadOk) {
        SmartDialog.dismiss();
        if (uploadResp == null) {
          showToast('图片上传超时，请重试');
          return;
        }
        final msg = _extractResponseMessage(uploadResp);
        showToast(msg.isEmpty ? '图片上传失败' : msg);
        return;
      }

      final leaveResp = await ProductApi()
          .simulateCompleteTrainEntry(
            trainEntryCode: trainEntryCode,
            repairEndTime: repairEndTime,
          )
          .timeout(
            const Duration(seconds: 50),
            onTimeout: () => null,
          );
      final leaveOk = _isResponseOk(leaveResp);
      _logger.i({
        'action': 'departureConfirmResponse',
        'trainEntryCode': trainEntryCode,
        'leaveOk': leaveOk,
        'uploadOk': uploadOk,
        'leaveResponse': leaveResp,
        'uploadResponse': uploadResp,
      });

      if (!leaveOk) {
        SmartDialog.dismiss();
        if (leaveResp == null) {
          showToast('离段提交超时，请重试');
          return;
        }
        final msg = _extractResponseMessage(leaveResp);
        showToast(msg.isEmpty ? '提交失败' : msg);
        return;
      }

      SmartDialog.dismiss();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('离段确认成功'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SmartDialog.dismiss();
      _logger.e(e);
      showToast('提交失败');
    } finally {
      SmartDialog.dismiss();
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _isResponseOk(Map<String, dynamic>? resp) {
    if (resp == null) return false;
    dynamic code = resp['code'] ?? resp['status'] ?? resp['statusCode'];
    if (code is Map) code = code['code'];
    if (code == 'S_F_S000') return true;
    if (code == 200 || code == '200') return true;
    if (resp['success'] == true) return true;
    final data = resp['data'];
    if (data is Map) {
      final c = data['code'] ?? data['status'];
      if (c == 'S_F_S000') return true;
      if (c == 200 || c == '200') return true;
      if (data['success'] == true) return true;
    }
    return false;
  }

  String _extractResponseMessage(Map<String, dynamic>? resp) {
    if (resp == null) return '';
    for (final k in const ['msg', 'message', 'error', 'errmsg']) {
      final v = resp[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    final data = resp['data'];
    if (data is Map) {
      for (final k in const ['msg', 'message', 'error', 'errmsg']) {
        final v = data[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
    return '';
  }

  Widget _buildAssetGrid() {
    final items = _assets.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items,
      itemBuilder: (context, index) {
        if (index == items - 1) {
          return GestureDetector(
            onTap: _openCamera,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.grey),
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 40),
            ),
          );
        }
        final asset = _assets[index];
        return GestureDetector(
          onTap: () => _previewAsset(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Image(
                  image: AssetEntityImageProvider(asset),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _deleteAsset(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('机车离段确认')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ZjcFormSelectCell(
            title: '待离段车号',
            text: _trainDisplay,
            hintText: _loadingList ? '加载中...' : '请选择',
            showRedStar: true,
            clickCallBack: _showTrainPicker,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '离段照片',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('(${_assets.length})'),
            ],
          ),
          const SizedBox(height: 8),
          _buildAssetGrid(),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? '提交中...' : '提交'),
            ),
          ),
        ],
      ),
    );
  }
}
