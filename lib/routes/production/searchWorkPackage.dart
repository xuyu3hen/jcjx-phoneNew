import 'dart:convert';
import 'package:jcjx_phone/index.dart';
import 'package:http/http.dart' as http;

import '../../models/searchWorkPackage/secondPackage.dart';

class SearchWorkPackage extends StatefulWidget {
  const SearchWorkPackage({super.key});

  @override
  State<SearchWorkPackage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<SearchWorkPackage> {
  // 主流程节点以及修程
  late List<Map<String, dynamic>> mainNodeAndProcList = [];
  // 主流程节点以及修程选择
  late Map<dynamic, dynamic> mainNodeAndProcSelected = {};

  // 工序节点
  late List<Map<String, dynamic>> procList = [];
  // 工序节点选择
  late Map<dynamic, dynamic> procSelected = {};

  // 车号
  late List<Map<String, dynamic>> trainNumList = [];
  // 车号选择
  late Map<dynamic, dynamic> trainNumSelected = {};
  // 作业包
  late WorkPackageList workPackageList = WorkPackageList(
    data: [],
  );
  // 作业包选择
  List<WorkPackage> selectedWorkPackages = [];

  //第二工位作业包
  late SecondPackage secondPackage = SecondPackage();

  @override
  void initState() {
    super.initState();
    // 创建带有Authorization头的请求

    // 主流程节点以及修程
    getMainNodeANdProc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('查看作业包'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.1 +
                    20), // 为开工按钮预留空间，根据按钮高度（屏幕高度10%）加上按钮距底部距离（20像素）设置
            children: <Widget>[
              // 选择器部分
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ZjcFormSelectCell(
                    title: "修程",
                    text: mainNodeAndProcSelected["name"] ?? "",
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (mainNodeAndProcList.isEmpty) {
                        showToast("无修程选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: mainNodeAndProcList,
                          labelKey: 'name',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择动力类型",
                          clickCallBack: (selectItem, selectArr) {
                            print(selectArr);
                            setState(() {
                              mainNodeAndProcSelected["name"] =
                                  selectItem["name"];
                              List<Map<String, dynamic>> repairNodecList = [];
                              print(
                                  selectItem["repairMainNodeList"].toString());
                              selectItem["repairMainNodeList"]
                                  ?.forEach((element) {
                                repairNodecList.add(element.toJson());
                              });
                              procList = repairNodecList;
                              print(procList.toString());
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "工序节点",
                    text: procSelected["name"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (procList.isEmpty) {
                        showToast("无工序节点可以选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: procList,
                          labelKey: 'name',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择机型",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              print(selectArr);
                              procSelected["name"] = selectItem["name"];
                              procSelected["repairMainNodeCode"] =
                                  selectItem["code"];
                              getTrainNum();
                            });
                          },
                        );
                      }
                    },
                  ),
                  ZjcFormSelectCell(
                    title: "车号",
                    text: trainNumSelected["trainNum"],
                    hintText: "请选择",
                    showRedStar: true,
                    clickCallBack: () {
                      if (trainNumList.isEmpty) {
                        showToast("无车号可以选择");
                      } else {
                        ZjcCascadeTreePicker.show(
                          context,
                          data: trainNumList,
                          labelKey: 'trainNum',
                          valueKey: 'code',
                          childrenKey: 'children',
                          title: "选择检修地点",
                          clickCallBack: (selectItem, selectArr) {
                            setState(() {
                              print(selectArr);
                              trainNumSelected["trainNum"] =
                                  selectItem["trainNum"];
                              trainNumSelected["code"] = selectItem["code"];
                              getWorkPackage();
                            });
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              // 作业包列表展示部分，使用Expanded让其占据更多空间，便于增大触摸选中区域，同时调整触摸区域相关属性
              Expanded(
                child: Column(
                  children: workPackageList.data != null &&
                          workPackageList.data!.isNotEmpty
                      ? workPackageList.data!
                          .map((package) => GestureDetector(
                                onTap: () async {
                                  SecondPackage secondPackage =
                                      await getSecondPackage(
                                          package.code ?? '');
                              
                                  // ignore: use_build_context_synchronously
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TaskPackageDetailsPage(
                                              package: package,
                                              secondPackage: secondPackage),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  width: MediaQuery.of(context).size.width - 40,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: Checkbox(
                                              value: selectedWorkPackages
                                                  .contains(package),
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value!) {
                                                    selectedWorkPackages
                                                        .add(package);
                                                  } else {
                                                    selectedWorkPackages
                                                        .remove(package);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              package.name ?? '',
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // 先展示主修、辅修信息的行（此处假设主修、辅修信息暂时不展示，如有需要可根据实际情况添加）
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '开工时间：${package.startTime ?? ''}',
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '工位：${package.station ?? ''}',
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'A/B端：${package.ends ?? ''}',
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList()
                      : [const Center(child: Text("暂无作业包信息"))],
                ),
              ),
            ],
          ),
          // 使用Positioned将开工按钮悬浮在屏幕底部，且与底部无缝衔接
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: selectedWorkPackages.isNotEmpty
                ? Center(
                    child: ElevatedButton(
                      onPressed: () => startWork(selectedWorkPackages),
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height * 0.1)),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(horizontal: 0, vertical: 10)),
                      ),
                      child: const Text('开工', style: TextStyle(fontSize: 18)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void getMainNodeANdProc() async {
    var r = await ProductApi().getMainNodeANdProc1();
    setState(() {
      mainNodeAndProcList = r.toMapList();
    });
  }

  void getTrainNum() async {
    //构建查询车号参数
    Map<String, dynamic> queryParameters = {
      'repairMainNodeCode': procSelected["repairMainNodeCode"],
      'pageNum': 0,
      'pageSize': 0
    };
    //获取车号
    var r =
        await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
    setState(() {
      trainNumList = r.toMapList();
    });
  }

  //获取个人作业包
  Future<WorkPackageList> getWorkPackage() async {
    //构建查询作业包参数
    Map<String, dynamic> queryParameters = {
      'trainEntryCode': trainNumSelected["code"],
    };
    //获取作业包
    var r = await ProductApi()
        .getPersonalWorkPackage(queryParametrs: queryParameters);
    setState(() {
      workPackageList = r;
      print(workPackageList.toJson());
    });
    return r;
  }

  // 开工
  void startWork(List<WorkPackage> workPackageList) async {
    List<Map<String, dynamic>> startWorkList = [];
    workPackageList.forEach((element) {
      startWorkList.add({
        "code": element.code,
        "startTime": DateTime.now().millisecondsSinceEpoch
      });
    });
    // 等待开工操作完成
    ProductApi().startWork(startWorkList);
    try {
      // 获取最新作业包列表数据
      var updatedWorkPackageList = await getWorkPackage();
      setState(() {
        this.workPackageList = updatedWorkPackageList;
      });
    } catch (e) {
      // 处理获取作业包列表出现错误的情况，比如打印错误信息等
      print('获取作业包列表失败: $e');
    }
  }

  //获取第二作业包
  Future<SecondPackage> getSecondPackage(String code) {
    Map<String, dynamic> queryParameters = {
      'instructPackageCode': code,
    };
    return ProductApi().getSecondWorkPackage(queryParametrs: queryParameters);
  }
}
