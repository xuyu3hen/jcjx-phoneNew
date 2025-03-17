

import 'package:jcjx_phone/models/prework/package_user.dart';


class MainDataStructure {
  bool assigned;
  List<PackageUserDTO> packageUserDTOList;
  String station;

  MainDataStructure({
    required this.assigned,
    required this.packageUserDTOList,
    required this.station
  });

  factory MainDataStructure.fromJson(Map<String, dynamic> json) {
    return MainDataStructure(
      assigned: json['assigned'] as bool,
      packageUserDTOList: (json['packageUserDTOList'] as List)
      .map((e) => PackageUserDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
      station: json['station'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assigned': assigned,
      'packageUserDTOList': packageUserDTOList
      .map((e) => e.toJson())
      .toList(),
      'station': station,
    };
  }
}