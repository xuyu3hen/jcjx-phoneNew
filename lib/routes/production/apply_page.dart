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

  @override
  void initState() {
    getTrainShunting();
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
                            Text('状态: ${item['status'] ?? ''}'),
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
                TextField(
                  controller: trainTypeController,
                  decoration: const InputDecoration(
                    labelText: '机型',
                  ),
                ),
                TextField(
                  controller: trainNumController,
                  decoration: const InputDecoration(
                    labelText: '车号',
                  ),
                ),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: '端',
                  ),
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
                _submitLocomotiveCommand(
                  sortController.text,
                  trainTypeController.text,
                  trainNumController.text,
                  endController.text,
                  startPositionController.text,
                  endPositionController.text,
                  remarkController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 提交机车调令
  void _submitLocomotiveCommand(
    String sort,
    String trainType,
    String trainNum,
    String end,
    String startPosition,
    String endPosition,
    String remark,
  ) {
    // 在这里处理提交逻辑
    // 可以调用API保存数据
    SmartDialog.showToast('已提交：$trainNum');
    
    // 如果需要刷新列表，可以在这里调用getTrainShunting()
    // getTrainShunting();
  }
// ... existing code ...
