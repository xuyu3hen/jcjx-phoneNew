class repairTimes {
  int? total;
  List<Rows>? rows;
  int? code;
  String? msg;

  repairTimes({this.total, this.rows, this.code, this.msg});

  repairTimes.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['rows']!= null) {
      rows = [];
      json['rows'].forEach((v) {
        rows?.add(Rows.fromJson(v));
      });
    }
    code = json['code'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['total'] = total;
    if (rows!= null) {
      data['rows'] = rows?.map((v) => v.toJson()).toList();
    }
    data['code'] = code;
    data['msg'] = msg;
    return data;
  }

  //tomapList
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

  Rows({this.code, this.name, this.sort, this.repairProcCode, this.remark});

  Rows.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    sort = json['sort'];
    repairProcCode = json['repairProcCode'];
    remark = json['remark'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['code'] = code;
    data['name'] = name;
    data['sort'] = sort;
    data['repairProcCode'] = repairProcCode;
    data['remark'] = remark;
    return data;
  }
}