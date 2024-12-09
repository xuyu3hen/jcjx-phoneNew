import 'package:json_annotation/json_annotation.dart';
part 'package_base_list.g.dart';

@JsonSerializable()
class PackageBaseList {

    String? code;
    String? message;

  PackageBaseList({
    this.code,
    this.message,
  });

  factory PackageBaseList.fromJson(Map<String,dynamic> json) => _$PackageBaseListFromJson(json);
  Map<String, dynamic> toJson() => _$PackageBaseListToJson(this);
}