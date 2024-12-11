import '../../index.dart';
import 'package:flutter/material.dart';

class TaskPackageDetailsPage extends StatefulWidget {
  final WorkPackage package;
  final SecondPackage secondPackage;

  TaskPackageDetailsPage({required this.package, required this.secondPackage});

  @override
  _TaskPackageDetailsPageState createState() => _TaskPackageDetailsPageState();
}

class _TaskPackageDetailsPageState extends State<TaskPackageDetailsPage> {
  // 用于记录每个作业项（SecondShowPackage实例）与对应的勾选状态
  final Map<SecondShowPackage, bool> _packageCheckedMap = {};

  @override
  Widget build(BuildContext context) {
    List<SecondShowPackage> secondShowPackageList =
        getGroupSecondPackageCodeList();
    return Scaffold(
      appBar: AppBar(
        title: Text('作业包详情'),
      ),
      body: ListView.builder(
        itemCount: secondShowPackageList.length,
        itemBuilder: (context, index) {
          final secondShowPackage = secondShowPackageList[index];
          return buildPackageDetailsItem(context, secondShowPackage);
        },
      ),
    );
  }

  Widget buildPackageDetailsItem(BuildContext context, SecondShowPackage secondShowPackage) {
    bool isChecked = _packageCheckedMap[secondShowPackage]?? false;
    print('isChecked value for ${secondShowPackage.toString()}: $isChecked');
    return GestureDetector(
      onTap: () {
        // 点击整个作业项时，切换当前作业项对应的勾选状态
        _toggleCheckStatusForPackage(secondShowPackage);
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
            _buildCheckbox(isChecked, secondShowPackage),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '作业项名称: ${secondShowPackage.taskCertainPackageList?.name?? '无'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColoredText(
                          '风险等级: ${secondShowPackage.taskCertainPackageList?.riskLevel?? '无'}',
                          secondShowPackage.color),
                      SizedBox(width: 16),
                      _buildStatusIconAndText(secondShowPackage.taskCertainPackageList!.complete),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildColoredText(
                      'Second Package Node: ${secondShowPackage.secondPackageNode}',
                      secondShowPackage.color),
                  if (isChecked) _buildUploadButton(context), // 根据勾选状态决定是否显示上传按钮
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isChecked, SecondShowPackage secondShowPackage) {
    return Checkbox(
      key: Key(secondShowPackage.toString()),
      value: isChecked,
      onChanged: (newValue) {
        if (newValue!= null) {
          // 更新当前作业项对应的勾选状态
          _packageCheckedMap[secondShowPackage] = newValue;
          setState(() {});
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  Widget _buildColoredText(String text, int? colorIndex) {
    Color textColor = getColorFromIndex(colorIndex?? 0);
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

  void _toggleCheckStatusForPackage(SecondShowPackage secondShowPackage) {
    bool currentStatus = _packageCheckedMap[secondShowPackage]?? false;
    _packageCheckedMap[secondShowPackage] =!currentStatus;
    setState(() {});
  }

  Widget _buildUploadButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 这里添加点击上传按钮后的逻辑，比如打开文件选择器等，暂时可以先打印提示信息
        print('点击了上传作业项图片按钮');
      },
      child: Text('上传作业项图片'),
    );
  }

  List<SecondShowPackage> getGroupSecondPackageCodeList() {
    // 第二工位设置
    List<Rows>? secondPackageList = widget.secondPackage.rows;
    //每一个secondPackageNode对应一种颜色
    Map<String, int> secondPackageNode2Color = {};
    int color = 1;
    if (secondPackageList!= null && secondPackageList.isNotEmpty) {
      for (Rows rows in secondPackageList) {
        String secondPackageNode = rows.secondPackageCode?? '';
        secondPackageNode2Color[secondPackageNode] = color % 4;
        color++;
      }
    }
    // 第二工位以及taskCertainPackageList设置
    List<SecondShowPackage> secondShowPackageList = [];

    List<TaskCertainPackageList>? taskCertainPackageList =
        widget.package.taskCertainPackageList;

    if (secondPackageList == null || taskCertainPackageList == null) {
      return secondShowPackageList;
    }

    for (TaskCertainPackageList taskCertainPackage in taskCertainPackageList) {
      String secondPackageCode = '';
      for (Rows rows in secondPackageList) {
        if (taskCertainPackage.code == rows.certainPackageCode) {
          secondPackageCode = rows.secondPackageCode?? '';
        }
      }
      int i = secondPackageNode2Color[secondPackageCode]?? 0;
      SecondShowPackage secondShowPackage = SecondShowPackage(
        taskCertainPackageList: taskCertainPackage,
        secondPackageNode: secondPackageCode,
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
    // 简单示例，根据索引返回不同的颜色，可根据实际需求替换为更复杂的颜色逻辑，比如使用主题颜色或者预定义的颜色列表等
    switch (index) {
      case 0:
        return Colors.black;
      case 1:
        return Colors.red;
      case 2:
        return Colors.green;
      case 3:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}