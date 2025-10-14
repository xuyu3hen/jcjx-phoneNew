import 'dart:math';

import 'package:jcjx_phone/routes/production/mutual_startwork.dart';
import 'package:jcjx_phone/routes/production/package_mutual_deal.dart';

import '../../index.dart';
import 'jt_startwork.dart';

//范围作业互检
class ApplyList extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  const ApplyList(
      {Key? key,
      required this.trainNum,
      required this.trainNumCode,
      required this.typeName,
      required this.typeCode,
      required this.trainEntryCode})
      : super(key: key);
  @override
  State<ApplyList> createState() => _JtShowPageState();
}

class _JtShowPageState extends State<ApplyList> {
  List<Map<String, dynamic>> applyList = [];
  List<Map<String, dynamic>> stopLocationList = [];

  @override
  void initState() {
    getTrainShunting();
    getDynamicType();
    getStopLocation();
    super.initState();
  }

  void getTrainShunting() async {
    Map<String, dynamic> queryParameters = {
      "typeCode": widget.typeCode,
      "trainEntryCode": widget.trainEntryCode,
    };
    var r =
        await ProductApi().getTrainShunting(queryParametrs: queryParameters);
    setState(() {
      applyList =
          (r as List).map((item) => item as Map<String, dynamic>).toList();
    });
  }

    // 获取检修地点
  void getStopLocation() async {
    try {
      var r = await ProductApi().getstopLocation({
        'pageNum': 0,
        'pageSize': 0,
      });
      List<Map<String, dynamic>> processedStopLocations = [];
      if (r.rows != null && r.rows!.isNotEmpty) {
        for (var item in r.rows!) {
          if (item.areaName != null &&
              item.deptName != null &&
              item.trackNum != null) {
            processedStopLocations.add({
              'code': item.code,
              'deptName': item.deptName,
              'realLocation':
                  '${item.deptName}-${item.trackNum}-${item.areaName}',
              'areaName': item.areaName,
              'trackNum': item.trackNum,
            });
          }
        }
      }
      setState(() {
        stopLocationList = processedStopLocations;
        logger.i(stopLocationList);
      });
    } catch (e, stackTrace) {
      logger.e('initSelectInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("调车申请单"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  // 添加状态筛选相关变量
  late List<Map<String, dynamic>> statusFilterList = [
    {"name": "待互检", "value": 1},
    {"name": "已开工", "value": 6},
  ];

  
  // 添加状态筛选相关变量
  late List<Map<String, dynamic>> statusList = [
    {"name": 2, "value": '已完成'},
    {"name": 0, "value": '未发布 '},
  ];

  

  late Map<String, dynamic> statusFilterSelected = {"name": "待互检", "value": 1};

  

  String _getStatusText(dynamic statusCode) {
    if (statusCode == null) return '';
    
    for (var status in statusList) {
      if (status['name'].toString() == statusCode.toString()) {
        return status['value'].toString();
      }
    }
    
    // 如果没有匹配的状态，返回原值
    return statusCode.toString();
  }
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
                            Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showAddLocomotiveDialog(context);
                  },
                  child: const Text('添加机车调令'),
                ),
              ),
              Container(
                height: 400,
                padding: const EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: applyList.length,
                  itemBuilder: (context, index) {
                    final item = applyList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          '车号:' + item['trainNum'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('机型: ${item['typeName'] ?? ''}'),
                            Text('入段时间: ${item['entryTime'] ?? ''}'),
                           Text('状态: ${_getStatusText(item['status'] ?? '')}'),
                            Text('终点区域: ${item['endAreaName'] ?? ''}'),
                            Text('终点股道号 : ${item['endTrackNum'] ?? ''}'),
                          ],
                        ),
                        onTap: () {
                          // 可以在这里添加点击事件处理
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    
  }
  // 显示添加机车调令对话框
 // ... existing code ...
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

  var logger = AppLogger.logger;
  
  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      setState(() {
        dynamicTypeList = r.toMapList();
        // permissions = permissionResponse;
        // logger.i(permissions.toJson());
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
      setState(() {
        trainNumCodeList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getTrainNumCodeList 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 显示添加机车调令对话框
  void _showAddLocomotiveDialog(BuildContext context) {
    final TextEditingController sortController = TextEditingController();
    final TextEditingController trainTypeController = TextEditingController();
    final TextEditingController trainNumController = TextEditingController();
    final TextEditingController endController = TextEditingController();
    final TextEditingController startPositionController = TextEditingController();
    final TextEditingController endPositionController = TextEditingController();
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加机车调令'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sortController,
                  decoration: const InputDecoration(
                    labelText: '显示排序',
                  ),
                  keyboardType: TextInputType.number,
                ),
                // 机型车号展示
                ZjcFormSelectCell(
                  title: "动力类型",
                  text: dynamciTypeSelected["name"]?.toString() ?? "",
                  hintText: "请选择",
                  showRedStar: true,
                  clickCallBack: () {
                    if (dynamicTypeList.isEmpty) {
                      showToast("无动力类型选择");
                    } else {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: dynamicTypeList,
                        labelKey: 'name',
                        valueKey: 'code',
                        childrenKey: 'children',
                        title: "选择动力类型",
                        clickCallBack: (selectItem, selectArr) {
                          logger.i(selectArr);
                          setState(() {
                            dynamciTypeSelected["code"] = selectItem["code"];
                            dynamciTypeSelected["name"] = selectItem["name"];
                            getJcType();
                          });
                        },
                      );
                    }
                  },
                ),
                ZjcFormSelectCell(
                  title: "机型",
                  text: jcTypeListSelected["name"]?.toString() ?? "",
                  hintText: "请选择",
                  showRedStar: true,
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
                            jcTypeListSelected["name"] = selectItem["name"];
                            getTrainNumCodeList();
                          });
                        },
                      );
                    }
                  },
                ),
                ZjcFormSelectCell(
                  title: "车号",
                  text: trainNumSelected["trainNum"]?.toString() ?? "",
                  hintText: "请选择",
                  showRedStar: true,
                  clickCallBack: () {
                    if (trainNumCodeList.isEmpty) {
                      showToast("无车号可以选择");
                    } else {
                      ZjcCascadeTreePicker.show(
                        context,
                        data: trainNumCodeList,
                        labelKey: 'trainNum',
                        valueKey: 'code',
                        childrenKey: 'children',
                        title: "选择车号",
                        clickCallBack: (selectItem, selectArr) {
                          setState(() {
                            logger.i(selectArr);
                            trainNumSelected["trainNum"] = selectItem["trainNum"];
                            trainNumSelected["code"] = selectItem["code"];
                          });
                        },
                      );
                    }
                  },
                ),
                FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '端',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: endController.text.isEmpty ? null : endController.text,
                          isDense: true,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              endController.text = newValue;
                              state.didChange(newValue);
                            }
                          },
                          items: <String>['A', 'B']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                TextField(
                  controller: startPositionController,
                  decoration: const InputDecoration(
                    labelText: '起始位置',
                  ),
                ),
                TextField(
                  controller: endPositionController,
                  decoration: const InputDecoration(
                    labelText: '终点位置',
                  ),
                ),
                TextField(
                  controller: remarkController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 这里处理提交逻辑
                // _submitLocomotiveCommand(
                //   sortController.text,
                //   trainTypeController.text,
                //   trainNumController.text,
                //   endController.text,
                //   startPositionController.text,
                //   endPositionController.text,
                //   remarkController.text,
                // );
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

