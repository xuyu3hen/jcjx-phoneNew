import 'package:jcjx_phone/index.dart';

class SearchWorkPackage extends StatefulWidget {
  Map<String, dynamic>? loco;
  SearchWorkPackage({super.key, this.loco});

  @override
  State<SearchWorkPackage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<SearchWorkPackage> {
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );
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
  late List<WorkPackage> selectedWorkPackages = [];
  //第二工位作业包
  late SecondPackage secondPackage = SecondPackage();

  bool isLoadingA = false;
  bool isLoadingB = false;

  @override
  void initState() {
    super.initState();
    // 创建带有Authorization头的请求
    // 主流程节点以及修程
    // getMainNodeANdProc();
    initData();
  }

  //初始化数据
  Future<void> initData() async {
    try {
      // 主流程节点以及修程
      var r = await ProductApi().getMainNodeANdProc1();
      mainNodeAndProcList = r.toMapList();
      mainNodeAndProcSelected = mainNodeAndProcList[0];
      logger.i(mainNodeAndProcList);
      logger.i(mainNodeAndProcSelected["repairMainNodeList"].toString());
      mainNodeAndProcSelected["repairMainNodeList"]?.forEach((element) {
        procList.add(element.toJson());
      });
      procSelected = procList[0];
      logger.i(procSelected);
      //构建查询车号参数
      Map<String, dynamic> queryParameters = {
        'repairMainNodeCode': procSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      //获取车号
      var r1 =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      trainNumList = r1.toMapList();
      logger.i(trainNumList);
      trainNumSelected = trainNumList[0];
      //构建查询作业包参数
      Map<String, dynamic> queryParameters1 = {
        'trainEntryCode': trainNumSelected["code"],
      };
      //获取作业包
      workPackageList = await ProductApi()
          .getPersonalWorkPackage(queryParametrs: queryParameters1);

      setState(() {});
    } catch (e, stackTrace) {
      logger.e('initData 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getMainNodeANdProc() async {
    try {
      var r = await ProductApi().getMainNodeANdProc1();
      setState(() {
        mainNodeAndProcList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getMainNodeANdProc 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getTrainNum() async {
    try {
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
    } catch (e, stackTrace) {
      logger.e('getTrainNum 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //获取个人作业包
  Future<WorkPackageList> getWorkPackage() async {
    try {
      //构建查询作业包参数
      Map<String, dynamic> queryParameters = {
        'trainEntryCode': trainNumSelected["code"],
      };
      //获取作业包
      workPackageList = await ProductApi()
          .getPersonalWorkPackage(queryParametrs: queryParameters);
      setState(() {});
      return workPackageList;
    } catch (e, stackTrace) {
      logger.e('getWorkPackage 方法中发生异常: $e\n堆栈信息: $stackTrace');
      return WorkPackageList(data: []);
    }
  }

  // 开工
  void startWork(List<WorkPackage> workPackageList) async {
    List<Map<String, dynamic>> startWorkList = [];
    for (var element in workPackageList) {
      startWorkList.add({
        "code": element.code,
        "startTime": DateTime.now().millisecondsSinceEpoch
      });
    }
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
      logger.i('获取作业包列表失败: $e');
    }
  }

  //获取第二作业包
  Future<SecondPackage> getSecondPackage(String code) {
    try {
      Map<String, dynamic> queryParameters = {
        'instructPackageCode': code,
      };
      return ProductApi().getSecondWorkPackage(queryParametrs: queryParameters);
    } catch (e, stackTrace) {
      logger.e('getSecondPackage 方法中发生异常: $e\n堆栈信息: $stackTrace');
      return Future.value(SecondPackage());
    }
  }

  //置为A端或B端作业包
  Future<void> setEnds(List<WorkPackage> workPackageList) async {
    try {
      await ProductApi().updateTaskInstructPackage(workPackageList);
    } catch (e, stackTrace) {
      logger.e('setAEnds 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
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
                bottom: MediaQuery.of(context).size.height * 0.1 + 20),
            shrinkWrap: true,
            children: [
              // 选择器部分
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
                            logger.i(selectArr);
                            setState(() {
                              mainNodeAndProcSelected["name"] =
                                  selectItem["name"];
                              List<Map<String, dynamic>> repairNodecList = [];
                              logger.i(
                                  selectItem["repairMainNodeList"].toString());
                              selectItem["repairMainNodeList"]
                                  ?.forEach((element) {
                                repairNodecList.add(element.toJson());
                              });
                              procList = repairNodecList;
                              logger.i(procList.toString());
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
                              logger.i(selectArr);
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
                              logger.i(selectArr);
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
              // 作业包列表展示部分
              Column(
                children: workPackageList.data != null &&
                        workPackageList.data!.isNotEmpty
                    ? workPackageList.data!
                        .map((package) => GestureDetector(
                              onTap: () async {
                                SecondPackage secondPackage =
                                    await getSecondPackage(package.code ?? '');

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
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                width: MediaQuery.of(context).size.width - 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
          // 使用Positioned将开工按钮悬浮在屏幕底部，且与底部无缝衔接
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: selectedWorkPackages.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: isLoadingA
                            ? null // 如果正在加载，禁用按钮
                            : () async {
                                if (isLoadingA) return; // 如果正在加载，直接返回，防止重复点击
                                setState(() {
                                  isLoadingA = true; // 设置加载状态为 true
                                });

                                try {
                                  List<WorkPackage> workPackageListAEnds = [];
                                  for (WorkPackage package
                                      in selectedWorkPackages) {
                                    package.ends = 'A';
                                    workPackageListAEnds.add(package);
                                  }
                                  await setEnds(workPackageListAEnds); // 等待操作完成
                                  await getWorkPackage();
                                  setState(() {
                                    isLoadingA = false; // 无论成功或失败，都重置加载状态
                                  });
                                } catch (e, stackTrace) {
                                  logger
                                      .e('Error: $e\nStackTrace: $stackTrace');
                                  setState(() {
                                    isLoadingA = false; // 确保在异常情况下也重置加载状态
                                  });
                                }
                              },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(Size(
                              MediaQuery.of(context).size.width / 3 - 10,
                              MediaQuery.of(context).size.height * 0.1)),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10)),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey; // 禁用时为灰色
                              }
                              return Theme.of(context).primaryColor; // 默认颜色
                            },
                          ),
                        ),
                        child: isLoadingA
                            ? const CircularProgressIndicator() // 显示加载指示器
                            : const Text('置为A端作业包',
                                style: TextStyle(fontSize: 18)),
                      ),
                      ElevatedButton(
                        onPressed: isLoadingB
                            ? null // 如果正在加载，禁用按钮
                            : () async {
                                if (isLoadingB) return; // 如果正在加载，直接返回，防止重复点击
                                setState(() {
                                  isLoadingB = true; // 设置加载状态为 true
                                });

                                try {
                                  List<WorkPackage> workPackageListBEnds = [];
                                  for (WorkPackage package
                                      in selectedWorkPackages) {
                                    package.ends = 'B';
                                    workPackageListBEnds.add(package);
                                  }
                                  await setEnds(workPackageListBEnds); // 等待操作完成
                                  await getWorkPackage();
                                  setState(() {
                                    isLoadingB = false; // 无论成功或失败，都重置加载状态
                                  });
                                } catch (e, stackTrace) {
                                  logger
                                      .e('Error: $e\nStackTrace: $stackTrace');
                                  setState(() {
                                    isLoadingB = false; // 确保在异常情况下也重置加载状态
                                  });
                                }
                              },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(Size(
                              MediaQuery.of(context).size.width / 3 - 10,
                              MediaQuery.of(context).size.height * 0.1)),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10)),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey; // 禁用时为灰色
                              }
                              return Theme.of(context).primaryColor; // 默认颜色
                            },
                          ),
                        ),
                        child: isLoadingB
                            ? const CircularProgressIndicator() // 显示加载指示器
                            : const Text('置为B端作业包',
                                style: TextStyle(fontSize: 18)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          startWork(selectedWorkPackages);
                          await getWorkPackage();
                        },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(Size(
                              MediaQuery.of(context).size.width / 3 - 10,
                              MediaQuery.of(context).size.height * 0.1)),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10)),
                          backgroundColor: MaterialStateProperty.all(
                              Colors.lightGreen), // 设置为浅绿色
                        ),
                        child: const Text('开工', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
