class WorkInstructPackageUser {
  bool assigned;
  String assistant;
  String assistantName;
  String certainCode;
  String code;
  String createdBy;
  DateTime createdTime;
  int deptId;
  String deptName;
  int itemType;
  String itemTypeName;
  String mutualInspectionPersonnel;
  String mutualPersonnelName;
  String name;
  String packageEternalCode;
  String packageName;
  String packageVersionCode;
  String packageVersionEncode;
  String repairMainNodeCode;
  String repairMainNodeName;
  String repairPersonnel;
  String repairPersonnelName;
  String repairProcCode;
  String repairProcName;
  String riskLevel;
  int sort;
  String specialInspectionPersonnel;
  String specialPersonnelName;
  String station;
  bool techMeasure;
  String typeCode;
  String updatedBy;
  DateTime updatedTime;

WorkInstructPackageUser({
    required this.assigned,
    required this.assistant,
    required this.assistantName,
    required this.certainCode,
    // 这里应该是逗号，用于分隔参数
    required this.code,
    required this.createdBy,
    required this.createdTime,
    required this.deptId,
    required this.deptName,
    required this.itemType,
    required this.itemTypeName,
    required this.mutualInspectionPersonnel,
    required this.mutualPersonnelName,
    required this.name,
    required this.packageEternalCode,
    required this.packageName,
    required this.packageVersionCode,
    required this.packageVersionEncode,
    required this.repairMainNodeCode,
    required this.repairMainNodeName,
    required this.repairPersonnel,
    required this.repairPersonnelName,
    required this.repairProcCode,
    required this.repairProcName,
    required this.riskLevel,
    required this.sort,
    required this.specialInspectionPersonnel,
    required this.specialPersonnelName,
    required this.station,
    required this.techMeasure,
    required this.typeCode,
    required this.updatedBy,
    required this.updatedTime,
});

factory WorkInstructPackageUser.fromJson(Map<String, dynamic> json) {
    DateTime? updatedTime;
  if (json['updatedTime']!= null && json['updatedTime'].isNotEmpty) {
    updatedTime = DateTime.parse(json['updatedTime'] as String);
  }

  DateTime? createdTime;
  if (json['createdTime']!= null && json['createdTime'].isNotEmpty) {
    createdTime = DateTime.parse(json['createdTime'] as String);
  } else {
    // 这里可根据具体需求设置一个默认值，比如设置为一个特定的代表空日期的时间戳或当前时间等
    createdTime = DateTime.now(); 
  }


    return WorkInstructPackageUser(
      assigned: json['assigned'] as bool,
      assistant: json['assistant'] as String,
      assistantName: json['assistantName'] as String,
      certainCode: json['certainCode'] as String,
      // 这里是参数之间的逗号
      code: json['code'] as String,
      createdBy: json['createdBy'] as String,
      createdTime: createdTime,
      deptId: json['deptId'] as int,
      deptName: json['deptName'] as String,
      itemType: json['itemType'] as int,
      itemTypeName: json['itemTypeName'] as String,
      mutualInspectionPersonnel: json['mutualInspectionPersonnel'] as String,
      mutualPersonnelName: json['mutualPersonnelName'] as String,
      name: json['name'] as String,
      packageEternalCode: json['packageEternalCode'] as String,
      packageName: json['packageName'] as String,
      packageVersionCode: json['packageVersionCode'] as String,
      packageVersionEncode: json['packageVersionEncode'] as String,
      repairMainNodeCode: json['repairMainNodeCode'] as String,
      repairMainNodeName: json['repairMainNodeName'] as String,
      repairPersonnel: json['repairPersonnel'] as String,
      repairPersonnelName: json['repairPersonnelName'] as String,
      repairProcCode: json['repairProcCode'] as String,
      repairProcName: json['repairProcName'] as String,
      riskLevel: json['riskLevel'] as String,
      sort: json['sort'] as int,
      specialInspectionPersonnel: json['specialInspectionPersonnel'] as String,
      specialPersonnelName: json['specialPersonnelName'] as String,
      station: json['station'] as String,
      techMeasure: json['techMeasure'] as bool,
      typeCode: json['typeCode'] as String,
      updatedBy: json['updatedBy'] as String,
      updatedTime: updatedTime?? DateTime.now(),

    );
}

  Map<String, dynamic> toJson() {
    return {
      'assigned': assigned,
      'assistant': assistant,
      'assistantName': assistantName,
      'certainCode': certainCode,
      'code': code,
      'createdBy': createdBy,
      'createdTime': createdTime.toString(),
      'deptId': deptId,
      'deptName': deptName,
      'itemType': itemType,
      'itemTypeName': itemTypeName,
      'mutualInspectionPersonnel': mutualInspectionPersonnel,
      'mutualPersonnelName': mutualPersonnelName,
      'name': name,
      'packageEternalCode': packageEternalCode,
      'packageName': packageName,
      'packageVersionCode': packageVersionCode,
      'packageVersionEncode': packageVersionEncode,
      'repairMainNodeCode': repairMainNodeCode,
      'repairMainNodeName': repairMainNodeName,
      'repairPersonnel': repairPersonnel,
      'repairProcCode': repairProcCode,
      'repairProcName': repairProcName,
      'riskLevel': riskLevel,
      'sort': sort,
      'specialInspectionPersonnel': specialInspectionPersonnel,
      'specialPersonnelName': specialPersonnelName,
      'station': station,
      'techMeasure': techMeasure,
      'typeCode': typeCode,
      'updatedBy': updatedBy,
      'updatedTime': updatedTime.toString(),
    };
  }
}
