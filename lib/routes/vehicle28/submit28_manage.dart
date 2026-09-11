import 'dart:convert';
import 'dart:developer';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../config/filter_data.dart';
import '../../index.dart';
import 'package:intl/intl.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class Vehicle28FormManage extends StatefulWidget {
  const Vehicle28FormManage({Key? key}) : super(key: key);

  @override
  State createState() => _Vehicle28FormManageState();
}

class _Vehicle28FormManageState extends State<Vehicle28FormManage> {
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
  // 施修方案
  String? repairPlan;
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
  int? workshopId;
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
  // 车间列表（首次独立拉取，非 deptTree 嵌套）
  List<Map<String, dynamic>> workshopList = [];
  // 班组人员
  List<dynamic> userList = [];
  // 检修作业来源
  List<dynamic> jtTypeList = [];
  // 加工方法
  List<dynamic> jt28DictList = [];
  // 假设类别
  List<String> assumeTypeList = ['正常', '人工', '自然'];
  // 派工方式
  List<String> assignTypeList = ['自检自修', '工长派工'];
  String selectedAssumeType = '正常';
  // 自动派活
  bool isAssigned = false;
  String completeLabel = "自检自修";
  int completeStatus = 0;

  // 完成节点（工序主节点）
  List<dynamic> repairMainNodeList = [];
  String? repairMainNodeName;
  String? repairMainNodeCode;
  // 排程节点：选完工序节点后，按 {procCode, repairMainNodeCode} 从 trainScheduleTemplate 拉
  List<Map<String, dynamic>> scheduleNodeList = [];
  String? scheduleNodeName;
  String? scheduleNodeCode;
  // 修程编码（来自选中车号 selectItem.repairProcCode，用于工序节点/排程节点查询）
  String? repairProcCode;

  Map<dynamic, dynamic> dynamciTypeSelected = {};

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    getDynamicType();
    _loadAllWorkshops(); // 先拉全部车间
    getJtType();
    getJt28Dict();
    // 工序节点必须绑定修程编码（repairProcCode），只有选完车号才有修程，
    // 所以 initState 不调，改到「选完车号 clickCallBack」里调 getRepairMainNodeAll()
  }

  // 拉取全部车间（parentIdList: 101 检修部作为根，对齐 jt28_dispatch_page 模式）
  Future<void> _loadAllWorkshops() async {
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': 101},
      );
      if (res is List && res.isNotEmpty) {
        final children = res[0]['children'];
        if (mounted) {
          if (children is List && children.isNotEmpty) {
            setState(() {
              workshopList = children
                  .map((e) => e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map))
                  .toList();
            });
          } else {
            setState(() => workshopList = []);
          }
        }
      } else if (mounted) {
        setState(() => workshopList = []);
      }
    } catch (e, stackTrace) {
      log("_loadAllWorkshops error: $e");
      logger.e("_loadAllWorkshops", e, stackTrace);
      if (mounted) setState(() => workshopList = []);
    }
  }

  // 拉取工序主节点（根据修程编码 repairProcCode 查询，没有修程时拉全量兜底）
  // GET /subparts/repairMainNode/selectAll  ?repairProcCode=xxx
  // ⚠️ 返回的 RepairMainNode.rows 元素是"类实例"（不同模块都叫 Rows，存在同名类 import 冲突，不能写 is Rows）。
  //    转纯 Map 策略：类实例若带 toJson() 就调用，否则当作 Map，递归 children 统一挂到 'children' 下。
  void getRepairMainNodeAll() async {
    try {
      final Map<String, dynamic> q = {'pageNum': 0, 'pageSize': 0};
      if (repairProcCode != null && repairProcCode!.isNotEmpty) {
        q['repairProcCode'] = repairProcCode;
      }
      logger.i(
          '[工序节点查询][REQ] GET /subparts/repairMainNode/selectAll '
          'queryParams=${jsonEncode(q)}  '
          '(key=repairProcCode，严格按照后端文档传修程编码)');
      final r = await ProductApi().getRepairMainNodeAll(queryParametrs: q);
      if (r != null && r.rows != null) {
        if (mounted) {
          Map<String, dynamic> _toMap(dynamic item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            // 类实例兜底：只要带 toJson() 方法就调用（不管是哪个 Rows 类 / Dept 类 / 其他 Model 类）
            try {
              final dynamic fn = item.toJson;
              if (fn is Function) {
                final dynamic res = fn();
                if (res is Map) return Map<String, dynamic>.from(res);
              }
            } catch (_) {}
            return <String, dynamic>{};
          }
          Map<String, dynamic> _map(dynamic e) {
            final m = _toMap(e);
            // children 字段归一化：children/childList/rows 任一存在就挂到 m['children']
            final rawChildren = m['children'] ?? m['childList'] ?? m['rows'];
            if (rawChildren is List) {
              m['children'] = rawChildren
                  .map<Map<String, dynamic>>((sub) => _map(sub))
                  .toList();
            } else {
              m['children'] ??= [];
            }
            return m;
          }
          final rowsList = r.rows!
              .map<Map<String, dynamic>>((dynamic item) => _map(item))
              .toList();
          logger.i(
              '[工序节点查询][RES] repairProcCode=${q['repairProcCode'] ?? '未传⚠️'}  '
              '返回节点数=${rowsList.length}');
          setState(() {
            repairMainNodeList = rowsList;
          });
        }
      }
    } catch (e, stackTrace) {
      log("getRepairMainNodeAll error: $e");
      logger.e("getRepairMainNodeAll", e, stackTrace);
    }
  }

  // 根据 修程编码（procCode，来自车号 repairProcCode） + 已选工序节点编码（repairMainNodeCode） 拉排程节点
  // GET /dispatch/trainScheduleTemplate/getTemplateNodeByProcCodeAndMainNodeCode
  // 严格对齐接口文档入参名：procCode / repairMainNodeCode（注意第一个参数是 procCode，不是 repairProcCode）
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
          '[排程节点查询][REQ] '
          'GET /dispatch/trainScheduleTemplate/getTemplateNodeByProcCodeAndMainNodeCode '
          'queryParams=${jsonEncode(q)}  '
          '(procCode=车号修程码=${procCode.isEmpty ? '空⚠️' : procCode}, '
          'repairMainNodeCode=工序节点code=${mainNodeCode.isEmpty ? '空⚠️' : mainNodeCode})');
      final r =
          await ProductApi().getTemplateNodeByProcCodeAndMainNodeCode(
        queryParametrs: q,
      );
      logger.i(
          '[排程节点查询][RES] '
          'procCode=$procCode, repairMainNodeCode=$mainNodeCode → 返回排程节点数=${r.length}');
      if (r.isNotEmpty) {
        final sample =
            jsonEncode(r.length <= 5 ? r : r.take(5).toList());
        logger.i('[排程节点查询][RES_SAMPLE] 前5条字段名示例=$sample');
      }
      if (mounted) {
        setState(() {
          scheduleNodeList = r;
        });
      }
    } catch (e, stackTrace) {
      log("_loadScheduleNodeBy error: $e");
      logger.e("_loadScheduleNodeBy", e, stackTrace);
      if (mounted) {
        setState(() => scheduleNodeList = []);
      }
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
    logger.i('[机统28车号][管理][BUILD_DISPLAY] trainNum=$trainNum ends=$ends result=$result');
    return result;
  }

  void _logTrainNumQueryPreview(List<Map<String, dynamic>> rows) {
    final total = rows.length;
    const head = 10;
    const tail = 5;
    final headCount = total < head ? total : head;
    final tailCount = total > head ? (total - head < tail ? total - head : tail) : 0;
    logger.i('[机统28车号查询][管理][RES_PREVIEW] total=$total head=$headCount tail=$tailCount');
    for (var i = 0; i < headCount; i++) {
      final item = rows[i];
      logger.i(
        '[机统28车号查询][管理][RES_ITEM] idx=$i '
        'trainNum=${_asText(item['trainNum'])} '
        'ends=${_asText(item['ends'])} '
        'displayTrainNum=${_asText(item['displayTrainNum'])} '
        'code=${_asText(item['code'])}',
      );
    }
    if (tailCount > 0) {
      logger.i('[机统28车号查询][管理][RES_ITEM] ...');
      for (var i = total - tailCount; i < total; i++) {
        final item = rows[i];
        logger.i(
          '[机统28车号查询][管理][RES_ITEM] idx=$i '
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
      logger.i('[机统28车号查询][管理][REQ] isLoadMore=$isLoadMore params=$queryParameters');
      
      if (!isLoadMore) {
        // 只在初次加载时显示loading
        SmartDialog.showLoading(msg: '加载车号中...');
      }
      
      // 获取车号
      var r = await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      final rows = r.toMapList();
      logger.i('[机统28车号查询][管理][RES] rows=${rows.length} pageNum=$pageNum');
      if (rows.isNotEmpty) {
        logger.i('[机统28车号查询][管理][RAW_FIRST_ITEM] ${jsonEncode(rows.first)}');
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
          logger.i('[机统28车号][管理][NEXT_DATA_SAMPLE] ${jsonEncode(next.take(3).toList())}');
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
        });
      }
      
    } catch (e, stackTrace) {
      if (!isLoadMore) {
        SmartDialog.dismiss();
      }
      logger.e('[机统28车号查询][管理] getTrainNumCodeList 发生异常: $e\n堆栈信息: $stackTrace');
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
        title: const Text("机统28-提报（管理）"),
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
                                title: "选择车号",
                                clickCallBack: (selectItem, selectArr) {
                                  logger.i('[机统28车号][管理][SELECTED_ITEM] ${jsonEncode(selectItem)}');
                                  setState(() {
                                    logger.i(selectArr);
                                    trainNumSelected["trainNum"] =
                                        selectItem["displayTrainNum"] ??
                                            selectItem["trainNum"];
                                    trainNumSelected["code"] =
                                        selectItem["code"];
                                    // 多 fallback 取修程编码，并记录命中了哪个 key，方便日志查
                                    String? pickProcCode;
                                    String hitKey = 'N/A';
                                    if (selectItem["repairProcCode"] !=
                                        null) {
                                      pickProcCode =
                                          selectItem["repairProcCode"].toString();
                                      hitKey = 'repairProcCode';
                                    } else if (selectItem["repair_procode"] !=
                                        null) {
                                      pickProcCode =
                                          selectItem["repair_procode"].toString();
                                      hitKey = 'repair_procode';
                                    } else if (selectItem["procCode"] != null) {
                                      pickProcCode =
                                          selectItem["procCode"].toString();
                                      hitKey = 'procCode';
                                    }
                                    repairProcCode = pickProcCode;
                                    logger.i(
                                        '[机统28车号][管理][REPAIR_PROC_CODE] '
                                        '车号=${trainNumSelected["trainNum"]}, '
                                        '命中字段=$hitKey, '
                                        'repairProcCode=${repairProcCode ?? 'NULL⚠️'}');
                                    // 选新车号时，所有节点数据要刷新
                                    repairMainNodeName = null;
                                    repairMainNodeCode = null;
                                    repairMainNodeList = [];
                                    scheduleNodeName = null;
                                    scheduleNodeCode = null;
                                    scheduleNodeList = [];
                                  });
                                  // 车号选完立刻根据修程拉这个修程下的所有工序主节点
                                  getRepairMainNodeAll();
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
                  ZjcFormInputCell(
                    title: "建议施修方案",
                    text: maintenanceNotice,
                    maxLines: 7,
                    maxLength: 300,
                    showRedStar: true,
                    inputCallBack: (value) {
                      maintenanceNotice = value;
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
                              setState(() {
                                if (!selected) return;
                                // 互斥：选中「自检自修」就把 completeStatus 强制 0，completeLabel 自检自修
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
                              setState(() {
                                if (!selected) return;
                                // 互斥：选中「工长派工」，把 completeStatus 强制 1，并清空自检自修模式下才填的 5 个字段，避免下次再切回时看到脏数据
                                completeStatus = 1;
                                completeLabel = '工长派工';
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "假设类别",
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
                            label: const Text('正常'),
                            selected: selectedAssumeType == '正常',
                            selectedColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool selected) {
                              setState(() {
                                selectedAssumeType =
                                    selected ? '正常' : selectedAssumeType;
                              });
                            },
                          ),
                          const SizedBox(width: 20),
                          ChoiceChip(
                            label: const Text('人工'),
                            selected: selectedAssumeType == '人工',
                            selectedColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool selected) {
                              setState(() {
                                selectedAssumeType =
                                    selected ? '人工' : selectedAssumeType;
                              });
                            },
                          ),
                          const SizedBox(width: 20),
                          ChoiceChip(
                            label: const Text('自然'),
                            selected: selectedAssumeType == '自然',
                            selectedColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool selected) {
                              setState(() {
                                selectedAssumeType =
                                    selected ? '自然' : selectedAssumeType;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

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
                              setState(() {
                                assestPics = assetEntityList;
                                faultPics = files;
                              });
                            } else {
                              setState(() {
                                faultPics = [];
                                assestPics = [];
                              });
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
        if (false) {
          showToast("内容未填写完");
        } else {
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
              
              "trainEntryCode": trainNumSelected["code"],
              "repairWorkResource": repairWorkResource["code"],
              "riskLevel": riskLevel,
              "requiredProcessingMethod": requiredProcessingMethod["code"],
              "completeStatus": completeStatus,
              "repairScheme": maintenanceNotice,
              "faultAssumption": selectedAssumeType, 
              "status": 0
            };
            if (completeStatus == 0) {
              queryParameters["repairPersonnel"] =
                  Global.profile.permissions?.user.userId;
            }
            if (faultPics.isNotEmpty) {
              await JtApi().uploadMixJt(imagedata: faultPics).then(
                    (value) async {
                      if (value['data'] != null && value['data'] != "") {
                        queryParameters["repairPicture"] = value['data'];
                        l.insert(0, queryParameters);
                        submit = await JtApi().uploadJt28(queryParametrs: l);
                        if (!_isSubmitSuccess(submit) && submit['data'] != null) {
                          showToast("${submit['data']}");
                          // SmartDialog.dismiss(status: SmartStatus.loading)
                        }
                      } else {
                        showToast("图片上传失败，请检查网络连接");
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
            showToast("故障提报失败");
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
          }
        }
      ,
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
