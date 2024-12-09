
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../utils/zjc_device_utils.dart';
import '../utils/zjc_permission_utils.dart';
import 'zjc_bottom_sheet.dart';
import 'zjc_progress_hud.dart';
import '/config/colors.dart';

// 最大数量
const int _maxAssets = 9;
// 录制视频最长时长, 默认为 15 秒，可以使用 `null` 来设置无限制的视频录制
const Duration _maximumRecordingDuration = Duration(seconds: 15);
// 一行显示几个
const int _lineCount = 3;
// 每个GridView item间距(GridView四周与内部item间距在此统一设置)
const double _itemSpace = 5.0;
// 右上角删除按钮大小
const double _deleteBtnWH = 20.0;
// 默认添加图片
const String _addBtnIcon = 'assets/images/selectPhoto_add.png';
// 默认删除按钮图片
const String _deleteBtnIcon = 'assets/images/selectPhoto_close.png';
// 默认背景色
const Color _bgColor = Colors.transparent;

enum AssetType {
  image,
  video,
  imageAndVideo,
}

class ZjcAssetPicker extends StatefulWidget {
  ZjcAssetPicker({
    Key? key,
    this.assetType = AssetType.image,
    this.maxAssets = _maxAssets,
    this.lineCount = _lineCount,
    this.itemSpace = _itemSpace,
    this.maximumRecordingDuration = _maximumRecordingDuration,
    this.bgColor = _bgColor,
    this.callBack,
    required this.selectedAssets,
  }) : super(key: key);

  final AssetType assetType; // 资源类型
  final int maxAssets; // 最大数量
  final int lineCount; // 一行显示几个
  final double itemSpace; // 每个GridView item间距(GridView四周与内部item间距在此统一设置)
  final Duration? maximumRecordingDuration; // 录制视频最长时长, 默认为 15 秒，可以使用 `null` 来设置无限制的视频录制
  final Color bgColor; // 背景色
  final Function(List<AssetEntity> assetEntityList)? callBack; // 选择回调
  List<AssetEntity> selectedAssets;

  @override
  State<ZjcAssetPicker> createState() => _ZjcAssetPickerState();
}

class _ZjcAssetPickerState extends State<ZjcAssetPicker> {
  // List<AssetEntity> _selectedAssets = [];
  Color _themeColor = KColors.kThemeColor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _body();
  }

  _body() {
    // TODO: 通过ThemeProvider进行主题管理
    // final provider = Provider.of<ThemeProvider>(context);
    _themeColor = KColors.dynamicColor(context, Theme.of(context).primaryColor, KColors.kThemeColor);

    // var allCount = _selectedAssets.length + 1;
    var allCount = widget.selectedAssets.length + 1;

    return Container(
      color: widget.bgColor,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // 可以直接指定每行（列）显示多少个Item
          crossAxisCount: widget.lineCount, // 一行的Widget数量
          crossAxisSpacing: widget.itemSpace, // 水平间距
          mainAxisSpacing: widget.itemSpace, // 垂直间距
          childAspectRatio: 1.0, // 子Widget宽高比例
        ),
        // GridView内边距
        padding: EdgeInsets.all(widget.itemSpace),
        // itemCount: _selectedAssets.length == widget.maxAssets ? _selectedAssets.length : allCount,
        itemCount: widget.selectedAssets.length == widget.maxAssets ? widget.selectedAssets.length : allCount,
        itemBuilder: (context, index) {
          // if (_selectedAssets.length == widget.maxAssets) {
          if (widget.selectedAssets.length == widget.maxAssets) {
            return _itemWidget(index);
          }
          if (index == allCount - 1) {
            return _addBtnWidget();
          } else {
            return _itemWidget(index);
          }
        },
      ),
    );
  }

  // 添加按钮
  Widget _addBtnWidget() {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: Colors.grey)
        ),
        child: const Icon(Icons.add_a_photo_outlined,size: 50,),
      ),
      // child: const Image(image: AssetImage(_addBtnIcon)),
      onTap: () => _showBottomSheet(),
    );
  }

  // 图片和删除按钮
  Widget _itemWidget(index) {
    return GestureDetector(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              // child: _loadAsset(_selectedAssets[index]),
              child: _loadAsset(widget.selectedAssets[index]),
            ),
            GestureDetector(
              child: Icon(Icons.delete),
              // const Image(
              //   image: AssetImage(_deleteBtnIcon),
              //   width: _deleteBtnWH,
              //   height: _deleteBtnWH,
              // ),
              onTap: () => _deleteAsset(index),
            )
          ],
        ),
      ),
      onTap: () => _clickAsset(index),
    );
  }

  Widget _loadAsset(AssetEntity asset) {
    return Image(image: AssetEntityImageProvider(asset), fit: BoxFit.cover);
  }

  void _deleteAsset(index) {
    setState(() {
      widget.selectedAssets.removeAt(index);
      // _selectedAssets.removeAt(index);
      // 选择回调
      widget.callBack?.call(widget.selectedAssets);
      // widget.callBack?.call(_selectedAssets);
    });
  }

  // 全屏查看
  void _clickAsset(index) {
    AssetPickerViewer.pushToViewer(
      context,
      currentIndex: index,
      // previewAssets: _selectedAssets,
      previewAssets: widget.selectedAssets,
      themeData: AssetPicker.themeData(_themeColor),
    );
  }

  // 点击添加按钮
  void _showBottomSheet() {
    ZjcBottomSheet.showText(context, dataArr: ['拍摄', '相册'], title: '请选择', clickCallback: (index, str) async {
      if (index == 1) {
        _openCamera(context);
      }
      if (index == 2) {
        _openAlbum(context);
      }
    });
  }

  // 相册选择
  Future<void> _openAlbum(context) async {
    if (!ZjcDeviceUtils.isMobile) {
      ZjcProgressHUD.showText('当前平台暂不支持');
      return;
    }
    // 相册权限
    bool isGrantedPhotos = await ZjcPermissionUtils.photos();
    if (!isGrantedPhotos) {
      return;
    }

    RequestType requestType = RequestType.image;
    if (widget.assetType == AssetType.video) {
      requestType = RequestType.video;
    }
    if (widget.assetType == AssetType.imageAndVideo) {
      requestType = RequestType.common;
    }
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: widget.maxAssets,
        requestType: requestType,
        // selectedAssets: _selectedAssets,
        selectedAssets: widget.selectedAssets,
        themeColor: _themeColor,
        // textDelegate: const EnglishAssetPickerTextDelegate(),
      ),
    );
    if (result != null) {
      setState(() {
        widget.selectedAssets = result;
      });
      // 相册选择回调
      widget.callBack?.call(result);
    }
  }

  // 拍照或录像
  Future<void> _openCamera(context) async {
    if (!ZjcDeviceUtils.isMobile) {
      ZjcProgressHUD.showText('当前平台暂不支持');
      return;
    }
    // 相机权限
    bool isGrantedCamera = await ZjcPermissionUtils.camera();
    if (!isGrantedCamera) {
      return;
    }

    if (widget.assetType != AssetType.image) {
      // 麦克风权限
      bool isGrantedMicrophone = await ZjcPermissionUtils.microphone();
      if (!isGrantedMicrophone) {
        return;
      }
    }

    // 相册权限
    bool isGrantedPhotos = await ZjcPermissionUtils.photos();
    if (!isGrantedPhotos) {
      return;
    }

    final AssetEntity? result = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: CameraPickerConfig(
        // 是否可以录像
        enableRecording: widget.assetType != AssetType.image,
        // 录制视频最长时长
        maximumRecordingDuration: widget.maximumRecordingDuration,
        // textDelegate: const EnglishCameraPickerTextDelegate(),
      ),
    );
    if (result != null) {
      setState(() {
        // _selectedAssets.add(result);
        widget.selectedAssets.add(result);
        // 相机回调
        // widget.callBack?.call(_selectedAssets);
        widget.callBack?.call(widget.selectedAssets);
      });
    }
  }
}
