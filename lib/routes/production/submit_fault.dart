
import '../../index.dart';



class FaultReportPage extends StatefulWidget {
  const FaultReportPage({Key? key}) : super(key: key);

  @override
  State createState() => _FaultReportPageState();
}

class _FaultReportPageState extends State<FaultReportPage> {
  String? selectedFaultType;
  String? selectedRiskLevel;
  String? selectedProcessingMethod;
  String? selectedDispatchMethod;
  String? selectedFaultHypothesis;
  String faultPhenomenon = '';
  List<File> repairImages = [];
  List<File> repairNoticeFiles = [];

  var logger = AppLogger.logger;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickRepairImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    setState(() {
      repairImages.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
  }

  Future<void> _pickRepairNoticeFiles() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    setState(() {
      repairNoticeFiles.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
  }

  void _removeRepairImage(int index) {
    setState(() {
      repairImages.removeAt(index);
    });
  }

  void _removeRepairNoticeFile(int index) {
    setState(() {
      repairNoticeFiles.removeAt(index);
    });
  }

  void _submitReport() {
    // 这里可以添加提交表单数据的逻辑
    logger.i('故障类型: $selectedFaultType');
    logger.i('风险等级: $selectedRiskLevel');
    logger.i('加工方法: $selectedProcessingMethod');
    logger.i('派工方式: $selectedDispatchMethod');
    logger.i('故障现象: $faultPhenomenon');
    logger.i('故障假设: $selectedFaultHypothesis');
    logger.i('报修图片数量: ${repairImages.length}');
    logger.i('修程通知单数量: ${repairNoticeFiles.length}');
  }

  @override
  Widget build(BuildContext context) {
    final List<String> faultTypes = ['类型1', '类型2', '类型3'];
    final List<String> riskLevels = ['低', '中', '高'];
    final List<String> processingMethods = ['方法1', '方法2', '方法3'];
    final List<String> dispatchMethods = ['方式1', '方式2', '方式3'];
    final List<String> faultHypotheses = ['假设1', '假设2', '假设3'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('故障提报'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 故障类型选择框
            DropdownButtonFormField<String>(
              value: selectedFaultType,
              items: faultTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedFaultType = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: '故障类型',
              ),
            ),
            const SizedBox(height: 16.0),
            // 风险等级选择框
            DropdownButtonFormField<String>(
              value: selectedRiskLevel,
              items: riskLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedRiskLevel = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: '风险等级',
              ),
            ),
            const SizedBox(height: 16.0),
            // 加工方法选择框
            DropdownButtonFormField<String>(
              value: selectedProcessingMethod,
              items: processingMethods.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedProcessingMethod = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: '加工方法',
              ),
            ),
            const SizedBox(height: 16.0),
            // 派工方式选择框
            DropdownButtonFormField<String>(
              value: selectedDispatchMethod,
              items: dispatchMethods.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedDispatchMethod = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: '派工方式',
              ),
            ),
            const SizedBox(height: 16.0),
            // 故障现象输入框
            TextField(
              onChanged: (value) {
                setState(() {
                  faultPhenomenon = value;
                });
              },
              decoration: const InputDecoration(
                labelText: '故障现象',
              ),
            ),
            const SizedBox(height: 16.0),
            // 故障假设选择框
            DropdownButtonFormField<String>(
              value: selectedFaultHypothesis,
              items: faultHypotheses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedFaultHypothesis = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: '故障假设',
              ),
            ),
            const SizedBox(height: 16.0),
            // 上传报修图片
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('上传报修图片'),
                ElevatedButton(
                  onPressed: _pickRepairImages,
                  child: const Text('选择图片'),
                ),
                Wrap(
                  children: repairImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeRepairImage(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // 上传修程通知单
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('上传修程通知单'),
                ElevatedButton(
                  onPressed: _pickRepairNoticeFiles,
                  child: const Text('选择文件'),
                ),
                Wrap(
                  children: repairNoticeFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('文件'),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeRepairNoticeFile(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitReport,
          child: const Text('提报'),
        ),
      ),
    );
  }
}