import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jcjx_phone/models/getWorkPackage/repair.dart';
import 'package:jcjx_phone/models/searchWorkPackage/mainNode.dart';

import '../index.dart';

class ProductApi extends AppApi {
  // 入段列车查询
  Future<TrainEntryList> getTrainEntry({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    var r = await AppApi.dio.get(
      "/dispatch/trainEntry/selectAll",
      queryParameters: queryParametrs,
    );
    return TrainEntryList.fromJson((r.data["data"])["data"]);
  }

  // 预派工查询
  Future<MainDataStructure> getPreDispatchWork({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/workInstructPackageUser/getPackageUserList",
      queryParameters: queryParametrs,
    );
    return MainDataStructure.fromJson((r.data["data"])["data"]);
  }

  // 车号展示
  Future<InnerData> getTrainNum() async {
    var r = await AppApi.dio
        .get("/dispatch/trainRepairScheduleEdit/getNeedToDeptSchedulePlan");
    print(r.data);
    return InnerData.fromJson(r.data["data"]);
  }

  // 检修地点展示
  Future<TrainLocation> getstopLocation(
    Map<String, dynamic>? queryParametrs,
  ) async {
    var r = await AppApi.dio.get(
      "/subparts/stopPosition/selectAll",
      queryParameters: queryParametrs,
    );
    print(r.data["data"]);
    return TrainLocation.fromJson((r.data["data"])["data"]);
  }

  // 动力类型查询
  Future<DynamicTypeList> getDynamicType({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/jcDynamicType/selectAll",
      queryParameters: queryParametrs,
    );
    print((r.data["data"])["data"]["rows"]);
    return DynamicTypeList.fromJson((r.data["data"])["data"]);
  }

  // 机车型号
  Future<JcTypeList> getJcType({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/jcType/selectAll",
      queryParameters: queryParametrs,
    );
    return JcTypeList.fromJson((r.data["data"])["data"]);
  }

  // 获取车号（本质查询检修计划）
  Future<RepairPlanList> getRepairPlanList({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get(
      "/dispatch/trainEntry/selectAll",
      queryParameters: queryParametrs,
    );
    // log("getRepairPlanList${r.data}");
    return RepairPlanList.fromJson((r.data["data"])["data"]);
  }

  // 修程查询
  Future<RepairProcList> getRepairProc({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/repairProc/selectAll",
      queryParameters: queryParametrs,
    );
    return RepairProcList.fromJson((r.data["data"])["data"]);
  }

  // 修次查询
  Future<RepairTimesList> getRepairTimes({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/repairTimes/selectAll",
      queryParameters: queryParametrs,
    );
    return RepairTimesList.fromJson((r.data["data"])["data"]);
  }

  // 新增入段
  Future<dynamic> newTrainEntry({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.post(
      "/dispatch/trainEntry/save",
      data: queryParametrs,
    );
    print(r.data["data"]);
    return r.data["data"];
  }

  // 查看领取作业包
  Future<dynamic> getWorkPackage({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get(
      "/tasks/taskInstructPackage/getCommonPackageList",
      queryParameters: queryParametrs,
    );
    print(r.data["data"]);
    return WorkPackageList.fromJson(r.data["data"]);
  }

  // 成为主修
  void beMainRepair(
    List<String> queryParametrs,
  ) async {
    var r = await AppApi.dio2.post(
      "/tasks/taskInstructPackage/selectPersonalPackage",
      data: queryParametrs,
    );
    print(r.data["data"]);
    // if(r.data["data"]["code"] == "S_F_5003"){
    // return RepairResponse.fromJson(r.data["data"]);
    // }else{
    //   return FaultResponse.fromJson(r.data["data"]);
    // }
  }

  // 取消主修
  void cancelMainRepair(List<String> queryParametrs) async {
    var r = await AppApi.dio2.post(
      "/tasks/taskInstructPackage/cancelPersonalPackage",
      data: queryParametrs,
    );
    print(r.data["data"]);

    // return RepairResponse.fromJson(r.data["data"]);
  }

  // 成为辅修
  void beAssistantRepair(List<String> queryParametrs) async {
    var r = await AppApi.dio2.post(
      "/tasks/taskInstructPackage/selectAssistantPackage",
      data: queryParametrs,
    );
    print(r.data["data"]);

    // return RepairResponse.fromJson(r.data["data"]);
  }

  // 取消辅修
  void cancelAssistantRepair(List<String> queryParametrs) async {
    var r = await AppApi.dio2.post(
      "/tasks/taskInstructPackage/cancelAssistantPackage",
      data: queryParametrs,
    );
    print(r.data["data"]);

    // return RepairResponse.fromJson(r.data["data"]);
  }

  // 上传油量照片
  Future<int> uploadOilImg(
      {Map<String, dynamic>? queryParametrs, File? imagedata}) async {
    FormData formData = FormData.fromMap({
      "trainEntryCode": queryParametrs!["trainEntryCode"],
      "uploadFileList": await MultipartFile.fromFile(imagedata!.path)
    });
    var r = await AppApi.dio.post("/fileserver/oilInfoFile/uploadFile",
        data: formData, options: Options(contentType: "multipart/form-data"));
    log("uploadOilImg${r.data}");
    return (r.data["code"]);
  }

  // 上传防溜照片
  Future<int> upSlipImg(
      {Map<String, dynamic>? queryParametrs, File? imagedata}) async {
    FormData formData = FormData.fromMap({
      "trainEntryCode": queryParametrs!["trainEntryCode"],
      "uploadFileList": await MultipartFile.fromFile(imagedata!.path)
    });
    var r = await AppApi.dio.post("/fileserver/antiSlipFile/uploadFile",
        data: formData, options: Options(contentType: "multipart/form-data"));
    log("upSlipImg${r.data}");
    return (r.data["code"]);
  }

  // 图片预览
  Future<Image> previewImage({
    Map<String, dynamic>? queryParametrs,
  }) async {
    var r = await AppApi.dio.get("/fileserver/FileOperation/previewImage",
        queryParameters: queryParametrs);
    log("previewImage${r.data}");
    return r.data;
  }

  // 文件下载
  Future<dynamic> downloadFile({
    Map<String, dynamic>? queryParametrs,
  }) async {
    log(queryParametrs?["url"]);
    var r = await AppApi.dio.post("/fileserver/FileOperation/downloadFile",
        queryParameters: queryParametrs);
    log("downloadFile${r.data}");
    return r;
  }

  // 查看主流程节点以及工序节点
  Future<MainNodeList> getMainNodeANdProc1() async {
    var r = await AppApi.dio.get(
      "/subparts/repairMainNode/getProcessingMainNodeAndProc",
    );
    print((r.data["data"])["data"]);
    return MainNodeList.fromJson(r.data["data"]);
  }

  // 获取个人作业包
  Future<dynamic> getPersonalWorkPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/tasks/taskInstructPackage/getIndividualTaskPackage",
      queryParameters: queryParametrs,
    );
    print(r.data["data"]);
    return WorkPackageList.fromJson(r.data["data"]);
  }

  //开工
  void startWork(
    List<Map<String, dynamic>>? queryParametrs,
  ) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/startWork",
      data: queryParametrs,
    );
    print(r.data["data"]);
  }

//开工测试
    void startWork2(
    List<Map<String, dynamic>>? queryParametrs,
  ) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/startWork",
      data: queryParametrs,
    );
    print(r.data["data"]);
  }

  // 获取动力类型-车型树
  Future<dynamic> getDynamicAndJcType() async {
    var r = await AppApi.dio.get(
      "/subparts/jcDynamicType/getDynamicAndJcType",
    );
    // log("getDynamicAndJcType${r.data}");
    return (r.data["data"])["data"];
  }

  // 获取修制-修程
  Future<dynamic> getSysAndProc({Map<String, dynamic>? queryParameters}) async {
    var r = await AppApi.dio.get("/subparts/repairSys/getSysAndProc",
        queryParameters: queryParameters);
    // log("getSysAndProc${r.data}");
    return (r.data["data"])["data"];
  }

  // 获取工序节点
  Future<dynamic> getRepairMainNode(
      {Map<String, dynamic>? queryParameters}) async {
    var r = await AppApi.dio.get("/subparts/repairMainNode/selectAll",
        queryParameters: queryParameters);
    // log("getRepairMainNode${r.data}");
    return ((r.data["data"])["data"])['rows'];
  }
}
