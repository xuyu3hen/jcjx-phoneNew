// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_data_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupData _$GroupDataFromJson(Map<String, dynamic> json) => GroupData(
      code: json['code'] as String,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PhotoData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GroupDataToJson(GroupData instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

PhotoData _$PhotoDataFromJson(Map<String, dynamic> json) => PhotoData(
      code: json['code'] as String?,
      fileType: json['fileType'] as String?,
      groupId: json['groupId'] as String?,
      fileSize: json['fileSize'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      fileName: json['fileName'] as String?,
      remark: json['remark'] as String?,
      createdBy: json['createdBy'] as String?,
      createdTime: (json['createdTime'] as num?)?.toInt(),
      updatedBy: json['updatedBy'] as String?,
      updatedTime: (json['updatedTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PhotoDataToJson(PhotoData instance) => <String, dynamic>{
      'code': instance.code,
      'fileType': instance.fileType,
      'groupId': instance.groupId,
      'fileSize': instance.fileSize,
      'downloadUrl': instance.downloadUrl,
      'fileName': instance.fileName,
      'remark': instance.remark,
      'createdBy': instance.createdBy,
      'createdTime': instance.createdTime,
      'updatedBy': instance.updatedBy,
      'updatedTime': instance.updatedTime,
    };
