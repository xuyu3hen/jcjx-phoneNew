// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materialstore.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialStore _$MaterialStoreFromJson(Map<String, dynamic> json) =>
    MaterialStore(
      id: json['id'] as String?,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
      serialNum: json['serialNum'] as String?,
      batchNum: json['batchNum'] as String?,
      num: (json['num'] as num?)?.toInt(),
      storeplaceId: json['storeplaceId'] as String?,
      rootStoreplaceId: json['rootStoreplaceId'] as String?,
      supplierName: json['supplierName'] as String?,
      storelocationId: json['storelocationId'] as String?,
      state: (json['state'] as num?)?.toInt(),
      locationType: json['locationType'] as String?,
      materialModel: json['materialModel'] as String?,
    );

Map<String, dynamic> _$MaterialStoreToJson(MaterialStore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materialName': instance.materialName,
      'materialCode': instance.materialCode,
      'serialNum': instance.serialNum,
      'batchNum': instance.batchNum,
      'num': instance.num,
      'storeplaceId': instance.storeplaceId,
      'rootStoreplaceId': instance.rootStoreplaceId,
      'supplierName': instance.supplierName,
      'storelocationId': instance.storelocationId,
      'state': instance.state,
      'locationType': instance.locationType,
      'materialModel': instance.materialModel,
    };
