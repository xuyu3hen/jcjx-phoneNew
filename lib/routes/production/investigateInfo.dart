import '../../index.dart';
import 'package:jcjx_phone/models/progress.dart';
import 'dart:typed_data';

import 'investigateInfo_edit.dart';

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

  @override
  void initState() {
    super.initState();
    getMasInvestigate(widget.repairItem);
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
                            // 编辑操作

                            // _showInvestigateInputDialog(
                            //     context, widget.repairItem, item);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvestigateDetailPage(
                                  investigateItem: item,
                                  repairItem: widget.repairItem,
                                ),
                              ),
                            );
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

  void _showInvestigateInputDialog(BuildContext context, RepairItem item,
      Map<String, dynamic> investigateItem) {
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _resultController = TextEditingController();
    final masInvestigateList = investigateItem['masInvestigateListList'] ?? [];
    final shuntingNoticeList = investigateItem['shuntingNoticeList'] ?? [];
    List<Map<String, dynamic>> mappedList = [];
    List<Map<String, dynamic>> shuntingMappedList = [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    if (shuntingNoticeList is List) {
      shuntingMappedList = shuntingNoticeList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('填写调查内容与签收情况'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //展示mappedList内容
                //标题是调查内容
                const Text(
                  '调查内容',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: mappedList.length,
                    itemBuilder: (context, index) {
                      final masItem = mappedList[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('调查内容发布人: ${masItem['createdBy'] ?? ''}'),
                              Text('发布时间: ${masItem['createdTime'] ?? ''}'),
                              Text(
                                  '调查内容: ${masItem['investigateContent'] ?? ''}'),
                              Text(
                                  '调查结果: ${masItem['investigateResult'] ?? ''}'),
                              Text('调查部门: ${masItem['deptName'] ?? ''}'),
                              Text('调查班组: ${masItem['teamName'] ?? ''}'),
                              Text('调查人: ${masItem['reportUserName'] ?? ''}'),
                              // 自己的部门或者父部门
                              // if (Global.profile.permissions?.user.deptId ==
                              //         masItem['deptId'] ||
                              //     Global.profile.permissions?.user.dept
                              //             ?.parentId ==
                              //         masItem['deptId'])
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // _showEditInvestigateDialog(
                                    //     context, item, masItem);
                                  },
                                  child: const Text('编辑'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 查看详情方法
  void _showDetailView(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '调查详情',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(),
              SizedBox(height: 10),
              Text('编号: ${item['encode'] ?? ''}'),
              SizedBox(height: 8),
              Text('故障现象: ${item['faultInformation'] ?? ''}'),
              SizedBox(height: 8),
              Text('故障类别: ${item['failureCategory'] ?? ''}'),
              SizedBox(height: 8),
              Text('故障时间: ${item['faultDate'] ?? ''}'),
              SizedBox(height: 8),
              Text('停留地点: ${item['trainLocation'] ?? ''}'),
              SizedBox(height: 8),
              Text('填报时间: ${item['createdTime'] ?? ''}'),
              SizedBox(height: 8),
              Text('调查内容: ${item['investigateContent'] ?? ''}'),
              SizedBox(height: 8),
              Text('签收情况: ${item['signStatus'] ?? ''}'),
              Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 添加一个新的页面类来展示调查内容
class InvestigateDetailPage extends StatefulWidget {
  final Map<String, dynamic> investigateItem;
  final RepairItem repairItem;

  const InvestigateDetailPage(
      {super.key, required this.investigateItem, required this.repairItem});

  @override
  _InvestigateDetailPageState createState() => _InvestigateDetailPageState();
}

class _InvestigateDetailPageState extends State<InvestigateDetailPage> {
  List<Map<String, dynamic>> mappedList = [];
  List<Map<String, dynamic>> shuntingMappedList = [];
  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    final masInvestigateList =
        widget.investigateItem['masInvestigateListList'] ?? [];
    final shuntingNoticeList =
        widget.investigateItem['shuntingNoticeList'] ?? [];

    // 安全地将List<dynamic>转换为List<Map<String, dynamic>>
    if (masInvestigateList is List) {
      mappedList = masInvestigateList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    if (shuntingNoticeList is List) {
      shuntingMappedList = shuntingNoticeList
          .where((item) => item is Map)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调查内容详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 展示调查基本信息
            // 横向展示修程 修次 走行公里 修程日期
            Text(
              '修程公里数',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
      
            // 创建表单样式展示
            Table(
              border: TableBorder.all(),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
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
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['newRepairProcName']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['newRepairProcTimes']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['newRepairKilometer']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['newRepairDate']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['normalRepairProcName']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['normalRepairProcTimes']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['normalRepairKilometer']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['normalRepairDate']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['advanceRepairProcName']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['advanceRepairProcTimes']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['advanceRepairKilometer']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.investigateItem['advanceRepairDate']?.toString() ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 标题
            const Text(
              '其他作业项点',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 展示mappedList内容
            if (mappedList.isNotEmpty) ...[
              ...mappedList.asMap().entries.map((entry) {
                final index = entry.key;
                final masItem = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('排序: ${masItem['sort'] ?? ''}'),
                        Text('作业项点: ${masItem['investigateTitle'] ?? ''}'),
                        Text(
                            '二级作业项点: ${masItem['investigateContent'] ?? ''}'),
                        Text('调查部门: ${masItem['deptName'] ?? ''}'),
                        Text('指派调查班组: ${masItem['teamName'] ?? ''}'),
                        Text('调查人: ${masItem['reportUserName'] ?? ''}'),
                        Text('调查结果: ${masItem['investigateResult'] ?? ''}'),
                        // 自己的部门或者父部门
                        // if (Global.profile.permissions?.user.deptId ==
                        //         masItem['deptId'] ||
                        //     Global.profile.permissions?.user.dept
                        //             ?.parentId ==
                        //         masItem['deptId'])
                                                   Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditInvestigatePage(
                                        repairItem: widget.repairItem,
                                        investigateItem: masItem,
                                      ),
                                    ),
                                  );
                                  
                                  // 如果保存成功，刷新数据
                                  if (result == true) {
                                    // 这里可以添加刷新数据的逻辑
                                    // 例如重新加载调查数据
                                    // _loadInvestigateData();
                                  }
                                },
                                child: const Text('填写调查结果'),
                              ),
                            ),
                      
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],

            // 如果没有数据则显示提示
            if (mappedList.isEmpty) ...[
              const Center(
                child: Text(
                  '暂无调查内容',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  


}
