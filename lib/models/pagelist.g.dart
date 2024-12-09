// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagelist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageList _$PageListFromJson(Map<String, dynamic> json) => PageList(
      total: json['total'] as int?,
      pageNum: json['pageNum'] as int?,
      pageSize: json['pageSize'] as int?,
      size: json['size'] as int?,
      startRow: json['startRow'] as int?,
      endRow: json['endRow'] as int?,
      pages: json['pages'] as int?,
      prePage: json['prePage'] as int?,
      nextPage: json['nextPage'] as int?,
      isFirstPage: json['isFirstPage'] as bool?,
      isLastPage: json['isLastPage'] as bool?,
      hasPreviousPage: json['hasPreviousPage'] as bool?,
      hasNextPage: json['hasNextPage'] as bool?,
      navigatePages: json['navigatePages'] as int?,
      navigatepageNums: (json['navigatepageNums'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      navigateFirstPage: json['navigateFirstPage'] as int?,
      navigateLastPage: json['navigateLastPage'] as int?,
    )..materialName = json['materialName'] as String?;

Map<String, dynamic> _$PageListToJson(PageList instance) => <String, dynamic>{
      'total': instance.total,
      'materialName': instance.materialName,
      'pageNum': instance.pageNum,
      'pageSize': instance.pageSize,
      'size': instance.size,
      'startRow': instance.startRow,
      'endRow': instance.endRow,
      'pages': instance.pages,
      'prePage': instance.prePage,
      'nextPage': instance.nextPage,
      'isFirstPage': instance.isFirstPage,
      'isLastPage': instance.isLastPage,
      'hasPreviousPage': instance.hasPreviousPage,
      'hasNextPage': instance.hasNextPage,
      'navigatePages': instance.navigatePages,
      'navigatepageNums': instance.navigatepageNums,
      'navigateFirstPage': instance.navigateFirstPage,
      'navigateLastPage': instance.navigateLastPage,
    };
