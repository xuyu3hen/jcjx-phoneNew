import 'package:jcjx_phone/routes/production/team_people.dart';
import 'package:jcjx_phone/routes/production/jt28_search.dart';

import '../../index.dart';

class MutualAssign extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  const MutualAssign(
      {Key? key,
      required this.trainNum,
      required this.trainNumCode,
      required this.typeName,
      required this.typeCode,
      required this.trainEntryCode})
      : super(key: key);
  @override
  State<MutualAssign> createState() => _JtShowPageState();
}

class _JtShowPageState extends State<MutualAssign> {
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
      // 'pageNum': pageNum,
      // 'pageSize': pageSize,
      // 'completeStatus': 2,
      'trainEntryCode': widget.trainEntryCode,
      // 'status': 0
    };
    logger.i(widget.trainNumCode);
    logger.i(widget.trainNum);
    logger.i(widget.typeName);
    logger.i(widget.typeCode);

    try {
      var r = await ProductApi()
          .getNeedToDispatchInspectionJt28(queryParametrs: queryParameters);
      setState(() {
        // info = r;
        sys28List = r;
        // total = info['total'] ?? 0;
        // isLoading = false;
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

  late Image image;
  Future<Image?> getPreviewImage(Map<String, dynamic> photo) async {
    Map<String, dynamic> queryParameters = {'url': photo['downloadUrl']};
    logger.i(queryParameters);
    var r = await ProductApi().previewImage(queryParametrs: queryParameters);
    return r;
  }

  // 添加图片预览方法
  void _previewImage(Map<String, dynamic> photo) async {
    Image? i = await getPreviewImage(photo);
    // 实现图片预览逻辑
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(photo['fileName'] ?? '图片预览'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 修正内容显示部分，添加错误处理和占位符
              if (i != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: i,
                )
              else if (photo['dowanloadUrl'] != null)
                Image.network(
                  photo['dowanloadUrl'],
                  width: 200,
                  height: 200,
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
                    return Column(
                      children: const [
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

  List<Map<String, dynamic>> photoList = [];
  void getPhotoList(String groupId) async {
    Map<String, dynamic> queryParameters = {
      'groupId': groupId,
    };
    var r = await ProductApi()
        .getFaultVideoAndImage(queryParametrs: queryParameters);
    //将List<dynamic>转换为List<Map<String, dynamic>>
    photoList =
        (r as List).map((item) => item as Map<String, dynamic>).toList();
    logger.i(photoList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("互检作业-派工"),
      ),
      body: _buildBody(),
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
              // if (total > 0)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Text('共 $total 条记录'),
              //         Text('第 $pageNum / ${((total - 1) ~/ pageSize) + 1} 页'),
              //       ],
              //     ),
              //   ),
              // //展示列表信息
              // if (isLoading)
              //   const Center(child: CircularProgressIndicator())
              // else
              if (sys28List.isNotEmpty)
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sys28List.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> item = sys28List[index];
                        return Jt28AssignListItem(
                          item: item,
                          statusMap: status,
                          buildStatusBadge: _buildStatusBadge,
                          onViewMedia: item['repairPicture'] != null &&
                                  item['repairPicture'].toString().isNotEmpty
                              ? () {
                                  PhotoPreviewDialog.show(
                                      context,
                                      item['repairPicture'] ?? "",
                                      ProductApi().getFaultVideoAndImage);
                                }
                              : null,
                          onAssign: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MutualAssignPeople(
                                  jtCode: item['code'],
                                  jtInfo: item,
                                ),
                              ),
                            );
                            if (result == true) {
                              getInfo();
                              showToast('分配成功');
                            }
                          },
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

/// 班组模型
class Team {
  String name; // 班组名（如“北折一组”）
  late List<Member> members; // 成员列表
  Team(this.name, this.members);
}

/// 成员模型
class Member {
  final String name; // 姓名（如“曹阳”）
  final int id; // 工号（如“3368”）
  Member(this.name, this.id);
}

/// 检修项模型
class InspectionItem {
  final String name; // 项名称（如“车底”）
  bool isChecked; // 是否勾选
  InspectionItem(this.name, this.isChecked);
}

class MutualAssignPeople extends StatefulWidget {
  final String jtCode;
  final Map<String, dynamic> jtInfo;
  const MutualAssignPeople({super.key, required this.jtCode, required this.jtInfo});

  @override
  State<MutualAssignPeople> createState() => _MutualAssignPeopleState();
}

// ... existing code ...
class _MutualAssignPeopleState extends State<MutualAssignPeople> {
  String? deptName = Global.profile.permissions?.user.dept?.deptName;

  // 班组数据（模拟）
  late Team _team;

  // 当前选中的成员（默认选第一个）
  late Member _selectedMember;

  // 机型选项（模拟下拉）
  final List<String> _modelOptions = ['HXD3CA', 'HXD3C', 'HXD1D'];
  String _selectedModel = 'HXD3CA';

  // 检修项列表（模拟状态）
  final List<InspectionItem> _inspectionItems = [
    InspectionItem('施修', false),
  ];

  // 添加搜索控制器和过滤后的成员列表
  final TextEditingController _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  var logger = AppLogger.logger;

  void getUserList() async {
    Map<String, dynamic> params = {
      "deptId": widget.jtInfo['deptId'],
      "riskLevel": widget.jtInfo['riskLevel'],
      "isSpecialCheck": false,
    };
    try {
      var response = await ProductApi().getUserListByPostAndDeptId(queryParametrs: params);

      if (response is List) {
        // 将List<dynamic>转换为List<Map<String, dynamic>>
        List<Map<String, dynamic>> userList = response
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
        print(userList);
        // 根据获取的用户列表更新_team.members
        if (userList.isNotEmpty) {
          List<Member> members = userList.map((user) {
            return Member(
              user['nickName'] ?? '未知用户',
              user['userId'] ?? '未知ID',
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
    _team = Team(deptName ?? '默认班组', []);
    // 监听搜索框输入
    _searchController.addListener(() {
      _filterMembers(_searchController.text);
    });
    getUserList();
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
      if (_selectedMember != null) {
        params['mutualInspectionPersonnel'] = _selectedMember.id;
        params['mutualName'] = _selectedMember.name;
      }
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
        title: const Text('开工点名(互检)'),
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
