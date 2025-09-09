import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class SpecialDisposalPage extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  final String repairScheme;
  final String faultDescription;
  final String code;
  final Map<String, dynamic>? jtInfo;

  const SpecialDisposalPage(
      {super.key,
      required this.trainNum,
      required this.typeName,
      required this.trainEntryCode,
      required this.repairScheme,
      required this.faultDescription,
      required this.trainNumCode,
      required this.typeCode,
      required this.code, this.jtInfo});

  @override
  State<SpecialDisposalPage> createState() => _SpecialDisposalPageState();
}

class _SpecialDisposalPageState extends State<SpecialDisposalPage> {
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

  // 加工方法列表
  List<Map<String, dynamic>> _processMethodList = [];
  Map<String, dynamic> dynamicMethodSelected = {};

  var logger = AppLogger.logger;

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

  @override
  void initState() {
    super.initState();
    _loadJt28Data();
    getProcessMethod();
  }

  // 加载机统28数据
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('专检作业-处置'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('专统28-处置'),
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
            ZjcFormSelectCell(
              title: "加工方法",
              text: dynamicMethodSelected["dictName"],
              hintText: "请选择",
              showRedStar: true,
              clickCallBack: () {
                if (_processMethodList.isEmpty) {
                  showToast("无动力类型选择");
                } else {
                  ZjcCascadeTreePicker.show(
                    context,
                    data: _processMethodList,
                    labelKey: 'dictName',
                    valueKey: 'code',
                    childrenKey: 'children',
                    title: "选择动力类型",
                    clickCallBack: (selectItem, selectArr) {
                      logger.i(selectArr);
                      setState(() {
                        dynamicMethodSelected["code"] = selectItem["code"];
                        dynamicMethodSelected["dictName"] = selectItem["dictName"];
                        logger.i(dynamicMethodSelected);
                      });
                    },
                  );
                }
              },
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 0, 5),
                  child: Text(
                    '故障视频及图片',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: Colors.brown)),
                  child: ZjcAssetPicker(
                    assetType: APC.AssetType.imageAndVideo,
                    maxAssets: 9,
                    selectedAssets: assestPics,
                    // bgColor: Colors.grey,
                    callBack: (assetEntityList) async {
                      logger.i('assetEntityList-------------');
                      logger.i(assetEntityList);
                      if (assetEntityList.isNotEmpty) {
                        // 清空之前的文件列表
                        List<File> files = [];

                        // 处理所有选定的资源（图片和视频）
                        for (var asset in assetEntityList) {
                          var file = await asset.file;
                          if (file != null) {
                            files.add(file);
                          }
                        }

                        setState(() {
                          assestPics = assetEntityList;
                          faultPics = files;
                        });
                      } else {
                        setState(() {
                          faultPics = [];
                          assestPics = [];
                        });
                      }
                      logger.i('assetEntityList-------------');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 7. 申请专互检 按钮
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  var submit;
                  List<Map<String, dynamic>> l = [];
                  try {
                    SmartDialog.showLoading();
                    Map<String, dynamic> queryParameters = {
                      "code": widget.code,
                      "processMethod": dynamicMethodSelected['dictName'],
                      "repairStatus": _repairSituationController.text,
                      "completeStatus": 2
                    };
                    logger.i(queryParameters);
                    if (faultPics.isNotEmpty) {
                      await JtApi().uploadMixJt(imagedata: faultPics).then(
                            (value) async => {
                              if (value['data'] != null && value['data'] != "")
                                {
                                  queryParameters["repairPicture"] =
                                      value['data'],
                                  l.insert(0, queryParameters),
                                  submit = await JtApi()
                                      .uploadJt28(queryParametrs: l),
                                  if (submit['data'] != null)
                                    {
                                      showToast("${submit['data']}"),
                                      // SmartDialog.dismiss(status: SmartStatus.loading)
                                    }
                                }
                              else
                                {
                                  showToast("图片上传失败，请检查网络连接"),
                                  // SmartDialog.dismiss(status: SmartStatus.loading)
                                }
                            },
                          );
                    } else {
                      logger.i("$queryParameters");
                      l.insert(0, queryParameters);
                      submit = await JtApi().uploadJt28(queryParametrs: l);
                      if (submit["code"] == "S_T_S003") {
                        showToast("${submit['message']}");
                        // SmartDialog.dismiss(status: SmartStatus.loading);
                      } else {
                        showToast("机统28提报失败，请检查网络连接");
                        // SmartDialog.dismiss(status: SmartStatus.loading);
                      }
                    }
                  } on DioException catch (e) {
                    showToast("故障提报失败");
                    logger.i(e.toString());
                  } finally {
                    SmartDialog.dismiss(status: SmartStatus.loading);
                    if (submit['code'] == "S_T_S003") {
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  const Text(
                                    "机统28提报成功",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints.expand(
                                        height: 30, width: 160),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        SmartDialog.dismiss().then((value) =>
                                            Navigator.of(context).pop());
                                      },
                                      label: const Text('确定'),
                                      icon: const Icon(Icons
                                          .system_security_update_good_sharp),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                    }
                  }
                },
                child: const Text('专互检确认'),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ... existing code ...
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
