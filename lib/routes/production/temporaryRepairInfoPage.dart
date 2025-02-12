import 'package:flutter/material.dart';

class TemporaryRepairInfoPage extends StatefulWidget {
  @override
  _TemporaryRepairInfoPageState createState() => _TemporaryRepairInfoPageState();
}

class _TemporaryRepairInfoPageState extends State<TemporaryRepairInfoPage> {
  // 控制器用于获取 TextField 的输入内容
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _faultDescriptionController = TextEditingController();
  final TextEditingController _reporterController = TextEditingController();

  @override
  void dispose() {
    // 释放控制器资源
    _deviceNameController.dispose();
    _faultDescriptionController.dispose();
    _reporterController.dispose();
    super.dispose();
  }

  // 提交临修信息的方法
  void _submitRepairInfo() {
    String deviceName = _deviceNameController.text;
    String faultDescription = _faultDescriptionController.text;
    String reporter = _reporterController.text;

    // 简单验证输入是否为空
    if (deviceName.isEmpty || faultDescription.isEmpty || reporter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写所有必填字段')),
      );
      return;
    }

    // 这里可以添加将信息发送到服务器或进行其他处理的逻辑
    print('临修设备名称: $deviceName');
    print('故障描述: $faultDescription');
    print('报修人: $reporter');

    // 显示提交成功的提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('临修信息提交成功')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('临修信息页面'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 临修设备名称输入框
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: '临修设备名称',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // 故障描述输入框
            TextField(
              controller: _faultDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '故障描述',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // 报修人输入框
            TextField(
              controller: _reporterController,
              decoration: InputDecoration(
                labelText: '报修人',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32.0),
            // 提交按钮
            ElevatedButton(
              onPressed: _submitRepairInfo,
              child: Text('提交临修信息'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TemporaryRepairInfoPage(),
  ));
}