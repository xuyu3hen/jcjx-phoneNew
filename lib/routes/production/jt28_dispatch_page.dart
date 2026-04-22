import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:jcjx_phone/api/production_api.dart';
import 'package:jcjx_phone/common/funs.dart';
import 'package:jcjx_phone/common/global.dart';

class Jt28DispatchPage extends StatefulWidget {
  final Map<String, dynamic> noticeItem;
  final List<Map<String, dynamic>> workList;

  const Jt28DispatchPage({
    Key? key,
    required this.noticeItem,
    required this.workList,
  }) : super(key: key);

  @override
  State<Jt28DispatchPage> createState() => _Jt28DispatchPageState();
}

class _Jt28DispatchPageState extends State<Jt28DispatchPage> {
  List<Map<String, dynamic>> _workList = [];
  final Map<int, List<Map<String, dynamic>>> _teamsByWorkshopId = {};
  final Map<int, List<Map<String, dynamic>>> _usersByTeamId = {};

  // For Personnel Section
  List<Map<String, dynamic>> _personnelList = [];
  int _peopleCount = 0;
  String _departureTime = '';

  List<Map<String, dynamic>> _deptList = [];

  Map<String, dynamic>? _signDept;
  Map<String, dynamic>? _signTeam;
  List<Map<String, dynamic>> _signUsers = [];
  
  List<Map<String, dynamic>> _signeeList = [
    {
      'signDept': null,
      'signTeam': null,
      'signUsers': <Map<String, dynamic>>[],
    }
  ];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': 101},
      );
      if (res is List && res.isNotEmpty) {
        final children = res[0]['children'];
        if (children is List) {
          if (mounted) {
            setState(() {
              _deptList = children.map((e) => Map<String, dynamic>.from(e)).toList();
            });
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _loadTeamsForWorkshopsById(int workshopId) async {
    if (_teamsByWorkshopId.containsKey(workshopId)) return;
    try {
      final res = await ProductApi().getDeptTreeByParentIdList(
        queryParametrs: {'parentIdList': workshopId},
      );
      if (res is List && res.isNotEmpty) {
        final children = res[0]['children'];
        if (children is List && mounted) {
          setState(() {
            _teamsByWorkshopId[workshopId] = children.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        } else if (mounted) {
          setState(() { _teamsByWorkshopId[workshopId] = []; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _teamsByWorkshopId[workshopId] = []; });
      }
    }
  }

  Future<Map<String, dynamic>?> _showSearchableListDialog({
    required String title,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required String valueKey,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = items.where((e) {
              final label = (e[labelKey] ?? '').toString();
              return label.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => query = v),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text((item[labelKey] ?? '').toString()),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _initData() {
    // Clone workList
    _workList = widget.workList.map((e) {
      final clone = Map<String, dynamic>.from(e);
      List<dynamic> deptList = [];
      if (clone['masAfterSaleWorkDeptList'] is List) {
        deptList = List<dynamic>.from(clone['masAfterSaleWorkDeptList']);
      } else if (clone['workDeptList'] is List) {
        deptList = List<dynamic>.from(clone['workDeptList']);
      }
      clone['masAfterSaleWorkDeptList'] = deptList.map((d) {
        final dMap = Map<String, dynamic>.from(d as Map);
        if (dMap['userIdList'] is List) {
          dMap['userIdList'] = List<dynamic>.from(dMap['userIdList']);
        }
        if (dMap['userNameList'] is List) {
          dMap['userNameList'] = List<dynamic>.from(dMap['userNameList']);
        }
        return dMap;
      }).toList();
      return clone;
    }).toList();

    // Init Personnel List
    final rawPeople = _pickList(
        widget.noticeItem, ['masAfterSaleUserList', 'userList', 'peopleList']);
    _personnelList = rawPeople.map((e) {
      final clone = Map<String, dynamic>.from(e);
      // Initialize personTypeDisplay
      final identityRaw = _pickText(clone, ['identity', 'userType', 'roleName', 'typeName', 'postName', 'dutyName']).trim();
      if (identityRaw == '1') {
        clone['personTypeDisplay'] = '队长';
      } else if (identityRaw == '2') {
        clone['personTypeDisplay'] = '带队干部';
      } else if (identityRaw == '0') {
        clone['personTypeDisplay'] = '队员';
      } else if (identityRaw.isNotEmpty &&
          (identityRaw.contains('队长') || identityRaw.contains('队员') || identityRaw.contains('带队干部'))) {
        clone['personTypeDisplay'] = identityRaw;
      }
      return clone;
    }).toList();

    final pc = _pickText(widget.noticeItem, ['personnelNumber', 'peopleCount']);
    _peopleCount = int.tryParse(pc) ?? _personnelList.length;
    _departureTime = _pickText(
        widget.noticeItem, ['personnelDepartureTime', 'departureTime']);

    _loadTeamsForWorkshops();
  }

  // --- Helper Methods ---
  String _asText(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final t = _asText(map[k]);
      if (t.isNotEmpty) return t;
    }
    for (final v in map.values) {
      if (v is Map) {
        final t = _pickText(Map<String, dynamic>.from(v), keys);
        if (t.isNotEmpty) return t;
      } else if (v is List) {
        for (final item in v) {
          if (item is Map) {
            final t = _pickText(Map<String, dynamic>.from(item), keys);
            if (t.isNotEmpty) return t;
          }
        }
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _pickList(
      Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      dynamic raw = v;
      if (raw is Map) raw = raw['rows'] ?? raw['records'] ?? raw['data'] ?? raw;
      if (raw is List) {
        final parsed = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    }
    for (final v in map.values) {
      if (v is Map) {
        final parsed = _pickList(Map<String, dynamic>.from(v), keys);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return <Map<String, dynamic>>[];
  }

  String _requiredText(String s) => s.trim().isEmpty ? '-' : s.trim();

  int? _parseId(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }
  // --- End Helpers ---

  Future<void> _loadTeamsForWorkshops() async {
    setState(() => _loading = true);
    for (final work in _workList) {
      final workshopId = _parseId(work['deptId'] ?? work['responsibleDeptId']);
      if (workshopId != null && !_teamsByWorkshopId.containsKey(workshopId)) {
        try {
          final res = await ProductApi().getDeptTreeByParentIdList(
            queryParametrs: {'parentIdList': workshopId},
          );
          if (res is List && res.isNotEmpty) {
            final children = res[0]['children'];
            if (children is List) {
              _teamsByWorkshopId[workshopId] =
                  children.map((e) => Map<String, dynamic>.from(e)).toList();
            } else {
              _teamsByWorkshopId[workshopId] = [];
            }
          }
        } catch (e) {
          _teamsByWorkshopId[workshopId] = [];
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _loadUsersForTeam(int teamId) async {
    if (_usersByTeamId.containsKey(teamId)) return;
    try {
      final res = await ProductApi().getUserListByDeptId(
        queryParametrs: {'deptId': teamId},
      );
      List<Map<String, dynamic>> userList = [];
      if (res is Map && res['rows'] is List) {
        for (var u in res['rows']) {
          if (u is Map) userList.add(Map<String, dynamic>.from(u));
        }
      } else if (res is List) {
        for (var u in res) {
          if (u is Map) userList.add(Map<String, dynamic>.from(u));
        }
      }
      
      setState(() {
        _usersByTeamId[teamId] = userList;
      });
    } catch (e) {
      setState(() {
        _usersByTeamId[teamId] = [];
      });
    }
  }

  void _addAssignment(Map<String, dynamic> work) {
    final workshopId = _parseId(work['deptId'] ?? work['responsibleDeptId']);
    final workshopName = work['deptName'] ?? work['responsibleDeptName'] ?? '';
    final deptList =
        work['masAfterSaleWorkDeptList'] as List<Map<String, dynamic>>;
        
    // Generate a temporary unique code if missing, to maintain structure parity
    final shuntingCode = work['afterSaleShuntingCode'] ?? '';
    final workCode = work['afterSaleWorkCode'] ?? '';
    
    setState(() {
      deptList.add({
        'afterSaleShuntingCode': shuntingCode,
        'afterSaleWorkCode': workCode,
        'deptId': workshopId,
        'deptName': workshopName,
        'teamId': null,
        'teamName': null,
        'userIdList': <dynamic>[],
        'userNameList': <dynamic>[],
      });
    });
  }

  void _removeAssignment(
      Map<String, dynamic> work, Map<String, dynamic> assignment) {
    final deptList =
        work['masAfterSaleWorkDeptList'] as List<Map<String, dynamic>>;
    setState(() {
      deptList.remove(assignment);
    });
  }

  void _submit() async {
    if (!mounted) return;
    
    // Check if the user is trying to submit but lacks permission/data
    final user = Global.profile.permissions?.user;
    if (user == null) {
      showToast('未获取到用户信息');
      return;
    }

    showToast('派工数据已收集，正在保存...');
    
    // Prepare the update parameters
    // Based on user request, the payload contains:
    // code, createdTime, jt28Code, masAfterSaleUserList, masAfterSaleWorkList, shuntingNoticeList
    
    final noticeItem = widget.noticeItem;
    final String code = noticeItem['code'] ?? noticeItem['noticeCode'] ?? '';
    final String createdTime = noticeItem['createdTime'] ?? '';
    final String jt28Code = noticeItem['jt28Code'] ?? noticeItem['masSaleInformationCode'] ?? '';
    
    // 组装 shuntingNoticeList 参数，更新状态或相关信息
    List<Map<String, dynamic>> shuntingNoticeList = [];
    if (noticeItem['shuntingNoticeList'] is List) {
      shuntingNoticeList = List<Map<String, dynamic>>.from(noticeItem['shuntingNoticeList']);
    } else if (noticeItem['masAfterSaleAuditList'] is List) {
      shuntingNoticeList = List<Map<String, dynamic>>.from(noticeItem['masAfterSaleAuditList']);
    }
    
    if (shuntingNoticeList.isEmpty) {
      shuntingNoticeList.add({});
    }

    final existingUserIds = _personnelList.map((e) => e['userId'].toString()).toSet();
    for (var work in _workList) {
      final deptList = work['masAfterSaleWorkDeptList'] ?? [];
      if (deptList is List) {
        for (var dept in deptList) {
          if (dept is Map) {
            final uIdList = dept['userIdList'];
            final uNameList = dept['userNameList'];
            
            List<dynamic> ids = [];
            List<dynamic> names = [];
            
            if (uIdList is String) {
              ids = uIdList.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } else if (uIdList is List) {
              ids = List<dynamic>.from(uIdList);
            }
            
            if (uNameList is String) {
              names = uNameList.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } else if (uNameList is List) {
              names = List<dynamic>.from(uNameList);
            }

            for (int i = 0; i < ids.length; i++) {
              final uId = ids[i].toString();
              if (uId.isNotEmpty && !existingUserIds.contains(uId)) {
                _personnelList.add({
                  'deptId': dept['deptId'],
                  'deptName': dept['deptName'],
                  'workshop': dept['deptName'],
                  'teamId': dept['teamId'],
                  'teamName': dept['teamName'],
                  'team': dept['teamName'],
                  'userId': int.tryParse(uId) ?? uId,
                  'userName': i < names.length ? names[i] : '',
                  'nickName': i < names.length ? names[i] : '',
                  'identity': '0',
                  'personTypeDisplay': '队员',
                });
                existingUserIds.add(uId);
              }
            }
          }
        }
      }
    }
    
    if (_signeeList.isNotEmpty) {
      for (var s in shuntingNoticeList) {
        // Collect all departments and users
        final deptNames = _signeeList.where((e) => e['signDept'] != null).map((e) => e['signDept']['deptName']).join(',');
        final deptIds = _signeeList.where((e) => e['signDept'] != null).map((e) => e['signDept']['deptId']).join(',');
        
        final List<Map<String, dynamic>> allUsers = [];
        for (var e in _signeeList) {
          if (e['signUsers'] != null && (e['signUsers'] as List).isNotEmpty) {
            allUsers.addAll(List<Map<String, dynamic>>.from(e['signUsers']));
          }
        }
        
        if (deptNames.isNotEmpty) s['auditDeptName'] = deptNames;
        if (deptIds.isNotEmpty) s['auditDeptId'] = deptIds;
        
        if (allUsers.isNotEmpty) {
          s['auditUserName'] = allUsers.map((u) => u['nickName'] ?? u['userName']).join(',');
          s['auditUserId'] = allUsers.map((u) => u['userId']).join(',');
        }
      }
    }
    
    final payload = {
      'code': code,
      'createdTime': createdTime,
      'jt28Code': jt28Code,
      'masAfterSaleUserList': _personnelList.map((person) {
        final clonePerson = Map<String, dynamic>.from(person);
        // 如果没有身份信息或者选了“请选择”，给个默认的队员 (0) 
        if (clonePerson['identity'] == null || clonePerson['identity'].toString().isEmpty) {
          clonePerson['identity'] = '0'; 
        }
        return clonePerson;
      }).toList(),
      'masAfterSaleWorkList': _workList.map((work) {
        final cloneWork = Map<String, dynamic>.from(work);
        if (cloneWork['masAfterSaleWorkDeptList'] is List) {
          final deptList = List<dynamic>.from(cloneWork['masAfterSaleWorkDeptList']);
          cloneWork['masAfterSaleWorkDeptList'] = deptList.map((dept) {
            final cloneDept = Map<String, dynamic>.from(dept as Map);
            
            // Ensure userIdList is properly joined as string if it's a list
            if (cloneDept['userIdList'] is List) {
              cloneDept['userIdList'] = (cloneDept['userIdList'] as List).join(', ');
            }
            
            // Ensure userNameList is properly joined as string if it's a list
            if (cloneDept['userNameList'] is List) {
              cloneDept['userNameList'] = (cloneDept['userNameList'] as List).join(', ');
            }
            
            return cloneDept;
          }).toList();
        }
        return cloneWork;
      }).toList(),
      'shuntingNoticeList': shuntingNoticeList,
      'masAfterSalesSubpartList': noticeItem['masAfterSalesSubpartList'] ?? [],
    };
    
    try {
      final res = await ProductApi().update(data: payload);
      if (res != null && res['code'] == 200) {
        if (mounted) {
          showToast('保存成功');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          showToast('保存失败: ${res?['msg'] ?? '未知错误'}');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast('保存失败，请检查网络');
      }
    }
  }

  Future<void> _selectUsers(Map<String, dynamic> assignment, int teamId) async {
    await _loadUsersForTeam(teamId);
    final users = _usersByTeamId[teamId] ?? [];
    if (users.isEmpty) {
      if (mounted) showToast('该班组下没有人员');
      return;
    }

    final rawUserIdList = assignment['userIdList'];
    List<dynamic> currentSelectedIds = [];
    if (rawUserIdList is String) {
      currentSelectedIds = rawUserIdList
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => int.tryParse(e) ?? e) // Convert string IDs back to integer if possible to match types
          .toList();
    } else if (rawUserIdList is List) {
      currentSelectedIds = rawUserIdList.map((e) => e is String ? (int.tryParse(e) ?? e) : e).toList();
    }

    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) {
        return _MultiSelectUserDialog(
          users: users,
          initialSelectedIds: currentSelectedIds,
        );
      },
    );

    if (result != null) {
      setState(() {
        assignment['userIdList'] = result.map((e) => e['userId']).toList();
        assignment['userNameList'] =
            result.map((e) => e['nickName'] ?? e['userName']).toList();
            
        // 自动向顶部人员列表中新增所选人员（如果不存在的话）
        final existingUserIds = _personnelList.map((e) => e['userId'].toString()).toSet();
        for (int i = 0; i < result.length; i++) {
          final u = result[i];
          final uId = u['userId'].toString();
          if (uId.isNotEmpty && !existingUserIds.contains(uId)) {
            _personnelList.add({
              'deptId': assignment['deptId'],
              'deptName': assignment['deptName'],
              'workshop': assignment['deptName'],
              'teamId': assignment['teamId'],
              'teamName': assignment['teamName'],
              'team': assignment['teamName'],
              'userId': int.tryParse(uId) ?? uId,
              'userName': u['nickName'] ?? u['userName'] ?? '',
              'nickName': u['nickName'] ?? u['userName'] ?? '',
              'personName': u['nickName'] ?? u['userName'] ?? '',
              'identity': '0',
              'personTypeDisplay': '队员',
              'phone': u['phonenumber'] ?? u['phoneNumber'] ?? u['phone'] ?? u['tel'] ?? '',
            });
            existingUserIds.add(uId);
            _peopleCount = _personnelList.length;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('售后服务通知单-车间派工', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('确认', style: TextStyle(color: Colors.black87)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 16),

                  // JT28 Editable Section
                  const Text(
                    '您设置的施修人中，第一个班组中的第一位自动成为主修，第一个班组中的其他人自动为辅修。后续班组及人员仅记录。',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  ..._workList.map((work) => _buildWorkCard(work)).toList(),
                  const SizedBox(height: 16),

                  // Personnel Section
                  _buildPersonnelSection(),
                  const SizedBox(height: 16),

                  // Parts Section
                  _buildPartsSection(),
                  const SizedBox(height: 16),

                  // Safety Section
                  _buildSafetySection(),
                  const SizedBox(height: 16),

                  // Sign-in Section
                  _buildSignInSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    final item = widget.noticeItem;
    final noticeNo =
        _pickText(item, ['encode', 'noticeCode', 'noticeNo', 'code']);
    final model = _pickText(item, ['typeName', 'trainType', 'model']);
    final trainNum = _pickText(item, ['trainNum', 'serialNumber']);
    final depot = _pickText(
        item, ['assignSegmentName', 'maintenanceSection', 'depotName']);
    final repairStatus =
        _pickText(item, ['repairStatus', 'repairProcName', 'repairTimes']);
    final contact = _pickText(item, ['customerContact', 'contactPerson']);
    final phone = _pickText(item, ['tel', 'customerPhone', 'phone']);
    final location = _pickText(item, ['trainLocation', 'parkingLocation']);
    final faultCategory =
        _pickText(item, ['failureCategory', 'faultCategory', 'faultType']);
    final faultTime =
        _pickText(item, ['faultTime', 'createdTime', 'applyTime']);
    final faultDesc =
        _pickText(item, ['faultInformation', 'faultDesc', 'faultPhenomenon']);
    final faultSituation = _pickText(item, ['faultSituation', 'faultSummary']);

    TableRow row3(
        String l1, String v1, String l2, String v2, String l3, String v3) {
      final headerStyle = TextStyle(color: Colors.grey[700], fontSize: 13);
      final valueStyle = const TextStyle(fontSize: 13);
      Widget cell(String text, TextStyle? style, {bool header = false}) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          color: header ? Colors.grey[100] : null,
          child: Text(text, style: style),
        );
      }

      return TableRow(
        children: [
          cell(l1, headerStyle, header: true),
          cell(_requiredText(v1), valueStyle),
          cell(l2, headerStyle, header: true),
          cell(_requiredText(v2), valueStyle),
          cell(l3, headerStyle, header: true),
          cell(_requiredText(v3), valueStyle),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '通知单编号：${_requiredText(noticeNo)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: Table(
                  border:
                      TableBorder.all(color: Colors.grey.shade300, width: 0.8),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(110),
                    1: FixedColumnWidth(220),
                    2: FixedColumnWidth(110),
                    3: FixedColumnWidth(220),
                    4: FixedColumnWidth(110),
                    5: FixedColumnWidth(220),
                  },
                  children: [
                    row3('故障机型', model, '故障车号', trainNum, '配属段', depot),
                    row3(
                        '客户联系人', contact, '联系电话', phone, '修程/修次', repairStatus),
                    row3('机车停留地点', location, '故障类别', faultCategory, '故障时间',
                        faultTime),
                    row3('故障现象', faultDesc, '故障概况', faultSituation, '处置方案',
                        _pickText(item, ['disposalPlan', 'repairScheme'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canDispatch(int? workshopId) {
    if (workshopId == null) return false;
    final user = Global.profile.permissions?.user;
    if (user == null) return false;
    if (user.deptId == workshopId) return true;
    if (user.dept?.parentId == workshopId) return true;
    return false;
  }

  Widget _buildWorkCard(Map<String, dynamic> work) {
    final workshopId = _parseId(work['deptId'] ?? work['responsibleDeptId']);
    final workshopName = _pickText(work, ['deptName', 'responsibleDeptName']);
    final bool canDispatch = _canDispatch(workshopId);

    final config = _pickText(work, [
      'configNodeName',
      'structure',
      'configName',
      'componentName',
      'nodeName',
      'config'
    ]);
    final processingMethod = _pickText(work, [
      'jtDictName',
      'jtDictCode',
      'processingMethod',
      'processingMethodName',
      'requiredProcessingMethodName',
      'requiredProcessingMethod'
    ]);
    final repairPlan = _pickText(work, [
      'repairProcContent',
      'repairScheme',
      'repairProgram',
      'repairPlan',
      'repairStatus',
      'maintenanceNotice'
    ]);
    final risk = _pickText(work, ['riskLevel', 'riskLevelName']);
    final factory = _pickText(work,
        ['outsourcingVendor', 'outSourcingFactory', 'outsourcingFactory']);
    final techGuide = _pickText(
        work, ['techGuideName', 'technicalGuidance', 'guide', 'techGuide']);

    final deptList =
        work['masAfterSaleWorkDeptList'] as List<Map<String, dynamic>>;

    // A customized row that looks more like a table layout
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Read-only section
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (config.isNotEmpty) _infoChip('构型', config),
                if (processingMethod.isNotEmpty)
                  _infoChip('加工方法', processingMethod),
                if (repairPlan.isNotEmpty) _infoChip('施修方案', repairPlan),
                if (risk.isNotEmpty) _infoChip('风险等级', risk),
                if (factory.isNotEmpty) _infoChip('外包厂家', factory),
                if (workshopName.isNotEmpty) _infoChip('责任车间', workshopName),
                if (techGuide.isNotEmpty) _infoChip('技术指导', techGuide),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Assignments section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ...deptList
                    .map((assignment) =>
                        _buildAssignmentRow(work, assignment, workshopId, canDispatch))
                    .toList(),
                if (canDispatch)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          workshopId == null ? null : () => _addAssignment(work),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新增派工'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection() {
    final item = widget.noticeItem;
    final rows = _pickList(item, ['masAfterSaleSubpartList']);

    if (rows.isEmpty) return const SizedBox();

    final displayRows = rows.map((r) {
      final mapped = Map<String, dynamic>.from(r);
      final raw =
          _pickText(r, ['recycleType', 'disposalType', 'disposalWay']).trim();
      String label;
      if (raw == '0') {
        label = '配送';
      } else if (raw == '1') {
        label = '回收';
      } else {
        label = raw;
      }
      mapped['disposalTypeDisplay'] = label.isEmpty ? '-' : label;
      return mapped;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '配件信息',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          '配件周转要求：${_pickText(item, [
                'subpartTurnoverRequirements',
                'subpartTurnoverReqirements',
                'turnoverRequirements'
              ])}',
          style: const TextStyle(fontSize: 13, color: Colors.green),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 38,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: Text('配件名称')),
              DataColumn(label: Text('规格型号')),
              DataColumn(label: Text('发货时间')),
              DataColumn(label: Text('数量')),
              DataColumn(label: Text('发货方式')),
              DataColumn(label: Text('处置方式')),
              DataColumn(label: Text('责任车间')),
              DataColumn(label: Text('责任班组')),
              DataColumn(label: Text('责任人')),
            ],
            rows: displayRows.map((r) {
              return DataRow(cells: [
                DataCell(Text(_requiredText(_pickText(r, [
                  'configName',
                  'configNodeName',
                  'materialName',
                  'partsName',
                  'accessoryName',
                  'name'
                ])))),
                DataCell(Text(_requiredText(_pickText(r, [
                  'modelInfoName',
                  'modelInfoCode',
                  'spec',
                  'specification',
                  'model',
                  'materialModel'
                ])))),
                DataCell(Text(_requiredText(_pickText(
                    r, ['deliveryTime', 'sendTime', 'materialDeliveryTime'])))),
                DataCell(Text(
                    _requiredText(_pickText(r, ['quantity', 'count', 'num'])))),
                DataCell(Text(_requiredText(_pickText(r, [
                  'deliveryMethod',
                  'sendWay',
                  'deliveryWay',
                  'sendType'
                ])))),
                DataCell(
                    Text(_requiredText(_pickText(r, ['disposalTypeDisplay'])))),
                DataCell(Text(_requiredText(_pickText(r, [
                  'responsibleDeptName',
                  'deptName',
                  'workshop',
                  'responsibilityDeptName'
                ])))),
                DataCell(Text(_requiredText(_pickText(r, [
                  'responsibleTeamName',
                  'teamName',
                  'team',
                  'responsibilityTeamName'
                ])))),
                DataCell(Text(_requiredText(_pickText(r, [
                  'responsibleUserName',
                  'responsibilityUserName',
                  'userName',
                  'nickName',
                  'responsibilityUser'
                ])))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonnelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '人员信息',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _personnelList.insert(0, {
                    'deptId': null,
                    'teamId': null,
                    'userId': null,
                  });
                  _peopleCount = _personnelList.length;
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('增加人员信息'),
            ),
            const SizedBox(width: 16),
            const Text('人数：'),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (_peopleCount > 0) setState(() => _peopleCount--);
              },
            ),
            Text('$_peopleCount'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() => _peopleCount++);
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '出发时间：${_departureTime.isEmpty ? '-' : _departureTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_personnelList.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 600, // 给足够宽度使其左右滑动
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey[100],
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: const Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Text('车间',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 3,
                                  child: Text('班组',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text('人员',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text('人员类型',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 3,
                                  child: Text('电话',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text('操作',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        ..._personnelList.map((person) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey[300]!)),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () async {
                              final selected = await _showSearchableListDialog(
                                title: '选择车间',
                                items: _deptList,
                                labelKey: 'deptName',
                                valueKey: 'deptId',
                              );
                              if (selected != null) {
                                setState(() {
                                  person['deptId'] = selected['deptId'];
                                  person['deptName'] = selected['deptName'];
                                  person['workshop'] = selected['deptName'];
                                  person['teamId'] = null;
                                  person['teamName'] = null;
                                  person['userId'] = null;
                                  person['userName'] = null;
                                });
                                final deptId = _parseId(selected['deptId']);
                                if (deptId != null) {
                                  await _loadTeamsForWorkshopsById(deptId);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                              child: Text(_pickText(person, ['deptName', 'workshop', 'teamDeptName']).isEmpty ? '请选择' : _pickText(person, ['deptName', 'workshop', 'teamDeptName']), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () async {
                              final deptId = _parseId(person['deptId']);
                              if (deptId == null) {
                                showToast('请先选择车间');
                                return;
                              }
                              final teams = _teamsByWorkshopId[deptId] ?? [];
                              final selected = await _showSearchableListDialog(
                                title: '选择班组',
                                items: teams,
                                labelKey: 'deptName',
                                valueKey: 'deptId',
                              );
                              if (selected != null) {
                                setState(() {
                                  person['teamId'] = selected['deptId'];
                                  person['teamName'] = selected['deptName'];
                                  person['team'] = selected['deptName'];
                                  person['userId'] = null;
                                  person['userName'] = null;
                                });
                                final teamId = _parseId(selected['deptId']);
                                if (teamId != null) {
                                  await _loadUsersForTeam(teamId);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                              child: Text(_pickText(person, ['teamName', 'team', 'groupName']).isEmpty ? '请选择' : _pickText(person, ['teamName', 'team', 'groupName']), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () async {
                              final teamId = _parseId(person['teamId']);
                              final deptId = _parseId(person['deptId']);
                              
                              if (teamId == null && deptId == null) {
                                showToast('请先选择班组或车间');
                                return;
                              }
                              
                              List<Map<String, dynamic>> users = [];
                              if (teamId != null) {
                                users = _usersByTeamId[teamId] ?? [];
                              } else if (deptId != null) {
                                // 如果只选了车间，则拉取车间下的人员
                                SmartDialog.showLoading(msg: '正在获取人员列表...');
                                final res = await ProductApi().getUserListByDeptId(
                                  queryParametrs: {'deptId': deptId},
                                );
                                SmartDialog.dismiss();
                                if (res is Map && res['rows'] is List) {
                                  for (var u in res['rows']) {
                                    if (u is Map) users.add(Map<String, dynamic>.from(u));
                                  }
                                } else if (res is List) {
                                  for (var u in res) {
                                    if (u is Map) users.add(Map<String, dynamic>.from(u));
                                  }
                                }
                              }
                              
                              final selected = await _showSearchableListDialog(
                                title: '选择人员',
                                items: users,
                                labelKey: 'nickName',
                                valueKey: 'userId',
                              );
                              if (selected != null) {
                                setState(() {
                                  person['userId'] = selected['userId'];
                                  person['userName'] = selected['nickName'] ?? selected['userName'];
                                  person['nickName'] = selected['nickName'] ?? selected['userName'];
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                              child: Text(_pickText(person, ['userName', 'nickName', 'name', 'personName']).isEmpty ? '请选择' : _pickText(person, ['userName', 'nickName', 'name', 'personName']), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () async {
                              final types = [
                                {'label': '队长', 'value': '1'},
                                {'label': '带队干部', 'value': '2'},
                                {'label': '队员', 'value': '0'},
                              ];
                              final selected = await _showSearchableListDialog(
                                title: '选择人员类型',
                                items: types,
                                labelKey: 'label',
                                valueKey: 'value',
                              );
                              if (selected != null) {
                                setState(() {
                                  person['identity'] = selected['value'];
                                  person['personTypeDisplay'] = selected['label'];
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                              child: Text(_pickText(person, ['personTypeDisplay', 'identity']).isEmpty ? '请选择' : _pickText(person, ['personTypeDisplay', 'identity']), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                                    child: TextFormField(
                              initialValue: _pickText(person, ['phone', 'tel', 'phoneNumber', 'telephone']),
                              onChanged: (val) {
                                person['phone'] = val;
                                person['tel'] = val;
                                person['phoneNumber'] = val;
                              },
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                border: InputBorder.none,
                                hintText: '请输入',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: InkWell(
                                      onTap: () {
                                setState(() {
                                  _personnelList.remove(person);
                                  _peopleCount = _personnelList.length;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                    Text('删除', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  }

  Widget _buildSafetySection() {
    final item = widget.noticeItem;
    final otherSafetyTips =
        _pickText(item, ['safetyTips', 'saftyTips', 'otherSafetyTips']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('安全提示',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
        const SizedBox(height: 8),
        if (otherSafetyTips.isNotEmpty)
          Text('其他安全提示: $otherSafetyTips',
              style: const TextStyle(fontSize: 13, color: Colors.red)),
      ],
    );
  }

  Widget _buildSignInSection() {
    final item = widget.noticeItem;
    final remark = _pickText(item, ['remark', 'comment']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remark.isNotEmpty) ...[
          const Text('备注:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(remark),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Text('签收人',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _signeeList.add({
                    'signDept': null,
                    'signTeam': null,
                    'signUsers': <Map<String, dynamic>>[],
                  });
                });
              },
              child: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._signeeList.asMap().entries.map((entry) {
          final index = entry.key;
          final signee = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await _showSearchableListDialog(
                        title: '选择部门',
                        items: _deptList,
                        labelKey: 'deptName',
                        valueKey: 'deptId',
                      );
                      if (selected != null) {
                        setState(() {
                          signee['signDept'] = selected;
                          signee['signTeam'] = null;
                          signee['signUsers'] = <Map<String, dynamic>>[];
                        });
                        final deptId = _parseId(selected['deptId']);
                        if (deptId != null) {
                          await _loadTeamsForWorkshopsById(deptId);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                      child: Text(signee['signDept'] != null ? (signee['signDept']['deptName'] ?? '请选择部门') : '请选择部门', style: TextStyle(color: signee['signDept'] != null ? Colors.black87 : Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final deptId = signee['signDept'] != null ? _parseId(signee['signDept']['deptId']) : null;
                      final teams = deptId != null ? (_teamsByWorkshopId[deptId] ?? <Map<String, dynamic>>[]) : <Map<String, dynamic>>[];
                      final bool disabled = deptId != null && teams.isEmpty;
                      
                      return InkWell(
                        onTap: disabled ? null : () async {
                          if (deptId == null) {
                            showToast('请先选择部门');
                            return;
                          }
                          final selected = await _showSearchableListDialog(
                            title: '选择班组',
                            items: teams,
                            labelKey: 'deptName',
                            valueKey: 'deptId',
                          );
                          if (selected != null) {
                            setState(() {
                              signee['signTeam'] = selected;
                              signee['signUsers'] = <Map<String, dynamic>>[];
                            });
                            final teamId = _parseId(selected['deptId']);
                            if (teamId != null) {
                              await _loadUsersForTeam(teamId);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!), 
                            borderRadius: BorderRadius.circular(4),
                            color: disabled ? Colors.grey[200] : Colors.transparent,
                          ),
                          child: Text(
                            disabled ? '无班组' : (signee['signTeam'] != null ? (signee['signTeam']['deptName'] ?? '请选择班组') : '请选择班组'), 
                            style: TextStyle(color: (signee['signTeam'] != null && !disabled) ? Colors.black87 : Colors.grey), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                        ),
                      );
                    }
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final targetDeptId = signee['signTeam'] != null 
                          ? _parseId(signee['signTeam']['deptId']) 
                          : (signee['signDept'] != null ? _parseId(signee['signDept']['deptId']) : null);
                          
                      if (targetDeptId == null) {
                        showToast('请先选择签收部门');
                        return;
                      }
                      
                      SmartDialog.showLoading(msg: '正在获取人员列表...');
                      final users = await ProductApi().getUserListByDeptId(
                        queryParametrs: {
                          'deptId': targetDeptId,
                        }
                      );
                      SmartDialog.dismiss();
                      
                      final List<Map<String, dynamic>> userList = [];
                      if (users is Map && users['rows'] is List) {
                        for (var u in users['rows']) {
                          if (u is Map) userList.add(Map<String, dynamic>.from(u));
                        }
                      } else if (users is List) {
                        for (var u in users) {
                          if (u is Map) userList.add(Map<String, dynamic>.from(u));
                        }
                      }
                      
                      final List<Map<String, dynamic>> currentUsers = List<Map<String, dynamic>>.from(signee['signUsers'] ?? []);
                      
                      final selected = await showDialog<List<Map<String, dynamic>>>(
                        context: context,
                        builder: (ctx) {
                          return _MultiSelectUserDialog(
                            users: userList,
                            initialSelectedIds: currentUsers.map((u) => u['userId']).toList(),
                          );
                        },
                      );
                      
                      if (selected != null) {
                        setState(() {
                          signee['signUsers'] = selected;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        (signee['signUsers'] != null && (signee['signUsers'] as List).isNotEmpty) 
                            ? (signee['signUsers'] as List).map((u) => u['nickName'] ?? u['userName']).join(',') 
                            : '请选择签收人', 
                        style: TextStyle(color: (signee['signUsers'] != null && (signee['signUsers'] as List).isNotEmpty) ? Colors.black87 : Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (_signeeList.length > 1) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _signeeList.removeAt(index);
                      });
                    },
                    child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  ),
                ]
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _infoChip(String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow(Map<String, dynamic> work,
      Map<String, dynamic> assignment, int? workshopId, bool canDispatch) {
    final teams =
        workshopId != null ? _teamsByWorkshopId[workshopId] ?? [] : [];
    final currentTeamId = _parseId(assignment['teamId']);

    // 支持 userNameList 也可能是以逗号分隔的字符串
    final rawUserNames = assignment['userNameList'];
    List<dynamic> userNames = [];
    if (rawUserNames is String) {
      userNames = rawUserNames
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawUserNames is List) {
      userNames = List<dynamic>.from(rawUserNames);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Team Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('请选择班组'),
                value: currentTeamId,
                items: teams.map((t) {
                  return DropdownMenuItem<int>(
                    value: _parseId(t['deptId']),
                    child: Text(t['deptName'] ?? ''),
                  );
                }).toList(),
                onChanged: canDispatch ? (val) {
                  if (val != null) {
                    setState(() {
                      assignment['teamId'] = val;
                      assignment['teamName'] = teams.firstWhere(
                          (e) => _parseId(e['deptId']) == val)['deptName'];
                      // Reset users when team changes
                      assignment['userIdList'] = <dynamic>[];
                      assignment['userNameList'] = <dynamic>[];
                    });
                  }
                } : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Users Multi-select
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: (!canDispatch || currentTeamId == null)
                  ? null
                  : () => _selectUsers(assignment, currentTeamId),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                  color: canDispatch ? Colors.white : Colors.grey[200],
                ),
                child: Text(
                  userNames.isEmpty ? '请选择施修人' : userNames.join(', '),
                  style: TextStyle(
                    color:
                        userNames.isEmpty ? Colors.grey[600] : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Delete button
          if (canDispatch)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeAssignment(work, assignment),
            ),
        ],
      ),
    );
  }
}

class _MultiSelectUserDialog extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<dynamic> initialSelectedIds;

  const _MultiSelectUserDialog({
    required this.users,
    required this.initialSelectedIds,
  });

  @override
  State<_MultiSelectUserDialog> createState() => _MultiSelectUserDialogState();
}

class _MultiSelectUserDialogState extends State<_MultiSelectUserDialog> {
  late Set<dynamic> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<dynamic>.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.users.where((user) {
      final name = (user['nickName'] ?? user['userName'] ?? '').toString();
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('选择人员'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsers.length,
                itemBuilder: (ctx, index) {
                  final user = filteredUsers[index];
                  final userId = user['userId'];
                  final name = user['nickName'] ?? user['userName'] ?? '';
                  final isSelected = _selectedIds.contains(userId);
                  return CheckboxListTile(
                    title: Text(name),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(userId);
                        } else {
                          _selectedIds.remove(userId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedUsers = widget.users
                .where((u) => _selectedIds.contains(u['userId']))
                .toList();
            Navigator.pop(context, selectedUsers);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
