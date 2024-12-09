import 'package:jcjx_phone/models/prework/workInstructPackageUser%20.dart';

class PackageUserDTO {
  bool assigned;
  String packageEternalCode;
  String packageName;
  String packageVersionCode;
  String packageVersionEncode;
  String station;
  bool techMeasure;
  bool wholePackage;
  List<WorkInstructPackageUser> workInstructPackageUserList;

  PackageUserDTO({
    required this.assigned,
    required this.packageEternalCode,
    required this.packageName,
    required this.packageVersionCode,
    required this.packageVersionEncode,
    required this.station,
    required this.techMeasure,
    required this.wholePackage,
    required this.workInstructPackageUserList
  });

  factory PackageUserDTO.fromJson(Map<String, dynamic> json) {
    return PackageUserDTO(
      assigned: json['assigned'] as bool,
      packageEternalCode: json['packageEternalCode'] as String,
      packageName: json['packageName'] as String,
      packageVersionCode: json['packageVersionCode'] as String,
      packageVersionEncode: json['packageVersionEncode'] as String,
      station: json['station'] as String,
      techMeasure: json['techMeasure'] as bool,
      wholePackage: json['wholePackage'] as bool,
      workInstructPackageUserList: (json['workInstructPackageUserList'] as List)
      .map((e) => WorkInstructPackageUser.fromJson(e as Map<String, dynamic>))
      .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assigned': assigned,
      'packageEternalCode': packageEternalCode,
      'packageName': packageName,
      'packageVersionCode': packageVersionCode,
      'packageVersionEncode:': packageVersionEncode,
      'station': station,
      'techMeasure': techMeasure,
      'wholePackage': wholePackage,
      'workInstructPackageUserList': workInstructPackageUserList
      .map((e) => e.toJson())
      .toList(),
    };
  }
}