// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JtMessageList _$JtMessageListFromJson(Map<String, dynamic> json) =>
    JtMessageList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => JtMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JtMessageListToJson(JtMessageList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };

JtMessage _$JtMessageFromJson(Map<String, dynamic> json) => JtMessage(
      machineModel: json['machineModel'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      faultDescription: json['faultDescription'] as String?,
      jcNodeName: json['jcNodeName'] as String?,
      faultyComponent: json['faultyComponent'] as String?,
      reporter: json['reporter'] as int?,
      reportDate: json['reportDate'] as String?,
      repairPicture: json['repairPicture'] as String?,
      maintenanceNotice: json['maintenanceNotice'] as String?,
      faultAssumption: json['faultAssumption'] as String?,
      team: json['team'] as int?,
      professionalSystem: json['professionalSystem'] as String?,
      requiredProcessingMethod: json['requiredProcessingMethod'] as String?,
      repairStatus: json['repairStatus'] as String?,
      actualRepairStartDate: json['actualRepairStartDate'] as String?,
      repairPersonnel: json['repairPersonnel'] as int?,
      repairCompletionDate: json['repairCompletionDate'] as String?,
      assistant: json['assistant'] as int?,
      riskLevel: json['riskLevel'] as String?,
      mutualInspectionPersonnel: json['mutualInspectionPersonnel'] as int?,
      mutualInspectionPicture: json['mutualInspectionPicture'] as String?,
      mutualInspectionDate: json['mutualInspectionDate'] as String?,
      specialInspectionPersonnel: json['specialInspectionPersonnel'] as int?,
      specialInspectionDate: json['specialInspectionDate'] as String?,
      workpieceCoefficient: json['workpieceCoefficient'] as String?,
      specialInspectionPicture: json['specialInspectionPicture'] as String?,
      code: json['code'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as String?,
      status: json['status'] as int?,
      completeStatus: json['completeStatus'] as int?,
      deptName: json['deptName'] as String?,
      reporterName: json['reporterName'] as String?,
      assistantName: json['assistantName'] as String?,
      specialName: json['specialName'] as String?,
      mutualName: json['mutualName'] as String?,
      repairName: json['repairName'] as String?,
      trainType: json['trainType'] as String?,
      trainNum: json['trainNum'] as String?,
      trainModelName: json['trainModelName'] as String?,
      trainEntryCode: json['trainEntryCode'] as String?,
      repairDate:
          (json['repairDate'] as List<dynamic>?)?.map((e) => e as int).toList(),
      mutualDate:
          (json['mutualDate'] as List<dynamic>?)?.map((e) => e as int).toList(),
      specialDate: (json['specialDate'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      reportShowDate: (json['reportShowDate'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      repairResourceName: json['repairResourceName'] as String?,
      processMethodName: json['processMethodName'] as String?,
      repairEndPicture: json['repairEndPicture'] as String?,
    )..selected = json['selected'] as bool?;

Map<String, dynamic> _$JtMessageToJson(JtMessage instance) => <String, dynamic>{
      'machineModel': instance.machineModel,
      'vehicleNumber': instance.vehicleNumber,
      'faultDescription': instance.faultDescription,
      'jcNodeName': instance.jcNodeName,
      'faultyComponent': instance.faultyComponent,
      'reporter': instance.reporter,
      'reportDate': instance.reportDate,
      'repairPicture': instance.repairPicture,
      'maintenanceNotice': instance.maintenanceNotice,
      'faultAssumption': instance.faultAssumption,
      'team': instance.team,
      'professionalSystem': instance.professionalSystem,
      'requiredProcessingMethod': instance.requiredProcessingMethod,
      'repairStatus': instance.repairStatus,
      'actualRepairStartDate': instance.actualRepairStartDate,
      'repairPersonnel': instance.repairPersonnel,
      'repairCompletionDate': instance.repairCompletionDate,
      'assistant': instance.assistant,
      'riskLevel': instance.riskLevel,
      'mutualInspectionPersonnel': instance.mutualInspectionPersonnel,
      'mutualInspectionPicture': instance.mutualInspectionPicture,
      'mutualInspectionDate': instance.mutualInspectionDate,
      'specialInspectionPersonnel': instance.specialInspectionPersonnel,
      'specialInspectionDate': instance.specialInspectionDate,
      'workpieceCoefficient': instance.workpieceCoefficient,
      'specialInspectionPicture': instance.specialInspectionPicture,
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'status': instance.status,
      'completeStatus': instance.completeStatus,
      'deptName': instance.deptName,
      'reporterName': instance.reporterName,
      'assistantName': instance.assistantName,
      'specialName': instance.specialName,
      'mutualName': instance.mutualName,
      'repairName': instance.repairName,
      'trainType': instance.trainType,
      'trainNum': instance.trainNum,
      'trainModelName': instance.trainModelName,
      'trainEntryCode': instance.trainEntryCode,
      'repairDate': instance.repairDate,
      'mutualDate': instance.mutualDate,
      'specialDate': instance.specialDate,
      'reportShowDate': instance.reportShowDate,
      'repairResourceName': instance.repairResourceName,
      'processMethodName': instance.processMethodName,
      'repairEndPicture': instance.repairEndPicture,
      'selected': instance.selected,
    };
