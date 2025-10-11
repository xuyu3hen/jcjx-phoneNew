import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_asset_picker.dart' as APC;

class FaultDisposalPage extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  final String repairScheme;
  final String faultDescription;
  final String code;
  final String repairPicture;
  final String processMainNode;

  const FaultDisposalPage(
      {super.key,
      required this.trainNum,
      required this.typeName,
      required this.trainEntryCode,
      required this.repairScheme,
      required this.faultDescription,
      required this.trainNumCode,
      required this.typeCode,
      required this.code,
      required this.repairPicture,
      required this.processMainNode});

  @override
  State<FaultDisposalPage> createState() => _FaultDisposalPageState();
}

class _FaultDisposalPageState extends State<FaultDisposalPage> {
  // 数据变量
  String _model = '';
  String _trainNum = '';
  String _faultPhenomenon = '';
  String _repairPlan = '';
  String _processMainNode = '';

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
      //   Map<String, dynamic> params = {
      //     "trainEntryCode": widget.trainEntryCode,
      //   };

      //   var response =
      //       await ProductApi().selectRepairSys28(queryParametrs: params);

      //   if (response != null && response is List && response.isNotEmpty) {
      //     // 获取第一条记录
      //     var data = response[0];
      //     logger.i(data);

      //     setState(() {
      //       // 设置机型
      //       _model = data['trainType'] ?? widget.typeName;

      //       // 设置机车号
      //       _trainNum = data['trainNum'] ?? widget.trainNum;

      //       // 设置故障现象
      //       _faultPhenomenon = data['faultPhenomenon'] ??
      //           data['faultDesc'] ??
      //           widget.faultDescription;

      //       // 设置施修方案
      //       _repairPlan = data['repairScheme'] ??
      //           data['repairProgram'] ??
      //           widget.repairScheme;

      //       _processMainNode = data['processMainNode'] ?? '';
      //       _isLoading = false;
      //     });
      //   } else {
      // 如果没有获取到数据，使用传入的参数
      setState(() {
        _model = widget.typeName;
        _trainNum = widget.trainNum;
        _faultPhenomenon = widget.faultDescription;
        _repairPlan = widget.repairScheme;
        _isLoading = false;
        _processMainNode = widget.processMainNode;
      });
      //
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
            // 2. 工序节点
            _buildLabeledTextBlock(
              label: '工序节点',
              text: _processMainNode,
              height: 60,
            ),
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

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // 修复：直接调用PhotoPreviewDialog.show方法来展示图片
                      PhotoPreviewDialog.show(context, widget.repairPicture,
                          ProductApi().getFaultVideoAndImage);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("查看故障视频及图片"),
                  ),
                ),
              ],
            ),

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
                        dynamicMethodSelected["dictName"] =
                            selectItem["dictName"];
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
                    '施修情况图片',
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

            const SizedBox(height: 32),

            // 7. 申请专互检 按钮
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
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
                                  if (value['data'] != null &&
                                      value['data'] != "")
                                    {
                                      queryParameters["repairEndPicture"] =
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      const Text(
                                        "机统28提报成功",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints.expand(
                                                height: 30, width: 160),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            SmartDialog.dismiss().then(
                                                (value) => Navigator.of(context)
                                                    .pop());
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
                    child: const Text('销活申请'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      //点击申请放行进行弹窗
                      SmartDialog.show(
                          clickMaskDismiss: false,
                          builder: (con) {
                            return ApplyReleaseDialog(
                              extraParams: {
                                'trainNum': widget.trainNum,
                                'trainNumCode': widget.trainNumCode,
                                'typeName': widget.typeName,
                                'typeCode': widget.typeCode,
                                'trainEntryCode': widget.trainEntryCode,
                                'repairScheme': widget.repairScheme,
                                'faultDescription': widget.faultDescription,
                                'code': widget.code,
                                'repairPicture': widget.repairPicture,
                                'processMainNode': widget.processMainNode,
                              },
                              onConfirm: () {
                                // 确认操作
                                SmartDialog.dismiss();
                                // 这里可以添加确认后的逻辑
                              },
                              onCancel: () {
                                // 取消操作
                                SmartDialog.dismiss();
                              },
                            );
                          });
                    },
                    child: const Text('申请放行'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void applyWorkRelease() async {
    Map<String, dynamic> queryParameters = {
      // "jt28Code": widget.applyId,
    };
    var r =
        await ProductApi().saveReleaseShunting(queryParametrs: queryParameters);
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

class ApplyReleaseDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Map<String, dynamic>? extraParams; // 添加额外参数字段

  const ApplyReleaseDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
    this.extraParams,
  }) : super(key: key);

  @override
  State<ApplyReleaseDialog> createState() => _ApplyReleaseDialogState();
}

class _ApplyReleaseDialogState extends State<ApplyReleaseDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  Map<String, dynamic> _selectedRecipient = {};
  Future<void> getUserList() async {
    Map<String, dynamic> params = {
      "deptId": 231,
      "pageNum": 0,
      "pageSize": 0,
    };
    try {
      var response = await ProductApi().getUserList1(queryParametrs: params);
      if (response is List) {
        setState(() {
          // 将List<dynamic>转换为List<Map<String, dynamic>>
          List<Map<String, dynamic>> userList = response
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map))
              .toList();

          // 根据获取的用户列表更新_team.members
          if (userList.isNotEmpty) {
            _recipients = userList;
            // print(_recipients.toString());
          }
        });
      }
    } catch (e) {
      // 错误处理
      print('获取用户列表失败: $e');
    }
  }

  // 模拟签收人列表，实际应用中应该从API获取
  List<Map<String, dynamic>> _recipients = [];

  @override
  void initState() {
    getUserList();
    super.initState();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void releaseShunting() async {
    Map<String, dynamic> queryParameters = {};

    // 添加来自父页面的参数
    queryParameters['jt28Code'] = widget.extraParams?['code'];
    queryParameters['typeCode'] = widget.extraParams?['typeCode'];
    queryParameters['typeName'] = widget.extraParams?['typeName'];
    queryParameters['trainEntryCode'] = widget.extraParams?['trainEntryCode'];
    queryParameters['trainName'] = widget.extraParams?['trainNum'];
    queryParameters['jt28Name'] = widget.extraParams?['faultDescription'];
    queryParameters['reportDeptId'] = Global.profile.permissions?.user.deptId;
    queryParameters['reportDeptName'] =
        Global.profile.permissions?.user.dept?.deptName;
    queryParameters['reportUserId'] = Global.profile.permissions?.user.userId;
    queryParameters['reportUserName'] =
        Global.profile.permissions?.user.nickName;
    queryParameters['releaseApplicationReson'] = _reasonController.text;
    queryParameters['status'] = 0;
    List<Map<String, dynamic>> shuntingNoticeList = [];
    Map<String, dynamic> map = {};
    map['applyUserId'] = Global.profile.permissions?.user.userId;
    map['applyUserName'] = Global.profile.permissions?.user.nickName;
    //需要将其与信息进行绑定。现在是默认的
    map['auditDeptId'] = _selectedRecipient['deptId'];
    map['auditDeptName'] = _selectedRecipient['deptName'];
    map['auditUserId'] = _selectedRecipient['userId'];
    map['auditUserName'] = _selectedRecipient['nickName'];
    map['shuntingType'] = 14;
    map['status'] = 0;
    shuntingNoticeList.add(map);
    queryParameters['shuntingNoticeList'] = shuntingNoticeList;
    try {
      var r = await ProductApi()
          .saveReleaseShunting(queryParametrs: queryParameters);
      showToast(r['msg']);
    } catch (e) {
      // 处理异常情况
      print('保存放行申请时发生错误: $e');
      showToast('操作失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '申请放行',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 申请放行原因输入框
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('放行原因'),
              const SizedBox(height: 4),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入申请放行原因...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 签收人选择输入框
          ZjcFormSelectCell(
            title: "放行人员",
            text: _selectedRecipient["nickName"],
            hintText: "请选择",
            showRedStar: true,
            clickCallBack: () {
              if (_recipients.isEmpty) {
                showToast("无放行人员选择");
              } else {
                ZjcCascadeTreePicker.show(
                  context,
                  data: _recipients,
                  labelKey: 'nickName',
                  valueKey: 'userId',
                  childrenKey: 'children',
                  title: "选择放行人员",
                  clickCallBack: (selectItem, selectArr) {
                    setState(() {
                      _selectedRecipient["userId"] = selectItem["userId"];
                      _selectedRecipient["nickName"] = selectItem["nickName"];
                      _selectedRecipient["deptId"] = selectItem["deptId"];
                      _selectedRecipient["deptName"] = selectItem["deptName"];
                    });
                  },
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // 确认和取消按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('取消'),
                ),
              ),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    // 调用放行申请函数
                    releaseShunting();
                    // 执行原始的确认回调
                    widget.onConfirm();
                  },
                  child: const Text('确认'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
