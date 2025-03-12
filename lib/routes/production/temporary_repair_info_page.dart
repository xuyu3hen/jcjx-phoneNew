
import 'package:intl/intl.dart';
import '../../index.dart';

class TemporaryRepairInfoPage extends StatefulWidget {
  const TemporaryRepairInfoPage({super.key});

  @override
  State createState() =>
      _TemporaryRepairInfoPageState();
}

class _TemporaryRepairInfoPageState extends State<TemporaryRepairInfoPage> {
 
    // 创建 Logger 实例
  var logger = AppLogger.logger;
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
    getStopLocation();
    getDeptTreeByParentIdList();
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

  //机型
  List<Map<String, dynamic>> jcTypeInfo = [];
  List<String> _types = [];
  String? _selectedType;
  String? _selectedTypeKey;

  // 修制信息
  List<Map<String, dynamic>> jcRepairInfo = [];
  List<String> _repairInfos = [];
  String? _selectedRepairInfo;
  String? _selectedRepairInfoKey;

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
      logger.i('API Response: $jcRepairSegment');
      logger.i('API Response: $jcAssignSegment');

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
        logger.i('Error: jcRepairSegment[\'rows\'] is not a List');
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
        logger.i('Error: jcAssignSegment[\'rows\'] is not a List');
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
      logger.e('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败: $e')),
      );
    }
  }

  // 修制信息
  List<Map<String, dynamic>> deptInfo = [];
  List<String> deptInfos = [];
  String? _selectDeptName;
  int? _selectedDeptKey;
  // getDeptTreeByParentIdList 选择签收人
  //  获取所有部门
  Future<void> getDeptTreeByParentIdList() async {
    Map<String, dynamic> queryParameters = {};

    queryParameters['parentIdList'] = 101;
    try {
      List<dynamic> info = await ProductApi()
          .getDeptTreeByParentIdList(queryParametrs: queryParameters);
      if (info[0]['children'] is List) {
        List<dynamic> rows = info[0]['children'];
        logger.i(info[0]['children'].toString());
        List<Map<String, dynamic>> deptRows =
            rows.whereType<Map<String, dynamic>>().toList();
        logger.i(deptRows.toString());
        setState(() {
          deptInfo = deptRows;
          deptInfos = deptRows
              .where((item) => item.containsKey('deptName'))
              .map((item) => item['deptName'] as String)
              .toList();
          logger.i(deptInfos.toString());
        });
      }
    } catch (e) {
      logger.i('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败: $e')),
      );
    }
  }

//部门用户信息
  List<Map<String, dynamic>> deptUserInfo = [];
  List<String> deptUserInfos = [];
  String? selectNickName;
  String? selectUserId;

  List<String> selectedEmployees = [];

  //获取部门人员
  Future<void> getDeptUserInfo(int? deptId) async {
    Map<String, dynamic> queryParameters = {};

    queryParameters['deptId'] = deptId;
    try {
      List<dynamic> info = await ProductApi()
          .getUserListByDeptId(queryParametrs: queryParameters);
      List<Map<String, dynamic>> userRows =
          info.whereType<Map<String, dynamic>>().toList();
      logger.i(userRows.toString());
      setState(() {
        deptUserInfo = userRows;
        deptUserInfos = userRows
            .where((item) => item.containsKey('nickName'))
            .map((item) => item['nickName'] as String)
            .toList();
        logger.i(deptUserInfos.toString());
      });
    } catch (e) {
      logger.i('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败: $e')),
      );
    }
  }

  Future<void> getJcTypeInfo(String? code) async {
    Map<String, dynamic> queryParameters = {};
    queryParameters['pageNum'] = 0;
    queryParameters['pageSize'] = 0;
    queryParameters['dynamicCode'] = code;
    Map<String, dynamic> jcTypeInfo1 =
        await ProductApi().getJcTypeInfo(queryParametrs: queryParameters);
    if (jcTypeInfo1['rows'] is List) {
      List<dynamic> rows = jcTypeInfo1['rows'];
      List<Map<String, dynamic>> jcTypeRows =
          rows.whereType<Map<String, dynamic>>().toList();
      setState(() {
        jcTypeInfo = jcTypeRows;
        _types = jcTypeRows
            .where((item) => item.containsKey('name'))
            .map((item) => item['name'] as String)
            .toList();
        for (var element in _types) {
          logger.i(element);
        }
      });
    } else {
      logger.i('Error: jcAssignSegment[\'rows\'] is not a List');
    }
  }

  //获取修制
  Future<void> getJcRepairInfo(String? code) async {
    Map<String, dynamic> queryParameters = {};
    queryParameters['pageNum'] = 0;
    queryParameters['pageSize'] = 0;
    queryParameters['dynamicCode'] = code;
    Map<String, dynamic> jcRepairInfoDynamic =
        await ProductApi().getRepairSys(queryParametrs: queryParameters);
    if (jcRepairInfoDynamic['rows'] is List) {
      List<dynamic> rows = jcRepairInfoDynamic['rows'];
      List<Map<String, dynamic>> jcRepairRows =
          rows.whereType<Map<String, dynamic>>().toList();
      setState(() {
        jcRepairInfo = jcRepairRows;
        _repairInfos = jcRepairRows
            .where((item) => item.containsKey('name'))
            .map((item) => item['name'] as String)
            .toList();
      });
    }
  }

  //修程信息
  List<Map<String, dynamic>> jcRepairProcessInfo = [];
  List<String> _repairProcesses = [];
  String? _selectedRepairProcess;
  String? _selectedRepairProcessKey;

  //获取修程
  Future<void> getJcRepairProcess(String? code) async {
    Map<String, dynamic> queryParameters = {};
    queryParameters['pageNum'] = 0;
    queryParameters['pageSize'] = 0;
    queryParameters['repairSysCode'] = code;
    logger.i(queryParameters);
    Map<String, dynamic> jcRepairProcess =
        await ProductApi().getRepairProcMap(queryParametrs: queryParameters);
    logger.i('jcRepairProcess: $jcRepairProcess');
    if (jcRepairProcess['rows'] is List) {
      List<dynamic> rows = jcRepairProcess['rows'];
      List<Map<String, dynamic>> jcRepairProcessRows =
          rows.whereType<Map<String, dynamic>>().toList();
      setState(() {
        jcRepairProcessInfo = jcRepairProcessRows;
        _repairProcesses = jcRepairProcessRows
            .where((item) => item.containsKey('name'))
            .map((item) => item['name'] as String)
            .toList();
        logger.i(_repairProcesses.toString());
      });
    }
  }

  //修次信息
  List<Map<String, dynamic>> jcRepairTimesInfo = [];
  List<String> _repairTimes = [];
  String? _selectedRepairTime;
  String? _selectedRepairTimeKey;

  //获取修次
  Future<void> getJcRepairTimes(String? code) async {
    Map<String, dynamic> queryParameters = {};
    queryParameters['pageNum'] = 0;
    queryParameters['pageSize'] = 0;
    queryParameters['repairProcCode'] = code;
    Map<String, dynamic> jcRepairTimes = await ProductApi()
        .getRepairTimesDynamic(queryParametrs: queryParameters);
    if (jcRepairTimes['rows'] is List) {
      List<dynamic> rows = jcRepairTimes['rows'];
      List<Map<String, dynamic>> jcRepairTimesRows =
          rows.whereType<Map<String, dynamic>>().toList();
      setState(() {
        jcRepairTimesInfo = jcRepairTimesRows;
        _repairTimes = jcRepairTimesRows
            .where((item) => item.containsKey('name'))
            .map((item) => item['name'] as String)
            .toList();
      });
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
    Map<String, dynamic> queryParameters = {};
    queryParameters['arrivePlatFomTime'] = _estimatedStartDate;
    queryParameters['leaveDeptTime'] = _estimatedDepartureDate;
    queryParameters['deliverTrainTime'] = _estimatedDeliveryDate;
    queryParameters['attachDept'] = _selectedAssignSegment;
    queryParameters['attachSegmentCode'] = _selectedAssignSegmentKey;
    queryParameters['dynamicName'] = _selectedDynamicType;
    queryParameters['dynamicCode'] = _selectedDynamicTypeKey;
    queryParameters['month'] = _selectedMonth;
    queryParameters['remarks'] = _remarksController.text;
    queryParameters['repairDept'] = _selectedRepairSegment;
    queryParameters['repairLocationCode'] = _selectedRepairSegmentKey;
    queryParameters['repairProc'] = _selectedRepairProcess;
    queryParameters['repairProcCode'] = _selectedRepairProcessKey;
    queryParameters['repairSegmentCode'] = _selectedRepairSegmentKey;
    queryParameters['repairTimes'] = _selectedRepairTime;
    queryParameters['sort'] = _sort;
    queryParameters['status'] = 0;
    queryParameters['trainNum'] = _carNumberController.text;
    queryParameters['trainType'] = _selectedType;
    queryParameters['trainTypeCode'] = _selectedTypeKey;
    List<Map<String, dynamic>> shuntingNoticeList = [];
    for (var element in deptUserInfos) {
      Map<String, dynamic> map = {};
      map['applyUserId'] = Global.profile.permissions?.user.userId;
      map['applyUserName'] = Global.profile.permissions?.user.nickName;
      //需要将其与信息进行绑定。现在是默认的
      map['auditDeptId'] = 231;
      map['auditDeptName'] = '总成车间';
      map['auditUserId'] = 1026;
      map['auditUserName'] = '赖文圣';
      map['status'] = 0;
      shuntingNoticeList.add(map);
    }
    // 显示提交成功的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('临修信息提交成功')),
    );
  }

  // 存储选择的检修地点信息
  String? stopLocationSelected;
  List<Map<String, dynamic>> stopLocationList = [];
  List<String> stopLocationListStr = [];
  void getStopLocation() async {
    var r = await ProductApi().getstopLocation({
      'pageNum': 1,
      'pageSize': 10,
    });
    List<Map<String, dynamic>> processedStopLocations = [];
    if (r.rows != null && r.rows!.isNotEmpty) {
      for (var item in r.rows!) {
        if (item.areaName != null &&
            item.deptName != null &&
            item.trackNum != null) {
          processedStopLocations.add({
            'code': item.code,
            'deptName': item.deptName,
            'realLocation': '${item.deptName}-${item.trackNum}-${item.areaName}'
          });
          stopLocationListStr
              .add('${item.deptName}-${item.trackNum}-${item.areaName}');
        }
      }
    }
    setState(() {
      stopLocationList = processedStopLocations;
      logger.i(stopLocationList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('临修信息页面'),
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
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16.0),
                    // 承修段下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedRepairSegment,
                      decoration: const InputDecoration(
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
                          _selectedRepairSegmentKey = '';
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
                    const SizedBox(height: 16.0),
                    // 配属段下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedAssignSegment,
                      decoration: const InputDecoration(
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
                          _selectedAssignSegmentKey = null;
                          for (Map<String, dynamic> map
                              in jcAssignSegmentInfo) {
                            if (map['name'] == newValue) {
                              _selectedAssignSegmentKey = map['code'];
                            }
                          }
                          _assignedSectionController.text = newValue ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 16.0),
                    // 动力类型输入框
                    DropdownButtonFormField<String>(
                      value: _selectedDynamicType,
                      decoration: const InputDecoration(
                        labelText: '动力类型',
                        border: OutlineInputBorder(),
                      ),
                      items: _dynamicTypes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDynamicType = newValue;
                          _selectedTypeKey = null;
                          for (Map<String, dynamic> map in jcDynamicTypeInfo) {
                            if (map['name'] == newValue) {
                              _selectedTypeKey = map['code'];
                            }
                          }
                          _powerTypeController.text = newValue ?? '';
                          getJcTypeInfo(_selectedTypeKey);
                          getJcRepairInfo(_selectedTypeKey);
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // 机型选项
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: '机型',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _types.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue;
                          _selectedTypeKey = null;
                          for (Map<String, dynamic> map in jcTypeInfo) {
                            if (map['name'] == newValue) {
                              _selectedTypeKey = map['code'];
                            }
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16.0),
                    // 车号输入框
                    TextField(
                      controller: _carNumberController,
                      decoration: const InputDecoration(
                        labelText: '车号',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // 计划月份输入框
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
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
                          for (Map<String, dynamic> map in jcDynamicTypeInfo) {
                            if (map['name'] == newValue) {
                              _selectedDynamicTypeKey = map['code'];
                            }
                          }
                          _plannedMonthController.text =
                              newValue?.toString() ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // 修制下拉框选择
                    // 修制下拉框选择
                    DropdownButtonFormField<String>(
                      value: _selectedRepairInfo,
                      decoration: const InputDecoration(
                        labelText: '修制',
                        border: OutlineInputBorder(),
                      ),
                      items: _repairInfos
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRepairInfo = newValue;
                          _selectedRepairInfoKey = null;
                          for (Map<String, dynamic> map in jcRepairInfo) {
                            if (map['name'] == newValue) {
                              _selectedRepairInfoKey = map['code'];
                              break; // 找到匹配项后退出循环
                            }
                          }
                          logger.i(_selectedRepairInfoKey); //修程列表
                          getJcRepairProcess(_selectedRepairInfoKey);
                          _selectedRepairProcess =
                              null; // 初始化 _selectedRepairProcess
                          _repairProcesses = []; // 清空 _repairProcesses
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // 修程下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedRepairProcess,
                      decoration: const InputDecoration(
                        labelText: '修程',
                        border: OutlineInputBorder(),
                      ),
                      items: _repairProcesses
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRepairProcess = newValue;
                            _selectedRepairProcessKey = null;
                            for (Map<String, dynamic> map
                                in jcRepairProcessInfo) {
                              if (map['name'] == newValue) {
                                _selectedRepairProcessKey = map['code'];
                                break; // 找到匹配项后退出循环
                              }
                            }
                            // 修次列表
                            getJcRepairTimes(_selectedRepairProcessKey);
                            _selectedRepairTime =
                                null; // 初始化 _selectedRepairProcess
                            _repairTimes = []; // 清空 _repairProcesses
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16.0),
                                      
                    // 修次下拉框
                    DropdownButtonFormField<String>(
                      value: _selectedRepairTime,
                      decoration: const InputDecoration(
                        labelText: '修次',
                        border: OutlineInputBorder(),
                      ),
                      items: _repairTimes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRepairTime = newValue;
                            _selectedRepairTimeKey = null;
                            for (Map<String, dynamic> map
                                in jcRepairTimesInfo) {
                              if (map['name'] == newValue) {
                                _selectedRepairTimeKey = map['code'];
                                break; // 找到匹配项后退出循环
                              }
                            }
                            
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
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
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedStartDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
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
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedDeliveryDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
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
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, (date) {
                            setState(() {
                              _estimatedDepartureDate = date;
                            });
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // 选择部门
                    // 修次下拉框
                    // 部门选择下拉框
                    DropdownButtonFormField<String>(
                      value: _selectDeptName,
                      decoration: const InputDecoration(
                        labelText: '选择部门',
                        border: OutlineInputBorder(),
                      ),
                      items: deptInfos
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectDeptName = newValue;
                            _selectedDeptKey = null;
                            for (Map<String, dynamic> map in deptInfo) {
                              if (map['deptName'] == newValue) {
                                _selectedDeptKey = map['deptId'];
                                break; // 找到匹配项后退出循环
                              }
                            }
                            getDeptUserInfo(_selectedDeptKey);
                            //初始化
                            // selectNickName = null; // 初始化 _selectedRepairProcess
                            // deptUserInfos = [];
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    // 人员多选列表
                    if (_selectDeptName != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: deptUserInfos.map((employee) {
                          return CheckboxListTile(
                            title: Text(employee),
                            value: selectedEmployees.contains(employee),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value != null) {
                                  if (value) {
                                  
                                    selectedEmployees.add(employee);
                                  } else {
                                    selectedEmployees.remove(employee);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    // 检修地点下拉框
                    DropdownButtonFormField<String>(
                      value: stopLocationSelected,
                      decoration: const InputDecoration(
                        labelText: '检修地点',
                        border: OutlineInputBorder(),
                      ),
                      items: stopLocationListStr
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            stopLocationSelected = newValue;
                            for (Map<String, dynamic> map in stopLocationList) {
                              if (map['name'] == newValue) {
                                _selectedRepairTimeKey = map['code'];
                                break; // 找到匹配项后退出循环
                              }
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16.0),
                    // 备注输入框
                    TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: const InputDecoration(
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
              child: const Text('提交临修信息'),
            ),
          ),
        ],
      ),
    );
  }

  void main() {
    runApp(const MaterialApp(
      home: TemporaryRepairInfoPage(),
    ));
  }
}
