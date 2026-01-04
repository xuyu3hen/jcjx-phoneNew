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
                    item['newRepairProcName']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['newRepairProcTimes']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['newRepairKilometer']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['newRepairDate']?.toString() ?? '',
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
                    item['normalRepairProcName']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['normalRepairProcTimes']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['normalRepairKilometer']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['normalRepairDate']?.toString() ?? '',
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
                    item['advanceRepairProcName']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['advanceRepairProcTimes']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['advanceRepairKilometer']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['advanceRepairDate']?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
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
        var uploadResponse = await ProductApi().uploadShuntingJt28(
            imagedata: selectedMedia.map((xFile) => File(xFile.path)).toList()[0],
        );

        logger.i('文件上传成功: $uploadResponse');
      }

      // 更新调查内容
      await ProductApi().updateMasInvestigateList({
        'code': masItem['code'],
        'deptId': Global.profile.permissions?.user.deptId,
        'deptName': Global.profile.permissions?.user.dept?.deptName,
        'investigateResult': result,
        'reportUserId': Global.profile.permissions?.user.userId,
        'reportUserName': Global.profile.permissions?.user.nickName,
        'teamId': Global.profile.permissions?.user.deptId,
        'teamName': Global.profile.permissions?.user.dept?.deptName,
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
