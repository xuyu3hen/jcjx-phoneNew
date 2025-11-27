import '../../index.dart';
import 'package:jcjx_phone/models/progress.dart';
class PlanListPage extends StatefulWidget {
  final RepairItem repairItem;
  PlanListPage({required this.repairItem});
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
      Map<String, dynamic> queryParametrs = {
        'trainEntryCode': item.code,
      };
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
          itemCount: investigateList.length,
          itemBuilder: (context, index) {
            final item = investigateList[index];
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            _editInvestigateItem(context, item);
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

  // 编辑调查项方法
  void _editInvestigateItem(BuildContext context, Map<String, dynamic> item) {
    TextEditingController contentController = TextEditingController(text: item['investigateContent'] ?? '');
    TextEditingController signController = TextEditingController(text: item['signStatus'] ?? '');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('编辑调查内容与签收情况'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: '调查内容',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: signController,
                  decoration: InputDecoration(
                    labelText: '签收情况',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 更新数据逻辑
                setState(() {
                  item['investigateContent'] = contentController.text;
                  item['signStatus'] = signController.text;
                });
                Navigator.pop(context);
                showToast('保存成功');
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }
}