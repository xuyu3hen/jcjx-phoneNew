import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jcjx_phone/models/prework/repair_sys.dart';
import 'package:jcjx_phone/models/prework/repair_main_node.dart';
import 'package:jcjx_phone/models/searchWorkPackage/main_node.dart';
import '../index.dart';
import '../models/prework/package_user.dart';

class ProductApi extends AppApi {
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );
  // 入段列车查询
  Future<TrainEntryList> getTrainEntry({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/selectAll",
        queryParameters: queryParametrs,
      );
      return TrainEntryList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      // 根据具体情况可以选择重新抛出异常，让调用者进一步处理，这里简单返回一个默认值或null（需要根据实际业务调整）
      return TrainEntryList();
    }
  }

  // 预派工查询
  Future<MainDataStructure> getPreDispatchWork({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/workInstructPackageUser/getPackageUserList",
        queryParameters: queryParametrs,
      );
      return MainDataStructure.fromJson((r.data["data"])["data"]);
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
      _handleException(e);
      return MainDataStructure(
          assigned: false, packageUserDTOList: [], station: '');
    }
  }

  // 车号展示
  Future<InnerData> getTrainNum() async {
    try {
      var r = await AppApi.dio
          .get("/dispatch/trainRepairScheduleEdit/getNeedToDeptSchedulePlan");
      logger.i(r.data);
      return InnerData.fromJson(r.data["data"]);
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
      _handleException(e);
      return InnerData(list: null, data: []);
    }
  }

  //置为AB端作业包 subparts/workInstructPackage/updateTaskInstructPackage
  Future<dynamic> updateTaskInstructPackage(
      List<WorkPackage> workPackages) async {
    try {
      var r = await AppApi.dio2.post(
        "/subparts/workInstructPackage/updateTaskInstructPackage",
        data: workPackages,
      );
      logger.i(r.data["data"]);
      if ((r.data["data"])['data'] != null) {
        Map<String, dynamic> data = (r.data["data"])['data'];
        if (data['code'] == 500) {
          showToast(data['msg']);
        }
      }
      return r.data["data"];
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
    }
  }

  //同步作业包 subparts/workInstructPackage/syncWorkPackageToPackageUser
  Future<dynamic> syncWorkPackageToPackageUser({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/workInstructPackage/syncWorkPackageToPackageUser",
        queryParameters: queryParametrs,
      );
      logger.i(r);
      logger.i(r.data["data"]);
      return r.data["data"];
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
    }
  }

  //入段车号展示dynamic
  Future<dynamic> getTrainNumDynamic() async {
    try {
      var r = await AppApi.dio
          .get("/dispatch/trainRepairScheduleEdit/getNeedToDeptSchedulePlan");
      logger.i("展示获取信息");
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
    }
  }

  // 检修地点展示
  Future<TrainLocation> getstopLocation(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/stopPosition/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(r.data["data"]);
      return TrainLocation.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return TrainLocation();
    }
  }

  // 动力类型查询
  Future<DynamicTypeList> getDynamicType({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/jcDynamicType/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(r.data["data"]);
      logger.i((r.data["data"])["data"]["rows"]);
      return DynamicTypeList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return DynamicTypeList();
    }
  }

  // 机车型号
  Future<JcTypeList> getJcType({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/jcType/selectAll",
        queryParameters: queryParametrs,
      );
      return JcTypeList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return JcTypeList();
    }
  }



  // 获取车号（本质查询检修计划）
  Future<RepairPlanList> getRepairPlanList({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/selectAll",
        queryParameters: queryParametrs,
      );
      log("getRepairPlanList${r.data}");
      return RepairPlanList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return RepairPlanList();
    }
  }

  // 修程查询
  Future<RepairProcList> getRepairProc({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/repairProc/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return RepairProcList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return RepairProcList();
    }
  }

  // 修次查询
  Future<RepairTimesList> getRepairTimes({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/repairTimes/selectAll",
        queryParameters: queryParametrs,
      );
      return RepairTimesList.fromJson((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
      return RepairTimesList();
    }
  }

  // 新增入段
  Future<dynamic> newTrainEntry({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/trainEntry/save",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
      return r.data["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

    // 通过车号查询机车计划信息
  Future<dynamic> getTrainInfoByPlan({
    Map<String, dynamic>? queryParametrs,
  }) async{
    try {
      var r = await AppApi.dio.post(
        "/plan/repairPlan/getRepairPlanByTrainNum",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  //查询修制
  Future<RepairSysResponse> selectRepairSys({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      logger.i('code');
      //get中使用queryParameters，post中使用data
      logger.i(queryParametrs!['dynamicCode']);
      var r = await AppApi.dio.get(
        "/subparts/repairSys/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return RepairSysResponse.fromJson((r.data["data"])["data"]);
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
      return RepairSysResponse();
    }
  }

  //获取 subparts/jcRoleConfigNode/getUerListByDeptId
  Future<dynamic> getUserListByDeptId({
    Map<String, dynamic>? queryParametrs,
  }) async {
    // try {
    var r = await AppApi.dio.get(
      "/subparts/jcRoleConfigNode/getUserListByDeptId",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  //上传 plan/repairPlan/addTempPlan
  Future<dynamic> uploadPlan({
    Map<String, dynamic>? queryParametrs,
  }) async {
    // try {
    var r = await AppApi.dio.post(
      "/plan/repairPlan/addTempPlan",
      queryParameters: queryParametrs,
    );
    logger.i(r.data);
    return r.data;
  }

  // 查看领取作业包
  Future<dynamic> getWorkPackage({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getCommonPackageList",
        queryParameters: queryParametrs,
      );
      logger.i(r.data["data"]);
      return WorkPackageList.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
      return WorkPackageList(data: []);
    }
  }

  // 成为主修
  Future<void> beMainRepair(
    List<String> queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio2.post(
        "/tasks/taskInstructPackage/selectPersonalPackage",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
      // if(r.data["data"]["code"] == "S_F_5003"){
      // return RepairResponse.fromJson(r.data["data"]);
      // }else{
      //   return FaultResponse.fromJson(r.data["data"]);
      // }
    } catch (e) {
      _handleException(e);
    }
  }

  // 取消主修
  Future<void> cancelMainRepair(List<String> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/tasks/taskInstructPackage/cancelPersonalPackage",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);

      // return RepairResponse.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  // 成为辅修
  Future<void> beAssistantRepair(List<String> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/tasks/taskInstructPackage/selectAssistantPackage",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);

      // return RepairResponse.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  //查询机车预派工机车
  Future<dynamic> getNotEnterTrainPlan() async {
    try {
      var r = await AppApi.dio.post(
        "/plan/repairPlan/getNotEnterTrainPlan",
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  //查询班组
  Future<dynamic> getTeamInfo(Map<String, dynamic>? queryParametrs) async {
    //获取班组
    var r = await AppApi.dio.get(
        "/tasks/deptSchedule/getDeptScheduleByPlanCodeAndDeptId",
        queryParameters: queryParametrs);
    logger.i((r.data["data"])['data']);
    return (r.data["data"])['data'];
  }

  // 取消辅修
  Future<void> cancelAssistantRepair(List<String> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/tasks/taskInstructPackage/cancelAssistantPackage",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);

      // return RepairResponse.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  //dispatch/trainEntry/selectAll
  Future<dynamic> getTrainEntryDynamic(
      Map<String, dynamic>? queryParametrs) async {
    var r = await AppApi.dio.get(
      "/dispatch/trainEntry/selectAll",
      data: queryParametrs,
    );
    logger.i((r.data["data"])['data']);

    return (r.data["data"])['data'];
  }

  // dispatch/trainEntry/getTrainEntryByRepairMainNodeCodeList
  Future<Map<String, List<dynamic>>> getTrainEntryByRepairMainNodeCodeList(
      List<String> codeList) async {
    var r = await AppApi.dio2.post(
      "/dispatch/trainEntry/getTrainEntryByRepairMainNodeCodeList",
      data: codeList,
    );

    //将Map<String, dynamic>转换为Map<String, List<dynamic>>
    Map<String, List<dynamic>> map = {};
    for (var key in (r.data["data"])['data'].keys) {
      map[key] = (r.data["data"])['data'][key];
    }
    logger.i(map.toString());
    // return (r.data["data"])['data'];
    return map;
  }

  // dispatch/trainEntry/getRepairingTrainStatus
  Future<dynamic> getRepairingTrainStatus(List<String> codeList) async {
    var r = await AppApi.dio2.post(
      "/dispatch/trainEntry/getRepairingTrainStatus",
      data: codeList,
    );
    logger.i(r.data["data"]);
    return r.data["data"];
  }

  // 上传油量照片
  Future<int> uploadOilImg(
      {Map<String, dynamic>? queryParametrs, File? imagedata}) async {
    try {
      FormData formData = FormData.fromMap({
        "trainEntryCode": queryParametrs!["trainEntryCode"],
        "uploadFileList": await MultipartFile.fromFile(imagedata!.path)
      });
      var r = await AppApi.dio.post("/fileserver/oilInfoFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i("uploadOilImg${r.data}");
      return (r.data["code"]);
    } catch (e) {
      _handleException(e);
      return -1; // 根据具体情况返回合适的表示错误的值，这里返回 -1 示意上传失败
    }
  }

  //上传作业项图片
  //传输多个图片
  Future<int> uploadCertainPackageImg(
      {Map<String, dynamic>? queryParametrs,
      required List<File> imagedatas}) async {
    try {
      Map<String, dynamic> formMap = {};
      formMap["certainPackageCodeList"] =
          queryParametrs?["certainPackageCodeList"];
      formMap['secondPackageCode'] = queryParametrs?['secondPackageCode'];
      if (imagedatas.isNotEmpty) {
        for (var i = 0; i < imagedatas.length; i++) {
          List<MultipartFile> fileList = [];
          for (var i = 0; i < imagedatas.length; i++) {
            fileList.add(await MultipartFile.fromFile(imagedatas[i].path));
          }
          formMap['uploadFileList'] = fileList;
        }
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post(
          "/fileserver/taskCertainContentFile/uploadFile",
          data: formData,
          options: Options(contentType: "multipart/form-data"));
      logger.i("uploadImg${r.data}");
      return (r.data["code"]);
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
      return -1;
    }
  }

  // 完成作业项
  Future<int> finishCertainPackage(
      List<TaskCertainPackageList> queryParameters) async {
    // try {
    var r = await AppApi.dio2.post(
        "/tasks/taskCertainPackage/completeTaskCertainPackage",
        data: queryParameters);
    logger.i("finishCertainPackage${r.data}");
    return (r.data["code"]);
    // } catch (e) {
    //   _handleException(e);
    //   return -1;
    // }
  }

  // 上传防溜照片
  Future<int> upSlipImg(
      {Map<String, dynamic>? queryParametrs, File? imagedata}) async {
    try {
      FormData formData = FormData.fromMap({
        "trainEntryCode": queryParametrs!["trainEntryCode"],
        "uploadFileList": await MultipartFile.fromFile(imagedata!.path)
      });
      var r = await AppApi.dio.post("/fileserver/antiSlipFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i("upSlipImg${r.data}");
      return (r.data["code"]);
    } catch (e) {
      _handleException(e);
      return -1;
    }
  }

  // 图片预览
  Future<Image?> previewImage({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get("/fileserver/FileOperation/previewImage",
          queryParameters: queryParametrs);
      logger.i("previewImage${r.data}");
      return r.data;
    } catch (e) {
      _handleException(e);
      // 根据实际情况返回合适的默认图片或者抛出异常等，这里简单返回null
      return null;
    }
  }

  // 文件下载
  Future<dynamic> downloadFile({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      log(queryParametrs?["url"]);
      var r = await AppApi.dio.post("/fileserver/FileOperation/downloadFile",
          queryParameters: queryParametrs);
      log("downloadFile${r.data}");
      return r;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 查看主流程节点以及工序节点
  Future<MainNodeList> getMainNodeANdProc1() async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/repairMainNode/getProcessingMainNodeAndProc",
      );
      logger.i((r.data["data"])["data"]);
      return MainNodeList.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
      return MainNodeList(data: []);
    }
  }

  //获取班组作业包
  Future<PackageUserData> getTeamWorkPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    // try {
    var r = await AppApi.dio.get(
      "/subparts/workInstructPackageUser/getPakcageUserList",
      queryParameters: queryParametrs,
    );
    logger.i(r.data["data"]);
    return PackageUserData.fromJson(r.data["data"]);
    // } catch (e) {
    //   _handleException(e);
    //   return WorkPackageList(data: []);
    // }
  }

  //获取工序节点
  Future<RepairMainNode> getRepairMainNodeAll(
      {Map<String, dynamic>? queryParametrs}) async {
    // try {
    var r = await AppApi.dio.get(
      "/subparts/repairMainNode/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return RepairMainNode.fromJson((r.data["data"])["data"]);
    // } catch (e) {
    //   _handleException(e);
    //   return RepairMainNode();
    // }
  }

  // 获取个人作业包
  Future<dynamic> getPersonalWorkPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getIndividualTaskPackage",
        queryParameters: queryParametrs,
      );
      logger.i(r.data["data"]);
      return WorkPackageList.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
      return WorkPackageList(data: []);
    }
  }

  Future<dynamic> getRepairPlanByTrainNumber(
      {Map<String, dynamic>? queryParametrs}) async{
        var r = await AppApi.dio.post("/plan/repairPlan/getRepairPlanByTrainNum",
        queryParameters: queryParametrs,
      );
      logger.i(r);
      return r;
  }

  //开工
  void startWork(
    List<Map<String, dynamic>>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskInstructPackage/startWork",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  //开工测试
  void startWork2(
    List<Map<String, dynamic>>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskInstructPackage/startWork",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  // 获取动力类型-车型树
  Future<dynamic> getDynamicAndJcType() async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/jcDynamicType/getDynamicAndJcType",
      );
      // log("getDynamicAndJcType${r.data}");
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 获取修制-修程
  Future<dynamic> getSysAndProc({Map<String, dynamic>? queryParameters}) async {
    try {
      var r = await AppApi.dio.get("/subparts/repairSys/getSysAndProc",
          queryParameters: queryParameters);
      // log("getSysAndProc${r.data}");
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 获取工序节点
  Future<List<Map<String, dynamic>>> getRepairMainNode({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      var r = await AppApi.dio.get("/subparts/repairMainNode/selectAll",
          queryParameters: queryParameters);
      logger.i(r.data["data"]);
      // 确保返回的数据格式正确
      List<dynamic> rows = r.data["data"]["data"]["rows"];
      return rows.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  //获取第二工位作业包
  Future<SecondPackage> getSecondWorkPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    // try {
    var r = await AppApi.dio.get(
      "/tasks/taskSecondPackage/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return SecondPackage.fromJson((r.data["data"])["data"]);
    // } catch (e) {
    //   _handleException(e);
    //   return SecondPackage();
    // }
  }

  // 获取用户列表
  Future<UserList> getUserList(List<int> queryParametrs) async {
    // try {
    var r = await AppApi.dio2.post(
      "/jcjxsystem/sysUser/getUserListByUserIdList",
      data: queryParametrs,
    );
    logger.i(r.data["data"]);
    return UserList.fromJson(r.data["data"]);
    // } catch (e) {
    //   _handleException(e);
    //   return UserList(data: []);
    // }
  }

  //保存team
  void saveTeam(List<Map<String, dynamic>> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/tasks/deptSchedule/save",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  //保存施修人
  void saveAssociated(List<Map<String, dynamic>> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/subparts/workInstructPackageUser/saveOrUpdate",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  //保存机车入段信息
  Future<dynamic> trainEntrySave(
      Map<String, dynamic> queryParametrs) async {
    try {
      var r = await AppApi.dio2.post(
        "/dispatch/trainEntry/save",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
      return r.data["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  Future<dynamic> getDeptTreeByParentIdList(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/jcjxsystem/dept/getDeptTreeByParentIdList",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  //获取dispatch/jcRepairSegment/selectAll
  Future<dynamic> getJcRepairSegment(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/dispatch/jcRepairSegment/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i(r.data["data"]);
    return (r.data["data"])["data"];
  }

  //获取dispatch/jcAssignSegment/selectAll
  Future<dynamic> getJcAssignSegment(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/dispatch/jcAssignSegment/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i(r.data["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/repairTimes/selectAll
  Future<dynamic> getRepairTimesDynamic(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/repairTimes/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/jcDynamicType/selectAll
  Future<dynamic> getJcDynamicType(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/jcDynamicType/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i(r.data["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/jcType/selectAll
  Future<dynamic> getJcTypeInfo({Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/jcType/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i(r.data["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/stopPosition/selectAll
  Future<dynamic> getStopPosition(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/stopPosition/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/repairSys/selectAll
  Future<dynamic> getRepairSys({Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/repairSys/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  //获取subparts/repairProc/selectAll
  Future<dynamic> getRepairProcMap(
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.get(
      "/subparts/repairProc/selectAll",
      queryParameters: queryParametrs,
    );
    logger.i((r.data["data"])["data"]);
    return (r.data["data"])["data"];
  }

  Future<dynamic> getDictCode(Map<String, dynamic>? queryParameters) async {
    // try {
    var r = await AppApi.dio.get(
      "/system/dict/data/list",
      queryParameters: queryParameters,
    );
    logger.i(r.data);
    return r.data;
    // } catch (e) {
    //   _handleException(e);
    //   return null;
    // }
  }

  //根据riskLevel查询post
  Future<dynamic> getPostByRiskLevel(
      Map<String, dynamic> queryParameters) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/riskLevelPost/selectAll",
        queryParameters: queryParameters,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  //getUserListByPostIdList 获取对应的用户信息
  Future<dynamic> getUserListByPostIdList(List<int> postIdList) async {
    try {
      var r = await AppApi.dio2.post(
        "/jcjxsystem/sysPost/getUserListByPostIdList",
        data: postIdList,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  //jcjxsystem/dept/getDeptByIdList
  Future<dynamic> getDeptByDeptIdList(
      Map<String, dynamic> queryParameters) async {
    try {
      var r = await AppApi.dio.get(
        "/jcjxsystem/dept/getDeptByIdList",
        queryParameters: queryParameters,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e, stackTrace) {
      logger.e(e, stackTrace);
      return null;
    }
  }

  //subparts/repairMainNode/selectAll

// 统一异常处理方法
  void _handleException(dynamic e) {
    String errorMessage = "";
    if (e is DioException) {
      // 根据DioException的不同类型进行更细致的处理，比如网络连接错误、超时等
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = "网络连接超时，请检查网络设置";
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = "发送请求超时，请稍后重试";
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = "接收响应超时，请稍后重试";
          break;
        case DioExceptionType.badResponse:
          // 服务器返回了错误状态码，可以根据具体的状态码进行不同提示等
          if (e.response?.statusCode == 401) {
            errorMessage = "未授权，请重新登录";
          } else if (e.response?.statusCode == 403) {
            errorMessage = "权限不足，无法访问该资源";
          } else if (e.response?.statusCode == 404) {
            errorMessage = "请求的资源不存在，请检查请求地址";
          } else if (e.response!.statusCode! >= 500) {
            errorMessage = "服务器内部错误，请稍后重试";
          } else {
            errorMessage = "服务器返回错误，状态码: ${e.response?.statusCode}";
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = "请求已被取消";
          break;
        case DioExceptionType.badCertificate:
          errorMessage = "证书验证出现问题，请检查服务器证书配置";
          break;
        case DioExceptionType.unknown:
          errorMessage = "网络出现未知错误，请稍后重试";
          break;
        default:
          errorMessage = "出现未知网络异常，请稍后重试";
      }
    } else {
      // 其他非DioException类型的异常处理，比如文件读取错误等（如果相关方法涉及文件操作等）
      errorMessage = "出现未知错误，请稍后重试";
    }

    // 在开发环境下，打印更详细的错误信息，方便排查问题
    if (kDebugMode) {
      if (e is DioException && e.response != null) {
        // 打印请求的URL、请求方法、请求头、请求参数以及响应数据等详细信息
        log("请求URL: ${e.requestOptions.path}");
        log("请求方法: ${e.requestOptions.method}");
        log("请求头: ${e.requestOptions.headers}");
        log("请求参数: ${e.requestOptions.data}");
        log("响应Data: ${e.response?.data}");
      }
      log("出现异常: $e");
    }

    // 显示错误提示给用户
    Fluttertoast.showToast(msg: errorMessage);
  }
}
