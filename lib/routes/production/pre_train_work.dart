import '../../index.dart';

class PreTrainWork extends StatefulWidget {
  const PreTrainWork({super.key});

  @override
  State<PreTrainWork> createState() => _DataDisplayPageState();
}

// ... existing code ...
class _DataDisplayPageState extends State<PreTrainWork> {
  //科室车间列表
  late List<Map<String, dynamic>> deptList = [];
  // 筛选科室车间
  late Map<String, dynamic> deptSelected = {
    "deptName": "总成车间",
    "deptId": 231,
  };

  final TextEditingController _trainNumController = TextEditingController();
  // 创建 Logger 实例
  var logger = AppLogger.logger;

  @override
  void dispose() {
    _trainNumController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getDept(); // 获取科室车间信息
    getTrainInfo(); // 在初始化时调用 getTrainInfo 方法
  }

  // 获取科室车间
  void getDept() async {
    try {
      Map<String, dynamic> queryParameters = {
        'parentIdList': "231,232,233,234,235,236,237,230",
      };
      var r = await ProductApi()
          .getDeptTreeByParentIdList(queryParametrs: queryParameters);
      if (mounted) {
        setState(() {
          //将 List<dynamic> 转为 List<Map<String, dynamic>>
          if (r != null) {
            if (r is List) {
              deptList = r.map((item) => item as Map<String, dynamic>).toList();
            } else if (r is Map<String, dynamic>) {
              deptList = [r];
            } else {
              deptList = [];
            }
          } else {
            deptList = [];
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('getDept 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机车预派工'),
      ),
      body: Column(
        children: [
          // 科室车间筛选
          ZjcFormSelectCell(
            title: "科室车间",
            text: deptSelected["deptName"] ?? '',
            hintText: "请选择科室车间",
            showRedStar: false,
            clickCallBack: () {
              if (deptList.isEmpty) {
                showToast("无科室车间信息");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: deptList,
                  labelKey: 'deptName',
                  valueKey: 'deptId',
                  childrenKey: 'children1',
                  title: "选择科室车间",
                  clickCallBack: (selectItem, selectArr) {
                    if (mounted) {
                      setState(() {
                        logger.i(selectArr);
                        deptSelected["deptName"] = selectItem["deptName"];
                        deptSelected["deptId"] = selectItem["deptId"];
                      });
                    }
                  },
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trainNumController,
                    decoration: InputDecoration(
                      hintText: '请输入车号',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: searchTrainInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          // 列车列表
          Expanded(
            child: trainNotEnter.isEmpty
                ? const Center(
                    child: CircularProgressIndicator()) // 如果数据为空，显示加载指示器
                : ListView.builder(
                    itemCount: trainNotEnter.length,
                    itemBuilder: (context, index) {
                      var train = trainNotEnter[index];
                      return InkWell(
                        onTap: () {
                          // 点击时跳转到MotorStoragePage，并传递电机的存储内容
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamInfo(
                                  planCode: train['code'],
                                  deptId: deptSelected["deptId"]),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '机型: ${train['trainType'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '车号: ${train['trainNum'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '预计上台日期: ${train['arrivePlatformTime'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              //修程
                              Text(
                                '修程: ${train['repairProc'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              //修次
                              Text(
                                '修次: ${train['repairTimes'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<dynamic> trainNotEnter = [];

  void getTrainInfo() async {
    var r = await ProductApi().getNotEnterTrainPlan();
    if (mounted) {
      setState(() {
        trainNotEnter = r; // 假设 r 是包含机型车号信息的列表
      });
    }
  }

  //searchTrainInfo
  void searchTrainInfo() async {
     final trainNum = _trainNumController.text.trim();
     logger.d("trainNum: $trainNum");
    if (trainNum.isEmpty) {
      showToast("请输入车号");
      return;
    }

    try {
      Map<String, dynamic> queryParameters = {
        'trainNum': trainNum,
      };
      
      var r = await ProductApi().getNotEnterTrainPlan(queryParameters: queryParameters);
      
      if (mounted) {
        setState(() {
          if (r != null && r is List && r.isNotEmpty) {
            trainNotEnter = r;
          } else {
            trainNotEnter = [];
            showToast("未找到匹配的列车");
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('搜索列车时发生异常: $e\n堆栈信息: $stackTrace');
      showToast("搜索失败，请稍后重试");
    }
  }
}

// 班组信息展示
class TeamInfo extends StatefulWidget {
  final String planCode;
  final int deptId;
  const TeamInfo({super.key, required this.planCode, required this.deptId});
  @override
  State createState() => _TeamInfoState();
}

class _TeamInfoState extends State<TeamInfo> {
  var logger = AppLogger.logger;
  List<dynamic> teamList = [];
  @override
  void initState() {
    super.initState();
    getTeamInfo(); // 在初始化时调用 getTeamInfo 方法
  }

  void getTeamInfo() async {
    try {
      Map<String, dynamic> queryParameters = {
        'deptId': widget.deptId,
        'planCode': widget.planCode
      };
      var r = await ProductApi().getTeamInfo(queryParameters);
      if (mounted) {
        setState(() {
          teamList = r; // 假设 r 是包含班组信息的列表
        });
      }
    } catch (e, stackTrace) {
      logger.e('getWorkPackage 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void save() async {
    try {
      List<Map<String, dynamic>> associatedList = [];
      //遍历teamList
      for (var team in teamList) {
        if (team['associated'] == true) {
          // 调用接口
          Map<String, dynamic> queryParameters = {
            'repairPlanCode': widget.planCode,
            'deptId': team['deptId'],
            'teamName': team['deptName'],
            'teamId': team['deptId']
          };
          associatedList.add(queryParameters);
        }
      }
      if (mounted) {
        ProductApi().saveTeam(associatedList);
        //展示机车预派工成功 showToast
        showToast('机车预派工成功');
        //跳回界面
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      logger.e('save 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  void dispose() {
    // 取消所有正在进行的异步操作
    // 例如，如果有定时器，在这里取消
    // timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('班组信息'),
      ),
      body: teamList.isEmpty
          ? const Center(child: Text('暂无班组信息')) // 如果数据为空，显示提示文本而不是加载指示器
          : ListView.builder(
              itemCount: teamList.length,
              itemBuilder: (context, index) {
                var team = teamList[index];
                return ListTile(
                  leading: Checkbox(
                    value:
                        team['associated'] ?? false, // 假设 associated 字段表示是否已关联
                    onChanged: (value) {
                      setState(() {
                        team['associated'] = value; // 更新 associated 字段
                      });
                    },
                  ),
                  title:
                      Text(' ${team['deptName']}'), // 假设班组名称信息在 'deptName' 字段中
                  subtitle: team['associated'] == true
                      ? const Text('承修班组')
                      : null, // 显示承修班组字段
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: save, // 调用 save 方法
        child: const Text('保存'), // 按钮内容
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 按钮位置
    );
  }
}
