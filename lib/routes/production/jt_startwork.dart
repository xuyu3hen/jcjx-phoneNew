import '../../index.dart';

class FaultDisposalPage extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  final String repairScheme;
  final String faultDescription;

  const FaultDisposalPage(
      {super.key,
      required this.trainNum,
      required this.typeName,
      required this.trainEntryCode,
      required this.repairScheme,
      required this.faultDescription,
      required this.trainNumCode,
      required this.typeCode});

  @override
  State<FaultDisposalPage> createState() => _FaultDisposalPageState();
}

class _FaultDisposalPageState extends State<FaultDisposalPage> {
  // 数据变量
  String _model = '';
  String _trainNum = '';
  String _faultPhenomenon = '';
  String _repairPlan = '';
  
  // 输入控制器（管理各输入框内容）
  final TextEditingController _processingMethodController =
      TextEditingController();
  final TextEditingController _repairSituationController =
      TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJt28Data();
  }

  // 加载机统28数据
  void _loadJt28Data() async {
    try {
      Map<String, dynamic> params = {
        "trainEntryCode": widget.trainEntryCode,
      };

      var response = await ProductApi().selectRepairSys28(queryParametrs: params);

      if (response != null && response is List && response.isNotEmpty) {
        // 获取第一条记录
        var data = response[0];

        setState(() {
          // 设置机型
          _model = data['trainType'] ?? widget.typeName;
          
          // 设置机车号
          _trainNum = data['trainNum'] ?? widget.trainNum;
          
          // 设置故障现象
          _faultPhenomenon = data['faultPhenomenon'] ?? 
              data['faultDesc'] ?? 
              widget.faultDescription;
          
          // 设置施修方案
          _repairPlan = data['repairScheme'] ?? 
              data['repairProgram'] ?? 
              widget.repairScheme;
          
          _isLoading = false;
        });
      } else {
        // 如果没有获取到数据，使用传入的参数
        setState(() {
          _model = widget.typeName;
          _trainNum = widget.trainNum;
          _faultPhenomenon = widget.faultDescription;
          _repairPlan = widget.repairScheme;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('获取机统28数据失败: $e');
      // 出错时使用传入的参数
      setState(() {
        _model = widget.typeName;
        _trainNum = widget.trainNum;
        _faultPhenomenon = widget.faultDescription;
        _repairPlan = widget.repairScheme;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // 页面销毁时释放控制器资源
    _processingMethodController.dispose();
    _repairSituationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('机统28-处置'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('机统28-处置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机型 + 机车号 行
            Row(
              children: [
                Expanded(
                  child: _buildLabeledText(
                    label: '机型',
                    text: _model,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLabeledText(
                    label: '机车号',
                    text: _trainNum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 故障现象 文本域
            _buildLabeledTextBlock(
              label: '故障现象',
              text: _faultPhenomenon,
              height: 60,
            ),
            const SizedBox(height: 16),

            // 3. 施修方案 文本域
            _buildLabeledTextBlock(
              label: '施修方案',
              text: _repairPlan,
              height: 60,
            ),
            const SizedBox(height: 16),

            // 4. 加工方法 输入框
            _buildLabeledInput(
              label: '加工方法',
              controller: _processingMethodController,
            ),
            const SizedBox(height: 16),

            // 5. 施修情况（红色标签 + 文本域）
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '施修情况',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  height: 120,
                  child: TextField(
                    controller: _repairSituationController,
                    maxLines: null, // 支持多行
                    expands: true, // 填充父容器高度
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '请输入施修情况...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. 修复视频及图片（占位区域）
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('修复视频及图片'),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '点击上传视频或图片',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 7. 申请专互检 按钮
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 模拟“申请专互检”逻辑（可扩展为接口请求）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('申请专互检操作已触发')),
                  );
                },
                child: const Text('申请专互检'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 封装“带标签的文本展示”
  Widget _buildLabeledText({
    required String label,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(text),
        ),
      ],
    );
  }

  // 封装“带标签的多行文本展示”
  Widget _buildLabeledTextBlock({
    required String label,
    required String text,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
          height: height,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
      ],
    );
  }

  // 封装“带标签的单行输入框”
  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ],
    );
  }
}