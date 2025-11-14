import 'package:intl/intl.dart';
import 'package:jcjx_phone/routes/production/repair_train.dart';

import '../../index.dart';

//待范围作业
class PackagePartInfo extends StatefulWidget {
  //机车信息
  final Map<String, dynamic>? locoInfo;
  // 分包作业项信息
  final List<Map<String, dynamic>> taskInstructContentList;

  const PackagePartInfo({
    Key? key,
    this.locoInfo,
    required this.taskInstructContentList,
  }) : super(key: key);
  @override
  State<PackagePartInfo> createState() => _PackagePartInfoState();
}

class _PackagePartInfoState extends State<PackagePartInfo> {
  var logger = AppLogger.logger;

  List<Map<String, dynamic>> packageList = [];

  void initState() {
    print(widget.taskInstructContentList);
  }

  @override
  Widget build(BuildContext context) {
    return InspectionPackagePage(
      locoInfo: widget.locoInfo,
      packageList: widget.taskInstructContentList,
    );
  }
}

/// 机车信息模型
class Locomotive {
  final String id; // 机车编号（如 HXD3C 0016）
  final DateTime inTime; // 入段时间
  final String track; // 股道
  final String planTrain; // 计划车次
  final String planOut; // 计划出库
  final String status; // 整备状态（如“整备中”）

  Locomotive({
    required this.id,
    required this.inTime,
    required this.track,
    required this.planTrain,
    required this.planOut,
    required this.status,
  });
}

/// 作业项模型（如车内2、车底等）
class TaskItem {
  final String name; // 作业名称（如“车内2”）
  final int completed; // 已完成数量（如 0）
  final int total; // 总数量（如 16）
  final String userStatus; // 领用人状态（如“未申领”）

  TaskItem({
    required this.name,
    required this.completed,
    required this.total,
    required this.userStatus,
  });
}

class InspectionPackagePage extends StatefulWidget {
  final List<Map<String, dynamic>> packageList;
  final Map<String, dynamic>? locoInfo;
  const InspectionPackagePage(
      {super.key, this.locoInfo, required this.packageList});

  @override
  State<InspectionPackagePage> createState() => _InspectionPackagePageState();
}

class _InspectionPackagePageState extends State<InspectionPackagePage> {
  List<Map<String, dynamic>> packageListUse = [];
  var logger = AppLogger.logger;

  void initState() {
    packageListUse = widget.packageList;
    getCertainPackage();
  }

  Future<void> getCertainPackage() async {
    Map<String, dynamic> params = {
      "packageCode": widget.packageList[0]['packageCode'],
      'pageSize': 0,
      'pageNum': 0
    };
    var certainPackageList =
        await ProductApi().getTaskCertainPackage(queryParametrs: params);
    if (mounted) {
      setState(() {
        //将List<dynamic>转换为List<Map<String, dynamic>>
        packageListUse = (certainPackageList as List)
            .where((item) => item is Map)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        logger.i(packageListUse.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss"); // 时间格式化

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            } else {
              // 如果无法pop，尝试使用maybePop或者给出提示
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text("检修作业-作业包分包"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // 支持滚动（防止内容溢出）
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机车基本信息
            _buildTrainInfo(),
            const SizedBox(height: 16),
            // 2. 作业项列表
            ...packageListUse.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建机车基本信息区域
  Widget _buildTrainInfo() {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.locoInfo?['typeName'] ?? ''} ${widget.locoInfo?['trainNum'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.locoInfo != null &&
                      widget.locoInfo!['arrivePlatformTime'] != null
                  ? '入段:${timeFormat.format(DateTime.parse(widget.locoInfo!['arrivePlatformTime']))}'
                  : '入段:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 每一项单独一行显示
        _InfoItem(
            label: '停留地点',
            value: widget.locoInfo?['stopPlace'] != "null-null"
                ? (widget.locoInfo?['stopPlace'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序节点',
            value: widget.locoInfo?['repairMainNodeName'] != ''
                ? (widget.locoInfo?['repairMainNodeName'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转入时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['mainNodeChangeTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['mainNodeChangeTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转出时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['theoreticEndTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['theoreticEndTime']))
                : '无'),
      ],
    );
  }

  /// 辅助方法：信息项（标签+值）
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 构建单个作业项（如车内2、车底）
  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 文件夹图标
            Icon(
              Icons.folder,
              color: Colors.yellow.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),

            // 作业名称 + 进度文本 + 进度条
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称 + 进度（如“车内2 0/16”）
                  Text(
                    "${task['name']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 进度条
                ],
              ),
            ),
            // 开工按钮
            const SizedBox(width: 12),

            // 开工按钮 - 仅在任务未完成时显示
            if (task['complete'] == '0')
              ElevatedButton(
                onPressed: () async {
                  task['startTime'] = DateTime.now().toString();
                  Map<String, dynamic> queryParametrs = task;
                  await ProductApi().startCertainPackageWork(queryParametrs);
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InspectionVertexOnePage(
                        locoInfo: widget.locoInfo,
                        packageInfo: task,
                      ),
                    ),
                  );
                  // 检查多种可能的返回值
                  if (result == true || result == null) {
                    // 刷新数据，null表示页面被直接关闭
                    await getCertainPackage();
                    if (result == true) {}
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 背景色设为绿色
                  foregroundColor: Colors.white, // 文字颜色设为白色
                ),
                child: const Text('开工'),
              ),

            if (task['complete'] == '6')
              ElevatedButton(
                onPressed: () async {
                  // task['startTime'] = DateTime.now().toString();
                  // Map<String, dynamic> queryParametrs = task;
                  // await ProductApi().startCertainPackageWork(queryParametrs);
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InspectionVertexOnePage(
                        locoInfo: widget.locoInfo,
                        packageInfo: task,
                      ),
                    ),
                  );
                  // 检查多种可能的返回值
                  if (result == true || result == null) {
                    // 刷新数据，null表示页面被直接关闭
                    await getCertainPackage();
                    if (result == true) {}
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 背景色设为绿色
                  foregroundColor: Colors.white, // 文字颜色设为白色
                ),
                child: const Text('继续作业'),
              )
            else if (task['complete'] == '1')
              //展示已完成
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已完成',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectionVertexOnePage extends StatefulWidget {
  Map<String, dynamic>? packageInfo = {};
  Map<String, dynamic>? locoInfo = {};

  InspectionVertexOnePage(
      {super.key, required this.packageInfo, required this.locoInfo});

  @override
  State<InspectionVertexOnePage> createState() =>
      _InspectionVertexOnePageState();
}

class _InspectionVertexOnePageState extends State<InspectionVertexOnePage> {
  // 模拟已采集的照片（可扩展为文件路径列表）
  var logger = AppLogger.logger;

  final List<String> _photos = ["photo_1"]; // 示例：存储照片标识
  //展示照片文件
  final List<XFile> _files = [];
  int _currentIndex = 0;

  Map<String, dynamic>? currentPackage;

  //作业项点内容
  List<Map<String, dynamic>> packagePoints = [];

  Map<String, dynamic> currentPackagePoint = {};

  List<Map<String, dynamic>> taskContentItemList = [];

  List<Map<String, dynamic>> taskInstructContentList = [];

  @override
  void initState() {
    List<Map<String, dynamic>> list = [];
    if (widget.packageInfo != null) {
      list.add(widget.packageInfo!);
    }
    packagePoints = list;
    _loadTaskContentItems();

    logger.i(packagePoints);
  }

  void _loadTaskContentItems() {
    // 清空之前的数据
    taskContentItemList.clear();

    // 只在初始化时加载数据
    if (packagePoints.isNotEmpty && _currentIndex < packagePoints.length) {
      currentPackagePoint = packagePoints[_currentIndex];

      if (currentPackagePoint['taskInstructContentList'] != null &&
          currentPackagePoint['taskInstructContentList'] is List) {
        taskInstructContentList =
            (currentPackagePoint['taskInstructContentList'] as List)
                .where((item) => item is Map<String, dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList();
      }

      for (Map<String, dynamic> item in taskInstructContentList) {
        if (item['taskContentItemList'] != null &&
            item['taskContentItemList'] is List) {
          taskContentItemList.addAll((item['taskContentItemList'] as List)
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int number = packagePoints.length;

    if (packagePoints.isNotEmpty) {
      if (_currentIndex < packagePoints.length) {
        currentPackagePoint = packagePoints[_currentIndex];
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text("检修作业-项点"),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _reportJT6,
            child: const Text(
              "报机统28",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机车基本信息
            _buildTrainInfo(),
            const SizedBox(height: 16),

            // 2. 整备进度条
            LinearProgressIndicator(
              value: (_currentIndex + 1) / number,
              color: Colors.green,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
            const SizedBox(height: 16),

            // 3. 作业区域标题（车外 + 第二工位）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      currentPackagePoint['name']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _gotoSecondStation(taskInstructContentList),
                  child: const Text(
                    "作业内容",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 8),

            // // 4. 作业项：3右轴箱组装检查（红色强调）
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     // 红色竖线标记
            //     Container(
            //       width: 4,
            //       height: 24,
            //       color: Colors.red,
            //     ),
            //     const SizedBox(width: 8),
            //     const Text(
            //       "$",
            //       style: TextStyle(
            //         color: Colors.red,
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 16),

            // 5. 照片采集区（必须采集 + 拍照/删除功能）
            Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.grey[300],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行：必须采集 + 拍照按钮
                  Row(
                    children: [
                      const Text(
                        "必须采集",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _takePhoto, // 拍照逻辑（可扩展）
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 照片列表（模拟展示）
                  if (_files.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _files.map((photo) {
                        return Stack(
                          children: [
                            // 照片占位（实际可替换为Image）

                            Container(
                              width: 80,
                              height: 80,
                              color: Colors.black,
                              alignment: Alignment.center,
                              child: Image.file(
                                File(photo.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // 删除按钮
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () => _deletePhoto(photo),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 展示taskContentItemList
            taskContentItemList.isEmpty
                ? const Center(
                    child: Text(''),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taskContentItemList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '数据名称:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['name'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '最小值可等于:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitMin'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '最大值可等于:'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitMax'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(text: '单位'),
                              TextSpan(
                                text:
                                    '${taskContentItemList[index]['limitUnit'] ?? ''}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        subtitle: TextField(
                          decoration: const InputDecoration(
                            hintText: '请输入实际数值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // 在这里处理输入值的变化
                            // 你可以将值保存到 taskContentItemList[index] 的某个字段中
                            taskContentItemList[index]['realValue'] = value;
                          },
                        ),
                      );
                    }),
            const SizedBox(height: 20),

            // 6. 进入下一项按钮
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _files.isEmpty
                          ? null
                          : () async {
                              // 完成所有操作后返回成功结果
                              await upLoadFileList();
                              await saveContentItem();
                              await completePackage();
                              // 将图片清空
                              _files.clear();
                              if (packagePoints != null &&
                                  _currentIndex < packagePoints!.length - 1) {
                                // 如果还有下一项，则更新索引以显示下一项
                                setState(() {
                                  _currentIndex++;
                                });
                              } else {
                                debugPrint("已完成所有项");
                                Navigator.pop(context, true);
                              }
                            }, // 当没有图片时禁用按钮
                      child: _currentIndex < (packagePoints.length) - 1
                          ? const Text("进入下一项")
                          : const Text("完成"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- 交互逻辑（可扩展） ----------------------
  void _reportJT6() {
    // 报JT6的业务逻辑（如提交数据、跳转页面）
    debugPrint("报JT6功能触发");
  }

  _gotoSecondStation(List<Map<String, dynamic>> taskInstructContentList) {
    logger.i(taskInstructContentList);

    // 构建显示内容
    StringBuffer contentBuffer = StringBuffer();
    for (var i = 0; i < taskInstructContentList.length; i++) {
      final item = taskInstructContentList[i];
      final name = item['name'] ?? '无名称';
      final workContent = item['workContent'] ?? '无工作内容';

      contentBuffer.writeln('名称: $name');
      contentBuffer.writeln('工作内容: $workContent');
      if (i < taskInstructContentList.length - 1) {
        contentBuffer.writeln('-------------------');
      }
    }

    // 如果列表为空，显示提示信息
    if (taskInstructContentList.isEmpty) {
      contentBuffer.writeln('暂无作业内容');
    }

    // 使用WidgetsBinding.instance.addPostFrameCallback延迟显示弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('作业内容'),
            content: SingleChildScrollView(
              child: Text(contentBuffer.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    });
  }

  void _takePhoto() async {
    // 调用相机采集照片（可结合image_picker库实现）
    debugPrint("拍照功能触发");

    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _photos.add(photo.path);
        _files.add(photo);
      });
    }
  }

  void _deletePhoto(XFile photo) {
    // 删除照片逻辑
    debugPrint("删除照片：$photo");
    setState(() {
      _files.remove(photo);
    });
  }

  void _gotoNextItem() {
    // 检查是否上传了必须采集的图片
    if (_files.isEmpty) {
      // 如果没有图片，显示提示信息并返回
      SmartDialog.showToast('请上传"必须采集"的照片');
      return;
    }

    // 进入下一项的业务逻辑（如校验照片、跳转步骤）
    upLoadFileList();
    saveContentItem();
    completePackage();
    // 将图片清空
    _files.clear();
    if (packagePoints != null && _currentIndex < packagePoints!.length - 1) {
      // 如果还有下一项，则更新索引以显示下一项
      setState(() {
        _currentIndex++;
      });
    } else {
      debugPrint("已完成所有项");
      Navigator.pop(context, true);
    }
  }

  Future<void> upLoadFileList() async {
    try {
      List<File> files = _files.map((xFile) => File(xFile.path)).toList();
      logger.i(currentPackagePoint['code']);
      var r = await ProductApi().uploadCertainPackageImg(queryParametrs: {
        'certainPackageCodeList': currentPackagePoint['code'],
      }, imagedatas: files);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> completePackage() async {
    try {
      List<Map<String, dynamic>> queryParameters = [];
      Map<String, dynamic> taskCertainPackageList = {
        'code': currentPackagePoint['code'],
        'completeTime':
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      };
      queryParameters.add(taskCertainPackageList);
      var r = await ProductApi().finishCertainPackage(queryParameters);
      logger.i(r);
    } catch (e) {
      logger.e(e);
    }
  }

  //保存作业项数据
  Future<void> saveContentItem() async {
    try {
      var r =
          await ProductApi().saveOrUpdateTaskContentItem(taskContentItemList);
      logger.i(r);
    } catch (e) {
      logger.e(e);
    }
  }

  // ---------------------- 辅助方法：机车信息展示 ----------------------
  /// 构建机车基本信息区域
  Widget _buildTrainInfo() {
    final timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.locoInfo?['typeName'] ?? ''} ${widget.locoInfo?['trainNum'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.locoInfo != null &&
                      widget.locoInfo!['arrivePlatformTime'] != null
                  ? '入段:${timeFormat.format(DateTime.parse(widget.locoInfo!['arrivePlatformTime']))}'
                  : '入段:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 每一项单独一行显示
        _InfoItem(
            label: '停留地点',
            value: widget.locoInfo?['stopPlace'] != "null-null"
                ? (widget.locoInfo?['stopPlace'] ?? '无')
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转入时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['mainNodeChangeTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['mainNodeChangeTime']))
                : '无'),
        const SizedBox(height: 8),
        _InfoItem(
            label: '工序转出时间',
            value: widget.locoInfo != null &&
                    widget.locoInfo!['theoreticEndTime'] != null
                ? timeFormat.format(
                    DateTime.parse(widget.locoInfo!['theoreticEndTime']))
                : '无'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
