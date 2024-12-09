import 'dart:convert';
import 'package:jcjx_phone/index.dart';
import 'package:http/http.dart' as http;

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
      child: ListView(
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
                          mainNodeAndProcSelected["name"] = selectItem["name"];
                          List<Map<String, dynamic>> repairNodecList = [];
                          print(selectItem["repairMainNodeList"].toString());
                          selectItem["repairMainNodeList"]?.forEach((element) {
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
                    ZjcCascadeTreePicker.show(context,
                        data: trainNumList,
                        labelKey: 'trainNum',
                        valueKey: 'code',
                        childrenKey: 'children',
                        title: "选择检修地点",
                        clickCallBack: (selectItem, selectArr) {
                      setState(
                        () {
                          print(selectArr);
                          trainNumSelected["trainNum"] = selectItem["trainNum"];
                          trainNumSelected["code"] = selectItem["code"];
                          getWorkPackage();
                        },
                      );
                    });
                  }
                },
              ),
            ],
          ),
          // 作业包列表展示部分
          if (workPackageList.data != null && workPackageList.data!.isNotEmpty)
            Column(
                children: workPackageList.data!
                    .map((package) => Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          width: MediaQuery.of(context).size.width - 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value:
                                        selectedWorkPackages.contains(package),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value!) {
                                          selectedWorkPackages.add(package);
                                        } else {
                                          selectedWorkPackages.remove(package);
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      package.name ?? '',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // 先展示主修、辅修信息的行（此处假设主修、辅修信息暂时不展示，如有需要可根据实际情况添加）
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '开工时间：${package.startTime ?? ''}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                        ))
                    .toList())
          else
            const Center(
              child: Text("暂无作业包信息"),
            ),
                 if (selectedWorkPackages.isNotEmpty)
          ElevatedButton(
            onPressed: () => startWork(selectedWorkPackages),
            child: const Text('开工'),
          )
        else
          const SizedBox.shrink(),
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
  void getWorkPackage() async {
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
    ProductApi().startWork(startWorkList);
    setState(() {
      getWorkPackage();
    });
  }
}
