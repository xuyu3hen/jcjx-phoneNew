import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../index.dart';

class TemporaryRepairInfoPage extends StatefulWidget {
  const TemporaryRepairInfoPage({super.key});

  @override
  _TemporaryRepairInfoPageState createState() =>
      _TemporaryRepairInfoPageState();
}

class _TemporaryRepairInfoPageState extends State<TemporaryRepairInfoPage> {
  // 排序数字
  int _sort = 1;
  final TextEditingController _repairSectionController =
      TextEditingController();
  final TextEditingController _assignedSectionController =
      TextEditingController();
  final TextEditingController _powerTypeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _plannedMonthController = TextEditingController();
  final TextEditingController _repairSystemController = TextEditingController();
  final TextEditingController _repairProcessController =
      TextEditingController();
  final TextEditingController _repairTimesController = TextEditingController();
  DateTime? _estimatedStartDate;
  DateTime? _estimatedDeliveryDate;
  DateTime? _estimatedDepartureDate;
  final TextEditingController _signerController = TextEditingController();
  final TextEditingController _maintenanceLocationController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void dispose() {
    // 释放控制器资源
    _repairSectionController.dispose();
    _assignedSectionController.dispose();
    _powerTypeController.dispose();
    _modelController.dispose();
    _carNumberController.dispose();
    _plannedMonthController.dispose();
    _repairSystemController.dispose();
    _repairProcessController.dispose();
    _repairTimesController.dispose();
    _signerController.dispose();
    _maintenanceLocationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getBasicInfo();
  }

  List<Map<String, dynamic>> jcRepairSegmentInfo = [];
  List<String> _repairSegments = [];
  // 当前选中的承修段
  String? _selectedRepairSegment;
  // 获取承修段主键
  String? _selectedRepairSegmentKey;

  List<Map<String, dynamic>> jcAssignSegmentInfo = [];
  List<String> _assignSegments = [];
  String? _selectedAssignSegment;
  String? _selectedAssignSegmentKey;
  int? _selectedMonth;

  //动力类型
  List<Map<String, dynamic>> jcDynamicTypeInfo = [];
  List<String> _dynamicTypes = [];
  String? _selectedDynamicType;
  String? _selectedDynamicTypeKey;

  //获取初始选择需要的数据
  Future<void> getBasicInfo() async {
    Map<String, dynamic> queryParameters = {};
    queryParameters['pageNum'] = 0;
    queryParameters['pageSize'] = 0;

    try {
      Map<String, dynamic> jcRepairSegment = await ProductApi()
          .getJcRepairSegment(queryParametrs: queryParameters);

      Map<String, dynamic> jcAssignSegment = await ProductApi()
          .getJcAssignSegment(queryParametrs: queryParameters);

      //获取动力类型
      Map<String, dynamic> dynamicType =
          await ProductApi().getJcDynamicType(queryParametrs: queryParameters);

      // 打印返回的数据结构以进行调试
      print('API Response: $jcRepairSegment');
      print('API Response: $jcAssignSegment');

      // 确保 jcRepairSegment['rows'] 是一个 List<Map<String, dynamic>>
      if (jcRepairSegment['rows'] is List) {
        List<dynamic> rows = jcRepairSegment['rows'];

        // 进一步检查每个元素是否是 Map<String, dynamic>
        List<Map<String, dynamic>> repairSegmentRows =
            rows.whereType<Map<String, dynamic>>().toList();

        setState(() {
          jcRepairSegmentInfo = repairSegmentRows;
          _repairSegments = repairSegmentRows
              .where((item) => item.containsKey('repairSegment'))
              .map((item) => item['repairSegment'] as String)
              .toList();
        });
      } else {
        print('Error: jcRepairSegment[\'rows\'] is not a List');
      }

      if (jcAssignSegment['rows'] is List) {
        List<dynamic> rows = jcAssignSegment['rows'];
        List<Map<String, dynamic>> assignSegmentRows =
            rows.whereType<Map<String, dynamic>>().toList();
        setState(() {
          jcAssignSegmentInfo = assignSegmentRows;
          _assignSegments = assignSegmentRows
              .where((item) => item.containsKey('assignSegment'))
              .map((item) => item['assignSegment'] as String)
              .toList();
        });
      } else {
        print('Error: jcAssignSegment[\'rows\'] is not a List');
      }

      if (dynamicType['rows'] is List) {
        List<dynamic> rows = dynamicType['rows'];
        List<Map<String, dynamic>> dynamicTypeRows =
            rows.whereType<Map<String, dynamic>>().toList();
        setState(() {
          jcDynamicTypeInfo = dynamicTypeRows;
          _dynamicTypes = dynamicTypeRows
              .where((item) => item.containsKey('name'))
              .map((item) => item['name'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败: $e')),
      );
    }
  }

  // 显示日期选择器
  Future<void> _selectDate(
      BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  // 提交临修信息的方法
  void _submitRepairInfo() {
    String repairSection = _repairSectionController.text;
    String assignedSection = _assignedSectionController.text;
    String powerType = _powerTypeController.text;
    String model = _modelController.text;
    String carNumber = _carNumberController.text;
    String plannedMonth = _plannedMonthController.text;
    String repairSystem = _repairSystemController.text;
    String repairProcess = _repairProcessController.text;
    String repairTimes = _repairTimesController.text;
    String estimatedStartDate = _estimatedStartDate?.toString() ?? '';
    String estimatedDeliveryDate = _estimatedDeliveryDate?.toString() ?? '';
    String estimatedDepartureDate = _estimatedDepartureDate?.toString() ?? '';
    String signer = _signerController.text;
    String maintenanceLocation = _maintenanceLocationController.text;
    String remarks = _remarksController.text;

    // 简单验证输入是否为空
    if (repairSection.isEmpty ||
        assignedSection.isEmpty ||
        powerType.isEmpty ||
        model.isEmpty ||
        carNumber.isEmpty ||
        plannedMonth.isEmpty ||
        repairSystem.isEmpty ||
        repairProcess.isEmpty ||
        repairTimes.isEmpty ||
        estimatedStartDate.isEmpty ||
        estimatedDeliveryDate.isEmpty ||
        estimatedDepartureDate.isEmpty ||
        signer.isEmpty ||
        maintenanceLocation.isEmpty ||
        remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写所有必填字段')),
      );
      return;
    }

    // 这里可以添加将信息发送到服务器或进行其他处理的逻辑
    print('排序: $_sort');
    print('承修段: $repairSection');
    print('配属段: $assignedSection');
    print('动力类型: $powerType');
    print('机型: $model');
    print('车号: $carNumber');
    print('计划月份: $plannedMonth');
    print('修制: $repairSystem');
    print('修程: $repairProcess');
    print('修次: $repairTimes');
    print('预计上台日期: $estimatedStartDate');
    print('预计交车日期: $estimatedDeliveryDate');
    print('预计离段日期: $estimatedDepartureDate');
    print('选择签收人: $signer');
    print('检修地点: $maintenanceLocation');
    print('备注: $remarks');

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 排序数字选择器
                    DropdownButtonFormField<int>(
                      value: _sort,
                      decoration: InputDecoration(
                        labelText: '排序',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(10, (index) => index + 1)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _sort = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    // 承修段下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedRepairSegment,
                      decoration: InputDecoration(
                        labelText: '承修段',
                        border: OutlineInputBorder(),
                      ),
                      items: _repairSegments
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRepairSegment = newValue;
                          //在jcRepairSegmentInfo中找到repairSegment
                          for (Map<String, dynamic> map
                              in jcRepairSegmentInfo) {
                            if (map['repairSegment'] == newValue) {
                              _selectedRepairSegmentKey = map['code'];
                              // print(_selectedRepairSegment);
                              // print(_selectedRepairSegmentKey);
                            }
                          }

                          _repairSectionController.text = newValue ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    // 配属段下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedAssignSegment,
                      decoration: InputDecoration(
                        labelText: '配属段',
                        border: OutlineInputBorder(),
                      ),
                      items: _assignSegments
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAssignSegment = newValue;
                          for (Map<String, dynamic> map
                              in jcAssignSegmentInfo) {
                            if (map['assignSegment'] == newValue) {
                              _selectedAssignSegmentKey = map['code'];
                            }
                          }
                          _assignedSectionController.text = newValue ?? '';
                        });
                      },
                    ),

                    SizedBox(height: 16.0),
                    // 动力类型输入框
                    DropdownButtonFormField<String>(
                      value: _selectedDynamicType,
                      decoration: InputDecoration(
                        labelText: '动力类型',
                        border: OutlineInputBorder(),
                      ),
                      items: 
                          _dynamicTypes.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDynamicType = newValue;
                          _powerTypeController.text = newValue ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    // 机型输入框
                    TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: '机型',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 车号输入框
                    TextField(
                      controller: _carNumberController,
                      decoration: InputDecoration(
                        labelText: '车号',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 计划月份输入框
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: '计划月份',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(12, (index) => index + 1)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedMonth = newValue;
                          for (Map<String, dynamic> map
                              in jcDynamicTypeInfo) {
                            if (map['name'] == newValue) {
                              _selectedDynamicTypeKey = map['code'];
                            }
                          }
                          _plannedMonthController.text =
                              newValue?.toString() ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    // 修制输入框
                    TextField(
                      controller: _repairSystemController,
                      decoration: InputDecoration(
                        labelText: '修制',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 修程输入框
                    TextField(
                      controller: _repairProcessController,
                      decoration: InputDecoration(
                        labelText: '修程',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 修次输入框
                    TextField(
                      controller: _repairTimesController,
                      decoration: InputDecoration(
                        labelText: '修次',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 预计上台日期选择器
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _estimatedStartDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(_estimatedStartDate!)
                            : '未选择',
                      ),
                      decoration: InputDecoration(
                        labelText: '预计上台日期',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedStartDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
// 预计交车日期选择器
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _estimatedDeliveryDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(_estimatedDeliveryDate!)
                            : '未选择',
                      ),
                      decoration: InputDecoration(
                        labelText: '预计交车日期',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedDeliveryDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
// 预计离段日期选择器
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _estimatedDepartureDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(_estimatedDepartureDate!)
                            : '未选择',
                      ),
                      decoration: InputDecoration(
                        labelText: '预计离段日期',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedDepartureDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 选择签收人输入框
                    TextField(
                      controller: _signerController,
                      decoration: InputDecoration(
                        labelText: '选择签收人',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 检修地点输入框
                    TextField(
                      controller: _maintenanceLocationController,
                      decoration: InputDecoration(
                        labelText: '检修地点',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // 备注输入框
                    TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 提交按钮置于底部，左右占满
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitRepairInfo,
              child: Text('提交临修信息'),
            ),
          ),
        ],
      ),
    );
  }

  void main() {
    runApp(MaterialApp(
      home: TemporaryRepairInfoPage(),
    ));
  }
}
