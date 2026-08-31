import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jcjx_phone/models/prework/repair_sys.dart';
import 'package:jcjx_phone/models/prework/repair_main_node.dart';
import 'package:jcjx_phone/models/searchWorkPackage/main_node.dart';
import '../index.dart';
import '../models/prework/package_user.dart';
import '../models/progress.dart';

class ProductApi extends AppApi {
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );

  void _logLargeTagged(String tag, dynamic value) {
    String text;
    try {
      if (value is String) {
        text = value;
      } else {
        text = const JsonEncoder.withIndent('  ').convert(value);
      }
    } catch (_) {
      text = value?.toString() ?? 'null';
    }
    debugPrintSynchronously('$tag ===== BEGIN =====');
    const chunkSize = 700;
    final lines = const LineSplitter().convert(text);
    for (final line in lines) {
      if (line.isEmpty) {
        debugPrintSynchronously(tag);
        continue;
      }
      for (var i = 0; i < line.length; i += chunkSize) {
        final end = (i + chunkSize < line.length) ? i + chunkSize : line.length;
        final prefix = i == 0 ? '$tag ' : '$tag > ';
        debugPrintSynchronously('$prefix${line.substring(i, end)}');
      }
    }
    debugPrintSynchronously('$tag ===== END =====');
  }

  // 统一异常处理方法
  void _handleException(dynamic e, [StackTrace? stackTrace]) {
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
      debugPrintSynchronously('===== [ERROR] [API] =====');
      if (e is DioException) {
        debugPrintSynchronously('[ERROR] 接口路径: ${e.requestOptions.path}');
        debugPrintSynchronously('[ERROR] 请求方法: ${e.requestOptions.method}');
        debugPrintSynchronously('[ERROR] 请求头: ${e.requestOptions.headers}');
        debugPrintSynchronously('[ERROR] 请求body: ${e.requestOptions.data}');
        debugPrintSynchronously(
            '[ERROR] 请求query: ${e.requestOptions.queryParameters}');
        if (e.response != null) {
          debugPrintSynchronously('[ERROR] 响应状态码: ${e.response?.statusCode}');
          _logLargeTagged('[ERROR] 响应Data', e.response?.data);
        }
        debugPrintSynchronously('[ERROR] 错误类型: ${e.type}');
        debugPrintSynchronously('[ERROR] 错误信息: ${e.message}');
      }
      debugPrintSynchronously('[ERROR] 异常对象: $e');
      if (stackTrace != null) {
        debugPrintSynchronously('[ERROR] 堆栈信息:\n$stackTrace');
      }
      debugPrintSynchronously('===== [ERROR] END =====');
    }

    // 显示错误提示给用户
    showToast(errorMessage);
  }

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

  //  /task/taskCertainPackage/getNeedToMutualInspectionCertainPackageList
  Future<dynamic> getNeedToMutualInspectionCertainPackageList(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskCertainPackage/getNeedToMutualInspectionCertainPackageList",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data)['data'])['data']);
      return ((r.data)['data'])['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/trainShunting/selectAll
  Future<dynamic> getTrainShunting({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShunting/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data["data"])["data"])['rows']);
      return ((r.data["data"])["data"])['rows'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/trainShuntingPackage/selectAll
  Future<dynamic> getTrainShuntingPackage({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPackage/selectAllByDeptId",
        queryParameters: queryParametrs,
      );
      final body = r.data;
      dynamic rows;
      if (body is Map) {
        final data = body["data"];
        final inner = data is Map ? data["data"] : null;
        if (inner is Map && inner["rows"] is List) {
          rows = inner["rows"];
        } else if (inner is List) {
          rows = inner;
        } else if (data is Map && data["rows"] is List) {
          rows = data["rows"];
        }
      }
      final list = rows is List ? rows : const <dynamic>[];
      logger.i(list);
      return list;
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  Future<dynamic> getTrainShuntingPackageAll({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPackage/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data["data"])["data"])["rows"]);
      return ((r.data["data"])["data"])["rows"];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/trainShuntingPackage/receiveShuntingPackage 领取作业包
  Future<dynamic> receiveTrainShuntingPackage({
    required String code,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPackage/receiveShuntingPackage",
        queryParameters: {'code': code},
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/trainShuntingPackage/startWork
  Future<dynamic> startTrainShuntingPackage({
    required List<String> shuntingPlanCodeList,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPlan/startWork",
        queryParameters: {
          'shuntingPlanCodeList': shuntingPlanCodeList.join(',')
        },
      );
      logger.i((r.data["data"]));
      return (r.data["data"]);
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/trainShuntingPackage/invalidPlan
  Future<dynamic> invalidTrainShuntingPackage({
    required List<String> shuntingPlanCodeList,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPlan/invalidPlan",
        queryParameters: {
          'shuntingPlanCodeList': shuntingPlanCodeList.join(',')
        },
      );
      logger.i((r.data["data"]));
      return (r.data["data"]);
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/trainShuntingPackage/completeShuntingPlan
  Future<dynamic> completeTrainShuntingPackage({
    required List<String> shuntingPlanCodeList,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainShuntingPlan/completeShuntingPlan",
        queryParameters: {
          'shuntingPlanCodeList': shuntingPlanCodeList.join(',')
        },
      );
      logger.i((r.data["data"]));
      return (r.data["data"]);
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  Future<dynamic> uploadTrainShuntingPlanFile({
    required String code,
    required XFile file,
  }) async {
    try {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[\\/]+')).last;
      final bytes = await file.readAsBytes();
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: fileName),
        "shuntingPlanCode": code,
      });

      var r = await AppApi.dio.post(
        "/fileserver/trainShuntingPlanFile/uploadFile",
        data: formData,
      );
      logger.i(r.data);
      return r.data;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/trainShunting/selectAll
  Future<dynamic> saveTrainShunting({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/trainShunting/save",
        data: queryParametrs,
      );
      logger.i((r.data["data"]));
      return ((r.data["data"]));
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/trainShuntingPlan/directPublishShuntingPlan
  Future<dynamic> directPublishShuntingPlan({
    List<Map<String, dynamic>>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/trainShuntingPlan/directPublishShuntingPlan",
        data: queryParametrs,
      );
      logger.i((r.data["data"]));
      return ((r.data["data"]));
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  //  /dispatch/masInestigate/selectAll
  Future<dynamic> getMasInestigate({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/masInvestigate/selectAll",
        queryParameters: queryParametrs,
      );
      // logger.i(r.data["data"]['data']['rows']);
      return r.data["data"]['data']['rows'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // 更新调查内容。
  // /dispatch/masInvestigateList/update
  Future<dynamic> updateMasInvestigateList(
    Map<String, dynamic> queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/masInvestigateList/update",
        data: queryParametrs,
      );
      logger.i('updateMasInvestigateList: ${(r.data)['data']}');
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/masAfterSaleShunting/selectAll
  Future<dynamic> getMasAfterSaleShunting({
    Map<String, dynamic>? queryParametrs, // 分页参数
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/masAfterSaleShunting/selectAll",
        queryParameters: queryParametrs,
      );
      // logger.i(r.data["data"]['data']['rows']);
      return r.data["data"]['data']['rows'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/changeMainNodeShunting/selectAll
  Future<List<Map<String, dynamic>>> getChangeMainNodeShunting({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      final r = await AppApi.dio.get(
        "/dispatch/changeMainNodeShunting/selectAll",
        queryParameters: queryParametrs,
      );
      dynamic raw = r.data;
      if (raw is Map) {
        raw = raw['data'] ?? raw;
      }
      if (raw is Map) {
        raw = raw['data'] ?? raw['rows'] ?? raw['list'] ?? raw;
      }
      if (raw is Map) {
        raw =
            raw['rows'] ?? raw['records'] ?? raw['list'] ?? raw['data'] ?? raw;
      }
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (raw is Map) {
        return [Map<String, dynamic>.from(raw)];
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      _handleException(e);
      return <Map<String, dynamic>>[];
    }
  }

  // /dispatch/masSaleInformation/getMasInformationByJt28Code
  Future<dynamic> getMasSaleInformation(
    Map<String, dynamic> queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/masSaleInformation/getMasInformationByJt28Code",
        queryParameters: queryParametrs,
      );
      logger.i('getMasSaleInformation: ${(r.data)['data']}');
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/masSaleInformation/selectAll
  Future<List<Map<String, dynamic>>> getMasSaleInformationList({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      final r = await AppApi.dio.get(
        "/dispatch/masSaleInformation/selectAll",
        queryParameters: queryParametrs,
      );
      dynamic raw = r.data;
      if (raw is Map) {
        raw = raw['data'] ?? raw;
      }
      if (raw is Map) {
        raw = raw['data'] ?? raw['rows'] ?? raw['list'] ?? raw;
      }
      if (raw is Map) {
        raw =
            raw['rows'] ?? raw['records'] ?? raw['list'] ?? raw['data'] ?? raw;
      }
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (raw is Map) {
        return [Map<String, dynamic>.from(raw)];
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      _handleException(e);
      return <Map<String, dynamic>>[];
    }
  }

  //jcjxsystem/message/getMessageInfo  响应格式: { code, message, data: { sysMessageVO: [...], count } }
  Future<dynamic> getMessageInfo({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      final body = queryParametrs ?? {};
      logger.i(
          'getMessageInfo 请求开始: ${AppApi.dio.options.baseUrl}/jcjxsystem/message/getMessageInfo');
      var r = await AppApi.dio.post(
        "/jcjxsystem/message/getMessageInfo",
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      logger.i(r.data['data']);
      return ((r.data['data'])['data']);
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/shuntingNotice/selectAll
  Future<dynamic> getShuntingNotice({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/shuntingNotice/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data)['data'])['data']);
      return ((r.data)['data'])['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /dispatch/shuntingReceiveGroup/selectAll
  Future<dynamic> getShuntingReceiveGroup({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      debugPrintSynchronously(
        '[修程通知单签收组] 请求开始 query=$queryParametrs',
      );
      _logLargeTagged('[修程通知单签收组][QUERY]', queryParametrs ?? {});
      var r = await AppApi.dio.get(
        "/dispatch/shuntingReceiveGroup/selectAll",
        queryParameters: queryParametrs,
      );
      _logLargeTagged('[修程通知单签收组][RAW_RESPONSE]', r.data);
      final outer = r.data;
      final data = outer is Map ? outer['data'] : null;
      final inner = data is Map ? data['data'] : null;
      if (inner is Map && inner['rows'] is List) {
        debugPrintSynchronously(
          '[修程通知单签收组] 请求完成 rows=${(inner['rows'] as List).length}',
        );
        return inner['rows'];
      }
      if (inner is List) {
        debugPrintSynchronously(
          '[修程通知单签收组] 请求完成 rows=${inner.length}',
        );
        return inner;
      }
      if (data is Map && data['rows'] is List) {
        debugPrintSynchronously(
          '[修程通知单签收组] 请求完成 rows=${(data['rows'] as List).length}',
        );
        return data['rows'];
      }
      debugPrintSynchronously('[修程通知单签收组] 请求完成 rows=0');
      return [];
    } catch (e) {
      debugPrintSynchronously('[修程通知单签收组] 请求失败 error=$e');
      _handleException(e);
      return [];
    }
  }

  // 获取最新数据
  // /fileserver/TApkVersion/getLatestOne
  Future<dynamic> getLatestOne({
    String? env, // 环境参数：dev, test, release
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (env != null) {
        queryParams['env'] = env;
      }
      logger.i(queryParams);
      var r = await AppApi.dio.get(
        "/fileserver/TApkVersion/getLatestOne",
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      // 解析返回的数据为 MyApkVersion 对象
      if (r.data["data"] != null) {
        return (r.data["data"])['data'];
      }
      return null;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 通过通用下载接口下载文件 (POST请求，参数为url)
  Future<String?> downloadFileByGeneralDownload({
    required String url,
    required String savePath,
    required Function(int, int) onReceiveProgress,
  }) async {
    try {
      // 使用 download 方法直接保存文件
      // url 是目标文件的地址，通过 POST body 传递给通用下载接口
      await AppApi.dio.download(
        "/fileserver/FileOperation/generalDownloadFile",
        savePath,
        data: {'url': url},
        options: Options(
          method: 'POST',
        ),
        onReceiveProgress: onReceiveProgress,
      );
      return savePath;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /dispatch/shuntingNotice/update  参数为 list
  Future<dynamic> updateShuntingNotice(List<dynamic>? queryParametrs) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/shuntingNotice/update",
        data: queryParametrs,
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // /tasks/taskCertainPackage/wholePackageMutualInspection
  Future<dynamic> wholePackageMutualInspection(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskCertainPackage/wholePackageMutualInspection",
        data: queryParametrs,
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /tasks/taskCertainPackage/wholePackageSpecialInspection
  Future<dynamic> wholePackageSpecialInspection(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskCertainPackage/wholePackageSpecialInspection",
        data: queryParametrs,
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  //  /task/taskCertainPackage/getNeedToSpecialInspectionCertainPackageList
  Future<dynamic> getNeedToSpecialInspectionCertainPackageList(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskCertainPackage/getNeedToSpecialInspectionCertainPackageList",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data)['data'])['data']);
      return ((r.data)['data'])['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // 机统28施修
  Future<dynamic> jt28SaveOrUpdate(
    List<Map<String, dynamic>> queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/locomotiveMaintenanceLogDO/saveOrUpdate",
        data: queryParametrs,
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // /tasks/locomotiveMaintenanceLogDO/updateUserId
  Future<dynamic> updateUserId(
    Map<String, dynamic> queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/locomotiveMaintenanceLogDO/update",
        data: queryParametrs,
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
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
      logger.e(e.toString(), e, stackTrace);
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
      logger.e(e.toString(), e, stackTrace);
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
      logger.e(e.toString(), e, stackTrace);
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
      logger.e(e.toString(), e, stackTrace);
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
      logger.e(e.toString(), e, stackTrace);
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

  //  获取加工方法 /tasks/jt28Dict/selectAll
  Future<dynamic> getProcessMethod(
    Map<String, dynamic>? queryParametrs, // 分页参数
  ) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/jt28Dict/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data["data"]))["data"]["rows"]);
      return (((r.data["data"]))["data"]["rows"]);
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  // 故障零部件查询
  Future<dynamic> getFaultPart(Map<String, dynamic>? queryParametrs) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/jcConfigNode/getPrefixConfigNode",
        queryParameters: queryParametrs,
      );
      // logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

// 查询互检专检人员
  Future<dynamic> getCheckPerson(Map<String, dynamic>? queryParametrs) async {
    try {
      var r = await AppApi.dio.post(
        "/subparts/riskLevelPost/getUserList",
        data: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // tasks/taskContentItem/saveOrUpdate
  Future<dynamic> saveOrUpdateTaskContentItem(
      List<Map<String, dynamic>> queryParametrs) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskContentItem/saveOrUpdate",
        data: queryParametrs,
      );
      logger.i((r.data)['data']);
      return (r.data)['data'];
    } catch (e) {
      _handleException(e);
      return [];
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
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      final inner = (outer is Map) ? outer["data"] : null;
      final json = (inner is Map)
          ? Map<String, dynamic>.from(inner)
          : (outer is Map
              ? Map<String, dynamic>.from(outer)
              : <String, dynamic>{});
      return JcTypeList.fromJson(json);
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      _handleException(e, stackTrace);
      return JcTypeList();
    }
  }

  // 获取车号（本质查询检修计划）
  Future<RepairPlanList> getRepairPlanList({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      _logLargeTagged('[机统28车号查询接口][QUERY]', queryParametrs ?? {});
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/selectAll",
        queryParameters: queryParametrs,
      );
      _logLargeTagged('[机统28车号查询接口][RAW_RESPONSE]', r.data);
      return RepairPlanList.fromJson((r.data["data"])["data"]);
    } catch (e, stackTrace) {
      _handleException(e, stackTrace);
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
  }) async {
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
      logger.e(e.toString(), e, stackTrace);
      return RepairSysResponse();
    }
  }

  // 查询机统28相关 tasks/vJtWebSearch/selectAll
  Future<dynamic> selectRepairSys28({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/vJtWebSearch/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
    }
  }

  // 机统28派工 tasks/locomotiveMaitenanceLogDO/getNeedToDispatchJt28
  Future<dynamic> getNeedToDispatchJt28({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/getNeedToDispatchJt28",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // 机统28派工 tasks/locomotiveMaitenanceLogDO/getNeedToDispatchTeamJt28
  Future<dynamic> getNeedToDispatchTeamJt28({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/getNeedToDispatchTeamJt28",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // 机统28待作业 tasks/locomotiveMaitenanceLogDO/getNeedToWorkJt28
  Future<dynamic> getNeedToWorkJt28({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/getNeedToWorkJt28",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // 机统28待作业 tasks/locomotiveMaitenanceLogDO/getNeedToDispatchInspectionJt28
  Future<dynamic> getNeedToDispatchInspectionJt28({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/getNeedToDispatchInspectionJt28",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // tasks/locomotiveMainTenanceLogDO/queryMutualInspectionJt28ByUserId
  Future<dynamic> queryMutualInspectionJt28ByUserId({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/queryMutualInspectionJt28ByUserId",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // tasks/locomotiveMainTenanceLogDO/queryMutualInspectionJt28ByUserId
  Future<dynamic> querySpecialInspectionJt28ByUserId({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/querySpecialInspectionJt28ByUserId",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  //获取 subparts/jcRoleConfigNode/getUerListByDeptId
  Future<dynamic> getUserListByDeptId({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      debugPrintSynchronously(
        '[修程通知单签收人] 请求开始 query=$queryParametrs',
      );
      _logLargeTagged('[修程通知单签收人][QUERY]', queryParametrs ?? {});
      var r = await AppApi.dio.get(
        "/subparts/jcRoleConfigNode/getUserListByDeptId",
        queryParameters: queryParametrs,
      );
      _logLargeTagged('[修程通知单签收人][RAW_RESPONSE]', r.data);
      final data = (r.data["data"])["data"];
      final rows = data is Map && data['rows'] is List
          ? data['rows'] as List
          : (data is List ? data : const []);
      debugPrintSynchronously(
        '[修程通知单签收人] 请求完成 rows=${rows.length}',
      );
      return data;
    } catch (e) {
      debugPrintSynchronously('[修程通知单签收人] 请求失败 error=$e');
      _handleException(e);
      return [];
    }
  }

  Future<dynamic> getVUserRolePostDetailListByRoleIdList(
    List<int> roleIdList,
  ) async {
    try {
      debugPrintSynchronously(
        '[修程通知单签收角色] 请求开始 roleIdList=$roleIdList',
      );
      _logLargeTagged('[修程通知单签收角色][QUERY]', roleIdList);
      final r = await AppApi.dio2.post(
        "/jcjxsystem/sysUser/getVUserRolePostDetailListByRoleIdList",
        data: roleIdList,
      );
      _logLargeTagged('[修程通知单签收角色][RAW_RESPONSE]', r.data);
      final outer = r.data is Map ? r.data['data'] : null;
      final data = outer is Map ? outer['data'] : null;
      final rows = data is Map ? data.keys.toList() : const [];
      debugPrintSynchronously(
        '[修程通知单签收角色] 请求完成 rows=${rows.length}',
      );
      return data ?? [];
    } catch (e) {
      debugPrintSynchronously('[修程通知单签收角色] 请求失败 error=$e');
      _handleException(e);
      return [];
    }
  }

  //dispatch/masAfterSaleShunting/Update
  Future<dynamic> update({
    dynamic data,
  }) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/masAfterSaleShunting/update",
        data: data,
      );
      logger.i(r.data);
      return r.data;
    } catch (e) {
      _handleException(e);
    }
  }

  Future<dynamic> saveMasNotice({
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrintSynchronously('[修程通知单保存] 请求开始');
      _logLargeTagged('[修程通知单保存][QUERY]', data);
      final r = await AppApi.dio.post(
        "/dispatch/masNotice/save",
        data: data,
      );
      _logLargeTagged('[修程通知单保存][RAW_RESPONSE]', r.data);
      final code = r.data is Map ? r.data['code'] : null;
      debugPrintSynchronously('[修程通知单保存] 请求完成 code=$code');
      return r.data;
    } catch (e) {
      debugPrintSynchronously('[修程通知单保存] 请求失败 error=$e');
      _handleException(e);
    }
  }

  Future<dynamic> getMasNoticeSelectAll({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      debugPrintSynchronously('[修程通知单回写] 请求开始 query=$queryParametrs');
      _logLargeTagged('[修程通知单回写][QUERY]', queryParametrs ?? {});
      final r = await AppApi.dio.get(
        "/dispatch/masNotice/selectAll",
        queryParameters: queryParametrs,
      );
      _logLargeTagged('[修程通知单回写][RAW_RESPONSE]', r.data);
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data['data'];
      final inner = outer is Map ? outer['data'] : null;
      final rows = inner is Map
          ? inner['rows']
          : (outer is Map ? outer['rows'] : (data['rows'] ?? inner ?? outer));
      final rowsCount = rows is List ? rows.length : 0;
      debugPrintSynchronously('[修程通知单回写] 请求完成 rows=$rowsCount');
      return inner ?? outer ?? data;
    } catch (e) {
      debugPrintSynchronously('[修程通知单回写] 请求失败 error=$e');
      _handleException(e);
    }
  }

  // 获取 /dispatch/releaseShunting/save
  Future<dynamic> releaseShunting({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/releaseShunting/save",
        queryParameters: queryParametrs,
      );
      logger.i(r.data);
      return r.data;
    } catch (e) {
      _handleException(e);
    }
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
  Future<dynamic> getNotEnterTrainPlan(
      {Map<String, dynamic>? queryParameters}) async {
    try {
      var r = await AppApi.dio
          .post("/plan/repairPlan/getNotEnterTrainPlan", data: queryParameters);
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

  // /subparts/repairProc/selectAll

  //dispatch/trainEntry/selectAll
  Future<dynamic> getTrainEntryDynamic(
      Map<String, dynamic>? queryParametrs) async {
    var r = await AppApi.dio.get(
      "/dispatch/trainEntry/selectAll",
      queryParameters: queryParametrs,
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

  //上传机统28图片参数只有二进制文件
  Future<dynamic> uploadImgJt28({File? imagedata}) async {
    try {
      FormData formData = FormData.fromMap(
          {"uploadFileList": await MultipartFile.fromFile(imagedata!.path)});
      var r = await AppApi.dio.post("/fileserver/shuntingFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i(r.data["data"]);
      return (r.data["data"]);
    } catch (e) {
      _handleException(e);
      return ''; // 根据具体情况返回合适的表示错误的值，这里返回 -1 示意上传失败
    }
  }

  //增加信息

  //上传调查清单图片
  Future<dynamic> uploadShuntingInfo(
      {required List<File>? data, String? code}) async {
    try {
      Map<String, dynamic> formMap = {};
      formMap["shuntingCode"] = code;
      if (data!.isNotEmpty) {
        List<MultipartFile> fileList = [];
        for (var i = 0; i < data.length; i++) {
          fileList.add(await MultipartFile.fromFile(data[i].path));
        }
        formMap['multipartFileList'] = fileList;
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post("/fileserver/shuntingFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i(r.data["data"]);
      return (r.data["data"]);
    } catch (e) {
      _handleException(e);
      return ''; // 根据具体情况返回合适的表示错误的值，这里返回 -1 示意上传失败
    }
  }

  // 获取作业进度
  Future<dynamic> getWorkProgress(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      log(queryParametrs.toString());
      var r = await AppApi.dio.post(
        "/tasks/taskInstructPackage/getRepairMainNodeProgress",
        data: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  Future<int> uploadShuntingFile(
      {Map<String, dynamic>? queryParametrs,
      required List<File> imagedatas}) async {
    try {
      Map<String, dynamic> formMap = {};
      formMap["shuntingCode"] = queryParametrs?["code"];

      if (imagedatas.isNotEmpty) {
        List<MultipartFile> fileList = [];
        for (var i = 0; i < imagedatas.length; i++) {
          fileList.add(await MultipartFile.fromFile(imagedatas[i].path));
        }
        formMap['uploadFileList'] = fileList;
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post("/fileserver/shuntingFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i(r.data["data"]);
      return (r.data["data"]);
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      return -1;
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
        List<MultipartFile> fileList = [];
        for (var i = 0; i < imagedatas.length; i++) {
          fileList.add(await MultipartFile.fromFile(imagedatas[i].path));
        }
        formMap['uploadFileList'] = fileList;
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post(
          "/fileserver/taskCertainContentFile/uploadFile",
          data: formData,
          options: Options(contentType: "multipart/form-data"));
      logger.i("uploadImg${r.data}");
      return (r.data["code"]);
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      return -1;
    }
  }

  // 完成作业项
  Future<int> finishCertainPackage(
      List<Map<String, dynamic>> queryParameters) async {
    try {
      var r = await AppApi.dio2.post(
          "/tasks/taskCertainPackage/completeTaskCertainPackage",
          data: queryParameters);
      logger.i(queryParameters);
      return (r.data["code"]);
    } catch (e) {
      _handleException(e);
      return -1;
    }
  }

  // 查看分配作业包
  Future<dynamic> getAssignPackage(Map<String, dynamic>? queryParametrs) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getTaskPackageByTrainEntryCode",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
    }
  }

  // /dispatch/trainEntry/getTrainEntryAndDynamics
  // 查询检修调令
  Future<List<RepairGroup>> getTrainEntryAndDynamics(
      Map<String, dynamic>? queryParametrs) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/getTrainEntryAndDynamics",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      List<RepairGroup> repairGroups = [];

      for (var item in (r.data["data"])["data"]) {
        logger.i(item.toString());
        repairGroups.add(RepairGroup.fromJson(item));
      }
      logger.i(repairGroups.toString());
      return repairGroups;
    } catch (e) {
      _handleException(e);
      return [
        RepairGroup(
            children: [], repairProcCode: '', repairProcName: '', sort: 0)
      ];
    }
  }

  // 上传防溜照片
  Future<int> upSlipImg(
      {Map<String, dynamic>? queryParametrs, List<File>? imagedataList}) async {
    try {
      List<MultipartFile> multipartFiles = [];
      for (var file in imagedataList!) {
        var multipartFile = await MultipartFile.fromFile(file.path);
        multipartFiles.add(multipartFile);
      }

      final antiSlipType = queryParametrs?['antiSlipType'];
      final formMap = <String, dynamic>{
        "trainEntryCode": queryParametrs!["trainEntryCode"],
        'shuntingPlanCode': queryParametrs['shuntingPlanCode'],
        "uploadFileList": multipartFiles,
      };
      if (antiSlipType != null) {
        formMap['antiSlipType'] = antiSlipType;
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post("/fileserver/antiSlipFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i("upSlipImg${r.data}");
      return (r.data["code"]);
    } catch (e) {
      _handleException(e);
      return -1;
    }
  }

  // 上传调车防溜照片
  Future<int> upShuntingImg(
      {Map<String, dynamic>? queryParametrs, List<File>? imagedataList}) async {
    try {
      List<MultipartFile> multipartFiles = [];
      for (var file in imagedataList!) {
        var multipartFile = await MultipartFile.fromFile(file.path);
        multipartFiles.add(multipartFile);
      }

      final antiSlipType = queryParametrs?['antiSlipType'];
      final formMap = <String, dynamic>{
        "trainEntryCode": queryParametrs!["trainEntryCode"],
        'shuntingPlanCode': queryParametrs['shuntingPlanCode'],
        "uploadFileList": multipartFiles,
      };
      if (antiSlipType != null) {
        formMap['antiSlipType'] = antiSlipType;
      }
      FormData formData = FormData.fromMap(formMap);
      var r = await AppApi.dio.post("/fileserver/antiSlipFile/uploadFile",
          data: formData, options: Options(contentType: "multipart/form-data"));
      logger.i("upShuntingImg${r.data}");
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
      // 直接获取字节响应，指定responseType为bytes
      var response = await AppApi.dio.get(
          "/fileserver/FileOperation/previewImage",
          queryParameters: queryParametrs,
          options: Options(responseType: ResponseType.bytes));

      logger.i("previewImage bytes length: ${response.data?.length}");

      // 处理字节流数据
      if (response.data != null) {
        // response.data 应该是 Uint8List 类型的字节数据
        if (response.data is Uint8List) {
          return Image.memory(response.data as Uint8List);
        }
        // 如果是 List<int>，转换为 Uint8List
        else if (response.data is List<int>) {
          return Image.memory(Uint8List.fromList(response.data as List<int>));
        }
      }

      // 如果没有有效的数据，返回null
      return null;
    } catch (e) {
      _handleException(e);
      logger.e("previewImage 错误: $e");
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

  // jcjxsystem/sysUser/selectAll
  Future<dynamic> getTeamUser({Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/jcjxsystem/sysUser/selectAll",
        queryParameters: queryParametrs,
      );
      // logger.i(((r.data["data"])["data"])['rows']);
      return ((r.data["data"])["data"])['rows'];
    } catch (e) {
      _handleException(e);
    }
  }

  // /subparts/riskLevelPost/getUserListByPostAndDeptId
  Future<dynamic> getUserListByPostAndDeptId(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/subparts/riskLevelPost/getUserListByPostAndDeptId",
        queryParameters: queryParametrs,
      );
      // logger.i(((r.data["data"])["data"])['rows']);
      logger.i(((r.data["data"])["data"]));
      return ((r.data["data"])["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  // jcjxsystem/sysUser/selectAll
  Future<dynamic> getUserList1({Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/jcjxsystem/sysUser/selectUserList",
        queryParameters: queryParametrs,
      );
      // logger.i(((r.data["data"])["data"])['rows']);
      return ((r.data["data"])["data"])['rows'];
    } catch (e) {
      _handleException(e);
    }
  }

  // /tasks/taskInstructPackage/update
  Future<dynamic> updateTaskInstructPackageRepairInfo(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskInstructPackage/update",
        data: queryParametrs,
      );
      logger.i(r.data);
      return r.data;
    } catch (e) {
      _handleException(e);
      return -1;
    }
  }

  // /dispatch/releaseShunting/save
  Future<dynamic> saveReleaseShunting(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/releaseShunting/save",
        data: queryParametrs,
      );
      logger.i((r.data['data'])['data']);
      return (r.data['data'])['data'];
    } catch (e) {
      _handleException(e);
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

  // 获取相关联排程 /dispatch/mainNodeSchedleNode/selectAll
  Future<dynamic> getMainNodeSchedleNodeAll(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/mainNodeScheduleNode/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 获取个人作业包
  Future<dynamic> getPersonalWorkPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getIndividualTaskPackage",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return WorkPackageList(data: []);
    }
  }

  // 获取作业项 /tasks/taskCertainPackage/selectAll
  Future<dynamic> getTaskCertainPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskCertainPackage/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data["data"])["data"])["rows"]);
      return ((r.data["data"])["data"])["rows"];
    } catch (e) {
      _handleException(e);
      return RepairPlan();
    }
  }

  // 获取作业包 tasks/taskInstructPackage/selectAll
  Future<dynamic> getInstructPackage(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(r.data["data"]);
      return WorkPackageList.fromJson(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  // tasks/taskInstructPackage/getPersonalPackageList
  Future<dynamic> getPersonalPackageList(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getPersonalPackageList",
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
      {Map<String, dynamic>? queryParametrs}) async {
    var r = await AppApi.dio.post(
      "/plan/repairPlan/getRepairPlanByTrainNum",
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

  Future<void> startCertainPackageWork(
    Map<String, dynamic>? queryParametrs,
  ) async {
    try {
      var r = await AppApi.dio.post(
        "/tasks/taskCertainPackage/certainPackageStartWork",
        data: queryParametrs,
      );
      logger.i(r.data["data"]);
    } catch (e) {
      _handleException(e);
    }
  }

  // 查看故障视频及图片 /fileserver/jt28File/getByGroupId
  Future<dynamic> getFaultVideoAndImage(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/fileserver/jt28File/getByGroupId",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])['data']);
      return (r.data["data"])['data'];
    } catch (e) {
      _handleException(e);
      return [];
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

  // /dispatch/trainEntry/getJT9 post
  Future<dynamic> getJT9({Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.post(
        "/dispatch/trainEntry/getJT9",
        data: queryParametrs,
      );
      logger.i({
        'api': '/dispatch/trainEntry/getJT9',
        'method': r.requestOptions.method,
        'url': r.requestOptions.uri.toString(),
        'request': queryParametrs,
        'statusCode': r.statusCode,
        'response': r.data,
      });
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      if (outer is Map && outer.containsKey("data")) {
        return outer["data"];
      }
      return outer;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 机统28查询 tasks/locomotiveMaintenanceLogDO/selectAll
  Future<dynamic> getJt28SelectAll({
    Map<String, dynamic>? queryParametrs,
  }) async {
    try {
      logger.i('[修程通知单JT28] 请求开始 query=$queryParametrs');
      _logLargeTagged('[修程通知单JT28][QUERY]', queryParametrs ?? {});
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/selectAll",
        queryParameters: queryParametrs,
      );
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      final inner = outer is Map ? outer["data"] : null;
      final rows = inner is Map ? inner["rows"] : null;
      final rowsCount = rows is List
          ? rows.length
          : (inner is List ? inner.length : (outer is List ? outer.length : 0));
      logger.i(
        '[修程通知单JT28] 请求完成 status=${r.statusCode} rows=$rowsCount url=${r.requestOptions.uri}',
      );
      _logLargeTagged('[修程通知单JT28][RAW_RESPONSE]', r.data);
      logger.i({
        'api': '/tasks/locomotiveMaintenanceLogDO/selectAll',
        'method': r.requestOptions.method,
        'url': r.requestOptions.uri.toString(),
        'request': queryParametrs,
        'statusCode': r.statusCode,
        'response': r.data,
      });
      if (outer is Map && outer.containsKey("data")) {
        return outer["data"];
      }
      return outer;
    } catch (e) {
      logger.e('[修程通知单JT28] 请求失败 error=$e');
      _handleException(e);
      return null;
    }
  }

  Future<dynamic> getJtTypeSelectAll(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/jtType/selectAll",
        queryParameters: queryParametrs,
      );
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      if (outer is Map && outer.containsKey("data")) {
        final inner = outer["data"];
        if (inner is Map && inner.containsKey("rows")) {
          final rows = inner["rows"];
          if (rows is List) {
            return rows
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        return inner;
      }
      return outer;
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  Future<dynamic> uploadMasFile({required List<File> uploadFileList}) async {
    try {
      final files = <MultipartFile>[];
      for (final f in uploadFileList) {
        files.add(await MultipartFile.fromFile(f.path));
      }
      final formData = FormData.fromMap({
        'uploadFileList': files,
      });
      final r = await AppApi.dio.post(
        "/fileserver/masFile/uploadFile",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );
      return r.data;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  Future<dynamic> saveMasSaleInformationAll(
      {required List<dynamic> data}) async {
    try {
      final r = await AppApi.dio.post(
        "/dispatch/masSaleInformation/saveAll",
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      return r.data;
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> uploadViolationFiles({
    required List<File> files,
  }) async {
    try {
      final multipartFiles = <MultipartFile>[];
      for (final f in files) {
        multipartFiles.add(await MultipartFile.fromFile(f.path));
      }
      final formData = FormData.fromMap({
        'file': multipartFiles,
      });
      final r = await AppApi.dio.post(
        "/file/upload",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final body = r.data;
      final data = body is Map ? body['data'] : null;
      final list = <Map<String, dynamic>>[];
      if (data is List) {
        for (final e in data) {
          if (e is Map) list.add(Map<String, dynamic>.from(e));
        }
      } else if (data is Map) {
        list.add(Map<String, dynamic>.from(data));
      }
      return list;
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  String buildAttachmentString(List<Map<String, dynamic>> uploaded) {
    final list = <Map<String, dynamic>>[];
    for (final e in uploaded) {
      final name = (e['fileName'] ?? e['name'] ?? '').toString();
      final url = (e['url'] ?? '').toString();
      final fileId = (e['fileId'] ?? e['id'] ?? '').toString();
      list.add({'name': name, 'url': url, 'fileId': fileId});
    }
    return jsonEncode(list);
  }

  Future<List<Map<String, dynamic>>> getAssemblyPendingDepartureTrainList({
    Map<String, dynamic>? queryParameters,
  }) async {
    return getReadyToLeaveTrainList(queryParameters: queryParameters);
  }

  Future<List<Map<String, dynamic>>> getReadyToLeaveTrainList({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      logger.i({
        'api': '/dispatch/trainEntry/getReadyToLeaveTrainList',
        'query': queryParameters ?? {},
      });
      final r = await AppApi.dio.get(
        "/dispatch/trainEntry/getReadyToLeaveTrainList",
        queryParameters: queryParameters,
      );
      final body = r.data;
      logger.i({
        'api': '/dispatch/trainEntry/getReadyToLeaveTrainList',
        'response': body,
      });
      dynamic rows;
      if (body is Map) {
        final data = body["data"];
        final inner = data is Map ? data["data"] : null;
        if (inner is Map && inner["rows"] is List) {
          rows = inner["rows"];
        } else if (inner is List) {
          rows = inner;
        } else if (data is Map && data["rows"] is List) {
          rows = data["rows"];
        } else if (data is List) {
          rows = data;
        }
      } else if (body is List) {
        rows = body;
      }
      final list = rows is List ? rows : const <dynamic>[];
      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final seen = <String>{};
      final filtered = <Map<String, dynamic>>[];
      for (final m in mapped) {
        final trainEntryCode =
            (m['trainEntryCode'] ?? m['code'] ?? m['id'] ?? '')
                .toString()
                .trim();
        if (trainEntryCode.isEmpty || trainEntryCode == 'null') continue;

        final trainNum =
            (m['trainNum'] ?? m['trainNo'] ?? m['trainNumber'] ?? '')
                .toString()
                .trim();
        if (trainNum.isEmpty || trainNum == 'null') continue;

        final ends = (m['ends'] ?? '').toString().trim();
        final bindingKey = '$trainNum|$ends';
        if (seen.contains(bindingKey)) continue;

        final leaveTime = (m['leavePlatformTime'] ??
                m['leaveDeptTime'] ??
                m['leaveTime'] ??
                '')
            .toString()
            .trim();
        if (leaveTime.isNotEmpty && leaveTime != 'null') continue;

        seen.add(bindingKey);
        filtered.add(m);
      }
      logger.i({
        'api': '/dispatch/trainEntry/getReadyToLeaveTrainList',
        'rawCount': mapped.length,
        'filteredCount': filtered.length,
      });
      return filtered;
    } catch (e) {
      _handleException(e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveTrainDepartureConfirm({
    required Map<String, dynamic> data,
  }) async {
    final trainEntryCode =
        (data['trainEntryCode'] ?? data['code'] ?? '').toString().trim();
    final repairEndTime = (data['repairEndTime'] ?? '').toString().trim();
    return simulateCompleteTrainEntry(
      trainEntryCode: trainEntryCode,
      repairEndTime: repairEndTime,
    );
  }

  Future<Map<String, dynamic>?> simulateCompleteTrainEntry({
    required String trainEntryCode,
    required String repairEndTime,
  }) async {
    try {
      logger.i({
        'api': '/dispatch/trainEntry/simulateCompleteTrainEntry',
        'trainEntryCode': trainEntryCode,
        'repairEndTime': repairEndTime,
      });
      final r = await AppApi.dio2.get(
        '/dispatch/trainEntry/simulateCompleteTrainEntry',
        queryParameters: {
          'trainEntryCode': trainEntryCode,
          'repairEndTime': repairEndTime,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final body = r.data;
      logger.i({
        'api': '/dispatch/trainEntry/simulateCompleteTrainEntry',
        'response': body,
      });
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
      return {"data": body};
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadTrainLeavePlatformFile({
    required String trainEntryCode,
    required List<File> uploadFileList,
  }) async {
    try {
      logger.i({
        'api': '/fileserver/trainLeavePlatformFile/uploadFile',
        'trainEntryCode': trainEntryCode,
        'fileCount': uploadFileList.length,
      });
      final files = <MultipartFile>[];
      for (final f in uploadFileList) {
        files.add(await MultipartFile.fromFile(f.path));
      }
      final formData = FormData.fromMap({
        'uploadFileList': files,
      });
      final r = await AppApi.dio.post(
        '/fileserver/trainLeavePlatformFile/uploadFile',
        queryParameters: {
          'trainEntryCode': trainEntryCode,
        },
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final body = r.data;
      logger.i({
        'api': '/fileserver/trainLeavePlatformFile/uploadFile',
        'response': body,
      });
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
      return {'data': body};
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

  //获取配属段信息
  Future<dynamic> getAssociatedSegment(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      Map<String, dynamic> queryParametrs = {'pageNum': 0, 'pageSize': 0};
      var r = await AppApi.dio.get(
        "/dispatch/jcAssignSegment/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  // 查询检修调令 /dispatch/trainRepairDynamics/selectAll 检修详情查询内容
  Future<dynamic> getTrainRepairDynamics(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainRepairDynamics/selectAll",
        queryParameters: queryParametrs,
      );
      logger.i(((r.data["data"])["data"])["rows"]);
      return ((r.data["data"])["data"])["rows"];
    } catch (e) {
      _handleException(e);
      return null;
    }
  }

  //保存机车入段信息
  Future<Map<String, dynamic>> trainEntrySave(
      Map<String, dynamic> queryParameters) async {
    try {
      var r = await AppApi.dio2.post(
        "/dispatch/trainEntry/save",
        data: queryParameters,
      );
      final body = r.data;
      if (body is Map) {
        final inner = body["data"];
        if (inner is Map && inner["code"] != null) {
          final data = Map<String, dynamic>.from(inner);
          logger.i(data);
          return data;
        }
        if (body["code"] != null || body["message"] != null) {
          final data = Map<String, dynamic>.from(body);
          logger.i(data);
          return data;
        }
        logger.i(body);
      } else {
        logger.i(body);
      }
      return {};
    } catch (e) {
      _handleException(e);
      return {};
    }
  }

  Future<dynamic> getDeptByParentIdList(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      logger.i(queryParametrs);
      var r = await AppApi.dio.get(
        "/jcjxsystem/dept/getDeptByParentIdList",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      return null;
    }
  }

  Future<dynamic> getDeptTreeByParentIdList(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/jcjxsystem/dept/getDeptTreeByParentIdList",
        queryParameters: queryParametrs,
      );
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      final inner = outer is Map ? outer["data"] : null;
      logger.i(inner ?? outer);
      return inner ?? outer;
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      _handleException(e, stackTrace);
      return null;
    }
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
    try {
      var r = await AppApi.dio.get(
        "/subparts/jcDynamicType/selectAll",
        queryParameters: queryParametrs,
      );
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final outer = data["data"];
      if (outer is Map) {
        final rows = outer["rows"];
        if (rows != null) {
          logger.i(rows);
          return rows;
        }
        final inner = outer["data"];
        logger.i(inner);
        return inner;
      }
      logger.i(outer);
      return outer;
    } catch (e, stackTrace) {
      logger.e(e.toString(), e, stackTrace);
      _handleException(e, stackTrace);
      return null;
    }
  }

  // 获取dispatch/trainEntry/getRepairingTrainEntryByUserId
  Future<dynamic> getRepairingTrainEntryByUserId(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/getRepairingTrainEntryByUserId",
        queryParameters: queryParametrs,
      );
      // logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
  }

  // 获取dispatch/trainEntry/getRepairingTrainEntryByUserId
  Future<dynamic> getRepairingTrainEntryByUserIdAndRepairProcCode(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/getRepairingTrainEntryByUserIdAndRepairProcCode",
        queryParameters: queryParametrs,
      );
      // logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
  }

  // 获取dispatch/trainEntry/getRepairingAllTrainEntryByRepairProcCode
  Future<List> getRepairingAllTrainEntryByRepairProcCode(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      logger.i('[机车派工接口][QUERY] ${(queryParametrs ?? {}).toString()}');
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/getRepairingAllTrainEntryByRepairProcCode",
        queryParameters: queryParametrs,
      );
      dynamic raw = r.data;
      try {
        raw = (r.data["data"])["data"];
      } catch (_) {}
      if (kDebugMode) {
        _logLargeTagged('[机车派工接口][RAW_RESPONSE]', raw);
      }
      if (raw is List) {
        logger.i('[机车派工接口][RES] len=${raw.length}');
        if (raw.isNotEmpty) {
          logger.i('[机车派工接口][RAW_FIRST_ITEM] ${jsonEncode(raw.first)}');
        }
        return raw;
      }
      logger.i('[机车派工接口][RES] type=${raw.runtimeType}');
      return [];
      // logger.i((r.data["data"])["data"]);
    } catch (e) {
      logger.e(e);
      return [];
    }
  }

  // 获取tasks/taskInstructPackage/getPackageAndInspectionStatistics
  Future<dynamic> getPackageAndInspectionStatistics(
      {Map<String, dynamic>? queryParametrs}) async {
    final user = Global.profile.permissions?.user;
    final name = (user?.nickName ?? user?.userName ?? '').toString().trim();
    if (name == '田凯') {
      return getAllPackageAndInspectionStatistics(
        queryParametrs: queryParametrs,
      );
    }
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getPackageAndInspectionStatistics",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> getAllPackageAndInspectionStatistics(
      {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/tasks/taskInstructPackage/getAllPackageAndInspectionStatistics",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
  }

  // 获取tasks/locomotiveMaintenanceLogDO/getTaskDistributionStatus
  Future<dynamic> getTaskDistributionStatus(
      {Map<String, dynamic>? queryParametrs}) async {
    final user = Global.profile.permissions?.user;
    final name = (user?.nickName ?? user?.userName ?? '').toString().trim();
    if (name == '田凯') {
      return getAllPackageAndInspectionStatistics(
        queryParametrs: queryParametrs,
      );
    }
    try {
      var r = await AppApi.dio.get(
        "/tasks/locomotiveMaintenanceLogDO/getTaskDistributionStatus",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
  }

  // 获取dispatch/trainEntry/getRepairingTrainEntryByUserIdAndRepairProcCode
  Future<dynamic>
      getRepairingTrainEntryByUserIdAndRepairProcCodeAndRepairSegment(
          {Map<String, dynamic>? queryParametrs}) async {
    try {
      var r = await AppApi.dio.get(
        "/dispatch/trainEntry/getRepairingTrainEntryByUserIdAndRepairProcCodeAndRepairSegment",
        queryParameters: queryParametrs,
      );
      logger.i((r.data["data"])["data"]);
      return (r.data["data"])["data"];
    } catch (e) {
      return [];
    }
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
    } catch (e) {
      logger.e(e);
      return null;
    }
  }
}
