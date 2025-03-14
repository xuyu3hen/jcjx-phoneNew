// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jt_type_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JtTypeList _$JtTypeListFromJson(Map<String, dynamic> json) => JtTypeList(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      total: json['total'] as int?,
      rows: json['rows'] as List<dynamic>?,
    );

Map<String, dynamic> _$JtTypeListToJson(JtTypeList instance) =>
    <String, dynamic>{
      'total': instance.total,
      'code': instance.code,
      'msg': instance.msg,
      'rows': instance.rows,
    };
