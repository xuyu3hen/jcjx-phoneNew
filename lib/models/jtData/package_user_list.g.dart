// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_user_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageUserList _$PackageUserListFromJson(Map<String, dynamic> json) =>
    PackageUserList(
      code: json['code'] as String?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PackageUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PackageUserListToJson(PackageUserList instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

PackageUser _$PackageUserFromJson(Map<String, dynamic> json) => PackageUser(
      station: json['station'] as String?,
      assigned: json['assigned'] as bool?,
      packageUserDTOList: (json['packageUserDTOList'] as List<dynamic>?)
          ?.map((e) => PackageUserDTOList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PackageUserToJson(PackageUser instance) =>
    <String, dynamic>{
      'station': instance.station,
      'assigned': instance.assigned,
      'packageUserDTOList': instance.packageUserDTOList,
    };

PackageUserDTOList _$PackageUserDTOListFromJson(Map<String, dynamic> json) =>
    PackageUserDTOList(
      packageEternalCode: json['packageEternalCode'] as String?,
      packageVersionCode: json['packageVersionCode'] as String?,
      packageVersionEncode: json['packageVersionEncode'] as String?,
      techMeasure: json['techMeasure'] as bool?,
      packageName: json['packageName'] as String?,
      assigned: json['assigned'] as bool?,
      station: json['station'] as String?,
      wholePackage: json['wholePackage'] as bool?,
      workInstructPackageUserList: (json['workInstructPackageUserList']
              as List<dynamic>?)
          ?.map((e) =>
              WorkInstructPackageUserList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PackageUserDTOListToJson(PackageUserDTOList instance) =>
    <String, dynamic>{
      'packageEternalCode': instance.packageEternalCode,
      'packageVersionCode': instance.packageVersionCode,
      'packageVersionEncode': instance.packageVersionEncode,
      'techMeasure': instance.techMeasure,
      'packageName': instance.packageName,
      'assigned': instance.assigned,
      'station': instance.station,
      'wholePackage': instance.wholePackage,
      'workInstructPackageUserList': instance.workInstructPackageUserList,
    };

WorkInstructPackageUserList _$WorkInstructPackageUserListFromJson(
        Map<String, dynamic> json) =>
    WorkInstructPackageUserList(
      repairMainNodeName: json['repairMainNodeName'] as String?,
      code: json['code'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: (json['createdTime'] as num?)?.toInt(),
      updatedBy: json['updatedBy'] as String?,
      name: json['name'] as String?,
      updatedTime: (json['updatedTime'] as num?)?.toInt(),
      station: json['station'] as String?,
      deptId: (json['deptId'] as num?)?.toInt(),
      repairProcCode: json['repairProcCode'] as String?,
      typeCode: json['typeCode'] as String?,
      repairMainNodeCode: json['repairMainNodeCode'] as String?,
      itemType: (json['itemType'] as num?)?.toInt(),
      repairProcName: json['repairProcName'] as String?,
      deptName: json['deptName'] as String?,
      itemTypeName: json['itemTypeName'] as String?,
      repairPersonnel: json['repairPersonnel'] as String?,
      packageName: json['packageName'] as String?,
      assistant: json['assistant'] as String?,
      mutualInspectionPersonnel: json['mutualInspectionPersonnel'],
      specialInspectionPersonnel: json['specialInspectionPersonnel'],
      riskLevel: json['riskLevel'] as String?,
      packageEternalCode: json['packageEternalCode'] as String?,
      packageVersionCode: json['packageVersionCode'] as String?,
      packageVersionEncode: json['packageVersionEncode'] as String?,
      techMeasure: json['techMeasure'] as bool?,
      sort: (json['sort'] as num?)?.toInt(),
      assigned: json['assigned'] as bool?,
      certainCode: json['certainCode'] as String?,
      repairPersonnelName: json['repairPersonnelName'] as String?,
      assistantName: json['assistantName'] as String?,
      mutualPersonnelName: json['mutualPersonnelName'] as String?,
      specialPersonnelName: json['specialPersonnelName'] as String?,
    );

Map<String, dynamic> _$WorkInstructPackageUserListToJson(
        WorkInstructPackageUserList instance) =>
    <String, dynamic>{
      'repairMainNodeName': instance.repairMainNodeName,
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'name': instance.name,
      'updatedTime': instance.updatedTime,
      'station': instance.station,
      'deptId': instance.deptId,
      'repairProcCode': instance.repairProcCode,
      'typeCode': instance.typeCode,
      'repairMainNodeCode': instance.repairMainNodeCode,
      'itemType': instance.itemType,
      'repairProcName': instance.repairProcName,
      'deptName': instance.deptName,
      'itemTypeName': instance.itemTypeName,
      'repairPersonnel': instance.repairPersonnel,
      'packageName': instance.packageName,
      'assistant': instance.assistant,
      'mutualInspectionPersonnel': instance.mutualInspectionPersonnel,
      'specialInspectionPersonnel': instance.specialInspectionPersonnel,
      'riskLevel': instance.riskLevel,
      'packageEternalCode': instance.packageEternalCode,
      'packageVersionCode': instance.packageVersionCode,
      'packageVersionEncode': instance.packageVersionEncode,
      'techMeasure': instance.techMeasure,
      'sort': instance.sort,
      'assigned': instance.assigned,
      'certainCode': instance.certainCode,
      'repairPersonnelName': instance.repairPersonnelName,
      'assistantName': instance.assistantName,
      'mutualPersonnelName': instance.mutualPersonnelName,
      'specialPersonnelName': instance.specialPersonnelName,
    };
