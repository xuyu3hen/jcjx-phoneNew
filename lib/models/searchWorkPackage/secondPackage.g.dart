// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'second_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecondShowPackage _$SecondShowPackageFromJson(Map<String, dynamic> json) =>
    SecondShowPackage(
      taskCertainPackageList: json['taskCertainPackageList'] == null
          ? null
          : TaskCertainPackageList.fromJson(
              json['taskCertainPackageList'] as Map<String, dynamic>),
      secondPackageNode: json['secondPackageNode'] as String?,
      color: json['color'] as int?,
    );

Map<String, dynamic> _$SecondShowPackageToJson(SecondShowPackage instance) =>
    <String, dynamic>{
      'taskCertainPackageList': instance.taskCertainPackageList,
      'secondPackageNode': instance.secondPackageNode,
      'color': instance.color,
    };

SecondPackage _$SecondPackageFromJson(Map<String, dynamic> json) =>
    SecondPackage(
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => Rows.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as int?,
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$SecondPackageToJson(SecondPackage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'rows': instance.rows,
      'code': instance.code,
      'msg': instance.msg,
    };

Rows _$RowsFromJson(Map<String, dynamic> json) => Rows(
      code: json['code'] as String?,
      certainPackageCode: json['certainPackageCode'] as String?,
      instructPackageCode: json['instructPackageCode'] as String?,
      riskLevel: json['riskLevel'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: json['createdTime'] as int?,
      updatedBy: json['updatedBy'] as String?,
      updatedTime: json['updatedTime'] as int?,
      secondPackageName: json['secondPackageName'] as String?,
      secondPackageCode: json['secondPackageCode'] as String?,
      sort: json['sort'] as int?,
    );

Map<String, dynamic> _$RowsToJson(Rows instance) => <String, dynamic>{
      'code': instance.code,
      'certainPackageCode': instance.certainPackageCode,
      'instructPackageCode': instance.instructPackageCode,
      'riskLevel': instance.riskLevel,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
      'secondPackageName': instance.secondPackageName,
      'secondPackageCode': instance.secondPackageCode,
      'sort': instance.sort,
    };
