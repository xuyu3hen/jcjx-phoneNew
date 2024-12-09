import 'package:json_annotation/json_annotation.dart';
part 'materialstore.g.dart';

@JsonSerializable()
class MaterialStore {

  MaterialStore({
    this.id,
    this.materialCode,
    this.materialName,
    this.serialNum,
    this.batchNum,
    this.num,
    this.storeplaceId,
    this.rootStoreplaceId,
    this.supplierName,
    this.storelocationId,
    this.state,
    this.locationType,
    this.materialModel,
  });

  String? id;
  String? materialName;
  String? materialCode;
  String? serialNum;
  String? batchNum;
  int? num;
  String? storeplaceId;
  String? rootStoreplaceId;
  String? supplierName;
  String? storelocationId;
  int? state;
  String? locationType;
  String? materialModel;

  factory MaterialStore.fromJson(Map<String,dynamic> json) => _$MaterialStoreFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialStoreToJson(this);
}
