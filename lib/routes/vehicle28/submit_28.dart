import 'dart:convert';
import 'dart:developer';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class Vehicle28Form extends StatefulWidget {
  final Map<dynamic, dynamic>? locoInfo;
  const Vehicle28Form({Key? key, this.locoInfo}) : super(key: key);

  @override
  State createState() => _Vehicle28FormState();
}

class _Vehicle28FormState extends State<Vehicle28Form> {
  // 动力类型
  // List<DynamicType> dynamicList = [];
  String? dynamicCode;
  String? dynamicName;
  // 机型
  Map<dynamic, dynamic> jcTypeListSelected = {"name": "", "code": ""};
  List<Map<String, dynamic>> jcTypeList = [];
  // 车号
  Map<dynamic, dynamic> trainNumSelected = {"trainNum": "", "code": ""};
  List<Map<String, dynamic>> trainNumCodeList = [];
  String? trainNum;
  String? trainCode;
  // 检修作业来源
  Map<dynamic, dynamic> repairWorkResource = {"name": "", "code": ""};
  // 风险等级
  String? riskLevel;
  // 加工方法
  Map<dynamic, dynamic> requiredProcessingMethod = {"dictName": "", "code": ""};
  // 故障现象
  String? faultDesc;
  // 故障假设
  String? faultAssumption;
  // 故障零部件
  Map<dynamic, dynamic> componentName = {"nodeName": "", "configCode": ""};
  // 报修时间
  DateTime? reportDate;
  // 故障图片
  List<AssetEntity> assestPics = [];
  List<File> faultPics = [];
  // 修程通知单
  String? maintenanceNotice;
  // 报修人
  String? reporter;
  // 科室车间
  String? workshop;
  // 班组
  String? team;
  int? teamCode;
  // 施修人员
  // Map<dynamic,dynamic> userSelected = {"userId":0,"nickName":""};
  // String? assignCode;

  List<Map<String, dynamic>> dynamicList = [];
  // 车组信息(组件试用版Map)
  List<dynamic> cascaderList = [];
  // 车厢信息
  List<dynamic> vehicleList = [];
  // 系统分类
  List<dynamic> sysTypeList = [];
  List<dynamic> workDeptIdList = [];
  // 零部件
  List<dynamic> configTree = [];
  // 车间班组
  List<dynamic> deptTree = [];
  // 全部车间树（根=检修部 parentId=101，直属子节点=车间；每个车间下的 children=班组）
  List<Map<String, dynamic>> workshopList = [];
  // 选到的车间
  int? workshopId;
  // 施修人员
  // Map<dynamic,dynamic> userSelected = {"userId":0,"nickName":""};
  // String? assignCode;

  // 完成工序节点（repairMainNode）—— 必须选车号拿到 repairProcCode 才能查
  String? repairProcCode; // 修程编码，来自 车号 selectItem.repairProcCode
  List<Map<String, dynamic>> repairMainNodeList = [];
  String? repairMainNodeName;
  String? repairMainNodeCode;

  // 完成排程节点 trainScheduleTemplate —— 选 工序节点.code + repairProcCode 才能查
  List<Map<String, dynamic>> scheduleNodeList = [];
  String? scheduleNodeName;
  String? scheduleNodeCode;

  // 班组人员（保留兼容命名，但不再是车间→班组 2 次接口模式）
  // ignore: unused_field
  List<dynamic> userList = [];
  // 检修作业来源
  List<dynamic> jtTypeList = [];
  // 加工方法
  List<dynamic> jt28DictList = [];

  // 自动派活
  bool isAssigned = false;
  String completeLabel = "自检自修";
  int completeStatus = 0;

  Map<dynamic, dynamic> dynamciTypeSelected = {};

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getJtType();
    getJt28Dict();
    _loadAllWorkshops();
    // 从入口 locoInfo 预置：车号 / 机型 / repairProcCode
    // 如果 repairProcCode 非空，立刻查工序节点（这样用户从"检修作业项点"点进来不用再选一次车号）
    final locoProcCode = (widget.locoInfo?["repairProcCode"] ??
            widget.locoInfo?["repair_procode"] ??
            widget.locoInfo?["procCode"])
        ?.toString();
    setState(() {
      trainNumSelected["trainNum"] = formatTrainNumWithEnds(
        widget.locoInfo?["trainNum"],
        extractEnds(widget.locoInfo),
      );
      trainNumSelected['code'] = widget.locoInfo?["trainNumCode"] ??
          widget.locoInfo?["code"] ??
          "";
      jcTypeListSelected['name'] = widget.locoInfo?["typeName"] ?? "";
      jcTypeListSelected['code'] = widget.locoInfo?["typeCode"] ?? "";
      repairProcCode = locoProcCode?.isNotEmpty == true ? locoProcCode : null;
    });
    logger.i('[机统28-提报(普通)][INIT] locoInfo=${jsonEncode(widget.locoInfo)} '
        '预置 repairProcCode=$repairProcCode');
    if (repairProcCode != null && repairProcCode!.isNotEmpty) {
      getRepairMainNodeAll();
    }
    // 如果从 locoInfo 带了机型 → 先把车号列表加载出来
    // 加载完成后会在 getTrainNumCodeList 内部"模拟选中一次"预置的车号，确保 repairProcCode 链路完整
    final typeCode = jcTypeListSelected['code']?.toString();
    final typeName = jcTypeListSelected['name']?.toString();
    if ((typeCode != null && typeCode.isNotEmpty) ||
        (typeName != null && typeName.isNotEmpty)) {
      getTrainNumCodeList();
    }
  }

  // ---------- 车号被选中时的统一处理（手工选 / 模拟选 都走这里，保证 repairProcCode 链路一致） ----------
  void _handleTrainNumPicked(Map<String, dynamic> selectItem) {
    logger.i('[机统28车号][SELECTED_ITEM] ${jsonEncode(selectItem)}');
    final pickedProcCode = (selectItem["repairProcCode"] ??
            selectItem["repair_procode"] ??
            selectItem["procCode"])
        ?.toString();
    logger.i(
        '[机统28车号][REPAIR_PROC_CODE] '
        '车号=${selectItem["trainNum"] ?? selectItem["displayTrainNum"]}, '
        'repairProcCode=${pickedProcCode ?? 'NULL⚠️'}');
    setState(() {
      trainNumSelected["trainNum"] =
          selectItem["displayTrainNum"] ?? selectItem["trainNum"];
      trainNumSelected["code"] = selectItem["code"];
      repairProcCode =
          pickedProcCode?.isNotEmpty == true ? pickedProcCode : null;
      // 车号变了，清空节点
      repairMainNodeName = null;
      repairMainNodeCode = null;
      repairMainNodeList = [];
      scheduleNodeName = null;
      scheduleNodeCode = null;
      scheduleNodeList = [];
    });
    if (repairProcCode != null && repairProcCode!.isNotEmpty) {
      getRepairMainNodeAll();
    }
  }

  // ---------- 车间班组：一次性加载全部车间树（parentIdList=101 检修部作为根，和 submit28_manage 1:1 对齐） ----------
  Future<void> _loadAllWorkshops() async {
    try {
      // 注意：和 submit28_manage.dart 完全一致 —— ProductApi.getDeptTreeByParentIdList
      // 用实例调用 ProductApi()，参数 parentIdList: int 101；返回结构外层 List[0]=检修部根节点，其 children=车间列表
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': 101},
      );
      logger.i('[车间树加载] getDeptTreeByParentIdList(parentIdList=101) 返回类型=${res.runtimeType} 长度=${(res is List) ? res.length : '非List⚠️'}');
      if (res is List && res.isNotEmpty) {
        final dynamic first = res[0];
        final dynamic children = first is Map ? first['children'] : null;
        if (children is List && children.isNotEmpty) {
          final sample = <String>[];
          for (var i = 0; i < (children.length > 3 ? 3 : children.length); i++) {
            final it = children[i];
            if (it is Map) {
              sample.add(
                  '#${i + 1} deptName=${it['deptName']} deptId=${it['deptId']} parentId=${it['parentId']} children_len=${(it['children'] as List?)?.length ?? 0}');
            }
          }
          logger.i('[车间树加载][车间前3条] ${sample.join(' | ')}');
          if (mounted) {
            setState(() {
              workshopList = children
                  .map<Map<String, dynamic>>((dynamic e) =>
                      e is Map<String, dynamic>
                          ? e
                          : Map<String, dynamic>.from(e as Map))
                  .toList();
            });
          }
        } else {
          logger.w('[车间树加载] 检修部节点下 children 为空/非List，最终 workshopList=[]');
          if (mounted) setState(() => workshopList = []);
        }
      } else {
        logger.w('[车间树加载] 接口返回非List或空，最终 workshopList=[]');
        if (mounted) setState(() => workshopList = []);
      }
    } catch (e, stackTrace) {
      logger.e('[车间树加载] error', e, stackTrace);
      if (mounted) setState(() => workshopList = []);
    }
  }

  // ---------- 工序节点：GET /subparts/repairMainNode/selectAll?repairProcCode=xxx （和 submit28_manage 1:1 对齐） ----------
  Future<void> getRepairMainNodeAll() async {
    try {
      final Map<String, dynamic> q = {'pageNum': 0, 'pageSize': 0};
      if (repairProcCode != null && repairProcCode!.isNotEmpty) {
        q['repairProcCode'] = repairProcCode;
      }
      logger.i(
          '[工序节点查询][REQ] GET /subparts/repairMainNode/selectAll queryParams=${jsonEncode(q)} '
          '(repairProcCode=${repairProcCode == null || repairProcCode!.isEmpty ? '未传⚠️' : repairProcCode})');
      // ⚠ 和 submit28_manage 完全一致：实例调用 ProductApi()（不是 ProductApi. 静态）
      final r = await ProductApi().getRepairMainNodeAll(queryParametrs: q);
      logger.i(
          '[工序节点查询][RES] repairProcCode=$repairProcCode '
          'r=${r == null ? 'NULL⚠️' : 'ok'} r.rows?.length=${r?.rows?.length ?? 0}');
      // 和 submit28_manage 一致：先判 r!=null 再判 r.rows!=null，避免 r 为 null 时取 r.rows 崩溃
      if (r != null && r.rows != null && mounted) {
        setState(() {
          repairMainNodeList = r.rows!
              .map<Map<String, dynamic>>((dynamic item) => _map(item))
              .toList();
        });
      } else if (r == null || r.rows == null) {
        logger.w('[工序节点查询] 返回 null 或 rows 为空 → repairMainNodeList=[]');
        if (mounted) setState(() => repairMainNodeList = []);
      }
    } catch (e, stackTrace) {
      log("getRepairMainNodeAll error: $e");
      logger.e("getRepairMainNodeAll", e, stackTrace);
      if (mounted) setState(() => repairMainNodeList = []);
    }
  }

  Map<String, dynamic> _toMap(dynamic item) {
    if (item is Map) return Map<String, dynamic>.from(item);
    try {
      final dynamic fn = item.toJson;
      if (fn is Function) {
        final dynamic res = fn();
        if (res is Map) return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Map<String, dynamic> _map(dynamic item) {
    final Map<String, dynamic> m = _toMap(item);
    dynamic ch;
    if (m['children'] is List && (m['children'] as List).isNotEmpty) {
      ch = m['children'];
    } else if (m['childList'] is List && (m['childList'] as List).isNotEmpty) {
      ch = m['childList'];
    } else if (m['rows'] is List && (m['rows'] as List).isNotEmpty) {
      ch = m['rows'];
    }
    if (ch != null) {
      m['children'] = (ch as List)
          .map<Map<String, dynamic>>((dynamic e) => _map(e))
          .toList();
    } else if (!m.containsKey('children')) {
      m['children'] = <Map<String, dynamic>>[];
    }
    return m;
  }

  // ---------- 排程节点：GET /dispatch/trainScheduleTemplate/getTemplateNodeByProcCodeAndMainNodeCode ----------
  Future<void> _loadScheduleNodeBy({
    required String procCode,
    required String mainNodeCode,
  }) async {
    try {
      final Map<String, dynamic> q = {
        'procCode': procCode,
        'repairMainNodeCode': mainNodeCode,
      };
      logger.i(
          '[排程节点查询][REQ] GET /dispatch/trainScheduleTemplate/getTemplateNodeByProcCodeAndMainNodeCode '
          'queryParams=${jsonEncode(q)}  (procCode=${procCode.isEmpty ? '空⚠️' : procCode}, '
          'repairMainNodeCode=${mainNodeCode.isEmpty ? '空⚠️' : mainNodeCode})');
      final r = await ProductApi().getTemplateNodeByProcCodeAndMainNodeCode(
        queryParametrs: q,
      );
      logger.i(
          '[排程节点查询][RES] procCode=$procCode, repairMainNodeCode=$mainNodeCode → 返回排程节点数=${r.length}');
      if (r.isNotEmpty) {
        logger.i(
            '[排程节点查询][RES_SAMPLE] 前5条=${jsonEncode(r.length <= 5 ? r : r.take(5).toList())}');
      }
      if (mounted) {
        setState(() => scheduleNodeList = r);
      }
    } catch (e, stackTrace) {
      log("_loadScheduleNodeBy error: $e");
      logger.e("_loadScheduleNodeBy", e, stackTrace);
      if (mounted) setState(() => scheduleNodeList = []);
    }
  }

  // 动力类型
  void getDynamicType() async {
    var r = await ProductApi().getDynamicType();
    if (r.rows != []) {
      if (mounted) {
        setState(() {
          List<DynamicType> dyn = r.rows!;
          List<Map<String, dynamic>> temp = [];
          for (DynamicType item in dyn) {
            temp.add(item.toJson()); 
          }
          dynamicList = temp;
          //默认动力类型
          dynamciTypeSelected = dynamicList[0];
          getTypeCode();
        });
      }
    }
  }

  // 机型
  //List<Map<String, dynamic>>类型才能够使用
  void getTypeCode() async {
    var r = await ProductApi().getJcType(queryParametrs: {
      'dynamicCode': dynamciTypeSelected['code'],
    });
    if (r.rows != []) {
      if (mounted) {
        setState(() {
          jcTypeList = r.toMapList();
        });
      }
    }
  }

  // 车号
  int pageNum = 0;
  int pageSize = 0;
  bool isLoading = false;
  bool hasMore = true;
  bool _submitting = false;

  String _asText(dynamic value) => (value ?? '').toString().trim();

  String _buildTrainNumDisplay(dynamic trainNum, dynamic ends) {
    final train = _asText(trainNum);
    if (train.isEmpty) return '';
    final endsText = _asText(ends);
    final result = endsText.isEmpty ? train : '$train$endsText';
    logger.i('[机统28车号][BUILD_DISPLAY] trainNum=$trainNum ends=$ends result=$result');
    return result;
  }

  void _logTrainNumQueryPreview(List<Map<String, dynamic>> rows) {
    final total = rows.length;
    const head = 10;
    const tail = 5;
    final headCount = total < head ? total : head;
    final tailCount = total > head ? (total - head < tail ? total - head : tail) : 0;
    logger.i('[机统28车号查询][RES_PREVIEW] total=$total head=$headCount tail=$tailCount');
    for (var i = 0; i < headCount; i++) {
      final item = rows[i];
      logger.i(
        '[机统28车号查询][RES_ITEM] idx=$i '
        'trainNum=${_asText(item['trainNum'])} '
        'ends=${_asText(item['ends'])} '
        'displayTrainNum=${_asText(item['displayTrainNum'])} '
        'code=${_asText(item['code'])}',
      );
    }
    if (tailCount > 0) {
      logger.i('[机统28车号查询][RES_ITEM] ...');
      for (var i = total - tailCount; i < total; i++) {
        final item = rows[i];
        logger.i(
          '[机统28车号查询][RES_ITEM] idx=$i '
          'trainNum=${_asText(item['trainNum'])} '
          'ends=${_asText(item['ends'])} '
          'displayTrainNum=${_asText(item['displayTrainNum'])} '
          'code=${_asText(item['code'])}',
        );
      }
    }
  }

  bool _isSubmitSuccess(dynamic submit) {
    if (submit is! Map) return false;
    final code = _asText(submit['code']);
    return code == 'S_T_S001' || code == 'S_T_S003' || code == '200';
  }

  void _showSubmitSuccessDialog() {
    SmartDialog.show(
      clickMaskDismiss: false,
      builder: (con) {
        return Container(
          height: 150,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                "机统28提报成功",
                style: TextStyle(fontSize: 18),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints.expand(height: 30, width: 160),
                child: ElevatedButton.icon(
                  onPressed: () {
                    SmartDialog.dismiss().then(
                      (value) => Navigator.of(context).pop(true),
                    );
                  },
                  label: const Text('确定'),
                  icon: const Icon(Icons.system_security_update_good_sharp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 车号（支持分页加载）
  void getTrainNumCodeList({bool isLoadMore = false}) async {
    if (isLoading) return;

    if (!isLoadMore) {
      // 刷新数据
      pageNum = 0;
      hasMore = true;
    } else {
      // 加载更多
      if (!hasMore) return;
      pageNum++;
    }

    try {
      isLoading = true;

      // 构建查询车号参数
      Map<String, dynamic> queryParameters = {
        'typeName': jcTypeListSelected["name"],
        'pageNum': pageNum,
        'pageSize': pageSize,
        'complete': 0,
      };
      logger.i('[机统28车号查询][REQ] isLoadMore=$isLoadMore params=$queryParameters');

      if (!isLoadMore) {
        // 只在初次加载时显示loading
        SmartDialog.showLoading(msg: '加载车号中...');
      }

      // 获取车号
      var r =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      final rows = r.toMapList();
      logger.i('[机统28车号查询][RES] rows=${rows.length} pageNum=$pageNum');
      if (rows.isNotEmpty) {
        logger.i('[机统28车号查询][RAW_FIRST_ITEM] ${jsonEncode(rows.first)}');
      }

      if (!isLoadMore) {
        SmartDialog.dismiss();
      }

      if (mounted) {
        setState(() {
          final next = rows.map((e) {
            final m = Map<String, dynamic>.from(e);
            m['displayTrainNum'] = _buildTrainNumDisplay(
              m['trainNum'],
              m['ends'],
            );
            return m;
          }).toList();
          _logTrainNumQueryPreview(next);
          logger.i('[机统28车号][NEXT_DATA_SAMPLE] ${jsonEncode(next.take(3).toList())}');
          if (isLoadMore) {
            // 加载更多数据
            trainNumCodeList.addAll(next);
          } else {
            // 刷新数据
            trainNumCodeList = next;
          }

          // 判断是否还有更多数据
          if (next.length < pageSize) {
            hasMore = false;
          }

          // ---------- 模拟选择一次预置的车号（从检修作业项点进入时走这里） ----------
          // 只在初次刷新（非 loadMore）且 trainNumSelected['code'] 有预置值时才模拟
          if (!isLoadMore) {
            final presetCode =
                (trainNumSelected['code'] ?? widget.locoInfo?["trainNumCode"] ?? widget.locoInfo?["code"])
                    ?.toString();
            if (presetCode != null && presetCode.isNotEmpty) {
              // 优先完全匹配 code；找不到则兜底匹配 trainNum（手写 for 循环，避免依赖 package:collection 的 firstWhereOrNull 扩展方法，保证不报错）
              Map<String, dynamic>? match;
              for (final m in next) {
                final c1 = m['code']?.toString();
                final c2 = m['trainNumCode']?.toString();
                if ((c1 != null && c1 == presetCode) ||
                    (c2 != null && c2 == presetCode)) {
                  match = m;
                  break;
                }
              }
              if (match == null) {
                final pT = (widget.locoInfo?["trainNum"] ?? '').toString().trim();
                if (pT.isNotEmpty) {
                  for (final m in next) {
                    final t = (m['trainNum'] ?? '').toString().trim();
                    if (t.isNotEmpty && t == pT) {
                      match = m;
                      break;
                    }
                  }
                }
              }
              if (match != null) {
                logger.i('[机统28车号][模拟选中] presetCode=$presetCode → 匹配到 ${jsonEncode(match)}');
                // 用微任务抛到下一次事件循环，避免嵌套 setState 的时序问题
                final picked = match!;
                Future.microtask(() {
                  if (mounted) _handleTrainNumPicked(picked);
                });
              } else {
                logger.w('[机统28车号][模拟选中] presetCode=$presetCode 在本次 ${next.length} 条结果中未匹配到任何项，跳过模拟选中');
              }
            }
          }
        });
      }
    } catch (e, stackTrace) {
      if (!isLoadMore) {
        SmartDialog.dismiss();
      }
      logger.e('[机统28车号查询] getTrainNumCodeList 发生异常: $e\n堆栈信息: $stackTrace');
      if (mounted) {
        if (isLoadMore) {
          pageNum--; // 恢复页码
        }
        showToast("获取车号失败，请重试");
      }
    } finally {
      isLoading = false;
    }
  }

  // 零部件
  void getAllConfigTreeByCode() async {
    try {
      var r = await JtApi().getAllConfigTreeByCode(
          queryParametrs: {'typeCode': jcTypeListSelected['code']});
      if (r['code'] != 200) {
        if (mounted) {
          setState(() {
            configTree = r['data'];
          });
        }
      } else {
        showToast("获取零部件表失败,请检查网络");
      }
    } catch (e) {
      log("$e");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  // 车间班组
  void getUserDeptree() async {
    try {
      var r = await JtApi().getUserDeptree();
      if (r != [] && r != null) {
        if (mounted) {
          setState(() {
            deptTree = ((r[0])["children"])[0]["children"];
          });
        }
      } else {
        showToast("未能获取车间班组");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 班组人员
  void getJtUsers() async {
    try {
      var r = await JtApi().getUserList(
          queryParametrs: {'pageNum': 0, 'pageSize': 0, 'deptId': teamCode});
      if (r != [] && r != null) {
        if (mounted) {
          setState(() {
            userList = r['rows'];
          });
        }
      } else {
        showToast("未能获取班组人员");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 检修作业来源
  void getJtType() async {
    try {
      var r = await JtApi().getJtType();
      if (r.code == 200 && r.rows != null) {
        if (mounted) {
          setState(() {
            jtTypeList = r.rows!;
            if ((repairWorkResource["code"] ?? "").toString().isEmpty &&
                jtTypeList.isNotEmpty &&
                jtTypeList.first is Map) {
              final first = jtTypeList.first as Map;
              repairWorkResource["name"] = (first["name"] ?? "").toString();
              repairWorkResource["code"] = (first["code"] ?? "").toString();
              riskLevel = first["riskLevel"]?.toString();
            }
          });
        }
      } else {
        showToast("未能获取作业来源");
      }
    } catch (e) {
      log("$e");
    }
  }

  // 加工方法
  void getJt28Dict() async {
    try {
      var r = await JtApi().getJt28Dict();
      if (r.code == 200 && r.rows != null) {
        if (mounted) {
          setState(() {
            jt28DictList = r.rows!;
            if ((requiredProcessingMethod["code"] ?? "").toString().isEmpty &&
                jt28DictList.isNotEmpty &&
                jt28DictList.first is Map) {
              final first = jt28DictList.first as Map;
              requiredProcessingMethod["dictName"] =
                  (first["dictName"] ?? "").toString();
              requiredProcessingMethod["code"] = (first["code"] ?? "").toString();
            }
          });
        }
      } else {
        showToast("未能获取加工方法");
      }
    } catch (e) {
      log("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("机统28-提报（作业）"),
      ),
      // resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar: _footer(),
    );
  }

  Widget _buildBody() {
    // reportDate = DateTime.now();
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView(
          children: <Widget>[
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // ZjcFormSelectCell(
                  //   title: "动力类型",
                  //   text: dynamciTypeSelected["name"],
                  //   hintText: "请选择",
                  //   showRedStar: true,
                  //   clickCallBack: () {
                  //     if (dynamicList.isEmpty) {
                  //       showToast("无动力类型选择");
                  //     } else {
                  //       ZjcCascadeTreePicker.show(
                  //         context,
                  //         data: dynamicList,
                  //         labelKey: 'name',
                  //         valueKey: 'code',
                  //         childrenKey: 'children',
                  //         title: "选择动力类型",
                  //         clickCallBack: (selectItem, selectArr) {
                  //           logger.i(selectArr);
                  //           setState(() {
                  //             dynamciTypeSelected["code"] = selectItem["code"];
                  //             dynamciTypeSelected["name"] = selectItem["name"];
                  //             getTypeCode();
                  //           });
                  //         },
                  //       );
                  //     }
                  //   },
                  // ),
                  // ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ZjcFormSelectCell(
                          title: "机型",
                          text: jcTypeListSelected["name"],
                          hintText: "请选择",
                          clickCallBack: () {
                            if (jcTypeList.isEmpty) {
                              showToast("无机型可以选择");
                            } else {
                              ZjcCascadeTreePicker.show(
                                context,
                                data: jcTypeList,
                                labelKey: 'name',
                                valueKey: 'code',
                                childrenKey: 'children',
                                title: "选择机型",
                                clickCallBack: (selectItem, selectArr) {
                                  setState(() {
                                    logger.i(selectArr);
                                    jcTypeListSelected["name"] =
                                        selectItem["name"];
                                    jcTypeListSelected["code"] =
                                        selectItem["code"];
                                    getTrainNumCodeList();
                                  });
                                },
                              );
                            }
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ZjcFormSelectCell(
                          title: "车号",
                          text: trainNumSelected["trainNum"],
                          hintText: "请选择",
                          clickCallBack: () {
                            if (trainNumCodeList.isEmpty) {
                              showToast("无车号可以选择");
                            } else {
                              ZjcCascadeTreePicker.show(
                                context,
                                data: trainNumCodeList,
                                labelKey: 'displayTrainNum',
                                valueKey: 'code',
                                childrenKey: 'children',
                                title: "选择检修地点",
                                clickCallBack: (selectItem, selectArr) {
                                  _handleTrainNumPicked(
                                    selectItem is Map<String, dynamic>
                                        ? selectItem
                                        : Map<String, dynamic>.from(
                                            selectItem as Map),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  // ZjcFormSelectCell(
                  //   title: "检修作业来源",
                  //   text: repairWorkResource["name"],
                  //   hintText: "请选择",
                  //   showRedStar: true,
                  //   clickCallBack: () {
                  //     ZjcCascadeTreePicker.show(
                  //       context,
                  //       data: jtTypeList,
                  //       labelKey: 'name',
                  //       valueKey: 'code',
                  //       title: "选择检修作业来源",
                  //       clickCallBack: (selectItem, selectArr) {
                  //         logger.i(selectArr);
                  //         setState(() {
                  //           repairWorkResource["name"] = selectItem["name"];
                  //           repairWorkResource["code"] = selectItem["code"];
                  //           riskLevel = selectItem["riskLevel"];
                  //         });
                  //       },
                  //     );
                  //   },
                  // ),
                  // ZjcFormInputCell(
                  //   title: "风险等级",
                  //   showRedStar: true,
                  //   text: riskLevel,
                  //   enabled: false,
                  // ),
                  // ZjcFormSelectCell(
                  //   title: "加工方法",
                  //   text: requiredProcessingMethod["dictName"],
                  //   hintText: "请选择",
                  //   showRedStar: true,
                  //   clickCallBack: () {
                  //     ZjcCascadeTreePicker.show(
                  //       context,
                  //       data: jt28DictList,
                  //       labelKey: 'dictName',
                  //       valueKey: 'code',
                  //       title: "选择加工方法",
                  //       clickCallBack: (selectItem, selectArr) {
                  //         logger.i(selectArr);
                  //         setState(() {
                  //           requiredProcessingMethod["dictName"] =
                  //               selectItem["dictName"];
                  //           requiredProcessingMethod["code"] =
                  //               selectItem["code"];
                  //         });
                  //       },
                  //     );
                  //   },
                  // ),
                  ZjcFormInputCell(
                    title: "故障现象",
                    text: faultDesc,
                    maxLines: 7,
                    maxLength: 300,
                    showRedStar: true,
                    inputCallBack: (value) {
                      faultDesc = value;
                    },
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "派工方式",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('自检自修'),
                            selected: completeStatus == 0,
                            selectedColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool selected) {
                              if (!selected) return;
                              setState(() {
                                completeStatus = 0;
                                completeLabel = '自检自修';
                              });
                            },
                          ),
                          const SizedBox(width: 20),
                          ChoiceChip(
                            label: const Text('工长派工'),
                            selected: completeStatus == 1,
                            selectedColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool selected) {
                              if (!selected) return;
                              setState(() {
                                completeStatus = 1;
                                completeLabel = '工长派工';
                                // 工长派工时清空自检自修专用字段，避免污染
                                workshop = null;
                                workshopId = null;
                                team = null;
                                teamCode = null;
                                repairMainNodeName = null;
                                repairMainNodeCode = null;
                                repairMainNodeList = [];
                                scheduleNodeName = null;
                                scheduleNodeCode = null;
                                scheduleNodeList = [];
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 自检自修专用：处置部门 + 工序节点 + 排程节点
                  if (completeStatus == 0) ...[
                    const SizedBox(height: 10),
                    // ---------- 1. 处置部门（车间/班组 两级一起选） ----------
                    ZjcFormSelectCell(
                      title: "处置部门",
                      hintText: "请选择处置部门（车间→班组）",
                      showRedStar: true,
                      text: (workshop != null && workshop!.isNotEmpty
                          ? (team != null && team!.isNotEmpty
                              ? "$workshop / $team"
                              : workshop!)
                          : null),
                      clickCallBack: () {
                        if (workshopList.isEmpty) {
                          showToast("车间数据加载中，请稍后再试");
                          return;
                        }
                        ZjcCascadeTreePicker.show(
                          context,
                          data: workshopList,
                          labelKey: 'deptName',
                          valueKey: 'deptId',
                          childrenKey: 'children',
                          title: "选择处置部门",
                          clickCallBack: (selectItem, selectArr) {
                            if (selectArr == null || selectArr.isEmpty) return;
                            final first = selectArr[0];
                            setState(() {
                              workshop = first["deptName"]?.toString();
                              final fId = first["deptId"];
                              workshopId = fId is int
                                  ? fId
                                  : int.tryParse(fId?.toString() ?? '');
                              if (selectArr.length >= 2) {
                                // 选到了班组层级
                                final last = selectItem;
                                team = last["deptName"]?.toString();
                                final tId = last["deptId"];
                                teamCode = tId is int
                                    ? tId
                                    : int.tryParse(tId?.toString() ?? '');
                              } else {
                                // 只选了车间，没选班组 → 清空班组
                                team = null;
                                teamCode = null;
                              }
                            });
                          },
                        );
                      },
                    ),
                    // ---------- 2. 完成工序节点（repairMainNode） ----------
                    if (repairProcCode == null || repairProcCode!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "需要选择车号后才能查到完成工序节点",
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ZjcFormSelectCell(
                      title: "完成工序节点",
                      hintText: repairProcCode == null || repairProcCode!.isEmpty
                          ? "需要选择车号后才能查到"
                          : "请选择",
                      showRedStar: true,
                      text: repairMainNodeName,
                      clickCallBack: () {
                        if (repairProcCode == null || repairProcCode!.isEmpty) {
                          showToast("需要选择车号后才能查到完成工序节点");
                          return;
                        }
                        if (repairMainNodeList.isEmpty) {
                          showToast("完成工序节点数据加载中，请稍后再试");
                          return;
                        }
                        ZjcCascadeTreePicker.show(
                          context,
                          data: repairMainNodeList,
                          labelKey: 'name',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择完成工序节点",
                          clickCallBack: (selectItem, selectArr) {
                            final code = selectItem["code"]?.toString();
                            final name = selectItem["name"]?.toString();
                            logger.i(
                                '[完成工序节点选中] '
                                'name=$name, code=$code. '
                                '⚠️ procCode 不是工序节点字段，它来自【车号.state.repairProcCode】=$repairProcCode '
                                '后续排程节点查询传参：procCode=$repairProcCode, repairMainNodeCode=$code');
                            setState(() {
                              repairMainNodeName = name;
                              repairMainNodeCode = code;
                              scheduleNodeName = null;
                              scheduleNodeCode = null;
                              scheduleNodeList = [];
                            });
                            if (repairProcCode != null &&
                                code != null &&
                                code.isNotEmpty) {
                              _loadScheduleNodeBy(
                                procCode: repairProcCode!,
                                mainNodeCode: code,
                              );
                            }
                          },
                        );
                      },
                    ),
                    // ---------- 3. 完成排程节点 ----------
                    ZjcFormSelectCell(
                      title: "完成排程节点",
                      hintText: "请先选择完成工序节点",
                      showRedStar: true,
                      text: scheduleNodeName,
                      clickCallBack: () {
                        if (repairMainNodeCode == null || repairMainNodeCode!.isEmpty) {
                          showToast("请先选择完成工序节点");
                          return;
                        }
                        if (repairProcCode == null || repairProcCode!.isEmpty) {
                          showToast("需要先选择车号（获取修程编码）");
                          return;
                        }
                        if (scheduleNodeList.isEmpty) {
                          showToast("该完成工序节点下暂无完成排程节点");
                          return;
                        }
                        String pickLabelKey() {
                          final first = scheduleNodeList.first;
                          if (first.keys.contains('name')) return 'name';
                          if (first.keys.contains('nodeName')) return 'nodeName';
                          if (first.keys.contains('scheduleNodeName')) return 'scheduleNodeName';
                          if (first.keys.contains('displayName')) return 'displayName';
                          return 'name';
                        }
                        String pickValueKey() {
                          final first = scheduleNodeList.first;
                          if (first.keys.contains('code')) return 'code';
                          if (first.keys.contains('nodeCode')) return 'nodeCode';
                          if (first.keys.contains('scheduleNodeId')) return 'scheduleNodeId';
                          if (first.keys.contains('id')) return 'id';
                          return 'code';
                        }
                        final L = pickLabelKey();
                        final V = pickValueKey();
                        ZjcCascadeTreePicker.show(
                          context,
                          data: scheduleNodeList,
                          labelKey: L,
                          valueKey: V,
                          childrenKey: 'children',
                          title: "选择完成排程节点",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              scheduleNodeName = selectItem[L]?.toString();
                              scheduleNodeCode = selectItem[V]?.toString();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  // 故障视频及图片
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(10, 10, 0, 5),
                        child: Text(
                          '故障视频及图片',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                            border: Border.all(color: Colors.brown)),
                        child: ZjcAssetPicker(
                          assetType: APC.AssetType.imageAndVideo,
                          maxAssets: 9,
                          selectedAssets: assestPics,
                          // bgColor: Colors.grey,
                          callBack: (assetEntityList) async {
                            logger.i('assetEntityList-------------');
                            logger.i(assetEntityList);
                            if (assetEntityList.isNotEmpty) {
                              // 清空之前的文件列表
                              List<File> files = [];

                              // 处理所有选定的资源（图片和视频）
                              for (var asset in assetEntityList) {
                                var file = await asset.file;
                                if (file != null) {
                                  files.add(file);
                                }
                              }

                              if (mounted) {
                                setState(() {
                                  assestPics = assetEntityList;
                                  faultPics = files;
                                });
                              }
                            } else {
                              if (mounted) {
                                setState(() {
                                  faultPics = [];
                                  assestPics = [];
                                });
                              }
                            }
                            logger.i('assetEntityList-------------');
                          },
                        ),
                      ),
                    ],
                  ),
                ])
          ],
        ));
  }

  Widget _footer() {
    return SafeArea(
        child: InkWell(
      onTap: () async {
        if (_submitting) {
          showToast("正在提报中，请勿重复提交");
          return;
        }
        // 验证必填字段
        if (jcTypeListSelected['code'] == null || 
            jcTypeListSelected['code'] == '') {
          showToast("请选择机型");
          return;
        }
        if (trainNumSelected['code'] == null || 
            trainNumSelected['code'] == '') {
          showToast("请选择车号");
          return;
        }
        if (faultDesc == null || faultDesc!.trim().isEmpty) {
          showToast("请填写故障现象");
          return;
        }
        if (widget.locoInfo?["code"] == null || 
            widget.locoInfo?["code"] == '') {
          showToast("机车信息不完整，请重新进入");
          return;
        }
        if ((repairWorkResource["code"] ?? "").toString().isEmpty) {
          showToast("检修作业来源未获取到，请稍后重试");
          return;
        }
        if ((requiredProcessingMethod["code"] ?? "").toString().isEmpty) {
          showToast("加工方法未获取到，请稍后重试");
          return;
        }
        
        // 所有必填字段验证通过，继续提报
        var submit;
        List<Map<String, dynamic>> l = [];
        try {
            if (mounted) {
              setState(() => _submitting = true);
            }
            SmartDialog.showLoading();
            Map<String, dynamic> queryParameters = {
              // "faultAssumption": faultAssumption,
              "faultDescription": faultDesc,
              // "faultyComponent": componentName['configCode'],
              "machineModel": jcTypeListSelected['code'],
              // "maintenanceNotice": maintenanceNotice,
              "trainEntryCode": widget.locoInfo?["code"],
              "repairWorkResource": repairWorkResource["code"],
              "riskLevel": riskLevel,
              'deptId': Global.profile.permissions?.user.deptId,
              'deptName': Global.profile.permissions?.user.dept?.deptName ,
              "requiredProcessingMethod": requiredProcessingMethod["code"],
              "completeStatus": completeStatus,
              "status": 0
            };
            queryParameters.removeWhere((key, value) {
              if (value == null) return true;
              if (value is String && value.trim().isEmpty) return true;
              return false;
            });
            // ---------- 自检自修 / 工长派工 分支 ----------
            if (completeStatus == 0) {
              // 自检自修：班组+完成工序节点+完成排程节点 必填
              if (teamCode == null) {
                showToast("自检自修请选到处置部门-班组层级（先选车间再选班组）");
                if (mounted) setState(() => _submitting = false);
                SmartDialog.dismiss(status: SmartStatus.loading);
                return;
              }
              if (repairMainNodeCode == null || repairMainNodeCode!.isEmpty) {
                showToast("自检自修请选择完成工序节点");
                if (mounted) setState(() => _submitting = false);
                SmartDialog.dismiss(status: SmartStatus.loading);
                return;
              }
              if (scheduleNodeCode == null || scheduleNodeCode!.isEmpty) {
                showToast("自检自修请选择完成排程节点");
                if (mounted) setState(() => _submitting = false);
                SmartDialog.dismiss(status: SmartStatus.loading);
                return;
              }
              queryParameters["team"] = teamCode;
              queryParameters["repairMainNodeCode"] = repairMainNodeCode;
              queryParameters["scheduleNodeCode"] = scheduleNodeCode;
              if (repairProcCode != null && repairProcCode!.isNotEmpty) {
                queryParameters["repairProcCode"] = repairProcCode;
              }
              queryParameters["repairPersonnel"] =
                  Global.profile.permissions?.user.userId;
            } else {
              // 工长派工：不写入处置部门/完成工序/完成排程字段，由后续派工流程处理
              // queryParameters["repairPersonnel"] = userSelected["userId"];
            }
            if (faultPics.isNotEmpty) {
              await JtApi().uploadMixJt(imagedata: faultPics).then(
                    (value) async => {
                      if (value['data'] != null && value['data'] != "")
                        {
                          queryParameters["repairPicture"] = value['data'],
                          l.insert(0, queryParameters),
                          submit = await JtApi().uploadJt28(queryParametrs: l),
                          if (!_isSubmitSuccess(submit) && submit['data'] != null)
                            {
                              showToast("${submit['data']}"),
                              // SmartDialog.dismiss(status: SmartStatus.loading)
                            }
                        }
                      else
                        {
                          showToast("图片上传失败，请检查网络连接"),
                          // SmartDialog.dismiss(status: SmartStatus.loading)
                        }
                    },
                  );
            } else {
              log("$queryParameters");
              l.insert(0, queryParameters);
              submit = await JtApi().uploadJt28(queryParametrs: l);
              if (!_isSubmitSuccess(submit)) {
                showToast("机统28提报失败，请检查网络连接");
                // SmartDialog.dismiss(status: SmartStatus.loading);
              }
            }
          } on DioException catch (e) {
            final serverMsg = e.response?.data is Map
                ? (e.response?.data["msg"] ??
                    e.response?.data["message"] ??
                    e.response?.data["error"])
                : null;
            showToast("故障提报失败${serverMsg != null ? "：$serverMsg" : ""}");
            logger.i(e.toString());
          } finally {
            SmartDialog.dismiss(status: SmartStatus.loading);
            if (mounted) {
              setState(() => _submitting = false);
            }
            if (_isSubmitSuccess(submit)) {
              _showSubmitSuccessDialog();
            }
          }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.blueGrey[100],
        height: 50,
        child: const Text('故障提报',
            style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
    ));
  }

  Future<String> selectDate(str) async {
    DateTimePickerType dt;
    if (str == "datetime") {
      dt = DateTimePickerType.datetime;
    } else if (str == "date") {
      dt = DateTimePickerType.date;
    } else {
      dt = DateTimePickerType.time;
    }

    var val = await showBoardDateTimePicker(
      context: context,
      pickerType: dt,
    );
    if (val != null && str == "datetime") {
      String str =
          formatDate(val, [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);
      logger.i(str);
      return str;
    } else if (val != null && str == "date") {
      String str = formatDate(val, [yyyy, '-', mm, '-', dd]);
      return str;
    } else {
      return "";
    }
  }
}
