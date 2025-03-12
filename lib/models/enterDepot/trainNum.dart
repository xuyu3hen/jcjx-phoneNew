



class InnerData {

  List<ItemData>? data;

  InnerData({
    required this.data, required List ,
  });

  factory InnerData.fromJson(Map<String, dynamic> json) {
    return InnerData(
      data: (json['data'] as List?)
         ?.map((e) => ItemData.fromJson(e))
         .toList(), List: null,
    );
  }

  List<Map<String, dynamic>> toMapList(){
    return data?.map((item) => item.toJson()).toList()??[];
  }
}

class ItemData {
  String? code;
  String? name;
  String? createdBy;
  int? createdTime;
  String? updatedBy;
  int? updatedTime;
  int? sort;
  String? repairDeptId;
  String? attachDeptId;
  String? trainTypeCode;
  String? trainNumCode;
  int? month;
  String? trainType;
  String? trainNum;
  String? arrivePlatformTime;
  String? deliverTrainTime;
  String? leaveDeptTime;
  String? remarks;
  String? repairProcCode;
  String? repairProc;
  String? repairDept;
  String? attachDept;
  String? assignName;
  String? assignID;
  String? assignMessage;
  bool? disable;
  String? dynamicCode;
  String? dynamicName;
  String? repairTimes;
  int? status;

  ItemData({
    required this.code,
    this.name,
    required this.createdBy,
    required this.createdTime,
    required this.updatedBy,
    required this.updatedTime,
    required this.sort,
    this.repairDeptId,
    this.attachDeptId,
    required this.trainTypeCode,
    required this.trainNumCode,
    required this.month,
    required this.trainType,
    required this.trainNum,
    required this.arrivePlatformTime,
    required this.deliverTrainTime,
    required this.leaveDeptTime,
    this.remarks,
    required this.repairProcCode,
    required this.repairProc,
    required this.repairDept,
    required this.attachDept,
    this.assignName,
    this.assignID,
    this.assignMessage,
    required this.disable,
    required this.dynamicCode,
    required this.dynamicName,
    this.repairTimes,
    required this.status,
  });

 factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      code: json['code'] as String?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as int?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as int?,
      sort: json['sort'] as int?,
      repairDeptId: json['repairDeptId'] as String?,
      attachDeptId: json['attachDeptId'] as String?,
      trainTypeCode: json['trainTypeCode'] as String?,
      trainNumCode: json['trainNumCode'] as String?,
      month: json['month'] as int?,
    trainType: json['trainType'] as String?,
    trainNum: json['trainNum'] as String?,
    arrivePlatformTime: json['arrivePlatformTime'] as String?,
    deliverTrainTime: json['deliverTrainTime'] as String?,
    leaveDeptTime: json['leaveDeptTime'] as String?,
    remarks: json['remarks'] as String?,
    repairProcCode: json['repairProcCode'] as String?,
    repairProc: json['repairProc'] as String?,
    repairDept: json['repairDept'] as String?,
    attachDept: json['attachDept'] as String?,
    assignName: json['assignName'] as String?,
    assignID: json['assignID'] as String?,
    assignMessage: json['assignMessage'] as String?,
    disable: json['disable'] as bool?,
    dynamicCode: json['dynamicCode'] as String,
    dynamicName: json['dynamicName'] as String,
    repairTimes: json['repairTimes'] as String?,
    status: json['status'] as int?,
  );
 } 
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'createdBy': createdBy,
      'createdTime': createdTime,
      'updatedBy': updatedBy,
      'updatedTime': updatedTime,
      'sort': sort,
      'repairDeptId': repairDeptId,
      'attachDeptId': attachDeptId,
      'trainTypeCode': trainTypeCode,
      'trainNumCode': trainNumCode,
      'month': month,
      'trainType': trainType,
      'trainNum': trainNum,
      'arrivePlatformTime': arrivePlatformTime,
      'deliverTrainTime': deliverTrainTime,
      'leaveDeptTime': leaveDeptTime,
      'remarks': remarks,
      'repairProcCode': repairProcCode,
      'repairProc': repairProc,
      'repairDept': repairDept,
      'attachDept': attachDept,
      'assignName': assignName,
      'assignID': assignID,
      'assignMessage': assignMessage,
      'disable': disable,
      'dynamicCode': dynamicCode,
      'dynamicName': dynamicName,
      'repairTimes': repairTimes,
      'status': status,
    };
  }

}


