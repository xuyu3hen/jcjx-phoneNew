// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) => Package(
      id: json['id'] as String?,
      code: json['code'] as String?,
      materialList: (json['materialList'] as List<dynamic>?)
          ?.map((e) => MaterialStore.fromJson(e as Map<String, dynamic>))
          .toList(),
      packageList: (json['packageList'] as List<dynamic>?)
          ?.map((e) => Package.fromJson(e as Map<String, dynamic>))
          .toList(),
      isExpand: json['isExpand'] as bool? ?? false,
    );

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'materialList': instance.materialList?.map((e) => e.toJson()).toList(),
      'packageList': instance.packageList?.map((e) => e.toJson()).toList(),
      'isExpand': instance.isExpand,
    };
