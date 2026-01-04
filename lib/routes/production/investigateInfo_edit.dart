import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../index.dart';
import '../../models/progress.dart';

class EditInvestigatePage extends StatefulWidget {
  final RepairItem repairItem;
  final Map<String, dynamic> investigateItem;

  const EditInvestigatePage({
    Key? key,
    required this.repairItem,
    required this.investigateItem,
  }) : super(key: key);

  @override
  _EditInvestigatePageState createState() => _EditInvestigatePageState();
}

class _EditInvestigatePageState extends State<EditInvestigatePage> {
  late TextEditingController _contentController;
  late TextEditingController _resultController;
  
  // 用于存储选择的媒体文件（图片和视频）
  List<XFile> _selectedMedia = [];
  
  // 用于存储已上传的媒体URL
  List<String> _uploadedMedia = [];
  
  var logger = AppLogger.logger;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
        text: widget.investigateItem['investigateContent'] as String? ?? '');
    _resultController = TextEditingController(
        text: widget.investigateItem['investigateResult'] as String? ?? '');
    
    if (widget.investigateItem['mediaUrls'] != null) {
      _uploadedMedia = List<String>.from(widget.investigateItem['mediaUrls']);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('填写调查结果'),
        actions: [
          TextButton(
            onPressed: _saveInvestigateResult,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _resultController,
              decoration: const InputDecoration(
                labelText: '调查结果',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 20),
            
            // 媒体上传区域
            const Text(
              '上传附件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            // 显示已上传的媒体
            if (_uploadedMedia.isNotEmpty) ...[
              const Text('已上传附件:'),
              const SizedBox(height: 8),
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
                                  ? Icon(Icons.video_library, size: 60, color: Colors.blue)
                                  : Image.network(
                                      _uploadedMedia[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _uploadedMedia.removeAt(index);
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
              const SizedBox(height: 15),
            ],
            
            // 显示新选择的媒体
            if (_selectedMedia.isNotEmpty) ...[
              const Text('待上传附件:'),
              const SizedBox(height: 8),
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
                                  ? Icon(Icons.videocam, size: 60, color: Colors.blue)
                                  : FutureBuilder<Uint8List?>(
                                      future: media.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done &&
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
              const SizedBox(height: 15),
            ],
            
            // 添加媒体按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.camera, false);
                    },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('拍照'),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.camera, true);
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('录像'),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickMedia(ImageSource.gallery, false);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('图库'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // 预览区域说明
            const Text(
              '说明:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text('• 点击拍照/录像按钮可以直接拍摄照片或录制视频', style: TextStyle(fontSize: 14)),
            const Text('• 点击图库可以从相册中选择图片或视频', style: TextStyle(fontSize: 14)),
            const Text('• 点击右上角删除按钮可以移除已选择的附件', style: TextStyle(fontSize: 14)),
            const Text('• 点击媒体预览可以查看大图或播放视频', style: TextStyle(fontSize: 14)),
            const Text('• 保存时将同时上传文本和附件', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // 辅助方法：判断文件是否为视频
  bool _isVideoFile(XFile file) {
    final String path = file.path.toLowerCase();
    return path.endsWith('.mp4') || 
           path.endsWith('.mov') || 
           path.endsWith('.avi') || 
           path.endsWith('.wmv') ||
           path.endsWith('.mkv');
  }

  // 辅助方法：判断URL是否为视频
  bool _isVideoUrl(String url) {
    final String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.mp4') || 
           lowerUrl.contains('.mov') || 
           lowerUrl.contains('.avi') || 
           lowerUrl.contains('.wmv') ||
           lowerUrl.contains('.mkv');
  }

  // 辅助方法：选择媒体文件
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final ImagePicker _picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        if (isVideo) {
          // 录像
          final XFile? video = await _picker.pickVideo(source: source);
          if (video != null) {
            setState(() {
              _selectedMedia.add(video);
            });
          }
        } else {
          // 拍照
          final XFile? photo = await _picker.pickImage(source: source, imageQuality: 80);
          if (photo != null) {
            setState(() {
              _selectedMedia.add(photo);
            });
          }
        }
      } else {
        // 从图库选择
        if (isVideo) {
          // 选择视频
          final XFile? video = await _picker.pickVideo(source: source);
          if (video != null) {
            setState(() {
              _selectedMedia.add(video);
            });
          }
        } else {
          // 选择图片
          final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
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

  // 预览已上传的媒体文件
  void _previewUploadedMedia(String mediaUrl) {
    if (_isVideoUrl(mediaUrl)) {
      // 视频文件，打开视频播放页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewPage(videoUrl: mediaUrl),
        ),
      );
    } else {
      // 图片文件，打开图片预览页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewPage(imageUrl: mediaUrl),
        ),
      );
    }
  }

  // 预览已选择的媒体文件
  void _previewSelectedMedia(XFile media) {
    if (_isVideoFile(media)) {
      // 视频文件，打开视频播放页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewPage(videoFile: media),
        ),
      );
    } else {
      // 图片文件，打开图片预览页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewPage(imageFile: media),
        ),
      );
    }
  }

  // 保存调查结果
  Future<void> _saveInvestigateResult() async {
    SmartDialog.showLoading();
    // print('保存调查结果: ${_resultController.text}');
    try {
      
    
        List<File> files = _selectedMedia.map((xFile) => File(xFile.path)).toList();
        Map<String,dynamic> queryParametrs = {
          "code": widget.investigateItem['code'],
        };
        logger.i('上传媒体参数：$queryParametrs');
        // 上传媒体到服务器
        // var uploadResponse = await ProductApi().uploadShuntingFile(imagedatas: files, queryParametrs: queryParametrs);
      // }
      
    

      // 更新调查内容
      await ProductApi().updateMasInvestigateList({
        'code': widget.investigateItem['code'],
        'deptId': Global.profile.permissions?.user.deptId,
        'deptName': Global.profile.permissions?.user.dept?.deptName,
        'investigateResult': _resultController.text,
        'reportUserId': Global.profile.permissions?.user.userId,
        'reportUserName': Global.profile.permissions?.user.nickName,
        'teamId': Global.profile.permissions?.user.deptId,
        'teamName': Global.profile.permissions?.user.dept?.deptName,
      });

      SmartDialog.dismiss();
      
      // 返回上一页并刷新数据
      Navigator.of(context).pop(true);
      SmartDialog.showToast('保存成功');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('保存失败: $e');
      logger.e('保存调查结果失败: $e');
    }
  }
}

// 图片预览页面
class ImagePreviewPage extends StatelessWidget {
  final String? imageUrl;
  final XFile? imageFile;

  const ImagePreviewPage({Key? key, this.imageUrl, this.imageFile}) : super(key: key);

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
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
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
class VideoPreviewPage extends StatefulWidget {
  final String? videoUrl;
  final XFile? videoFile;

  const VideoPreviewPage({Key? key, this.videoUrl, this.videoFile}) : super(key: key);

  @override
  _VideoPreviewPageState createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
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