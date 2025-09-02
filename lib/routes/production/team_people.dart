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

/// 检修项模型
class InspectionItem {
  final String name; // 项名称（如“车底”）
  bool isChecked; // 是否勾选
  InspectionItem(this.name, this.isChecked);
}

class JtAssignPeople extends StatefulWidget {
  final String jtCode;
  const JtAssignPeople({super.key, required this.jtCode});

  @override
  State<JtAssignPeople> createState() => _JtAssignPeopleState();
}

// ... existing code ...
class _JtAssignPeopleState extends State<JtAssignPeople> {
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
    InspectionItem('主修', false),
    InspectionItem('辅修', false),
  ];

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
    Map<String, dynamic> params = {
      // "code": widget.packageCode,
    };
    if (_inspectionItems[0].isChecked) {
      params['executorId'] = _selectedMember.id;
      params['executorName'] = _selectedMember.name;
    }
    if (_inspectionItems[1].isChecked) {
      params['assistantId'] = _selectedMember.id;
      params['assistantName'] = _selectedMember.name;
    }
    try {
      logger.i(params);
      var response = await ProductApi()
          .updateTaskInstructPackageRepairInfo(queryParametrs: params);

      if (response is List) {
        // 将List<dynamic>转换为List<Map<String, dynamic>>
      }
      if (response['code'] == 200) {
        showToast("确认成功");
      }
    } catch (e) {
      // 错误处理
      print('获取用户列表失败: $e');
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
        title: const Text('开工点名(检修)'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Row(
        children: [
          // 左侧：人员列表
          Container(
            width: 160,
            color: Colors.white,
            child: ListView(
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
                // 添加搜索框
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
                        '${member.name}(${member.id})',
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
