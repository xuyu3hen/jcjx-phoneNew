
import '../../index.dart';

class TaskPackageDetailsPage extends StatefulWidget {
  final WorkPackage package;
  final SecondPackage secondPackage;

   const TaskPackageDetailsPage({super.key, required this.package, required this.secondPackage});

  @override
  State createState() => _TaskPackageDetailsPageState();
}

class _TaskPackageDetailsPageState extends State<TaskPackageDetailsPage> {
  // 用于记录每个作业项（SecondShowPackage实例）与对应的勾选状态
  final List<SecondShowPackage> _packageCheckedList = [];
  //将SecondPackage转换为SecondShowPackage进行包装
  late List<SecondShowPackage> secondShowPackageList =
      getGroupSecondPackageCodeList();
  
  var logger = AppLogger.logger;

  void setCheck() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作业项内容'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: secondShowPackageList.length,
              itemBuilder: (context, index) {
                final secondShowPackage = secondShowPackageList[index];
                return buildPackageDetailsItem(context, secondShowPackage);
              },
            ),
          ),
          if (_anyPackageChecked()) _buildUploadButton(context),
        ],
      ),
    );
  }

//
  bool _anyPackageChecked() {
    if (_packageCheckedList.isNotEmpty) {
      return true;
    }
    return false;
  }

  Widget buildPackageDetailsItem(
      BuildContext context, SecondShowPackage secondShowPackage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskContentDetailsPage(
              taskInstructContentList: secondShowPackage
                  .taskCertainPackageList?.taskInstructContentList,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckbox(secondShowPackage),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '作业项名称: ${secondShowPackage.taskCertainPackageList?.name ?? '无'}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: getColorFromIndex(secondShowPackage.color ?? 0)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColoredText(
                          '风险等级: ${secondShowPackage.taskCertainPackageList?.riskLevel ?? '无'}',
                          secondShowPackage.color),
                      const SizedBox(width: 16),
                      _buildStatusIconAndText(
                          secondShowPackage.taskCertainPackageList!.complete),
                    ],
                  ),
                  // SizedBox(height: 16),
                  // _buildColoredText(
                  //     'Second Package Node: ${secondShowPackage.secondPackageNode}',
                  //     secondShowPackage.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(SecondShowPackage secondShowPackage) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Checkbox(
          key: Key(secondShowPackage.toString()),
          value: _packageCheckedList.contains(secondShowPackage),
          onChanged: (newValue) {
            if (newValue != null) {
              //如果点击勾选框
              if (newValue) {
                //secondShowPackage的secondPackageCode是否为空
                if (secondShowPackage.secondPackageNode == null ||
                    secondShowPackage.secondPackageNode!.isEmpty) {
                  _packageCheckedList.add(secondShowPackage);
                } else {
                  for (SecondShowPackage secondShowPackage1
                      in secondShowPackageList) {
                    //如果选了一个，就把所有的都选上
                    if (secondShowPackage.secondPackageNode ==
                        secondShowPackage1.secondPackageNode) {
                      _packageCheckedList.add(secondShowPackage1);
                    }
                  }
                }
              } else {
                //secondShowPackage的secondPackageCode是否为空
                if (secondShowPackage.secondPackageNode == null ||
                    secondShowPackage.secondPackageNode!.isEmpty) {
                  _packageCheckedList.remove(secondShowPackage);
                } else {
                  for (SecondShowPackage secondShowPackage1
                      in secondShowPackageList) {
                    if (secondShowPackage.secondPackageNode ==
                        secondShowPackage1.secondPackageNode) {
                      //如果删了一个，就把所有的都删了
                      _packageCheckedList.remove(secondShowPackage1);
                    }
                  }
                }
              }
              setState(() {
                logger.i(_packageCheckedList.length);
                if (_packageCheckedList.isNotEmpty) {
                  for (SecondShowPackage secondShowPackage
                      in _packageCheckedList) {
                    logger.i(secondShowPackage.secondPackageNode);
                    logger.i(secondShowPackage.taskCertainPackageList!.name);
                    logger.i(secondShowPackage.taskCertainPackageList!.riskLevel);
                  }
                }
              });
              setCheck();
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        );
      },
    );
  }

  Widget _buildColoredText(String text, int? colorIndex) {
    Color textColor = getColorFromIndex(colorIndex ?? 0);
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
    );
  }

  Widget _buildStatusIconAndText(String? status) {
    IconData iconData;
    String statusText;
    if (status == '0') {
      iconData = Icons.cancel;
      statusText = '未完成';
    } else if (status == '1') {
      iconData = Icons.done;
      statusText = '完成';
    } else if (status == '2') {
      iconData = Icons.error;
      statusText = '异常';
    } else if (status == '3') {
      iconData = Icons.skip_next;
      statusText = '跳过';
    } else if (status == '4') {
      iconData = Icons.access_time;
      statusText = '待检';
    } else {
      iconData = Icons.help;
      statusText = '未知';
    }
    return Row(
      children: [
        Icon(
          iconData,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(statusText),
      ],
    );
  }

  UserList special = UserList(code: '', message: '', data: []);
  UserList mutual = UserList(code: '', message: '', data: []);

  Widget _buildUploadButton(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.1;
    bool checkUploudPicture = false;
    // String secondPackageCode = '';

    // 如果只勾选一项可以提交作业列表
    if (_packageCheckedList.length == 1) {
      checkUploudPicture = true;
    } else {
      // 如果有多个，那么只有全是第二工位为相同值的时候存在
      List<String> secondCodeList = [];
      for (SecondShowPackage secondShowPackage in _packageCheckedList) {
        if (secondShowPackage.secondPackageNode == null ||
            secondShowPackage.secondPackageNode!.isEmpty) {
          secondCodeList.add('empty');
        } else {
          secondCodeList.add(secondShowPackage.secondPackageNode ?? '');
        }
      }
      checkUploudPicture = secondCodeList.toSet().length == 1;
    }

    String specialInspectionPersonnel = _packageCheckedList[0]
            .taskCertainPackageList!
            .specialInspectionPersonnel ??
        '';
    String mutualInspectionPersonnel = _packageCheckedList[0]
            .taskCertainPackageList!
            .mutualInspectionPersonnel ??
        '';
    getUserList(specialInspectionPersonnel, mutualInspectionPersonnel);
    List<UserInfo>? specialList = special.data;
    List<UserInfo>? mutualList = mutual.data;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: ElevatedButton(
        onPressed: () {
          // 在这里添加弹出上传界面的逻辑
          if (checkUploudPicture) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewPage(
                    mutualList: mutualList,
                    specialList: specialList,
                    secondPackageList: _packageCheckedList),
              ),
            );
          } else {
            // 弹出提示框非同一第二工位作业项，不可一起提交！
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('非同一第二工位作业项，不可一起提交！'),
                  actions: [
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
        child: const Text('上传作业项图片'),
      ),
    );
  }

  void getUserList(String specialList, String mutualList) async {
    List<int> specialList1 = [];
    List<int> mutualList1 = [];
    // 处理 specialList
    if (specialList.isNotEmpty) {
      specialList.split(',').forEach((element) {
        try {
          int value = int.parse(element);
          specialList1.add(value);
        } catch (e) {
          logger.e('Error parsing $element in specialList: $e');
        }
      });
    }
    // 处理 mutualList
    if (mutualList.isNotEmpty) {
      mutualList.split(',').forEach((element) {
        try {
          int value = int.parse(element);
          mutualList1.add(value);
        } catch (e) {
          logger.e('Error parsing $element in mutualList: $e');
        }
      });
    }
    logger.i('Special List: $specialList1');
    logger.i('Mutual List: $mutualList1');

    if (specialList1.isNotEmpty) {
      var specialUserList = await ProductApi().getUserList(specialList1);
      if (mounted) {
        setState(() {
          special = specialUserList;
          logger.i('${special.data}');
        });
      }
    }
    if (mutualList1.isNotEmpty) {
      var muutualUserList = await ProductApi().getUserList(mutualList1);
      if (mounted) {
        setState(() {
          mutual = muutualUserList;
          logger.i('${mutual.data}');
        });
      }
    }
  }

  List<SecondShowPackage> getGroupSecondPackageCodeList() {
    // 第二工位设置
    List<Rows>? secondPackageList = widget.secondPackage.rows;
    //每一个secondPackageNode对应一种颜色

    // 第二工位以及taskCertainPackageList设置
    List<SecondShowPackage> secondShowPackageList = [];

    List<TaskCertainPackageList>? taskCertainPackageList =
        widget.package.taskCertainPackageList;

    Map<String, int> secondPackageNode2Color = {};
    int color = 1;
    if (secondPackageList != null && secondPackageList.isNotEmpty) {
      for (TaskCertainPackageList taskCertainPackage
          in taskCertainPackageList!) {
        String secondPackageNode = taskCertainPackage.secondPackageCode ?? '';
        secondPackageNode2Color[secondPackageNode] = color % 14;
        color++;
      }
    }
    if (secondPackageList == null || taskCertainPackageList == null) {
      return secondShowPackageList;
    }

    for (TaskCertainPackageList taskCertainPackage in taskCertainPackageList) {
      String secondPackageCode = '';
      for (Rows rows in secondPackageList) {
        if (taskCertainPackage.code == rows.certainPackageCode) {
          secondPackageCode = rows.secondPackageCode ?? '';
        }
      }
      int i =
          secondPackageNode2Color[taskCertainPackage.secondPackageCode] ?? 0;
      SecondShowPackage secondShowPackage = SecondShowPackage(
        taskCertainPackageList: taskCertainPackage,
        secondPackageNode: taskCertainPackage.secondPackageCode,
        color: i,
      );
      secondShowPackageList.add(secondShowPackage);
    }
    for (SecondShowPackage secondShowPackage in secondShowPackageList) {
      logger.i(secondShowPackage.taskCertainPackageList?.toJson());
      logger.i(secondShowPackage.toJson());
    }
    return secondShowPackageList;
  }

  Color getColorFromIndex(int index) {
    switch (index) {
      case 0:
        return Colors.black;
      case 1:
        return Colors.red;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.orange;
      case 6:
        return Colors.purple;
      case 7:
        return Colors.pink;
      case 8:
        return Colors.brown;
      case 9:
        return Colors.cyan;
      case 10:
        return Colors.amber;
      case 11:
        return Colors.lime;
      case 12:
        return Colors.teal;
      case 13:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

//上传作业项图片以及互检专检人员
class NewPage extends StatefulWidget {
  final List<UserInfo>? mutualList;
  final List<UserInfo>? specialList;
  final List<SecondShowPackage>? secondPackageList;

  const NewPage({Key? key, this.mutualList, this.specialList, this.secondPackageList})
      : super(key: key);

  @override
  State createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  late List<Map<String, dynamic>> mutualListData = [];
  late List<Map<String, dynamic>> specialListData = [];
  // 互检筛选人员
  Map<String, dynamic> mutualSelected = {};
  // 专检筛选人员
  Map<String, dynamic> specialSelected = {};
  //图片
  File? _image;
  //图片筛选
  final ImagePicker picker = ImagePicker();

  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    // 将 mutualList 转换为 mutualListData
  }

  @override
  Widget build(BuildContext context) {
    mutualListData =
        widget.mutualList?.map((userInfo) => userInfo.toJson()).toList() ?? [];
    // 将 specialList 转换为 specialListData
    logger.i(mutualListData);
    specialListData =
        widget.specialList?.map((userInfo) => userInfo.toJson()).toList() ?? [];
    logger.i(specialListData);
    //刷新界面

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传作业项图片以及互检专检人员'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.1 + 20),
              children: [
                // 互检人员选择部分
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ZjcFormSelectCell(
                      title: "互检人员",
                      text: mutualSelected["nickName"] ?? "",
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: () {
                        if (mutualListData.isEmpty) {
                          showToast("无互检人员");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: mutualListData,
                            labelKey: 'nickName',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: "选择动力类型",
                            clickCallBack: (selectItem, selectArr) {
                              logger.i(selectArr);
                              setState(() {
                                mutualSelected['nickName'] =
                                    selectItem['nickName'];
                                mutualSelected['userId'] = selectItem['userId'];
                              });
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
                // 专检人员选择部分
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ZjcFormSelectCell(
                      title: "专检人员",
                      text: specialSelected["nickName"] ?? "",
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: () {
                        if (specialListData.isEmpty) {
                          showToast("无专检人员");
                        } else {
                          ZjcCascadeTreePicker.show(
                            context,
                            data: specialListData,
                            labelKey: 'nickName',
                            valueKey: 'code',
                            childrenKey: 'children',
                            title: "选择动力类型",
                            clickCallBack: (selectItem, selectArr) {
                              logger.i(selectArr);
                              setState(() {
                                specialSelected['nickName'] =
                                    selectItem['nickName'];
                                specialSelected['userId'] =
                                    selectItem['userId'];
                              });
                            },
                          );
                        }
                      },
                    ),
                    // 在此处添加 uploadDialog 的相关组件
                    uploadDialogComponents(context),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle leadingStyle(val) {
    return TextStyle(
      fontSize: val,
      color: Colors.black,
    );
  }

  Text dataText(str, val) {
    return Text(
      str,
      style: TextStyle(
        fontSize: val,
        color: Colors.black,
      ),
    );
  }

  // 上传照片弹窗
  Widget uploadDialogComponents(BuildContext context) {
    return Column(
      children: [
        if (_image == null)
          InkWell(
            child: Container(
              constraints:
                  const BoxConstraints.tightFor(width: 400, height: 400), // 放大图片的容器大小
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Icon(Icons.add_a_photo)],
              ),
            ),
            onTap: () => {showBottomSheet(context)},
          ),
        if (_image != null)
          Image.file(_image!, height: 400),
        const SizedBox(height: 20), // 增加一些间距
        SizedBox(
          //宽度为屏幕宽
          width: MediaQuery.of(context).size.width,
          //高度为屏幕0.1倍
          height: MediaQuery.of(context).size.height * 0.1,
          //放在屏幕最下方锁定

          child: ElevatedButton(
            onPressed: () => {
              if (_image != null)
                {
                  SmartDialog.showLoading(),
                  uploadPicture(),
                  completeCertainPackage(),
                  SmartDialog.dismiss()
                }
              else
                {showToast("请先选择上传图像")}
            },
            child: const Text("上传", style: TextStyle(fontSize: 18.0)),
          ),
        ),
      ],
    );
  }

  // 图片来源选择支
  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext icontext) {
          return buildBottomSheetWidget(icontext);
        });
  }

  // 选择支构筑
  Widget buildBottomSheetWidget(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          buildItem("拍照", onTap: () {
            getImage(ImageSource.camera);
            Navigator.of(context).pop();
          }),
          //分割线
          const Divider(),

          buildItem("打开相册", onTap: () {
            getImage(ImageSource.gallery);
            Navigator.of(context).pop();
          }),

          Container(
            color: Colors.grey[300],
            height: 8,
          ),

          //取消按钮
          //添加个点击事件
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: const Text("取消"),
            ),
          )
        ],
      ),
    );
  }

  // 选择支子单元
  Widget buildItem(String title, {String? imagePath, Function? onTap}) {
    //添加点击事件
    return InkWell(
      //点击回调
      onTap: () {
        //关闭弹框
        // Navigator.of(context).pop();
        //外部回调
        if (onTap != null) {
          onTap();
        }
      },
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 10,
            ),
            Text(title)
          ],
        ),
      ),
    );
  }

  // 获取图片函数
  Future getImage(ImageSource isource) async {
    final PickedFile = await picker.pickImage(
      source: isource,
    );
    setState(() {
      if (PickedFile != null) {
        _image = File(PickedFile.path);
        SmartDialog.dismiss();
      } else {
        showToast("未获取图片");
      }
    });
  }

  void uploadPicture() async {
    List<SecondShowPackage>? secondShowPackageList = widget.secondPackageList;
    String certainPackageCodeList = secondShowPackageList!
        .map((package) => package.taskCertainPackageList!.code)
        .join(',');
    logger.i(certainPackageCodeList);
    logger.i(secondShowPackageList[0].taskCertainPackageList!.secondPackageCode);
    var r = await ProductApi().uploadCertainPackageImg(queryParametrs: {
      'certainPackageCodeList': certainPackageCodeList,
      'secondPackageCode':
          secondShowPackageList[0].taskCertainPackageList!.secondPackageCode
    }, imagedata: File(_image!.path));
    if (r == 200) {
      showToast("上传成功");
      SmartDialog.dismiss();
      _image = null;
    }
  }

  static Map<String, WidgetBuilder> routes = {
    'searchWorkPackage': (BuildContext context) => SearchWorkPackage(),
  };

  //完成作业项图片上传
  void completeCertainPackage() async {
    List<TaskCertainPackageList> list = [];
    for (SecondShowPackage secondShowPackage in widget.secondPackageList!) {
      secondShowPackage.taskCertainPackageList?.mutualInspectionId =
          mutualSelected['userId'];
      secondShowPackage.taskCertainPackageList?.specialInspectionId =
          specialSelected['userId'];
      secondShowPackage.taskCertainPackageList?.mutualInspectionName =
          mutualSelected['nickName'];
      secondShowPackage.taskCertainPackageList?.specialInspectionName =
          specialSelected['nickName'];
      list.add(secondShowPackage.taskCertainPackageList!);
    }
    //展示list内容。每个元素值
    for (TaskCertainPackageList taskCertainPackageList in list) {
      print(taskCertainPackageList.toJson());
    }
    var r = await ProductApi().finishCertainPackage(list);
    if (r == 200) {
      showToast("完成成功");
      //进行页面跳转跳转到作业包模块
      //目前目前没有解决跳转问题
    }
  }
}
