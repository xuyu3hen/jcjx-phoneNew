import 'dart:math';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class MutualDisposalPackagePage extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  final String repairScheme;
  final String faultDescription;
  final String code;
  final Map<String, dynamic> trainInfo;
  final List<dynamic> repairPictures;

  const MutualDisposalPackagePage(
      {super.key,
      required this.trainNum,
      required this.typeName,
      required this.trainEntryCode,
      required this.repairScheme,
      required this.faultDescription,
      required this.trainNumCode,
      required this.typeCode,
      required this.code,
      required this.trainInfo, required this.repairPictures});

  @override
  State<MutualDisposalPackagePage> createState() => _MutualDisposalPackagePageState();
}

class _MutualDisposalPackagePageState extends State<MutualDisposalPackagePage> {
  // 数据变量
  String _model = '';
  String _trainNum = '';
  String _faultPhenomenon = '';
  String _repairPlan = '';

  // 故障图片
  List<AssetEntity> assestPics = [];
  List<File> faultPics = [];

  // 输入控制器（管理各输入框内容）
  final TextEditingController _processingMethodController =
      TextEditingController();
  final TextEditingController _repairSituationController =
      TextEditingController();

  bool _isLoading = true;

  bool _isChecked = false;

  // 加工方法列表
  List<Map<String, dynamic>> _processMethodList = [];
  Map<String, dynamic> dynamicMethodSelected = {};
  Map<String, dynamic> faultPartListInfo = {};
  Map<String, dynamic>? _selectedFaultPart;

  // 添加用于零部件搜索的控制器
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredFaultPartList = [];
  bool _isSearching = false;

  var logger = AppLogger.logger;

  List<Map<String, dynamic>> pictureList = [];
  
  // 获取加工方法
  void getProcessMethod() async {
    try {
      Map<String, dynamic> params = {"pageNum": 0, 'pageSize': 0};
      var response = await ProductApi().getProcessMethod(params);
      logger.i(response);
      if (response != null && response is List && response.isNotEmpty) {
        //将List<dynamic>转换为List<Map<String,dynamic>>
        _processMethodList = response
            .map((item) => {
                  'code': item['code'],
                  'dictName': item['dictName'],
                })
            .toList();
      }
    } catch (e) {
      print('获取机统28数据失败: $e');
    }
  }

  // 筛选故障零部件列表
  void _filterParts(String query) {
    if (query.isEmpty) {
      // 如果查询为空，清空列表
      setState(() {
        _filteredFaultPartList = [];
        _isSearching = false;
      });
    } else {
      // 根据查询关键词筛选零部件
      setState(() {
        _filteredFaultPartList = Global.faultPartList.where((part) {
          // 确保part是Map类型并且name字段存在
          if (part is Map) {
            final partName = part['nodeName']?.toString() ?? '';
            return partName.toLowerCase().contains(query.toLowerCase());
          }
          return false;
        }).toList();
        logger.i(_filteredFaultPartList);
        _isSearching = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadJt28Data();
    // 初始化筛选列表为空
    _filteredFaultPartList = [];
    // 添加搜索监听器
    _searchController.addListener(() {
      _filterParts(_searchController.text);
    });
    logger.i(Global.faultPartList.length);
  }

  void _loadJt28Data() async {
    try {
      Map<String, dynamic> params = {
        "trainEntryCode": widget.trainEntryCode,
      };

      var response =
          await ProductApi().selectRepairSys28(queryParametrs: params);

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('互检作业-处置'),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('互检作业-范围作业处置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 机型 + 机车号 行
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildLabeledText(
            //         label: '机型',
            //         text: _model,
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //       child: _buildLabeledText(
            //         label: '机车号',
            //         text: _trainNum,
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),

            // 2. 故障现象 文本域
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Expanded(
            //       child: _buildLabeledTextBlock(
            //         label: '故障现象',
            //         text: _faultPhenomenon,
            //         height: 60,
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //       child: _buildLabeledTextBlock(
            //         label: '施修方案',
            //         text: _repairPlan,
            //         height: 60,
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),

            // //  展示 加工方法 trainInfo['processMethondName'] 施修人  trainInfo['repairName'] 申请时间 trainInfo['repairCompletionDate']

            // const SizedBox(height: 16),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildLabeledText(
            //         label: '加工方法',
            //         text: widget.trainInfo['processMethodName'] ?? '',
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //       child: _buildLabeledText(
            //         label: '施修人',
            //         text: widget.trainInfo['repairName'] ?? '',
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //       child: _buildLabeledText(
            //         label: '申请时间',
            //         text: widget.trainInfo['repairCompletionDate'] ?? '',
            //       ),
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 16),

            // // 展示施修情况trainInfo['repairStatus']
            // _buildLabeledTextBlock(
            //   label: '施修情况',
            //   text: widget.trainInfo['repairStatus'] ?? '',
            //   height: 60,
            // ),
            // // 展示修复视频及图片（占位区域）
            // const SizedBox(height: 16),

            // 6. 修复视频及图片（占位区域）
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      PhotoPreviewDialog.show2(
                          context,
                          widget.repairPictures,
                         );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("修复视频及图片"),
                  ),
                ),
              ],
            ),
            //故障零部件构型确认在faultPartListInfo1中进行筛选
            const SizedBox(height: 16),
            // 7. 合格按钮
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    SmartDialog.showLoading();
                    Map<String, dynamic> queryParameters = {
                      "code": widget.code,
                      "mutualInspectionName": Global.profile.permissions?.user.nickName,
                      "mutualInspectionId": Global.profile.permissions?.user.userId,
                      'mutualInspectionTime': DateTime.now().toString(),
                    };
                    
                    var result = await ProductApi().wholePackageMutualInspection(queryParameters);

                    SmartDialog.dismiss();
                    
               
                      SmartDialog.show(
                        clickMaskDismiss: false,
                        builder: (con) {
                          return Container(
                            height: 150,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  "互检提报成功",
                                  style: TextStyle(fontSize: 18),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints.expand(
                                    height: 30, width: 160),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      SmartDialog.dismiss().then((value) =>
                                        Navigator.of(context).pop(true));
                                    },
                                    label: const Text('确定'),
                                    icon: const Icon(Icons
                                        .system_security_update_good_sharp),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      );
                   
                  } on DioException catch (e) {
                    SmartDialog.dismiss();
                    showToast("互检提报失败");
                    logger.e("互检提报失败: ${e.toString()}");
                  } catch (e) {
                    SmartDialog.dismiss();
                    showToast("发生未知错误");
                    logger.e("互检提报发生未知错误: ${e.toString()}");
                  }
                },
                child: const Text('合格'),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

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
          child: Text(text),
        ),
      ],
    );
  }

  // 封装"带标签的多行文本展示"
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
          padding: const EdgeInsets.all(8),
          height: height,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
      ],
    );
  }
// ... existing code ...

  // 封装"带标签的单行输入框"
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
