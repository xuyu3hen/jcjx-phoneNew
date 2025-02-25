class RepairMainNode {
  int? total;
  List<Rows>? rows;
  int? code;
  String? msg;

  RepairMainNode({this.total, this.rows, this.code, this.msg});

  RepairMainNode.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['rows']!= null) {
      rows = [];
      for (var v in (json['rows'] as List)) {
        rows?.add(Rows.fromJson(v));
      }
    }
    code = json['code'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['total'] = total;
    if (this.rows!= null) {
      data['rows'] = this.rows?.map((v) => v.toJson()).toList();
    }
    data['code'] = code;
    data['msg'] = msg;
    return data;
  }

  List<Map<String, dynamic>> toMapList() {
    return rows?.map((item) => item.toJson()).toList()?? [];
  }
}

class Rows {
  String? code;
  String? name;
  int? sort;
  String? repairProcCode;
  String? remark;
  String? deptIds;
  List<SysDeptList>? sysDeptList;
  dynamic childList;
  bool? deleted;

  Rows({
    this.code,
    this.name,
    this.sort,
    this.repairProcCode,
    this.remark,
    this.deptIds,
    this.sysDeptList,
    this.childList,
    this.deleted = false,
  });

  Rows.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    sort = json['sort'];
    repairProcCode = json['repairProcCode'];
    remark = json['remark'];
    deptIds = json['deptIds'];
    if (json['sysDeptList']!= null) {
      sysDeptList = [];
      (json['sysDeptList'] as List).forEach((v) {
        sysDeptList?.add(SysDeptList.fromJson(v));
      });
    }
    childList = json['childList'];
    deleted = json['deleted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['code'] = code;
    data['name'] = name;
    data['sort'] = sort;
    data['repairProcCode'] = repairProcCode;
    data['remark'] = remark;
    data['deptIds'] = deptIds;
    if (this.sysDeptList!= null) {
      data['sysDeptList'] = sysDeptList?.map((v) => v.toJson()).toList();
    }
    data['childList'] = childList;
    data['deleted'] = deleted;
    return data;
  }
}

class SysDeptList {
  String? createBy;
  String? createTime;
  String? updateBy;
  String? updateTime;
  String? remark;
  int? deptId;
  int? parentId;
  String? ancestors;
  String? deptName;
  int? orderNum;
  String? leader;
  String? phone;
  String? email;
  String? status;
  String? delFlag;
  String? parentName;
  List<Map<String, dynamic>>? children;

  SysDeptList({
    this.createBy,
    this.createTime,
    this.updateBy,
    this.updateTime,
    this.remark,
    this.deptId,
    this.parentId,
    this.ancestors,
    this.deptName,
    this.orderNum,
    this.leader,
    this.phone,
    this.email,
    this.status,
    this.delFlag,
    this.parentName,
    this.children = const [],
  });

  SysDeptList.fromJson(Map<String, dynamic> json) {
    createBy = json['createBy'];
    createTime = json['createTime'];
    updateBy = json['updateBy'];
    updateTime = json['updateTime'];
    remark = json['remark'];
    deptId = json['deptId'];
    parentId = json['parentId'];
    ancestors = json['ancestors'];
    deptName = json['deptName'];
    orderNum = json['orderNum'];
    leader = json['leader'];
    phone = json['phone'];
    email = json['email'];
    status = json['status'];
    delFlag = json['delFlag'];
    parentName = json['parentName'];
    if (json['children']!= null) {
      children = [];
      (json['children'] as List).forEach((v) {
        if (v is Map<String, dynamic>) {
          children?.add(v);
        } else {
          // 可以根据需要添加异常处理逻辑
          print('Invalid child element type: $v');
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['createBy'] = createBy;
    data['createTime'] = createTime;
    data['updateBy'] = updateBy;
    data['updateTime'] = updateTime;
    data['remark'] = remark;
    data['deptId'] = deptId;
    data['parentId'] = parentId;
    data['ancestors'] = ancestors;
    data['deptName'] = deptName;
    data['orderNum'] = orderNum;
    data['leader'] = leader;
    data['phone'] = phone;
    data['email'] = email;
    data['status'] = status;
    data['delFlag'] = delFlag;
    data['parentName'] = parentName;
    if (children!= null) {
      data['children'] = children;
    }
    return data;
  }
}