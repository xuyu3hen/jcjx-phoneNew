// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagelist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageList _$PageListFromJson(Map<String, dynamic> json) => PageList(
      total: (json['total'] as num?)?.toInt(),
      pageNum: (json['pageNum'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
      startRow: (json['startRow'] as num?)?.toInt(),
      endRow: (json['endRow'] as num?)?.toInt(),
      pages: (json['pages'] as num?)?.toInt(),
      prePage: (json['prePage'] as num?)?.toInt(),
      nextPage: (json['nextPage'] as num?)?.toInt(),
      isFirstPage: json['isFirstPage'] as bool?,
      isLastPage: json['isLastPage'] as bool?,
      hasPreviousPage: json['hasPreviousPage'] as bool?,
      hasNextPage: json['hasNextPage'] as bool?,
      navigatePages: (json['navigatePages'] as num?)?.toInt(),
      navigatepageNums: (json['navigatepageNums'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      navigateFirstPage: (json['navigateFirstPage'] as num?)?.toInt(),
      navigateLastPage: (json['navigateLastPage'] as num?)?.toInt(),
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
