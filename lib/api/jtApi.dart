import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import '../index.dart';

class JtApi extends AppApi{

  // 上传机统28照片
  Future<dynamic> uploadJt({
    File? imagedata
  })async{
    FormData formData = FormData.fromMap({
      "uploadFileList": await MultipartFile.fromFile(imagedata!.path)
    });
    var r = await AppApi.dio.post(
      "/fileserver/jt28File/uploadFile",
      data: formData,
      // options: Options(
      //   contentType: "multipart/form-data"
      // )
    );
    // log("uploadJtImg${r.data}");
    return (r.data['data']);
  }

  Future<dynamic> uploadMixJt({
    List<File>? imagedata
  })async{
    List<MultipartFile> MfList = [];
    for(var e in imagedata!){
      var a = await MultipartFile.fromFile(e.path);
      MfList.insert(0,a);
    }
    FormData formData = FormData.fromMap({
      "uploadFileList": MfList
    });
    var r = await AppApi.dio.post(
      "/fileserver/jt28File/uploadFile",
      data: formData,
      options: Options(
        contentType: "multipart/form-data"
      )
    );
    log("uploadMixJt${r.data}");
    return (r.data['data']);
  }

    // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );

  // subparts/workInstructPackage/syncWorkPackageToPackageUser 同步作业包
  Future<void> syncWorkPackageToPackageUser(Map<String, dynamic> params) async{
      var r = await AppApi.dio.get(
        "/subparts/workInstructPackage/syncWorkPackageToPackageUser",
        data: params
      );
      logger.i(r.data);  
  }


  // 机统28保存-更新(提报)
  Future<dynamic> uploadJt28({
    List<Map<String,dynamic>>? queryParametrs
  })async{
    var r = await AppApi.dio.post(
      "/tasks/locomotiveMaintenanceLogDO/saveOrUpdate",
      data: queryParametrs,
    );
    log("uploadJt28${r.data}");
    return (r.data['data']);
  }

  // 派工
  Future<dynamic> dispatchJt28({
    List<Map<String,dynamic>>? queryParametrs
  })async{
    var r = await AppApi.dio.post(
      "/tasks/locomotiveMaintenanceLogDO/saveOrUpdate",
      data: queryParametrs,
    );
    log("dispatchJt28${r.data}");
    return (r.data['data']);
  }

  // 获取零部件树
  Future<dynamic> getAllConfigTreeByCode({
    Map<String,dynamic>? queryParametrs
  })async{
    var r = await AppApi.dio.get(
      "/subparts/jcConfigNode/getAllConfigTreeByCode",
      queryParameters: queryParametrs,
    );
    // log("getAllConfigTreeByCode${r.data}");
    return (r.data['data']);
  }

  // 获取车间，班组
  Future<dynamic> getUserDeptree({
    Map<String,dynamic>? queryParametrs
  })async{
    var r = await AppApi.dio.get(
      "/system/user/deptTree",
      queryParameters: queryParametrs,
    );
    // log("getAllConfigTreeByCode${r.data}");
    return (r.data['data']);
  }

  // 获取班组成员
  Future<dynamic> getUserList({
    Map<String,dynamic>? queryParametrs
  })async{
    var r = await AppApi.dio.get(
      "/system/user/list",
      queryParameters: queryParametrs,
    );
    log("getUserList${r.data}");
    return (r.data);
  }

  // 机统Web展示查询
  // Future<List<JtMessage>> getJtList({
  //   Map<String,dynamic>? queryParameters
  // })async{
  //   var r = await AppApi.dio.get(
  //     "/tasks/vJtWebSearch/selectAll",
  //     queryParameters: queryParameters
  //   );
  //   log("getJtList${r.data}");
  //   return ((((r.data['data'])['data'])['rows']).map<JtMessage>((e) => JtMessage.fromJson(e)).toList());
  // }

  Future<JtMessageList> getJtList({
    Map<String,dynamic>? queryParameters
  })async{
    var r = await AppApi.dio.get(
      "/tasks/vJtWebSearch/selectAll",
      queryParameters: queryParameters
    );
    log("getJtList${r.data}");
    return JtMessageList.fromJson((r.data['data'])['data']);
  }

  // 机统自动派活人员组分组查找
  Future<dynamic> getJtAssign()async{
    var r = await AppApi.dio.post(
      "/tasks/jtAssign/list",
      data: {
        "pageNum" : 0,
        "pageSize" : 0,
      },
    );
    // log("getJtAssign${r.data}");
    return ((r.data['data'])['data'])['records'];
  }

  // 检修作业来源
  Future<JtTypeList> getJtType()async{
    var r = await AppApi.dio.get(
      "/tasks/jtType/selectAll",
      queryParameters: {
        "pageNum" : 0,
        "pageSize" : 0,
      },
    );
    // log("getJtType${r.data}");
    return JtTypeList.fromJson((r.data['data'])['data']);
  }

  // 加工方法
  Future<JtTypeList> getJt28Dict()async{
    var r = await AppApi.dio.get(
      "/tasks/jt28Dict/selectAll",
      queryParameters: {
        "pageNum" : 0,
        "pageSize" : 0,
      },
    );
    // log("getJt28Dict${r.data}");
    return JtTypeList.fromJson((r.data['data'])['data']);
  }

  // 查询专互检
  Future<dynamic> getCheckList({
    Map<String,dynamic>? queryParameters
  })async{
    var r = await AppApi.dio.post(
      "/subparts/riskLevelPost/getUserList",
      data: queryParameters,
    );
    log("getCheckList${r.data}");
    return (r.data['data'])['data'];
  }

  // 通过groupId获取对应文件信息(获取图片包)
  Future<GroupData> getByGroupId({
    Map<String,dynamic>? queryParameters
  })async{
    var r = await AppApi.dio.get(
      "/fileserver/jt28File/getByGroupId",
      queryParameters: queryParameters,
    );
    // log("getCheckList${r.data}");
    return GroupData.fromJson(r.data['data']);
  }

  // 获取个人作业包
  Future<IndividualTaskPackageList> getIndividualTaskPackage({
    Map<String,dynamic>? queryParameters
  }) async {
        var r = await AppApi.dio.get(
      "/tasks/taskInstructPackage/getIndividualTaskPackage",
      queryParameters: queryParameters,
    );
    // log("getCheckList${r.data}");
    return IndividualTaskPackageList.fromJson(r.data['data']);
  }

  // 更新作业包及确定作业项A-B端
  Future<Map<String,dynamic>> updateWorkInstructPackage({
    List<Map<String,dynamic>>? queryParameters
  }) async {
      var r = await AppApi.dio.post(
      "/subparts/workInstructPackage/updateWorkInstructPackage",
      data: queryParameters,
    );
    return r.data;
  }

  // 根据第二工位完成作业项
  Future<Map<String,dynamic>> completeTaskCertainPackage({
    List<Map<String,dynamic>>? queryParameters
  }) async {
      var r = await AppApi.dio.post(
      "/tasks/taskCertainPackage/completeTaskCertainPackage",
      data: queryParameters,
    );
    log("complete${r.data}");
    return r.data;
  }

  // 更新作业项数据
  Future<dynamic> getTaskCertainPackage({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskCertainPackage/selectAll",
      data: queryParameters
    );
    log("getTaskCertainPackage${r.data}");
    return r.data;
  }

  // 作业项图片上传
  Future<dynamic> uploadFileTaskCertainContentFile({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/fileserver/taskCertainContentFile/uploadFile",
      data: queryParameters
    );
    log("uploadFileTaskCertainContentFile${r.data}");
    return r.data;
  }

  // 参数填写
  Future<dynamic> updateTaskContentItem({
    List<TaskContentItem>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskContentItem/saveOrUpdate",
      data: queryParameters
    );
    log("updateTaskContentItem${r.data}");
    return r.data;
  }

  // 作业包模板
  Future<PackageUserList> getPackageUserList({
    Map<String,dynamic>? queryParameters
  }) async {
    print(queryParameters);
    var r = await AppApi.dio.get(
      "/subparts/workInstructPackageUser/getPackageUserList",
      queryParameters: queryParameters
    );
    // log("getPackageUserList${r.data}");
    print(r.data['data']);
    return PackageUserList.fromJson(r.data['data']);
  }

  // 主辅修设置
  Future<dynamic> updateInstructPackageUser({
    List<Map<String,dynamic>>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/subparts/workInstructPackageUser/saveOrUpdate",
      data: queryParameters
    );
    // log("updateInstructPackageUser${r.data}");
    return r.data;
  }

  // 作业项获取(点名用)
  Future<List<WorkInstructPackageUserList>> getworkInstructPackageUser({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/workInstructPackageUser/selectAll",
      queryParameters: queryParameters
    );
    // log("getworkInstructPackageUser${r.data}");
    return ((((r.data['data'])['data'])['rows']).map<WorkInstructPackageUserList>((e) => WorkInstructPackageUserList.fromJson(e)).toList());
  }

  //获取公共作业包 
  Future<IndividualTaskPackageList> getCommonPackageList({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.get(
      "/tasks/taskInstructPackage/getCommonPackageList",
      queryParameters: queryParameters
    );
    log("getCommonPackageList${r.data}");
    return IndividualTaskPackageList.fromJson(r.data['data']);
  }

  // 选择主修作业包(开工锁定)
  Future<dynamic> selectPersonalPackage({
    List<String>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/selectPersonalPackage",
      data: queryParameters
    );
    log("selectPersonalPackage${r.data}");
    return r.data;
  }

  // 取消主修作业包(释放锁定) 
  Future<dynamic> cancelPersonalPackage({
    List<String>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/cancelPersonalPackage",
      data: queryParameters
    );
    log("cancelPersonalPackage${r.data}");
    return r.data;
  }

  // 选择辅修作业包(开工锁定)
  Future<dynamic> selectAssistantPackage({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/selectAssistantPackage",
      data: queryParameters
    );
    log("selectAssistantPackage${r.data}");
    return r.data;
  }

  // 取消辅修作业包(释放锁定) 
  Future<dynamic> cancelAssistantPackage({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.post(
      "/tasks/taskInstructPackage/cancelAssistantPackage",
      data: queryParameters
    );
    log("cancelAssistantPackage${r.data}");
    return r.data;
  }

  // 获取在修工序节点-车号
  Future<dynamic> getProcessingMainNodeAndProc({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.get(
      "/subparts/repairMainNode/getProcessingMainNodeAndProc",
      queryParameters: queryParameters
    );
    log("getProcessingMainNodeAndProc${r.data}");
    return r.data['data'];
  }

  // 通过组流程节点获取机车入段信息
  Future<dynamic> getTrainEntryByRepairMainNodeCode({
    Map<String,dynamic>? queryParameters
  }) async {
    var r = await AppApi.dio.get(
      "/dispatch/trainEntry/getTrainEntryByRepairMainNodeCode",
      queryParameters: queryParameters
    );
    // log("getTrainEntryByRepairMainNodeCode${r.data}");
    return r.data['data'];
  }
}