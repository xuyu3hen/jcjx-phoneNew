import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../index.dart';

class TaskPackageDetailsPage extends StatefulWidget {
  final WorkPackage package;
  final SecondPackage secondPackage;

  TaskPackageDetailsPage({required this.package, required this.secondPackage});

  @override
  _TaskPackageDetailsPageState createState() => _TaskPackageDetailsPageState();
}

class _TaskPackageDetailsPageState extends State<TaskPackageDetailsPage> {
  // 用于记录每个作业项（SecondShowPackage实例）与对应的勾选状态
  final List<SecondShowPackage> _packageCheckedList = [];
  //将SecondPackage转换为SecondShowPackage进行包装
  late List<SecondShowPackage> secondShowPackageList =
      getGroupSecondPackageCodeList();

  void setCheck() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('作业项内容'),
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
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(16),
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
            SizedBox(width: 8),
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
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColoredText(
                          '风险等级: ${secondShowPackage.taskCertainPackageList?.riskLevel ?? '无'}',
                          secondShowPackage.color),
                      SizedBox(width: 16),
                      _buildStatusIconAndText(
                          secondShowPackage.taskCertainPackageList!.complete),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildColoredText(
                      'Second Package Node: ${secondShowPackage.secondPackageNode}',
                      secondShowPackage.color),
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
                print(_packageCheckedList.length);
                if (_packageCheckedList.isNotEmpty) {
                  for (SecondShowPackage secondShowPackage
                      in _packageCheckedList) {
                    print(secondShowPackage.secondPackageNode);
                    print(secondShowPackage.taskCertainPackageList!.name);
                    print(secondShowPackage.taskCertainPackageList!.riskLevel);
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
        SizedBox(width: 4),
        Text(statusText),
      ],
    );
  }

  late UserList special = UserList(code: '', message: '', data: []);
  late UserList mutual = UserList(code: '', message: '', data: []);

  Widget _buildUploadButton(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.1;
    bool checkUploudPicture = false;
    String secondPackageCode = '';

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

    return Container(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: ElevatedButton(
        onPressed: () {
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
                  title: Text('非同一第二工位作业项，不可一起提交！'),
                  actions: [
                    TextButton(
                      child: Text('确定'),
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
        child: Text('上传作业项图片'),
      ),
    );
  }

  void getUserList(String specialList, String mutualList) async {
    List<int> special_list =
        specialList.split(',').map((e) => int.parse(e)).toList();
    List<int> mutual_list =
        mutualList.split(',').map((e) => int.parse(e)).toList();

    print('Special List: $special_list');
    print('Mutual List: $mutual_list');
    var specialUserList = await ProductApi().getUserList(special_list);
    var muutualUserList = await ProductApi().getUserList(mutual_list);
    setState(() {
      special = specialUserList;
      print('${special.data}');
      mutual = muutualUserList;
      print('${mutual.data}');
    });
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
      print(secondShowPackage.taskCertainPackageList?.toJson());
      print(secondShowPackage.toJson());
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

class NewPage extends StatefulWidget {
  final List<UserInfo>? mutualList;
  final List<UserInfo>? specialList;
  final List<SecondShowPackage>? secondPackageList;

  NewPage({Key? key, this.mutualList, this.specialList, this.secondPackageList})
      : super(key: key);

  @override
  _NewPageState createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  List<Map<String, dynamic>> mutualListData = [];
  List<Map<String, dynamic>> specialListData = [];
  // 互检筛选人员
  Map<String, dynamic> mutualSelected = {};
  // 专检筛选人员
  Map<String, dynamic> specialSelected = {};
  //图片
  File? _image;
  //图片筛选
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 将 mutualList 转换为 mutualListData
    mutualListData =
        widget.mutualList?.map((userInfo) => userInfo.toJson()).toList() ?? [];
    // 将 specialList 转换为 specialListData
    specialListData =
        widget.specialList?.map((userInfo) => userInfo.toJson()).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('上传作业项图片以及互检专检人员'),
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
                              print(selectArr);
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
                              print(selectArr);
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

  TextStyle LeadingStyle(val) {
    return TextStyle(
      fontSize: val,
      color: Colors.black,
    );
  }

  Text DataText(str, val) {
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
        Text("上传作业项图片"),
        if (_image == null)
          InkWell(
            child: Container(
              constraints: BoxConstraints.tightFor(width: 200, height: 200),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Icon(Icons.add_a_photo)],
              ),
            ),
            onTap: () => {showBottomSheet(context)},
          ),
        if (_image != null)
          Container(
            child: Image.file(_image!, height: 200),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 140,
              height: 30.0,
              child: ElevatedButton(
                onPressed: () => {
                  if (_image != null)
                    {
                      SmartDialog.showLoading(),
                      uploadPicture(),
                      SmartDialog.dismiss()
                    }
                  else
                    {showToast("请先选择上传图像")}
                },
                child: Text("上传", style: TextStyle(fontSize: 18.0)),
              ),
            ),
            SizedBox(
              width: 140,
              height: 30.0,
              child: ElevatedButton(
                onPressed: () => {SmartDialog.dismiss(), _image = null},
                child: Text("取消", style: TextStyle(fontSize: 18.0)),
              ),
            ),
          ],
        )
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
    return Container(
      height: 150,
      child: Column(
        children: [
          buildItem("拍照", onTap: () {
            getImage(ImageSource.camera);
            Navigator.of(context).pop();
          }),
          //分割线
          Divider(),

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
              child: Text("取消"),
              height: 44,
              alignment: Alignment.center,
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
      child: Container(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
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
    print(certainPackageCodeList);
    print(secondShowPackageList[0].taskCertainPackageList!.secondPackageCode);
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
}
