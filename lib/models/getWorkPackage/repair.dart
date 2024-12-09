import 'package:json_annotation/json_annotation.dart';
part 'repair.g.dart';

@JsonSerializable()
class RepairResponse {
  String? code;
  String? data;
  String? msg;
  RepairResponse({required this.code, required this.data, required this.msg});
  factory RepairResponse.fromJson(Map<String, dynamic> json) =>
      _$RepairResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RepairResponseToJson(this);
}

@JsonSerializable()
class FaultResponse {
  String? code;
  FaultShow? data;
  String? message;
  String? time;
  FaultResponse(
      {required this.code,
      required this.data,
      required this.message,
      required this.time});
  factory FaultResponse.fromJson(Map<String, dynamic> json) =>
      _$FaultResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FaultResponseToJson(this);
}

@JsonSerializable()
class FaultShow {
  String? msg;
  String? code;
  FaultShow({required this.msg, required this.code});
  factory FaultShow.fromJson(Map<String, dynamic> json) =>
      _$FaultShowFromJson(json);
  Map<String, dynamic> toJson() => _$FaultShowToJson(this);
}
