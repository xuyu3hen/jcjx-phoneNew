import '../../index.dart';

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

class JtAssignPeople extends StatefulWidget {
  final String jtCode;
  const JtAssignPeople({super.key, required this.jtCode});

  @override
  State<JtAssignPeople> createState() => _JtAssignPeopleState();
}

class _JtAssignPeopleState extends State<JtAssignPeople> {
  String? deptName = Global.profile.permissions?.user.dept?.deptName;

  // 班组数据（模拟）
  late Team _team;

  // 当前选中的成员（默认选第一个）
  late Member _selectedMember;

  // 主修和辅修人员
  Member? _mainRepairMember;
  Member? _assistantMember;

  // 添加搜索控制器和过滤后的成员列表
  final TextEditingController _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  var logger = AppLogger.logger;

  void getUserList() async {
    Map<String, dynamic> params = {
      "deptId": Global.profile.permissions?.user.dept?.deptId,
      "pageNum": 0,
      "pageSize": 0,
    };
    try {
      var response = await ProductApi().getTeamUser(queryParametrs: params);

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
              user['userId'] ?? 0,
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
      // 必须至少选择一个主修或辅修人员
      if (_mainRepairMember == null && _assistantMember == null) {
        showToast("请至少选择一名主修或辅修人员");
        return;
      }

      // 构建参数
      Map<String, dynamic> params = {
        "code": widget.jtCode,
        'completeStatus': 0
      };

      // 设置主修人员
      if (_mainRepairMember != null) {
        params['repairPersonnel'] = _mainRepairMember!.id;
        params['repairName'] = _mainRepairMember!.name;
      }

      // 设置辅修人员
      if (_assistantMember != null) {
        params['assistant'] = _assistantMember!.id;
        params['assistantName'] = _assistantMember!.name;
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

  // 设置主修人员
  void _setMainRepair(Member member) {
    setState(() {
      _mainRepairMember = member;
    });
  }

  // 设置辅修人员
  void _setAssistant(Member member) {
    setState(() {
      _assistantMember = member;
    });
  }

  // 清除主修人员
  void _clearMainRepair() {
    setState(() {
      _mainRepairMember = null;
    });
  }

  // 清除辅修人员
  void _clearAssistant() {
    setState(() {
      _assistantMember = null;
    });
  }

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
        title: const Text('开工点名(机统28)'),
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
                        final isMainRepair = member == _mainRepairMember;
                        final isAssistant = member == _assistantMember;
                        
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
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${member.name}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.blue : Colors.black,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // 主修按钮
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_mainRepairMember == member) {
                                          _clearMainRepair();
                                        } else {
                                          _setMainRepair(member);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isMainRepair 
                                            ? Colors.green 
                                            : Colors.grey[300],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        minimumSize: const Size(0, 0),
                                      ),
                                      child: Text(
                                        '主修',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMainRepair 
                                              ? Colors.white 
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // 辅修按钮
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_assistantMember == member) {
                                          _clearAssistant();
                                        } else {
                                          _setAssistant(member);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAssistant 
                                            ? Colors.orange 
                                            : Colors.grey[300],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        minimumSize: const Size(0, 0),
                                      ),
                                      child: Text(
                                        '辅修',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isAssistant 
                                              ? Colors.white 
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                  const Text(
                    '已选择人员：',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 显示已选择的主修人员
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '主修：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mainRepairMember != null
                                ? '${_mainRepairMember!.name}'
                                : '未选择',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 显示已选择的辅修人员
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '辅修：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _assistantMember != null
                                ? '${_assistantMember!.name}'
                                : '未选择',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 底部按钮：固定检修项
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 提交检修项逻辑
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