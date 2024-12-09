import 'package:json_annotation/json_annotation.dart';
part 'rotable.g.dart';

@JsonSerializable()
class Rotable {

  Rotable({
        this.id,
        this.materialCode,
        this.materialName,
        this.materialModel,
        this.batchNum,
        this.dwgNo,
        this.unitNum,
        this.compositionsName,
        this.serialNum,
        this.producerName,
        this.productNum,
        this.capitalNum,
        this.capitalType,
        this.productionDate,
        this.putinQualitySignDate,
        this.qualityCertificationDate,
        this.qualityCertificationLocation,
        this.materialState,
        this.materialStateDetail,
        this.repairCycle,
        this.remark,
        this.lastUpdateDatetime,
        this.createDatetime,
        this.maintenanceCycle,
        this.expirationDate,
        this.trainModels,
        this.rootStoreplaceId,
        this.storeplaceId,
        this.storelocationId,
        this.lastMaintenanceDate,
        this.storeState,
        this.truckLocation,
        this.locationRemark,
        this.putinSource,
        this.rubberNodeDate,
        this.storePlaceName,
        this.storeLocationName,
        this.rootStorePlaceName,
  });

    String? id;
    String? materialCode;
    String? materialName;
    String? materialModel;
    String? batchNum;
    String? dwgNo;
    String? unitNum;
    String? compositionsName;
    String? serialNum;
    String? producerName;
    String? productNum;
    String? capitalNum;
    int? capitalType;
    String? productionDate;
    String? putinQualitySignDate;
    String? qualityCertificationDate;
    String? qualityCertificationLocation;
    int? materialState;
    String? materialStateDetail;
    String? repairCycle;
    String? remark;
    String? lastUpdateDatetime;
    String? createDatetime;
    int? maintenanceCycle;
    String? expirationDate;
    String? trainModels;
    String? rootStoreplaceId;
    String? storeplaceId;
    String? storelocationId;
    String? lastMaintenanceDate;
    int? storeState;
    String? truckLocation;
    String? locationRemark;
    String? putinSource;
    String? rubberNodeDate;
    String? storePlaceName;
    String? storeLocationName;
    String? rootStorePlaceName;

  factory Rotable.fromJson(Map<String,dynamic> json) => _$RotableFromJson(json);

  Map<String, dynamic> toJson() => _$RotableToJson(this);
}
