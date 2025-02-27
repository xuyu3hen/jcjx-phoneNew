import '../../index.dart';

class SecEnterModify extends StatefulWidget {
  const SecEnterModify({Key? key}) : super(key: key);

  @override
  _SecEnterModifyState createState() => _SecEnterModifyState();
}

class _SecEnterModifyState extends State<SecEnterModify> {
  // 车号
  late List<Map<String, dynamic>> trainNumCodeList;
  // 车号筛选信息
  late Map<dynamic, dynamic> trainNumSelected = {};
  // 检修地点
  late List<Map<String, dynamic>> stopLocationList;
  // 存储选择的检修地点信息
  late Map<dynamic, dynamic> stopLocationSelected = {};
  // 提报状态，true 表示正在提报
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    getTrainNumCodeList();
    getStopLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新增入段"),
      ),
      body: _buildBody(),
      bottomNavigationBar: _footer(),
    );
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
              ZjcFormSelectCell(
                title: "车号",
                text: trainNumSelected["name"],
                hintText: "请选择",
                showRedStar: true,
                clickCallBack: () {
                  if (trainNumCodeList.isEmpty) {
                    showToast("无车号可选择");
                  } else {
                    ZjcCascadeTreePicker.show(
                      context,
                      data: trainNumCodeList,
                      labelKey: 'trainNum',
                      valueKey: 'code',
                      childrenKey: 'children',
                      title: "选择车号",
                      clickCallBack: (selectItem, selectArr) {
                        print(selectArr);
                        setState(() {
                          trainNumSelected["name"] = selectItem["trainNum"];
                          trainNumSelected["code"] = selectItem["trainNumCode"];
                          trainNumSelected["repairTimes"] = selectItem["repairTimes"];
                          trainNumSelected["dynamicCode"] = selectItem["dynamicCode"];
                          trainNumSelected["repairPlanCode"] = selectItem["code"];
                          trainNumSelected["repairProcCode"] = selectItem["repairProcCode"];
                          trainNumSelected["typeCode"] = selectItem["trainTypeCode"];
                        });
                      },
                    );
                  }
                },
              ),
              ZjcFormSelectCell(
                title: "检修地点",
                text: stopLocationSelected["realLocation"],
                hintText: "请选择",
                showRedStar: true,
                clickCallBack: () {
                  if (stopLocationList.isEmpty) {
                    showToast("无检修地点可选择");
                  } else {
                    ZjcCascadeTreePicker.show(
                      context,
                      data: stopLocationList,
                      labelKey: 'realLocation',
                      valueKey: 'code',
                      childrenKey: 'children',
                      title: "选择检修地点",
                      clickCallBack: (selectItem, selectArr) {
                        setState(() {
                          print(selectArr);
                          stopLocationSelected["code"] = selectItem["code"];
                          stopLocationSelected["realLocation"] = selectItem["realLocation"];
                        });
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 获取车号
  void getTrainNumCodeList() async {
    List<dynamic> r = await ProductApi().getTrainNumDynamic();
    setState(() {
      // 将 List<dynamic> 转换为 List<Map<String, dynamic>>
      trainNumCodeList = r.map((item) => item as Map<String, dynamic>).toList();
    });
  }

  // 获取检修地点
  void getStopLocation() async {
    var r = await ProductApi().getstopLocation({
      'pageNum': 1,
      'pageSize': 10,
    });
    List<Map<String, dynamic>> processedStopLocations = [];
    if (r.rows != null && r.rows!.isNotEmpty) {
      for (var item in r.rows!) {
        if (item.areaName != null && item.deptName != null && item.trackNum != null) {
          processedStopLocations.add({
            'code': item.code,
            'deptName': item.deptName,
            'realLocation': '${item.deptName}-${item.trackNum}-${item.areaName}'
          });
        }
      }
    }
    setState(() {
      stopLocationList = processedStopLocations;
      print(stopLocationList);
    });
  }

  Future<String> newEntry() async {
    if (isSubmitting) {
      return ""; // 如果正在提报，直接返回空字符串
    }
    setState(() {
      isSubmitting = true; // 开始提报，设置状态为正在提报
    });
    Map<String, dynamic> queryParameters = {
      'trainNum': trainNumSelected["name"],
      'trainNumCode': trainNumSelected["code"],
      'repairTimes': trainNumSelected["repairTimes"],
      'dynamicCode': trainNumSelected["dynamicCode"],
      'repairPlanCode': trainNumSelected["repairPlanCode"], // 获取的 trainNum 的主键
      'repairProcCode': trainNumSelected["repairProcCode"],
      'repairLocation': stopLocationSelected["code"],
      'sort': 5,
      'typeCode': trainNumSelected["typeCode"],
    };
    try {
      var r = await ProductApi().newTrainEntry(queryParametrs: queryParameters);
      if (r["code"] == "S_T_S001") {
        showToast("新增入修成功");
        return r["data"];
      } else {
        showToast("新增入修失败");
        return "";
      }
    } finally {
      setState(() {
        isSubmitting = false; // 提报结束，设置状态为未提报
      });
    }
  }

  Widget _footer() {
    return SafeArea(
      child: InkWell(
        onTap: () async {
          if (isSubmitting) return; // 如果正在提报，不处理点击事件
          newEntry().then((code) {
            if (code != "") {
              exitDialog();
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.lightBlue[200],
          height: 50,
          child: isSubmitting
              ? const CircularProgressIndicator() // 显示加载指示器
              : const Text('新 增 入 段', style: TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }

  void exitDialog() {
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
              Text(
                "新增入段提报成功",
                style: TextStyle(fontSize: 18),
              ),
              ConstrainedBox(
                constraints: BoxConstraints.expand(height: 30, width: 160),
                child: ElevatedButton.icon(
                  onPressed: () {
                    SmartDialog.dismiss().then((value) => Navigator.of(context).pop());
                  },
                  label: Text('确定'),
                  icon: Icon(Icons.system_security_update_good_sharp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}