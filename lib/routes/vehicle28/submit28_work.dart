import 'package:flutter/material.dart';

// 全局颜色和样式定义
const Color kBlue = Color(0xFF0A4A78); // 深蓝色，可根据设计微调
const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 16);

class MachineReportPage extends StatefulWidget {
  const MachineReportPage({super.key});

  @override
  _MachineReportPageState createState() => _MachineReportPageState();
}

class _MachineReportPageState extends State<MachineReportPage> {
  String _model = '';         // 机型
  String _trainNumber = '';   // 机车号
  String _faultDesc = '';     // 故障现象
  bool _isSelfRepair = false; // 派工类别：true=自检自修，false=工长派工

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.all(16), // 外间距
        decoration: BoxDecoration(
          border: Border.all(color: kBlue, width: 2), // 蓝色边框
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 标题栏
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              color: kBlue,
              child: Text(
                '机统28-提报（作业）',
                style: whiteText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 2. 机型 + 机车号行
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  // 机型模块
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: kBlue,
                          child: Text('机型', style: whiteText),
                        ),
                        SizedBox(height: 4),
                        TextField(
                          onChanged: (val) => setState(() => _model = val),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: kBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: kBlue),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // 机车号模块
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: kBlue,
                          child: Text('机车号', style: whiteText),
                        ),
                        SizedBox(height: 4),
                        TextField(
                          onChanged: (val) => setState(() => _trainNumber = val),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: kBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: kBlue),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. 故障现象（多行输入）
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Container(
                color: kBlue,
                padding: EdgeInsets.all(8),
                child: TextField(
                  onChanged: (val) => setState(() => _faultDesc = val),
                  style: whiteText,
                  maxLines: 5, // 多行输入
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '请详细描述故障现象...',
                    hintStyle: whiteText.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),

            // 4. 派工类别（椭圆按钮）
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: StadiumBorder(), // 椭圆形状
                    ),
                    onPressed: () => setState(() => _isSelfRepair = true),
                    child: Text('自检自修', style: whiteText),
                  ),
                  SizedBox(width: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: StadiumBorder(),
                    ),
                    onPressed: () => setState(() => _isSelfRepair = false),
                    child: Text('工长派工', style: whiteText),
                  ),
                ],
              ),
            ),

            // 5. 故障视频及图片（占位容器）
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Container(
                height: 120,
                color: kBlue,
                alignment: Alignment.center,
                child: Text('故障视频及图片', style: whiteText),
              ),
            ),

            // 6. 确认提报按钮（右下角）
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue),
                  onPressed: () {
                    // 此处可扩展网络请求或数据提交逻辑
                    print('提报数据：');
                    print('机型：$_model，机车号：$_trainNumber');
                    print('故障现象：$_faultDesc');
                    print('派工类别：${_isSelfRepair ? "自检自修" : "工长派工"}');
                  },
                  child: Text('确认提报', style: whiteText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}