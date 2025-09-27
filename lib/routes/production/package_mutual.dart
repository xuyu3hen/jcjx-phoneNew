import 'dart:math';

import 'package:jcjx_phone/routes/production/mutual_startwork.dart';
import 'package:jcjx_phone/routes/production/package_mutual_deal.dart';

import '../../index.dart';
import 'jt_startwork.dart';

//范围作业互检
class MutualPackageList extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  const MutualPackageList(
      {Key? key,
      required this.trainNum,
      required this.trainNumCode,
      required this.typeName,
      required this.typeCode,
      required this.trainEntryCode})
      : super(key: key);
  @override
  State<MutualPackageList> createState() => _JtShowPageState();
}

class _JtShowPageState extends State<MutualPackageList> {
  late Map<String, dynamic> info = {};

  var logger = AppLogger.logger;
  // 动态类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动态类型信息
  late Map<dynamic, dynamic> dynamciTypeSelected = {};
  //机型列表
  late List<Map<String, dynamic>> jcTypeList = [];
  // 筛选的机型列表
  late Map<String, dynamic> jcTypeListSelected = {};
  // 车号列表
  late List<Map<String, dynamic>> trainNumCodeList = [];
  // 筛选的车号信息
  late Map<dynamic, dynamic> trainNumSelected = {};
  // 机统28信息
  late List<dynamic> sys28List = [];

  // 零件信息
  late Map<String, dynamic> faultPart = {};

  Permissions? permissions;

  late TextEditingController repairDetailsController = TextEditingController();

  late TextEditingController actualStartDateController =
      TextEditingController();

  late TextEditingController faultyPartController = TextEditingController();

  late TextEditingController mutualInspectorController =
      TextEditingController();

  late TextEditingController qualityInspectorController =
      TextEditingController();

  List<dynamic> faultPartList = [];

  List<Map<String, dynamic>> faultPartListInfo = [];

  // 当前选中的节点
  Map<String, dynamic>? selectedNode;

  //
  late Map<String, dynamic> faultInfo;

  // 添加分页相关变量
  int pageNum = 1;
  int pageSize = 10;
  int total = 0;
  bool isLoading = false;

  //获取机统28信息
  void getInfo() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> queryParameters = {
      'pageNum': pageNum,
      'pageSize': pageSize,
      'completeStatus': 2,
      'trainEntryCode': widget.trainEntryCode,
      'mutualName': Global.profile.permissions?.user.nickName,
      // 'status': 0
    };
    logger.i(widget.trainNumCode);
    logger.i(widget.trainNum);
    logger.i(widget.typeName);
    logger.i(widget.typeCode);

    try {
      var r =
          await ProductApi().selectRepairSys28(queryParametrs: queryParameters);
      setState(() {
        info = r;
        sys28List = info['rows'];
        total = info['total'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      logger.e('获取机统28信息失败: $e');
      setState(() {
        isLoading = false;
      });
      // 显示错误信息
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("获取数据失败")),
        );
      });
    }
  }

  @override
  void initState() {
    //初始化动力类型
    getDynamicType();

    // ✅ 初始化施修情况控制器
    repairDetailsController = TextEditingController();

    // 初始化分页相关变量
    pageNum = 1;
    pageSize = 10;
    total = 0;
    isLoading = false;

    // 初始化时加载第一页数据
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   getInfo();
    // });
    // getFaultPart();
    getMutualRepairInfo();
    super.initState();
  }

  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      setState(() {
        dynamicTypeList = r.toMapList();
        permissions = permissionResponse;
        dynamciTypeSelected["code"] = dynamicTypeList[0]["code"];
        dynamciTypeSelected["name"] = dynamicTypeList[0]["name"];
        getJcType();
        logger.i(permissions);
      });
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getJcType() async {
    try {
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamciTypeSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getJcType(queryParametrs: queryParameters);
      logger.i(r.toJson());
      setState(() {
        jcTypeList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getJcType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // Future<void> getFaultPart() async {
  //   try {
  //     Map<String, dynamic> queryParameters = {
  //       'typeCode': jcTypeListSelected["code"],
  //       'pageNum': 0,
  //       'pageSize': 0,
  //       'name': faultyPartController.text,
  //     };
  //     logger.i(queryParameters);
  //     var r = await ProductApi().getFaultPart(queryParameters);
  //     if (mounted) {
  //       setState(() {
  //         //将List<dynamic>转换为List<Map<String, dynamic>>
  //         faultPartListInfo = (r['rows'] as List)
  //             .map((item) => item as Map<String, dynamic>)
  //             .toList();
  //       });
  //     }
  //   } catch (e, stackTrace) {
  //     logger.e('getFaultPart 方法中发生异常: $e\n堆栈信息: $stackTrace');
  //   }
  // }

  void getTrainNumCodeList() async {
    try {
      //构建查询车号参数
      Map<String, dynamic> queryParameters = {
        'typeName': jcTypeListSelected["name"],
        'pageNum': 0,
        'pageSize': 0
      };
      //获取车号
      var r =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      if (mounted) {
        setState(() {
          trainNumCodeList = r.toMapList();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getTrainNumCodeList 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //获取互检专检人员信息
  void getUserList() async {
    try {
      Map<String, dynamic> queryParameters = {
        'configNodeCode': jcTypeListSelected["code"],
        'riskLevel': faultInfo["riskLevel"],
        'team': 100
      };
      logger.i(queryParameters);
      var r = await ProductApi().getCheckPerson(queryParameters);
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('getTrainInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //机车构型信息
  List<Map<String, dynamic>> faultPartListInfo1 = [];

  //故障信息
  Future<void> getFaultPart() async {
    logger.i(Global.typeInfo);
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': widget.typeCode,
        'pageNum': 0,
        'pageSize': 1,
        // 'name': faultyPartController.text,
      };

      var r = await ProductApi().getFaultPart(queryParameters);
      if (mounted) {
        setState(() {
          //将List<dynamic>转换为List<Map<String, dynamic>>
          Global.faultPartList = (r as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          logger.i(Global.faultPartList.length);
        });
      }
    } catch (e, stackTrace) {
      logger.e('getFaultPart 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

    List<Map<String, dynamic>> mutualRepairList= [];

  Future<void> getMutualRepairInfo() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> queryParameters = {
      'userId': Global.profile.permissions?.user.userId,
      'trainEntryCode': widget.trainEntryCode,
      'completeStatus': statusFilterSelected['value']
    };
    
    try {
      var r = await ProductApi().getNeedToMutualInspectionCertainPackageList(
        queryParameters
      );
      
      if(r is List) {
        setState(() {
          // 先保存所有数据
          List<Map<String, dynamic>> allData = r.cast<Map<String, dynamic>>();

          total = allData.length;
          
          // 根据当前页码和页面大小截取需要显示的数据
          int start = (pageNum - 1) * pageSize;
          int end = start + pageSize;
          if (end > allData.length) {
            end = allData.length;
          }
          
          if (pageNum == 1) {
            // 第一页替换数据
            mutualRepairList = allData.sublist(0, end);
          } else {
            // 其他页追加数据
            mutualRepairList.addAll(allData.sublist(start, end));
          }
          
          isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e('获取互检信息失败: $e\n堆栈信息: $s');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("获取数据失败")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("范围作业互检作业"),
      ),
      body: _buildBody(),
    );
  }

    // 添加状态筛选相关变量
  late List<Map<String, dynamic>> statusFilterList = [
    {"name": "待互检", "value": 1},
    {"name": "已开工", "value": 6},
  ];
  late Map<String, dynamic> statusFilterSelected = {"name": "待互检", "value": 1};

  Widget _buildBody() {
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
              //     if (dynamicTypeList.isEmpty) {
              //       showToast("无动力类型选择");
              //     } else {
              //       ZjcCascadeTreePicker.show(
              //         context,
              //         data: dynamicTypeList,
              //         labelKey: 'name',
              //         valueKey: 'code',
              //         childrenKey: 'children',
              //         title: "选择动力类型",
              //         clickCallBack: (selectItem, selectArr) {
              //           logger.i(selectArr);
              //           setState(() {
              //             dynamciTypeSelected["code"] = selectItem["code"];
              //             dynamciTypeSelected["name"] = selectItem["name"];
              //             getJcType();
              //           });
              //         },
              //       );
              //     }
              //   },
              // ),
              Row(
                children: [
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "机型",
                      text: widget.typeName,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "车号",
                      text: widget.trainNum,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                ],
              ),
                            Row(
                children: [
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "状态",
                      text: statusFilterSelected["name"],
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: () {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: statusFilterList,
                          labelKey: 'name',
                          valueKey: 'value',
                          title: "选择状态",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              statusFilterSelected =  Map<String, dynamic>.from(selectItem as Map);
                              // 重置分页并重新加载数据
                              pageNum = 1;
                              getMutualRepairInfo();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              //筛选条件
              // 添加分页信息显示和控制
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('共 $total 条记录'),
                      Text('第 $pageNum / ${((total - 1) ~/ pageSize) + 1} 页'),
                    ],
                  ),
                ),
              //展示列表信息
              if (isLoading && mutualRepairList.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (mutualRepairList.isNotEmpty)
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mutualRepairList.length ,
                      itemBuilder: (context, index) {
                        if (index == mutualRepairList.length) {
                          // 显示加载指示器
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        Map<String, dynamic> item = mutualRepairList[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue), // 添加蓝色边框
                            borderRadius: BorderRadius.circular(8.0), // 可选：添加圆角
                          ),
                          margin: const EdgeInsets.all(8.0), // 可选：为每个列表项添加外边距
                          padding: const EdgeInsets.all(8.0), // 可选：为内容添加内边距
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                "名称: ${item['name']}"),
                                          ),
                                          // Expanded(
                                          //   child: Text(
                                          //       "施修方案: ${item['repairScheme']}"),
                                          // ),
                                        ],
                                      ),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: ElevatedButton(
                                      //         onPressed: () async {
                                      //           // 使用新的可复用组件展示图片
                                      //           PhotoPreviewDialog.show(
                                      //               context,
                                      //               item['repairPicture'],
                                      //               ProductApi()
                                      //                   .getFaultVideoAndImage);
                                      //         },
                                      //         style: ElevatedButton.styleFrom(
                                      //           backgroundColor: Colors.green,
                                      //         ),
                                      //         child: const Text("查看故障视频及图片"),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: Text(
                                      //           "提报人: ${item['reporterName']}"),
                                      //     ),
                                      //     Expanded(
                                      //       child: Text(
                                      //           "提报时间: ${item['reportDate']}"),
                                      //     ),
                                      //     Expanded(
                                      //       child: Text(
                                      //           "流水号: ${item['deptName']}"),
                                      //     ),
                                      //   ],
                                      // ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                "主修: ${item['executorName']}"),
                                          ),
                                          // Expanded(
                                          //   child: Text(
                                          //       "辅修: ${item['assistantName']}"),
                                          // ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                "专检: ${item['specialInspectionPersonnelName']}"),
                                          ),
                                          Expanded(
                                            child: Text(
                                                "互检: ${item['mutualInspectionPersonnelName']}"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                height: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // 跳转到FaultDisposalPage()
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MutualDisposalPackagePage(
                                                faultDescription:
                                                    item['faultDescription'] ??
                                                        "",
                                                typeName: widget.typeName,
                                                trainEntryCode:
                                                    widget.trainEntryCode,
                                                trainNum: widget.trainNum,
                                                repairScheme:
                                                    item['repairScheme'] ?? "",
                                                trainNumCode:
                                                    widget.trainNumCode,
                                                typeCode: widget.typeCode,
                                                code: item['code'],
                                                trainInfo: item,
                                                repairPictures: item['taskCertainContentFileList']??[] ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  child: const Text(
                                    "互检",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // 加载更多按钮
                    if (mutualRepairList.length < total)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                            setState(() {
                              pageNum++;
                            });
                            getMutualRepairInfo();
                          },
                          child: isLoading
                              ? const Text("正在加载...")
                              : const Text("加载更多"),
                        ),
                      ),
                  ],
                )
              else if (!isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '暂无数据',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}





