import 'package:jcjx_phone/index.dart';
import 'package:json_annotation/json_annotation.dart';
part 'package_user_list.g.dart';

@JsonSerializable()
class PackageUserList extends PackageBaseList {
  List<PackageUser>? data;

  PackageUserList({
    super.code,
    super.message,
    this.data,
  });

  factory PackageUserList.fromJson(Map<String,dynamic> json) => _$PackageUserListFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PackageUserListToJson(this);
}

@JsonSerializable()
class PackageUser {
    String? station;
    bool? assigned;
    List<PackageUserDTOList>? packageUserDTOList;

    PackageUser({
        this.station,
        this.assigned,
        this.packageUserDTOList,
    });

    factory PackageUser.fromJson(Map<String,dynamic> json) => _$PackageUserFromJson(json);
    Map<String, dynamic> toJson() => _$PackageUserToJson(this);
}

@JsonSerializable()
class PackageUserDTOList {
    String? packageEternalCode;
    String? packageVersionCode;
    String? packageVersionEncode;
    bool? techMeasure;
    String? packageName;
    bool? assigned;
    String? station;
    bool? wholePackage;
    List<WorkInstructPackageUserList>? workInstructPackageUserList;

    PackageUserDTOList({
        this.packageEternalCode,
        this.packageVersionCode,
        this.packageVersionEncode,
        this.techMeasure,
        this.packageName,
        this.assigned,
        this.station,
        this.wholePackage,
        this.workInstructPackageUserList,
    });

    factory PackageUserDTOList.fromJson(Map<String,dynamic> json) => _$PackageUserDTOListFromJson(json);
    Map<String, dynamic> toJson() => _$PackageUserDTOListToJson(this);
}

@JsonSerializable()
class WorkInstructPackageUserList {
    String? repairMainNodeName;
    String? code;
    String? createdBy;
    int? createdTime;
    String? updatedBy;
    String? name;
    int? updatedTime;
    String? station;
    int? deptId;
    String? repairProcCode;
    String? typeCode;
    String? repairMainNodeCode;
    int? itemType;
    String? repairProcName;
    String? deptName;
    String? itemTypeName;
    String? repairPersonnel;
    String? packageName;
    String? assistant;
    dynamic mutualInspectionPersonnel;
    dynamic specialInspectionPersonnel;
    String? riskLevel;
    String? packageEternalCode;
    String? packageVersionCode;
    String? packageVersionEncode;
    bool? techMeasure;
    int? sort;
    bool? assigned;
    String? certainCode;
    String? repairPersonnelName;
    String? assistantName;
    String? mutualPersonnelName;
    String? specialPersonnelName;

    WorkInstructPackageUserList({
        this.repairMainNodeName,
        this.code,
        this.createdBy,
        this.createdTime,
        this.updatedBy,
        this.name,
        this.updatedTime,
        this.station,
        this.deptId,
        this.repairProcCode,
        this.typeCode,
        this.repairMainNodeCode,
        this.itemType,
        this.repairProcName,
        this.deptName,
        this.itemTypeName,
        this.repairPersonnel,
        this.packageName,
        this.assistant,
        this.mutualInspectionPersonnel,
        this.specialInspectionPersonnel,
        this.riskLevel,
        this.packageEternalCode,
        this.packageVersionCode,
        this.packageVersionEncode,
        this.techMeasure,
        this.sort,
        this.assigned,
        this.certainCode,
        this.repairPersonnelName,
        this.assistantName,
        this.mutualPersonnelName,
        this.specialPersonnelName,
    });

    factory WorkInstructPackageUserList.fromJson(Map<String,dynamic> json) => _$WorkInstructPackageUserListFromJson(json);
    Map<String, dynamic> toJson() => _$WorkInstructPackageUserListToJson(this);
}