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
  List<dynamic> teamTree = [];
  // 班组人员
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
    getUserDeptree();
    getJtType();
    getJt28Dict();
    setState(() {
      trainNumSelected["trainNum"] = formatTrainNumWithEnds(
        widget.locoInfo?["trainNum"],
        extractEnds(widget.locoInfo),
      );
      trainNumSelected['code'] = widget.locoInfo?["trainNumCode"] ?? "";
      jcTypeListSelected['name'] = widget.locoInfo?["typeName"] ?? "";
      jcTypeListSelected['code'] = widget.locoInfo?["typeCode"] ?? "";
    });
    logger.i(widget.locoInfo);
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
                                  logger.i('[机统28车号][SELECTED_ITEM] ${jsonEncode(selectItem)}');
                                  setState(() {
                                    logger.i(selectArr);
                                    trainNumSelected["trainNum"] =
                                        selectItem["displayTrainNum"] ??
                                            selectItem["trainNum"];
                                    trainNumSelected["code"] =
                                        selectItem["code"];
                                  });
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
                              setState(() {
                                completeStatus = selected ? 0 : completeStatus;
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
                                completeStatus = selected ? 1 : completeStatus;
                                completeLabel = '工长派工';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 自动派活组
                  // if (completeStatus == 1) ...[
                  //   ZjcFormSelectCell(
                  //     title: "科室车间",
                  //     hintText: "请选择",
                  //     showRedStar: true,
                  //     text: workshop,
                  //     clickCallBack: () {
                  //       ZjcCascadeTreePicker.show(context,
                  //           isShowSearch: false,
                  //           data: deptTree,
                  //           labelKey: 'label',
                  //           valueKey: 'label',
                  //           childrenKey: 'child',
                  //           title: "选择科室车间",
                  //           clickCallBack: (selectItem, selectArr) {
                  //         setState(() {
                  //           workshop = selectItem["label"];
                  //           if (selectItem["children"] != null) {
                  //             teamTree = selectItem["children"];
                  //           }
                  //           team = "";
                  //         });
                  //       });
                  //     },
                  //   ),
                  //   ZjcFormSelectCell(
                  //     title: "班组",
                  //     hintText: "请选择",
                  //     showRedStar: true,
                  //     text: team,
                  //     clickCallBack: () {
                  //       if (teamTree.isEmpty) {
                  //         showToast("请先选择科室车间");
                  //       } else {
                  //         ZjcCascadeTreePicker.show(context,
                  //             isShowSearch: false,
                  //             data: teamTree,
                  //             labelKey: 'label',
                  //             valueKey: 'id',
                  //             title: "选择班组",
                  //             clickCallBack: (selectItem, selectArr) {
                  //           setState(() {
                  //             team = selectItem["label"];
                  //             teamCode = selectItem["id"];
                  //           });
                  //           // getJtUsers();
                  //         });
                  //       }
                  //     },
                  //   ),
                  // ZjcFormSelectCell(
                  //   title: "施修人员",
                  //   hintText: "请选择",
                  //   showRedStar: true,
                  //   text: userSelected["nickName"],
                  //   clickCallBack: () {
                  //     ZjcCascadeTreePicker.show(context,
                  //       isShowSearch: false,
                  //       data: userList,
                  //       labelKey: 'nickName',
                  //       valueKey: 'userId',
                  //       title: "施修人员",
                  //       clickCallBack: (selectItem, selectArr) {
                  //         setState(() {
                  //           userSelected['nickName'] = selectItem['nickName'];
                  //           userSelected['userId'] = selectItem['userId'];
                  //         });
                  //       }
                  //     );
                  //   },
                  // ),
                  // ],
                  // if(faultPics.isNotEmpty)
                  // Container(child: Image.file(faultPics[0],width: 200,height: 200,),),
                  // 图片传输
                  // ... existing code ...

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
            if (completeStatus == 1) {
              queryParameters["team"] = teamCode;
              // queryParameters["repairPersonnel"] = userSelected["userId"];
            } else {
              queryParameters["team"] = Global.profile.permissions?.user.deptId;
              queryParameters["repairPersonnel"] =
                  Global.profile.permissions?.user.userId;
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
