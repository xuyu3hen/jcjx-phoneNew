import '../../index.dart';

class JtSearch extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  const JtSearch(
      {Key? key,
      required this.trainNum,
      required this.trainNumCode,
      required this.typeName,
      required this.typeCode,
      required this.trainEntryCode})
      : super(key: key);
  @override
  State<JtSearch> createState() => _JtShowPageState();
}

class _JtShowPageState extends State<JtSearch> {
  late Map<String, dynamic> info = {};

  var logger = AppLogger.logger;
  // 动态类型列表
  late List<Map<String, dynamic>> dynamicTypeList = [];
  // 筛选的动态类型信息
  late Map<dynamic, dynamic> dynamciTypeSelected = {};
  //机型列表
  late List<Map<String, dynamic>> jcTypeList = [];
  // 筛选的机型列表
  late Map<String, dynamic> jcTypeListSelected = {};
  // 车号列表
  late List<Map<String, dynamic>> trainNumCodeList = [];
  // 筛选的车号信息
  late Map<dynamic, dynamic> trainNumSelected = {};
  // 机统28信息
  late List<dynamic> sys28List = [];

  // 零件信息
  late Map<String, dynamic> faultPart = {};

  Permissions? permissions;

  late TextEditingController repairDetailsController = TextEditingController();

  late TextEditingController actualStartDateController =
      TextEditingController();

  late TextEditingController faultyPartController = TextEditingController();

  late TextEditingController mutualInspectorController =
      TextEditingController();

  late TextEditingController qualityInspectorController =
      TextEditingController();

  List<dynamic> faultPartList = [];

  List<Map<String, dynamic>> faultPartListInfo = [];

  // 当前选中的节点
  Map<String, dynamic>? selectedNode;

  //
  late Map<String, dynamic> faultInfo;

  late Map<int, String> status = {
    0: '待施修',
    1: '待派工',
    2: '待互检',
    3: '待专检',
    4: '已完成',
    5: '已放行',
    6: '已开工',
  };

  // ... existing code ...
  // 添加分页相关变量
  int pageNum = 1;
  int pageSize = 10;
  int total = 0;
  bool isLoading = false;

  //获取机统28信息
  void getInfo() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> queryParameters = {
      'pageNum': pageNum,
      'pageSize': pageSize,
      // 'status': 0,
      'trainEntryCode': widget.trainEntryCode,
 
      'trainType': widget.typeName
      // 'completeStatus': 1,
      // 'deptId': Global.profile.permissions?.user.dept?.deptId
    };


    logger.i(widget.trainNumCode);
    logger.i(widget.trainNum);
    logger.i(widget.typeName);
    logger.i(widget.typeCode);

    try {
      var r = await ProductApi()
          .selectRepairSys28(queryParametrs: queryParameters);
      setState(() {
        sys28List = r['rows'];
        total = r['total'];
        isLoading = false;
      });
    } catch (e) {
      logger.e('获取机统28信息失败: $e');
      setState(() {
        isLoading = false;
      });
      // 显示错误信息
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("获取数据失败")),
        );
      });
    }
  }

// ... existing code ...

  @override
  void initState() {
    //初始化动力类型
    getDynamicType();

    // ✅ 初始化施修情况控制器
    repairDetailsController = TextEditingController();

    // 初始化分页相关变量
    pageNum = 1;
    pageSize = 10;
    total = 0;
    isLoading = false;

    // 初始化时加载第一页数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInfo();
    });

    super.initState();
  }

  void getDynamicType() async {
    try {
      //获取动力类型
      var r = await ProductApi().getDynamicType();
      //获取用户信息
      var permissionResponse = await LoginApi().getpermissions();
      setState(() {
        dynamicTypeList = r.toMapList();
        permissions = permissionResponse;
        dynamciTypeSelected["code"] = dynamicTypeList[0]["code"];
        dynamciTypeSelected["name"] = dynamicTypeList[0]["name"];
        getJcType();
        logger.i(permissions);
      });
    } catch (e, stackTrace) {
      logger.e('getDynamicType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getJcType() async {
    try {
      Map<String, dynamic> queryParameters = {
        'dynamicCode': dynamciTypeSelected["code"],
        'pageNum': 0,
        'pageSize': 0
      };
      var r = await ProductApi().getJcType(queryParametrs: queryParameters);
      logger.i(r.toJson());
      setState(() {
        jcTypeList = r.toMapList();
      });
    } catch (e, stackTrace) {
      logger.e('getJcType 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  Future<void> getFaultPart() async {
    try {
      Map<String, dynamic> queryParameters = {
        'typeCode': jcTypeListSelected["code"],
        'pageNum': 0,
        'pageSize': 0,
        'name': faultyPartController.text,
      };
      logger.i(queryParameters);
      var r = await ProductApi().getFaultPart(queryParameters);
      if (mounted) {
        setState(() {
          //将List<dynamic>转换为List<Map<String, dynamic>>
          faultPartListInfo = (r['rows'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getFaultPart 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  void getTrainNumCodeList() async {
    try {
      //构建查询车号参数
      Map<String, dynamic> queryParameters = {
        'typeName': jcTypeListSelected["name"],
        'pageNum': 0,
        'pageSize': 0
      };
      //获取车号
      var r =
          await ProductApi().getRepairPlanList(queryParametrs: queryParameters);
      if (mounted) {
        setState(() {
          trainNumCodeList = r.toMapList();
        });
      }
    } catch (e, stackTrace) {
      logger.e('getTrainNumCodeList 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  //获取互检专检人员信息
  void getUserList() async {
    try {
      Map<String, dynamic> queryParameters = {
        'configNodeCode': jcTypeListSelected["code"],
        'riskLevel': faultInfo["riskLevel"],
        'team': 100
      };
      logger.i(queryParameters);
      var r = await ProductApi().getCheckPerson(queryParameters);
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('getTrainInfo 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("机统28作业查询"),
      ),
      body: _buildBody(),
    );
  }

  /// 获取图片/视频列表
  /// 返回Future以便在组件中处理加载状态和错误
  Future<List<Map<String, dynamic>>> getPhotoList(String groupId) async {
    try {
      if (groupId.isEmpty) {
        return [];
      }
      
      Map<String, dynamic> queryParameters = {
        'groupId': groupId,
      };
      var r = await ProductApi()
          .getFaultVideoAndImage(queryParametrs: queryParameters);
      
      //将List<dynamic>转换为List<Map<String, dynamic>>
      final photoList =
          (r as List).map((item) => item as Map<String, dynamic>).toList();
      logger.i(photoList);
      return photoList;
    } catch (e) {
      logger.e('获取图片列表失败: $e');
      rethrow;
    }
  }

  late Image image;
  Future<Image?> getPreviewImage(Map<String, dynamic> photo) async {
    Map<String, dynamic> queryParameters = {'url': photo['downloadUrl']};
    logger.i(queryParameters);
    var r = await ProductApi().previewImage(queryParametrs: queryParameters);
    return r;
  }

  /// 显示图片预览对话框
  /// 使用新的ImagePreviewDialog组件
  void _previewImage(Map<String, dynamic> photo) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => ImagePreviewDialog(media: photo),
    );
  }

  /// 构建美化状态卡片
  Widget _buildStatusBadge(int? statusCode) {
    String statusText = '';
    Color bgColor = Colors.grey;
    Color textColor = Colors.white;

    if (statusCode != null && status[statusCode] != null) {
      statusText = status[statusCode]!;

      // 根据状态设置不同颜色
      switch (statusCode) {
        case 0: // 待施修
          bgColor = Colors.orangeAccent;
          break;
        case 1: // 待派工
          bgColor = Colors.blueAccent;
          break;
        case 2: // 待互检
          bgColor = Colors.purpleAccent;
          break;
        case 3: // 待专检
          bgColor = Colors.indigoAccent;
          break;
        case 4: // 已完成
          bgColor = Colors.green;
          break;
        case 5: // 已放行
          bgColor = Colors.teal;
          break;
        case 6: // 已开工
          bgColor = Colors.lightBlue;
          break;
        default:
          bgColor = Colors.grey;
      }
    } else {
      statusText = '未知状态';
      bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // ZjcFormSelectCell(
              //   title: "动力类型",
              //   text: dynamciTypeSelected["name"],
              //   hintText: "请选择",
              //   showRedStar: true,
              //   clickCallBack: () {
              //     if (dynamicTypeList.isEmpty) {
              //       showToast("无动力类型选择");
              //     } else {
              //       ZjcCascadeTreePicker.show(
              //         context,
              //         data: dynamicTypeList,
              //         labelKey: 'name',
              //         valueKey: 'code',
              //         childrenKey: 'children',
              //         title: "选择动力类型",
              //         clickCallBack: (selectItem, selectArr) {
              //           logger.i(selectArr);
              //           setState(() {
              //             dynamciTypeSelected["code"] = selectItem["code"];
              //             dynamciTypeSelected["name"] = selectItem["name"];
              //             getJcType();
              //           });
              //         },
              //       );
              //     }
              //   },
              // ),
              Row(
                children: [
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "机型",
                      text: widget.typeName,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "车号",
                      text: widget.trainNum,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                ],
              ),
              // 添加分页信息显示和控制

              if (total > 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('共 $total 条记录'),
                      Text('第 $pageNum / ${((total - 1) ~/ pageSize) + 1} 页'),
                    ],
                  ),
                ),
              //展示列表信息
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (sys28List.isNotEmpty)
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sys28List.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> item = sys28List[index];
                        return Jt28ListItem(
                          item: item,
                          statusMap: status,
                          buildStatusBadge: _buildStatusBadge,
                          onViewMedia: item['repairPicture'] != null &&
                                  item['repairPicture'].toString().isNotEmpty
                              ? () {
                                  // 使用新的对话框组件
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return FaultMediaListDialog(
                                        groupId: item['repairPicture'].toString(),
                                        onLoadMedia: getPhotoList,
                                      );
                                    },
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                    // 分页控制按钮
                    if (total > pageSize)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: pageNum <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        pageNum = 1;
                                      });
                                      getInfo();
                                    },
                              child: const Text('首页'),
                            ),
                            ElevatedButton(
                              onPressed: pageNum <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        pageNum--;
                                      });
                                      getInfo();
                                    },
                              child: const Text('上一页'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  pageNum >= ((total - 1) ~/ pageSize) + 1
                                      ? null
                                      : () {
                                          setState(() {
                                            pageNum++;
                                          });
                                          getInfo();
                                        },
                              child: const Text('下一页'),
                            ),
                            ElevatedButton(
                              onPressed: pageNum >=
                                      ((total - 1) ~/ pageSize) + 1
                                  ? null
                                  : () {
                                      setState(() {
                                        pageNum = ((total - 1) ~/ pageSize) + 1;
                                      });
                                      getInfo();
                                    },
                              child: const Text('末页'),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
// ... existing code ...
              else if (!isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '暂无数据',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}

/// 机统28开工列表项组件
/// 基于Jt28ListItem，添加开工按钮
class Jt28StartWorkListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<int, String> statusMap;
  final Widget Function(int?) buildStatusBadge;
  final VoidCallback? onViewMedia;
  final VoidCallback? onStartWork;
  final String startWorkButtonText;

  const Jt28StartWorkListItem({
    Key? key,
    required this.item,
    required this.statusMap,
    required this.buildStatusBadge,
    this.onViewMedia,
    this.onStartWork,
    this.startWorkButtonText = '开工',
  }) : super(key: key);

  String _getSafeText(String key, {String defaultValue = ''}) {
    final value = item[key];
    if (value == null) return defaultValue;
    return value.toString().isEmpty ? defaultValue : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 故障现象和施修方案
                _buildInfoRow(
                  [
                    _buildInfoItem('故障现象', _getSafeText('faultDescription')),
                    _buildInfoItem('施修方案', _getSafeText('repairScheme')),
                  ],
                ),
                const SizedBox(height: 8),
                // 查看媒体按钮
                if (onViewMedia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onViewMedia,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text("查看故障视频及图片"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                // 提报信息
                _buildInfoRow(
                  [
                    _buildInfoItem('提报人', _getSafeText('reporterName')),
                    _buildInfoItem('提报时间', _getSafeText('reportDate')),
                    _buildInfoItem('部门', _getSafeText('deptName')),
                  ],
                ),
                const SizedBox(height: 8),
                // 班组信息
                _buildInfoRow(
                  [
                    _buildInfoItem('班组', _getSafeText('teamName')),
                    _buildInfoItem('主修', _getSafeText('repairName')),
                    _buildInfoItem('辅修', _getSafeText('assistantName')),
                  ],
                ),
                const SizedBox(height: 8),
                // 专检、互检和状态
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('专检', _getSafeText('specialName')),
                    ),
                    Expanded(
                      child: _buildInfoItem('互检', _getSafeText('mutualName')),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: buildStatusBadge(item['status'] as int?),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 开工按钮
          if (onStartWork != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 80,
                height: 120,
                child: ElevatedButton(
                  onPressed: onStartWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                  ),
                  child: Text(
                    startWorkButtonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(child: child))
          .toList(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '暂无' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 车间模型
class Chejian {
  String name; // 班组名（如“北折一组”）
  late List<Team> members; // 成员列表
  Chejian(this.name, this.members);
}

/// 班组模型
class Team {
  final String name; // 姓名（如“曹阳”）
  final int id; // 工号（如“3368”）
  Team(this.name, this.id);
}

/// 检修项模型
class InspectionItem {
  final String name; // 项名称（如“车底”）
  bool isChecked; // 是否勾选
  InspectionItem(this.name, this.isChecked);
}

class JtAssignTeam extends StatefulWidget {
  final String jtCode;
  const JtAssignTeam({super.key, required this.jtCode});

  @override
  State<JtAssignTeam> createState() => _JtAssignTeamState();
}

// ... existing code ...
class _JtAssignTeamState extends State<JtAssignTeam> {
  String? deptName = Global.profile.permissions?.user.dept?.deptName;

  // 班组数据（模拟）
  late Chejian _team;

  // 当前选中的成员（默认选第一个）
  late Team _selectedMember;

  // 机型选项（模拟下拉）
  final List<String> _modelOptions = ['HXD3CA', 'HXD3C', 'HXD1D'];
  String _selectedModel = 'HXD3CA';

  // 检修项列表（模拟状态）
  final List<InspectionItem> _inspectionItems = [
    InspectionItem('派工', false),
  ];

  // 添加搜索控制器和过滤后的成员列表
  final TextEditingController _searchController = TextEditingController();
  List<Team> _filteredMembers = [];

  var logger = AppLogger.logger;

  void getTeamList() async {
    Map<String, dynamic> params = {
      "parentIdList": Global.profile.permissions?.user.dept?.deptId,
    };
    try {
      var response =
          await ProductApi().getDeptByParentIdList(queryParametrs: params);
      if (response is List) {
        // 将List<dynamic>转换为List<Map<String, dynamic>>
        List<Map<String, dynamic>> teamList = response
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        print(teamList);
        // 根据获取的用户列表更新_team.members
        if (teamList.isNotEmpty) {
          List<Team> members = teamList.map((user) {
            return Team(
              user['deptName'] ?? '未知用户',
              user['deptId'] ?? '未知ID',
            );
          }).toList();

          setState(() {
            _team.members = members;
            _filteredMembers = members; // 同时更新过滤列表
            if (members.isNotEmpty) {
              _selectedMember = members[0]; // 更新选中的成员为第一个
            }
          });
        }
      }
    } catch (e) {
      // 错误处理
      print('获取用户列表失败: $e');
    }
  }

  // 添加过滤成员的方法
  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _team.members;
      } else {
        _filteredMembers = _team.members
            .where((member) =>
                member.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始化团队数据
    _team = Chejian(deptName ?? '默认班组', []);
    // 监听搜索框输入
    _searchController.addListener(() {
      _filterMembers(_searchController.text);
    });
    getTeamList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void setRepairInfo() async {
    try {
      // 构建参数
      Map<String, dynamic> params = {
        "code": widget.jtCode,
      };
      // 设置主修人员
      params['team'] = _selectedMember.id;
      params['teamName'] = _selectedMember.name;
      logger.i(params);
      // 调用API更新用户信息
      var response = await ProductApi().updateUserId(params);
      if (response['code'] == "S_T_S003") {
        showToast("分配成功");
      }
    } catch (e) {
      print('分配人员失败: $e');
      showToast("分配失败，请重试");
    }
  }

  int _selectedInspectionIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (Navigator.canPop(context)) {
              // 返回前刷新界面
              Navigator.pop(context, true); // 传递true表示需要刷新
            } else {
              // 如果无法pop，尝试使用maybePop或者给出提示
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('班组派工'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Row(
        children: [
          // 左侧：人员列表
          Container(
            width: 160,
            color: Colors.white,
            child: Column(
              children: [
                // 班组名称
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    _team.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 添加搜索框（固定在顶部）
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索用户...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                // 成员列表（可滚动部分）
                Expanded(
                  child: ListView(
                    children: [
                      // 成员列表
                      ..._filteredMembers.map((member) {
                        final isSelected = member == _selectedMember;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMember = member;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: isSelected ? Colors.green : Colors.white,
                            child: Text(
                              '${member.name}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16, // 增大字体
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal, // 选中时加粗
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右侧：详情区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // 检修项列表
                  Column(
                    children: _inspectionItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      InspectionItem item = entry.value;
                      return RadioListTile<int>(
                        title: Text(item.name),
                        value: idx,
                        groupValue: _selectedInspectionIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedInspectionIndex = value ?? -1;
                            // 重置所有项的选中状态
                            for (int i = 0; i < _inspectionItems.length; i++) {
                              _inspectionItems[i].isChecked =
                                  (i == _selectedInspectionIndex);
                            }
                          });
                        },
                        activeColor: Colors.green,
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  // 底部按钮：固定检修项
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 可扩展：提交检修项逻辑
                        setRepairInfo();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        '确认',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 故障图片/视频列表对话框组件
/// 处理各种极端情况：空数据、加载中、错误、大量数据等
class FaultMediaListDialog extends StatefulWidget {
  final String groupId;
  final Future<List<Map<String, dynamic>>> Function(String) onLoadMedia;

  const FaultMediaListDialog({
    Key? key,
    required this.groupId,
    required this.onLoadMedia,
  }) : super(key: key);

  @override
  State<FaultMediaListDialog> createState() => _FaultMediaListDialogState();
}

class _FaultMediaListDialogState extends State<FaultMediaListDialog> {
  List<Map<String, dynamic>> _mediaList = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMediaList();
  }

  Future<void> _loadMediaList() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final mediaList = await widget.onLoadMedia(widget.groupId);
      if (!mounted) return;
      
      setState(() {
        _mediaList = mediaList;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _handlePreviewMedia(Map<String, dynamic> media, int index) {
    Navigator.of(context).pop(); // 先关闭列表对话框
    showDialog(
      context: context,
      builder: (BuildContext context) => ImagePreviewDialog(media: media),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("故障视频及图片"),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: [
        if (_hasError)
          TextButton(
            onPressed: _loadMediaList,
            child: const Text('重试'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_mediaList.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('暂无图片或视频'),
            ],
          ),
        ),
      );
    }

    // 使用ListView.builder优化大量数据的情况
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _mediaList.length,
        itemBuilder: (context, index) {
          final media = _mediaList[index];
          final isVideo = media['type']?.toString().toLowerCase() == 'video' ||
              media['downloadUrl']?.toString().toLowerCase().contains('.mp4') == true;
          
          return ListTile(
            leading: Icon(
              isVideo ? Icons.videocam : Icons.image,
              color: isVideo ? Colors.red : Colors.blue,
            ),
            title: Text(
              '${isVideo ? "视频" : "图片"} ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              media['fileName']?.toString() ?? '点击查看',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handlePreviewMedia(media, index),
          );
        },
      ),
    );
  }
}

/// 图片预览对话框组件
/// 优化加载状态、错误处理和展示方式
class ImagePreviewDialog extends StatefulWidget {
  final Map<String, dynamic> media;

  const ImagePreviewDialog({
    Key? key,
    required this.media,
  }) : super(key: key);

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  Image? _previewImage;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreviewImage();
  }

  Future<void> _loadPreviewImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final downloadUrl = widget.media['downloadUrl']?.toString() ?? 
                         widget.media['dowanloadUrl']?.toString();
      
      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('图片URL为空');
      }

      // 尝试通过API获取图片
      Map<String, dynamic> queryParameters = {'url': downloadUrl};
      final image = await ProductApi().previewImage(queryParametrs: queryParameters);
      
      if (!mounted) return;
      
      setState(() {
        _previewImage = image;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.media['fileName']?.toString() ?? '图片预览'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildImageContent(),
      ),
      actions: [
        if (_hasError)
          TextButton(
            onPressed: _loadPreviewImage,
            child: const Text('重试'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      final downloadUrl = widget.media['downloadUrl']?.toString() ?? 
                         widget.media['dowanloadUrl']?.toString();
      
      // 如果API失败，尝试直接使用URL加载
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return _buildNetworkImage(downloadUrl);
      }

      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('图片加载失败'),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_previewImage != null) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: _previewImage!,
        ),
      );
    }

    final downloadUrl = widget.media['downloadUrl']?.toString() ?? 
                       widget.media['dowanloadUrl']?.toString();
    
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      return _buildNetworkImage(downloadUrl);
    }

    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('无图片可显示'),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('图片加载失败'),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 机统28列表项组件
/// 优化展示方式，处理空值、长文本等情况
class Jt28ListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<int, String> statusMap;
  final Widget Function(int?) buildStatusBadge;
  final VoidCallback? onViewMedia;

  const Jt28ListItem({
    Key? key,
    required this.item,
    required this.statusMap,
    required this.buildStatusBadge,
    this.onViewMedia,
  }) : super(key: key);

  String _getSafeText(String key, {String defaultValue = ''}) {
    final value = item[key];
    if (value == null) return defaultValue;
    return value.toString().isEmpty ? defaultValue : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 故障现象和施修方案
          _buildInfoRow(
            [
              _buildInfoItem('故障现象', _getSafeText('faultDescription')),
              _buildInfoItem('施修方案', _getSafeText('repairScheme')),
            ],
          ),
          const SizedBox(height: 8),
          // 查看媒体按钮
          if (onViewMedia != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewMedia,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text("查看故障视频及图片"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          // 提报信息
          _buildInfoRow(
            [
              _buildInfoItem('提报人', _getSafeText('reporterName')),
              _buildInfoItem('提报时间', _getSafeText('reportDate')),
              _buildInfoItem('部门', _getSafeText('deptName')),
            ],
          ),
          const SizedBox(height: 8),
          // 班组信息
          _buildInfoRow(
            [
              _buildInfoItem('班组', _getSafeText('teamName')),
              _buildInfoItem('主修', _getSafeText('repairName')),
              _buildInfoItem('辅修', _getSafeText('assistantName')),
            ],
          ),
          const SizedBox(height: 8),
          // 专检、互检和状态
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('专检', _getSafeText('specialName')),
              ),
              Expanded(
                child: _buildInfoItem('互检', _getSafeText('mutualName')),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: buildStatusBadge(item['status'] as int?),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(child: child))
          .toList(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '暂无' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 机统28派工列表项组件
/// 基于Jt28ListItem，添加派工按钮
class Jt28AssignListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<int, String> statusMap;
  final Widget Function(int?) buildStatusBadge;
  final VoidCallback? onViewMedia;
  final VoidCallback? onAssign;
  final String assignButtonText;

  const Jt28AssignListItem({
    Key? key,
    required this.item,
    required this.statusMap,
    required this.buildStatusBadge,
    this.onViewMedia,
    this.onAssign,
    this.assignButtonText = '派工',
  }) : super(key: key);

  String _getSafeText(String key, {String defaultValue = ''}) {
    final value = item[key];
    if (value == null) return defaultValue;
    return value.toString().isEmpty ? defaultValue : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 故障现象和施修方案
                _buildInfoRow(
                  [
                    _buildInfoItem('故障现象', _getSafeText('faultDescription')),
                    _buildInfoItem('施修方案', _getSafeText('repairScheme')),
                  ],
                ),
                const SizedBox(height: 8),
                // 查看媒体按钮
                if (onViewMedia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onViewMedia,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text("查看故障视频及图片"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                // 提报信息
                _buildInfoRow(
                  [
                    _buildInfoItem('提报人', _getSafeText('reporterName')),
                    _buildInfoItem('提报时间', _getSafeText('reportDate')),
                    _buildInfoItem('部门', _getSafeText('deptName')),
                  ],
                ),
                const SizedBox(height: 8),
                // 班组信息
                _buildInfoRow(
                  [
                    _buildInfoItem('班组', _getSafeText('teamName')),
                    _buildInfoItem('主修', _getSafeText('repairName')),
                    _buildInfoItem('辅修', _getSafeText('assistantName')),
                  ],
                ),
                const SizedBox(height: 8),
                // 专检、互检和状态
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('专检', _getSafeText('specialName')),
                    ),
                    Expanded(
                      child: _buildInfoItem('互检', _getSafeText('mutualName')),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: buildStatusBadge(item['status'] as int?),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 派工按钮
          if (onAssign != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 80,
                height: 120,
                child: ElevatedButton(
                  onPressed: onAssign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(assignButtonText),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(child: child))
          .toList(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '暂无' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
