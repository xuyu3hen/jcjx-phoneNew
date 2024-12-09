import 'package:json_annotation/json_annotation.dart';
import 'package:jcjx_phone/index.dart';
import 'index.dart';
part 'package.g.dart';

@JsonSerializable(explicitToJson: true)
class Package {

  Package({
    this.id,
    this.code,
    this.materialList,
    this.packageList,
    this.isExpand = false,
  });

  String? id;
  String? code;
  List<MaterialStore>? materialList;
  List<Package>? packageList;
  
  bool isExpand;

  factory Package.fromJson(Map<String,dynamic> json) => _$PackageFromJson(json);
  Map<String, dynamic> toJson() => _$PackageToJson(this);
}
