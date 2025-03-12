import '../../index.dart';

class PreTrainWork extends StatefulWidget {
  const PreTrainWork({super.key});

  @override
  State<PreTrainWork> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<PreTrainWork> {
  @override
  void initState() {
    super.initState();
    getTrainInfo(); // 在初始化时调用 getTrainInfo 方法
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机车预派工'),
      ),
      body: trainNotEnter.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 如果数据为空，显示加载指示器
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
                        builder: (context) => TeamInfo(planCode: train['code']),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0), // 上下间隔
                    padding: const EdgeInsets.all(16.0), // 增加内边距
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue), // 蓝色边框
                    ),
                    child: Row(
                      children: [
                        Text(
                            '机型: ${train['trainType']}'), // 假设车型信息在 'trainType' 字段中
                        const SizedBox(width: 10), // 添加一些间距
                        Text(
                            '车号: ${train['trainNum']}'), // 假设车号信息在 'trainNumber' 字段中
                        const SizedBox(width: 10), // 添加一些间距
                        Text(
                            '预计上台日期: ${train['arrivePlatformTime']}'), // 假设到达平台时间信息在 'arrivePlatFormTime' 字段中
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<dynamic> trainNotEnter = [];

  void getTrainInfo() async {
    var r = await ProductApi().getNotEnterTrainPlan();
    setState(() {
      trainNotEnter = r; // 假设 r 是包含机型车号信息的列表
    });
  }
}

// 班组信息展示
class TeamInfo extends StatefulWidget {
  final String planCode;
  const TeamInfo({super.key, required this.planCode});
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
        'deptId': Global.profile.permissions!.user.dept!.parentId,
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
          ? const Center(child: CircularProgressIndicator()) // 如果数据为空，显示加载指示器
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
