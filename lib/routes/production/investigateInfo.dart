import '../../index.dart';
import 'package:jcjx_phone/models/progress.dart';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';

class PlanListPage extends StatefulWidget {
  final RepairItem repairItem;
  final Map<String, dynamic>? shuntingItem;
  PlanListPage({required this.repairItem, this.shuntingItem});
  @override
  _PlanListPageState createState() => _PlanListPageState();
}

class _PlanListPageState extends State<PlanListPage> {
  var logger = AppLogger.logger;
  List<Map<String, dynamic>> investigateList = [];
  List<Map<String, dynamic>> repairProcList = []; // 修程列表

  @override
  void initState() {
    super.initState();
    getMasInvestigate(widget.repairItem);
    getRepairProc();
  }

  // /subparts/repairProc/selectAll
  Future<void> getRepairProc() async {
    try {
      Map<String, dynamic> queryParametrs = {
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getRepairProcMap(queryParametrs: queryParametrs);
      logger.i(r);
      
      // 处理返回的数据
      List<Map<String, dynamic>> rows = [];
      if (r != null) {
        if (r is Map && r.containsKey('rows')) {
          rows = List<Map<String, dynamic>>.from(r['rows'] ?? []);
        } else if (r is List) {
          rows = r.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      
      setState(() {
        repairProcList = rows;
      });
    } catch (e) {
      logger.e('获取修程列表失败: $e');
    }
  }

  Future<void> getMasInvestigate(RepairItem item) async {
    try {
      Map<String, dynamic> queryParametrs = {};
      if (widget.shuntingItem == null) {
        queryParametrs = {
          'trainEntryCode': item.code,
          // 'code': widget.shuntingItem != null
          //     ? widget.shuntingItem!['shuntingCode'] ?? ''
          //     : null,
        };
      } else {
        queryParametrs = {
          'trainEntryCode': item.code,
          'code': widget.shuntingItem != null
              ? widget.shuntingItem!['shuntingCode'] ?? ''
              : null,
        };
      }
      logger.i(queryParametrs);
      var r =
          await ProductApi().getMasInestigate(queryParametrs: queryParametrs);

      // 修复类型转换错误，确保返回的是List类型
      List<Map<String, dynamic>> rows = [];
      if (r != null && r is List) {
        rows = r.map((item) => item as Map<String, dynamic>).toList();
      }

      setState(() {
        investigateList = rows;
        logger.i(investigateList);
      });
    } catch (e) {
      logger.e('获取调查清单失败: $e');
      showToast('获取数据失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('调查清单'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.wifi),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: investigateList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // 第一项显示车号标题
              return Card(
                margin: EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '${widget.repairItem.typeName}-${widget.repairItem.repairProcName ?? ''}-${widget.repairItem.trainNum ?? ''}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final item = investigateList[index - 1];
            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 编号信息
                    Text(
                      '编号: ${item['encode'] ?? ''}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),

                    // 故障现象
                    Text(
                      '故障现象: ${item['faultInformation'] ?? ''}',
                    ),
                    SizedBox(height: 4),

                    // 故障类别
                    Text(
                      '故障类别: ${item['failureCategory'] ?? ''}',
                    ),
                    SizedBox(height: 4),

                    // 故障时间
                    Text(
                      '故障时间: ${item['faultDate'] ?? ''}',
                    ),
                    SizedBox(height: 4),

                    // 停留地点
                    Text(
                      '停留地点: ${item['trainLocation'] ?? ''}',
                    ),
                    SizedBox(height: 4),

                    // 停留地点
                    Text(
                      '填报人: ${item['reportUserName'] ?? ''}',
                    ),
                    SizedBox(height: 4),

                    // 填报时间
                    Text(
                      '填报时间: ${item['createdTime'] ?? ''}',
                    ),
                    SizedBox(height: 16),

                    // 操作按钮区域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // 查看详情操作
                            _showDetailView(context, item);
                          },
                          icon: Icon(Icons.visibility),
                          label: Text('查看'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // 编辑操作 - 在当前界面显示编辑弹窗
                            _showEditInvestigateDialog(context, item);
                          },
                          icon: Icon(Icons.edit),
                          label: Text('编辑'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 查看详情方法
  void _showDetailView(BuildContext context, Map<String, dynamic> item) {
      final masInvestigateList = item['masInvestigateListList'] ?? [];
    List<Map<String, dynamic>> mappedList = [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '编辑调查内容',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      // 基本信息展示
                      Text('编号: ${item['encode'] ?? ''}'),
                      SizedBox(height: 8),
                      Text('故障现象: ${item['faultInformation'] ?? ''}'),
                      SizedBox(height: 16),
                      // 修程公里数表格
                      _buildRepairKilometerTable(item),
                      SizedBox(height: 16),
                      // 调查内容列表
                      Text(
                        '其他作业项点',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      if (mappedList.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              '暂无调查内容',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...mappedList
                            .map((masItem) =>
                                _buildInvestigateItemCard(context, masItem))
                            .toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 编辑调查内容弹窗
  void _showEditInvestigateDialog(
      BuildContext context, Map<String, dynamic> item) {
    final masInvestigateList = item['masInvestigateListList'] ?? [];
    List<Map<String, dynamic>> mappedList = [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '编辑调查内容',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      // 基本信息展示
                      Text('编号: ${item['encode'] ?? ''}'),
                      SizedBox(height: 8),
                      Text('故障现象: ${item['faultInformation'] ?? ''}'),
                      SizedBox(height: 16),
                      // 修程公里数表格
                      _buildRepairKilometerTable(item),
                      SizedBox(height: 16),
                      // 保存修程公里数按钮
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _saveRepairKilometer(context, item);
                          },
                          icon: Icon(Icons.save),
                          label: Text('保存修程公里数'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // 调查内容列表
                      Text(
                        '其他作业项点',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      if (mappedList.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              '暂无调查内容',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...mappedList
                            .map((masItem) =>
                                _buildInvestigateItemCard(context, masItem))
                            .toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建修程公里数表格
  Widget _buildRepairKilometerTable(Map<String, dynamic> item) {
    return _RepairKilometerTableWidget(
      item: item,
      repairProcList: repairProcList,
      onDataChanged: () {
        // 数据变化时的回调，可以在这里处理
      },
    );
  }

  // 保存修程公里数
  Future<void> _saveRepairKilometer(
      BuildContext context, Map<String, dynamic> item) async {

    logger.i('保存修程公里数: ${item['masInvestigateProcList']}');
    try {
      SmartDialog.showLoading();

      // 获取masInvestigateProcList数组
      final masInvestigateProcList = item['masInvestigateProcList'] as List?;
      if (masInvestigateProcList == null || masInvestigateProcList.isEmpty) {
        SmartDialog.dismiss();
        SmartDialog.showToast('修程公里数数据为空');
        return;
      }

      // 准备保存的数据，包含masInvestigateProcList数组
      // 确保数据格式正确，移除null值，保留必要的字段
      List<Map<String, dynamic>> procListToSave = [];
      for (var proc in masInvestigateProcList) {
        if (proc is Map) {
          Map<String, dynamic> procMap = Map<String, dynamic>.from(proc);
          
          // 确保必要字段存在
          Map<String, dynamic> cleanProc = {
            'masInvestigateCode': procMap['masInvestigateCode'] ?? item['code'] ?? item['encode'] ?? '',
          };
          
          // 如果有code（已存在的记录），保留它
          if (procMap['code'] != null) {
            cleanProc['code'] = procMap['code'];
          }
          
          // 添加修程相关字段
          if (procMap['repairProcCode'] != null && procMap['repairProcCode'].toString().isNotEmpty) {
            cleanProc['repairProcCode'] = procMap['repairProcCode'];
          }
          if (procMap['repairProcName'] != null && procMap['repairProcName'].toString().isNotEmpty) {
            cleanProc['repairProcName'] = procMap['repairProcName'];
          }
          if (procMap['repairTimes'] != null && procMap['repairTimes'].toString().isNotEmpty) {
            cleanProc['repairTimes'] = procMap['repairTimes'];
          }
          if (procMap['repairKilometer'] != null) {
            cleanProc['repairKilometer'] = procMap['repairKilometer'];
          }
          if (procMap['repairDate'] != null && procMap['repairDate'].toString().isNotEmpty) {
            cleanProc['repairDate'] = procMap['repairDate'];
          }
          
          procListToSave.add(cleanProc);
        }
      }

      Map<String, dynamic> saveData = {
        'code': item['code'] ?? item['encode'], // 使用code或encode作为主键
        'masInvestigateProcList': procListToSave,
        'encode': item['encode'],
        'trainEntryCode': item['trainEntryCode'],
        'masInvestigateListList': item['masInvestigateListList'],
      };

      logger.i('保存修程公里数数据: $saveData');

      // 调用API保存数据
      await ProductApi().updateMasInvestigateList(saveData);

      SmartDialog.dismiss();
      SmartDialog.showToast('保存成功');

      // 刷新数据
      await getMasInvestigate(widget.repairItem);

      // 关闭弹窗
      Navigator.pop(context);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('保存失败: $e');
      logger.e('保存修程公里数失败: $e');
    }
  }

  // 构建调查项卡片
  Widget _buildInvestigateItemCard(
      BuildContext context, Map<String, dynamic> masItem) {
    return _InvestigateItemCardWidget(
      masItem: masItem,
      onSave: (result, selectedMedia) async {
        await _saveInvestigateResult(context, masItem, result, selectedMedia);
      },
    );
  }

  // 保存调查结果
  Future<void> _saveInvestigateResult(
    BuildContext context,
    Map<String, dynamic> masItem,
    String result,
    List<XFile> selectedMedia,
  ) async {
    try {
      SmartDialog.showLoading();

      // 如果有新选择的媒体文件，先上传
      if (selectedMedia.isNotEmpty) {
        Map<String, dynamic> queryParametrs = {
          "code": masItem['code'],
        };
        logger.i('上传媒体参数：$queryParametrs');

        // 上传媒体到服务器
        var uploadResponse = await ProductApi().uploadShuntingInfo(
            data: selectedMedia.map((xFile) => File(xFile.path)).toList(),
            code: masItem['code'],
        );

        logger.i('文件上传成功: $uploadResponse');
      }

      // 更新调查内容
      await ProductApi().updateMasInvestigateList({
        'code': masItem['code'],
        'investigateResult': result,
      });

      SmartDialog.dismiss();
      SmartDialog.showToast('保存成功');

      // 刷新数据
      await getMasInvestigate(widget.repairItem);

      // 关闭弹窗
      Navigator.pop(context);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('保存失败: $e');
      logger.e('保存调查结果失败: $e');
    }
  }
}

// 修程公里数表格组件
class _RepairKilometerTableWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> repairProcList;
  final VoidCallback? onDataChanged;

  const _RepairKilometerTableWidget({
    required this.item,
    required this.repairProcList,
    this.onDataChanged,
  });

  @override
  _RepairKilometerTableWidgetState createState() => _RepairKilometerTableWidgetState();
}

class _RepairKilometerTableWidgetState extends State<_RepairKilometerTableWidget> {
  // 存储修程公里数列表
  List<Map<String, dynamic>> repairProcList = [];
  
  // TextField controllers - 使用Map来存储每个记录的controller
  Map<String, TextEditingController> kilometerControllers = {};

  @override
  void initState() {
    super.initState();
    _loadRepairProcList();
  }

  // 从item中加载masInvestigateProcList数据
  void _loadRepairProcList() {
    final masInvestigateProcList = widget.item['masInvestigateProcList'];
    if (masInvestigateProcList != null && masInvestigateProcList is List) {
      repairProcList = masInvestigateProcList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      // 为每个记录创建controller
      for (var proc in repairProcList) {
        final code = proc['code']?.toString() ?? '';
        final key = code.isNotEmpty ? code : 'new_${repairProcList.indexOf(proc)}';
        kilometerControllers[key] = TextEditingController(
          text: proc['repairKilometer']?.toString() ?? '',
        );
      }
    } else {
      // 如果没有数据，初始化为空列表
      repairProcList = [];
      // 确保masInvestigateProcList存在
      if (widget.item['masInvestigateProcList'] == null) {
        widget.item['masInvestigateProcList'] = [];
      }
    }
  }

  // 新增修程公里数行
  void _addRepairProcRow() {
    setState(() {
      // 创建新行数据
      final newRow = {
        'code': null, // 新增行没有code
        'masInvestigateCode': widget.item['code'] ?? widget.item['encode'] ?? '',
        'repairProcCode': '',
        'repairProcName': '',
        'repairTimes': '',
        'repairKilometer': null,
        'repairDate': null,
      };
      
      repairProcList.add(newRow);
      
      // 同步添加到原始数据
      final masInvestigateProcList = widget.item['masInvestigateProcList'] as List;
      masInvestigateProcList.add(newRow);
      
      // 为新行创建controller
      final key = 'new_${repairProcList.length - 1}';
      kilometerControllers[key] = TextEditingController();
    });
  }

  // 删除修程公里数行
  void _deleteRepairProcRow(int index) {
    if (index < 0 || index >= repairProcList.length) return;
    
    setState(() {
      // 释放controller
      final proc = repairProcList[index];
      final code = proc['code']?.toString() ?? '';
      final key = code.isNotEmpty ? code : 'new_$index';
      kilometerControllers[key]?.dispose();
      kilometerControllers.remove(key);
      
      // 从列表中删除
      repairProcList.removeAt(index);
      
      // 同步从原始数据中删除
      final masInvestigateProcList = widget.item['masInvestigateProcList'] as List;
      if (index < masInvestigateProcList.length) {
        masInvestigateProcList.removeAt(index);
      }
      
      // 重新创建controllers（因为索引改变了）
      kilometerControllers.clear();
      for (var i = 0; i < repairProcList.length; i++) {
        final proc = repairProcList[i];
        final code = proc['code']?.toString() ?? '';
        final key = code.isNotEmpty ? code : 'new_$i';
        kilometerControllers[key] = TextEditingController(
          text: proc['repairKilometer']?.toString() ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    // 释放所有controllers
    for (var controller in kilometerControllers.values) {
      controller.dispose();
    }
    kilometerControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 格式化日期显示
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        DateTime date = DateTime.parse(dateStr);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        return dateStr;
      }
    }

    // 解析日期
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // 选择修程
    Future<void> selectRepairProc(int index) async {
      if (widget.repairProcList.isEmpty) {
        showToast('修程列表为空，请稍后再试');
        return;
      }
      
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('选择修程'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.repairProcList.length,
              itemBuilder: (context, idx) {
                final proc = widget.repairProcList[idx];
                return ListTile(
                  title: Text(proc['name']?.toString() ?? proc['repairProcName']?.toString() ?? ''),
                  onTap: () {
                    Navigator.pop(context, proc);
                  },
                );
              },
            ),
          ),
        ),
      );

      if (selected != null && index < repairProcList.length) {
        setState(() {
          repairProcList[index]['repairProcCode'] = selected['code']?.toString() ?? '';
          repairProcList[index]['repairProcName'] = selected['name']?.toString() ?? selected['repairProcName']?.toString() ?? '';
        });
        // 同步更新原始数据
        final masInvestigateProcList = widget.item['masInvestigateProcList'] as List?;
        if (masInvestigateProcList != null) {
          // 确保列表长度一致
          while (masInvestigateProcList.length < repairProcList.length) {
            masInvestigateProcList.add({});
          }
          if (index < masInvestigateProcList.length) {
            masInvestigateProcList[index]['repairProcCode'] = selected['code']?.toString() ?? '';
            masInvestigateProcList[index]['repairProcName'] = selected['name']?.toString() ?? selected['repairProcName']?.toString() ?? '';
          }
        }
      }
    }

    // 选择日期
    Future<void> selectDate(int index) async {
      if (index >= repairProcList.length) return;
      
      final proc = repairProcList[index];
      final currentDate = parseDate(proc['repairDate']) ?? DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        locale: const Locale('zh', 'CN'),
        helpText: '选择修程日期',
        cancelText: '取消',
        confirmText: '确定',
      );

      if (pickedDate != null) {
        final dateStr = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
        setState(() {
          repairProcList[index]['repairDate'] = dateStr;
        });
        // 同步更新原始数据
        final masInvestigateProcList = widget.item['masInvestigateProcList'] as List?;
        if (masInvestigateProcList != null) {
          // 确保列表长度一致
          while (masInvestigateProcList.length < repairProcList.length) {
            masInvestigateProcList.add({});
          }
          if (index < masInvestigateProcList.length) {
            masInvestigateProcList[index]['repairDate'] = dateStr;
          }
        }
      }
    }

    // 获取或创建controller
    TextEditingController getKilometerController(int index) {
      if (index >= repairProcList.length) {
        // 如果索引超出范围，创建一个临时controller
        final key = 'temp_$index';
        if (!kilometerControllers.containsKey(key)) {
          kilometerControllers[key] = TextEditingController();
        }
        return kilometerControllers[key]!;
      }
      
      final proc = repairProcList[index];
      final code = proc['code']?.toString() ?? '';
      final key = code.isNotEmpty ? code : 'new_$index';
      
      if (!kilometerControllers.containsKey(key)) {
        kilometerControllers[key] = TextEditingController(
          text: proc['repairKilometer']?.toString() ?? '',
        );
      }
      return kilometerControllers[key]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '修程公里数',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(0.5),
          },
          children: [
            // 表头
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('修程', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('修次', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('走行公里', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('修程日期', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('操作', textAlign: TextAlign.center),
                ),
              ],
            ),
            // 动态生成数据行
            ...repairProcList.asMap().entries.map((entry) {
              final index = entry.key;
              final proc = entry.value;
              
              return TableRow(
                children: [
                  // 修程
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => selectRepairProc(index),
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          proc['repairProcName']?.toString() ?? '点击选择',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  // 修次
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      proc['repairTimes']?.toString() ?? '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 走行公里
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: getKilometerController(index),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onChanged: (value) {
                        final numValue = value.isEmpty ? null : double.tryParse(value);
                        repairProcList[index]['repairKilometer'] = numValue;
                        // 同步更新原始数据
                        final masInvestigateProcList = widget.item['masInvestigateProcList'] as List?;
                        if (masInvestigateProcList != null) {
                          // 确保列表长度一致
                          while (masInvestigateProcList.length < repairProcList.length) {
                            masInvestigateProcList.add({});
                          }
                          if (index < masInvestigateProcList.length) {
                            masInvestigateProcList[index]['repairKilometer'] = numValue;
                          }
                        }
                      },
                    ),
                  ),
                  // 修程日期
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => selectDate(index),
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formatDate(proc['repairDate']) != '' 
                              ? formatDate(proc['repairDate']) 
                              : '点击选择',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  // 删除按钮
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRepairProcRow(index),
                      tooltip: '删除',
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        SizedBox(height: 10),
        // 新增按钮
        ElevatedButton.icon(
          onPressed: _addRepairProcRow,
          icon: Icon(Icons.add),
          label: Text('新增修程公里数'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// 调查项卡片组件（带文件上传功能）
class _InvestigateItemCardWidget extends StatefulWidget {
  final Map<String, dynamic> masItem;
  final Function(String result, List<XFile> selectedMedia) onSave;

  const _InvestigateItemCardWidget({
    required this.masItem,
    required this.onSave,
  });

  @override
  _InvestigateItemCardWidgetState createState() =>
      _InvestigateItemCardWidgetState();
}

class _InvestigateItemCardWidgetState
    extends State<_InvestigateItemCardWidget> {
  late TextEditingController resultController;
  List<XFile> _selectedMedia = [];
  List<String> _uploadedMedia = [];

  @override
  void initState() {
    super.initState();
    resultController = TextEditingController(
      text: widget.masItem['investigateResult'] as String? ?? '',
    );

    // 加载已上传的媒体
    if (widget.masItem['mediaUrls'] != null) {
      _uploadedMedia = List<String>.from(widget.masItem['mediaUrls']);
    }
  }

  @override
  void dispose() {
    resultController.dispose();
    super.dispose();
  }

  // 判断文件是否为视频
  bool _isVideoFile(XFile file) {
    final String path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.wmv') ||
        path.endsWith('.mkv');
  }

  // 判断URL是否为视频
  bool _isVideoUrl(String url) {
    final String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.mov') ||
        lowerUrl.contains('.avi') ||
        lowerUrl.contains('.wmv') ||
        lowerUrl.contains('.mkv');
  }

  // 选择媒体文件
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final ImagePicker _picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        if (isVideo) {
          final XFile? video = await _picker.pickVideo(source: source);
          if (video != null) {
            setState(() {
              _selectedMedia.add(video);
            });
          }
        } else {
          final XFile? photo =
              await _picker.pickImage(source: source, imageQuality: 80);
          if (photo != null) {
            setState(() {
              _selectedMedia.add(photo);
            });
          }
        }
      } else {
        if (isVideo) {
          final XFile? video = await _picker.pickVideo(source: source);
          if (video != null) {
            setState(() {
              _selectedMedia.add(video);
            });
          }
        } else {
          final List<XFile> images =
              await _picker.pickMultiImage(imageQuality: 80);
          if (images.isNotEmpty) {
            setState(() {
              _selectedMedia.addAll(images);
            });
          }
        }
      }
    } catch (e) {
      SmartDialog.showToast('选择媒体失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('排序: ${widget.masItem['sort'] ?? ''}'),
            SizedBox(height: 4),
            Text('作业项点: ${widget.masItem['investigateTitle'] ?? ''}'),
            SizedBox(height: 4),
            Text('二级作业项点: ${widget.masItem['investigateContent'] ?? ''}'),
            SizedBox(height: 4),
            Text('调查部门: ${widget.masItem['deptName'] ?? ''}'),
            SizedBox(height: 4),
            Text('指派调查班组: ${widget.masItem['teamName'] ?? ''}'),
            SizedBox(height: 4),
            Text('调查人: ${widget.masItem['reportUserName'] ?? ''}'),
            SizedBox(height: 12),
            // 调查结果输入框 - 增加行数
            TextField(
              controller: resultController,
              decoration: InputDecoration(
                labelText: '调查结果',
                border: OutlineInputBorder(),
                hintText: '请输入调查结果',
              ),
              maxLines: 10,
              minLines: 5,
            ),
            SizedBox(height: 16),
            // 上传附件区域
            Text(
              '上传附件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // 显示已上传的媒体
            if (_uploadedMedia.isNotEmpty) ...[
              Text('已上传附件:', style: TextStyle(fontSize: 14)),
              SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _uploadedMedia.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // 预览已上传的媒体
                              _previewUploadedMedia(_uploadedMedia[index]);
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isVideoUrl(_uploadedMedia[index])
                                  ? Icon(Icons.video_library,
                                      size: 60, color: Colors.blue)
                                  : Image.network(
                                      _uploadedMedia[index],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 15),
            ],
            // 显示新选择的媒体
            if (_selectedMedia.isNotEmpty) ...[
              Text('待上传附件:', style: TextStyle(fontSize: 14)),
              SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final media = _selectedMedia[index];
                    final isVideo = _isVideoFile(media);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // 预览选择的媒体
                              _previewSelectedMedia(media);
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isVideo
                                  ? Icon(Icons.videocam,
                                      size: 60, color: Colors.blue)
                                  : FutureBuilder<Uint8List?>(
                                      future: media.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                      },
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMedia.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                color: Colors.red.withOpacity(0.8),
                                child: const Icon(
                                  Icons.close,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 15),
            ],
            // 添加媒体按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.camera, false);
                    },
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const Text('拍照', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.camera, true);
                    },
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('录像', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.gallery, false);
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('图库', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onSave(resultController.text, _selectedMedia);
                },
                child: Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 预览已上传的媒体
  void _previewUploadedMedia(String mediaUrl) {
    if (_isVideoUrl(mediaUrl)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _VideoPreviewPage(videoUrl: mediaUrl),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImagePreviewPage(imageUrl: mediaUrl),
        ),
      );
    }
  }

  // 预览已选择的媒体
  void _previewSelectedMedia(XFile media) {
    if (_isVideoFile(media)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _VideoPreviewPage(videoFile: media),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImagePreviewPage(imageFile: media),
        ),
      );
    }
  }
}

// 图片预览页面
class _ImagePreviewPage extends StatelessWidget {
  final String? imageUrl;
  final XFile? imageFile;

  const _ImagePreviewPage({this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片预览'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: imageUrl != null
            ? Image.network(imageUrl!)
            : imageFile != null
                ? FutureBuilder<Uint8List?>(
                    future: imageFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Image.memory(snapshot.data!);
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  )
                : const Icon(Icons.error),
      ),
    );
  }
}

// 视频预览页面
class _VideoPreviewPage extends StatefulWidget {
  final String? videoUrl;
  final XFile? videoFile;

  const _VideoPreviewPage({this.videoUrl, this.videoFile});

  @override
  _VideoPreviewPageState createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.videoUrl != null) {
      _controller = VideoPlayerController.network(widget.videoUrl!);
    } else if (widget.videoFile != null) {
      _controller = VideoPlayerController.file(File(widget.videoFile!.path));
    }

    _controller.initialize().then((_) {
      setState(() {
        _initialized = true;
      });
      _controller.play();
    }).catchError((error) {
      SmartDialog.showToast('视频加载失败: $error');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频预览'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
