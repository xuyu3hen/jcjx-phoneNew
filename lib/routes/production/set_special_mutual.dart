import '../../index.dart';

class SetSpecialCheck extends StatefulWidget {
  final List<WorkInstructPackageUserList> selectedWorkItems;
  const SetSpecialCheck({Key? key, required this.selectedWorkItems})
      : super(key: key);

  @override
  State createState() => _SetSpecialCheckState();
}

class _SetSpecialCheckState extends State<SetSpecialCheck> {
  // 用于存储已勾选的作业项
  List<WorkInstructPackageUserList> selectedWorkItems = [];

  // 获取的互检用户
  late List<Map<String, dynamic>> mutual = [];

  // 获取的专检用户
  late List<Map<String, dynamic>> special = [];

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    // 初始化时，将传入的selectedWorkItems复制到selectedWorkItems中
    //对信息进行复制
    selectedWorkItems = List.from(widget.selectedWorkItems);
    getSpecialMutual();
  }

  void saveSelectedUsers() {
    try {
      List<int> mutualIdList = [];
      List<String> mutualNameList = [];
      for (var person in mutual) {
        if (person['associated'] == true) {
          mutualIdList.add(person['userId']);
          mutualNameList.add(person['name']);
        }
      }
      // idList和nameList分别以,拼接成字符串
      String mutualIdString = mutualIdList.join(',');
      String mutualNameString = mutualNameList.join(',');

      List<int> specialIdList = [];
      List<String> specialNameList = [];
      for (var person in special) {
        if (person['associated'] == true) {
          specialIdList.add(person['userId']);
          specialNameList.add(person['name']);
        }
      }
      // idList和nameList分别以,拼接成字符串
      String specialIdString = specialIdList.join(',');
      String specialNameString = specialNameList.join(',');

      List<Map<String, dynamic>> queryParameters = [];

      //selectedWorkItems 遍历 赋值
      for (var item in selectedWorkItems) {
        item.mutualInspectionPersonnel = mutualIdString;
        item.mutualPersonnelName = mutualNameString;
        item.specialInspectionPersonnel = specialIdString;
        item.specialPersonnelName = specialNameString;
        queryParameters.add(item.toJson());
      }

      // 打印queryParameters使用log
      logger.i(jsonEncode(queryParameters));

      if (mounted) {
        // 调用接口
        ProductApi().saveAssociated(queryParameters);

        showToast('专互检保存成功');
        //回退到上一页面
        Navigator.pop(context);
        setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('saveSelectedUsers方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 获取专互检信息
  void getSpecialMutual() async {
    try{
         if (selectedWorkItems.isNotEmpty) {
      Map<String, dynamic> queryParameters = {
        'pageNum': 0,
        'pageSize': 0,
        'dictType': 'tech_risk_level',
        'dictLabel': selectedWorkItems[0].riskLevel,
        'status': 0
      };
      var r = await ProductApi().getDictCode(queryParameters);
      int dictCode = r['rows'][0]['dictCode'];
      logger.i(dictCode);
      Map<String, dynamic> queryParameters1 = {
        'pageNum': 0,
        'pageSize': 0,
        'riskLevelCode': dictCode,
      };
      List<int> mutualIdList = [];
      List<int> specialIdList = [];
      var r1 = await ProductApi().getPostByRiskLevel(queryParameters1);
      for (var item in r1['rows']) {
        if (item['controlLevelName'] == '互检') {
          mutual.add(item);
          mutualIdList.add(item['postId']);
        } else {
          special.add(item);
          specialIdList.add(item['postId']);
        }
      }
      var r2 = await ProductApi().getUserListByPostIdList(mutualIdList);
      for (var item in mutual) {
        Map<String, dynamic> info = r2[item['postId'].toString()][0];
        item['name'] = info['nickName'];
        item['userId'] = info['userId'];

        //’1123，1134‘ 123匹配上的规则 仍然可以完善
        if (selectedWorkItems[0]
            .mutualInspectionPersonnel
            .toString()
            .contains(item['userId'].toString())) {
          item['associated'] = true;
        } else {
          item['associated'] = false;
        }

        logger.i(item);
      }
      var r3 = await ProductApi().getUserListByPostIdList(specialIdList);
      for (var item in special) {
        Map<String, dynamic> info = r3[item['postId'].toString()][0];
        item['name'] = info['nickName'];
        item['userId'] = info['userId'];

        //workInstructPackageUserList的userId
        if (selectedWorkItems[0]
            .specialInspectionPersonnel
            .toString()
            .contains(item['userId'].toString())) {
          item['associated'] = true;
        } else {
          item['associated'] = false;
        }
        logger.i(item);
      }
      if (mounted) {
        setState(() {});
      }
    }
    }catch(e, stackTrace){
      logger.e('getSpecialMutual方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置专互检'),
      ),
      body: Column(
        children: [
          const Text('互检'),
          // 互检
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.vertical, // 修改为垂直滚动
              itemCount: mutual.length,
              itemBuilder: (BuildContext context, int index) {
                var person = mutual[index];
                return Row(
                  children: [
                    Text(
                      mutual[index]['name'].toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: person['associated'] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          person['associated'] = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const Text('专检'),
          // 专检
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.vertical, // 修改为垂直滚动
              itemCount: special.length,
              itemBuilder: (BuildContext context, int index) {
                var person = special[index];
                return Row(
                  children: [
                    Text(
                      special[index]['name'].toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(), // 添加Spacer将文本和复选框分开
                    Checkbox(
                      value: person['associated'] ?? false, // 初始状态全选
                      onChanged: (bool? value) {
                        // 处理勾选状态改变的逻辑
                        setState(() {
                          person['associated'] = value; // 更新状态
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          //右下角保存按钮
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveSelectedUsers, // 调用 save 方法
        child: const Text('保存'), // 按钮内容
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 按钮位置
    );
  }
}
