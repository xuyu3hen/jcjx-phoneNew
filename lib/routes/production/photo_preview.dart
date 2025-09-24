import '../../index.dart';


/// 可复用的故障图片预览对话框组件
class PhotoPreviewDialog {
  /// 显示故障图片预览对话框
  /// [context] 上下文
  /// [groupId] 图片组ID
  /// [api] 获取图片列表的API函数
  static void show(
    BuildContext context,
    String groupId,
    Future<dynamic> Function({Map<String, dynamic>? queryParametrs}) api,
  ) async {
    SmartDialog.showLoading(msg: '加载中...');
    try {
      Map<String, dynamic> queryParameters = {
        'groupId': groupId,
      };
      
      var response = await api(queryParametrs: queryParameters);
      
      // 将List<dynamic>转换为List<Map<String, dynamic>>
      List<Map<String, dynamic>> photoList = (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      SmartDialog.dismiss();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("故障视频及图片"),
            content: photoList.isNotEmpty
                ? SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: photoList.map((photo) {
                        return ListTile(
                          title: Text(photo['fileName'] ?? ''),
                          onTap: () {
                            _previewImage(context, photo, ProductApi().previewImage);
                          },
                        );
                      }).toList(),
                    ),
                  )
                : const Text('暂无图片'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('加载失败，请检查网络连接');
    }
  }
  
  /// 预览单张图片
  static void _previewImage(
    BuildContext context,
    Map<String, dynamic> photo,
    Future<dynamic> Function({Map<String, dynamic>? queryParametrs}) api,
  ) async {
    Image? image;
    try {
      Map<String, dynamic> queryParameters = {
        'url': photo['downloadUrl'] 
      };
      
      var response = await api(queryParametrs: queryParameters);
      image = response as Image?;
    } catch (e) {
      // 忽略错误，使用网络图片作为备选方案
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(photo['fileName'] ?? '图片预览'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图片显示部分，添加错误处理和占位符
                if (image != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: image,
                  )
                else if (photo['downloadUrl'] != null)
                  Image.network(
                    photo['downloadUrl'],
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        children: [
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('图片加载失败'),
                        ],
                      );
                    },
                  )
                else
                  const Column(
                    children: [
                      Icon(Icons.image, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('无图片可显示'),
                    ],
                  ),
                const SizedBox(height: 10),
                if (photo['fileName'] != null)
                  Text('文件名: ${photo['fileName']}')
                else
                  const Text('未知文件'),
                if (photo['fileSize'] != null)
                  Text('文件大小: ${photo['fileSize']} bytes'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}