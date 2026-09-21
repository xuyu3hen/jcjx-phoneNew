import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../index.dart';

class AfterSaleLocalService {
  AfterSaleLocalService._();
  static final AfterSaleLocalService instance = AfterSaleLocalService._();
  factory AfterSaleLocalService() => instance;

  static const _kDraftKey = 'after_sale:draft:v1';
  static const _kPendingQueueKey = 'after_sale:pending_queue:v1';
  static const _kImagesDir = 'after_sale_images';
  static const _kDictPrefix = 'after_sale:dict:v1:';
  static const _kDictTtlMs = 24 * 60 * 60 * 1000;

  static final Random _rnd = Random.secure();
  static String _randomId([int len = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final sb = StringBuffer(now);
    for (int i = 0; i < len; i++) {
      sb.write(chars[_rnd.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  // ────────────────────────────────────────────
  // 1. 图片持久化
  // ────────────────────────────────────────────
  Future<String> _ensureImagesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/$_kImagesDir');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target.path;
  }

  /// 把 AssetEntity 写入 App 沙盒：
  /// 优先取缩略图（1920px / quality 85，平台侧已压缩好，数据量<原图 1/10，避免主线程 I/O 卡死）
  /// 缩略图失败时回退到原图 copy，单个 asset 失败返回 null 而非抛异常，保证批量时部分可用。
  Future<String?> copyAssetToSandbox(AssetEntity asset) async {
    final dir = await _ensureImagesDir();
    final ext = asset.title?.split('.').last ?? 'jpg';
    final dstPath = '$dir/${_randomId(12)}.$ext';

    // 1) 优先缩略图（主线程不会阻塞，wechat_assets_picker 平台端已做采样压缩）
    try {
      final thumb = await asset.thumbnailDataWithSize(
        const ThumbnailSize(1920, 1920),
        quality: 85,
      );
      if (thumb != null && thumb.isNotEmpty) {
        await File(dstPath).writeAsBytes(thumb, flush: false);
        return dstPath;
      }
    } catch (e) {
      AppLogger.logger.w('[离线售后] 缩略图写入失败，回退原图: $e');
    }

    // 2) 回退：原图文件 copy（视频或大图失败兜底）
    try {
      final File? file = await asset.file;
      if (file == null || !await file.exists()) return null;
      await file.copy(dstPath);
      return dstPath;
    } catch (e) {
      AppLogger.logger.e('[离线售后] 沙盒写入失败: $e');
      return null;
    }
  }

  /// 批量拷贝：并发 + 单张失败跳过，成功的路径按原顺序返回
  Future<List<String>> copyAssetsToSandbox(List<AssetEntity> assets) async {
    if (assets.isEmpty) return const [];
    final tasks = assets.map((a) => copyAssetToSandbox(a)).toList();
    final results = await Future.wait(tasks);
    return results.whereType<String>().toList(growable: false);
  }

  // ────────────────────────────────────────────
  // 2. 草稿持久化 (内存草稿结构: _AfterSaleTempRepairDraft)
  // 简化：存储为纯 JSON，图片存沙盒路径字符串
  // ────────────────────────────────────────────

  Future<void> saveDraft(Map<String, dynamic> draftJson) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDraftKey, jsonEncode(draftJson));
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearDraft() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kDraftKey);
  }

  // ────────────────────────────────────────────
  // 3. 待同步队列（未登录/离线时提交的单子）
  // 结构: { id, createdAt, basePayload, groups:[..., {imagePaths,summary,phenomenon}] }
  // ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadPendingQueue() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kPendingQueueKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<void> _writePendingQueue(List<Map<String, dynamic>> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPendingQueueKey, jsonEncode(list));
  }

  Future<String> enqueuePending({
    required Map<String, dynamic> basePayload,
    required List<Map<String, dynamic>> groups,
  }) async {
    final id = _randomId();
    final item = <String, dynamic>{
      'id': id,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending', // pending | synced | failed
      'failReason': null,
      'retryCount': 0,
      'basePayload': basePayload,
      'groups': groups, // [{faultSummary, faultInformation, imagePaths:[String,...]}]
    };
    final list = await loadPendingQueue();
    list.insert(0, item);
    await _writePendingQueue(list);
    return id;
  }

  Future<void> markFailed(String id, String reason, int retryCount) async {
    final list = await loadPendingQueue();
    for (final item in list) {
      if (item['id'] == id) {
        item['status'] = 'failed';
        item['failReason'] = reason;
        item['retryCount'] = retryCount;
        break;
      }
    }
    await _writePendingQueue(list);
  }

  Future<void> removePending(String id) async {
    final list = await loadPendingQueue();
    list.removeWhere((e) => e['id'] == id);
    await _writePendingQueue(list);
    // 【优化】移除此处的 cleanupOrphanImages()，避免 syncAllPending 循环中 N 次全量扫描磁盘；
    // 统一改为在 syncAllPending() 循环结束后执行一次即可。
    // await cleanupOrphanImages();
  }

  int pendingCountSync(List list) => list.where((e) => e['status'] != 'synced').length;

  /// 同步单项：上传每组图片 → 回填 fileCode → saveAll；失败直接 throw，由调用侧 catch
  Future<void> _syncOne(Map<String, dynamic> item) async {
    final groups = item['groups'] as List? ?? [];
    final basePayload =
        Map<String, dynamic>.from(item['basePayload'] as Map? ?? {});
    final payloadList = <Map<String, dynamic>>[];
    for (final g in groups) {
      final m = Map<String, dynamic>.from(g as Map? ?? {});
      final imagePaths = (m['imagePaths'] as List? ?? []).cast<String>();
      String fileCode = '';
      if (imagePaths.isNotEmpty) {
        final files = <File>[];
        for (final p in imagePaths) {
          final f = File(p);
          if (await f.exists()) files.add(f);
        }
        if (files.isNotEmpty) {
          final uploadResp = await ProductApi().uploadMasFile(
            uploadFileList: files,
          );
          dynamic v = uploadResp;
          if (v is Map && v.containsKey('data')) v = v['data'];
          if (v is Map && v.containsKey('data')) v = v['data'];
          fileCode = (v == null || v is List || v is Map)
              ? (v == null ? '' : jsonEncode(v))
              : v.toString();
        }
      }
      payloadList.add(<String, dynamic>{
        ...basePayload,
        'faultSummary': m['faultSummary'] ?? '',
        'faultInformation': m['faultInformation'] ?? '',
        'fileCode': fileCode,
      });
    }
    if (payloadList.isEmpty) return;
    final resp = await ProductApi().saveMasSaleInformationAll(
      data: payloadList,
    );
    final msg = _extractMsg(resp);
    final bad =
        msg.toLowerCase().contains('error') ||
        msg.toLowerCase().contains('exception') ||
        msg.toLowerCase().contains('parse') ||
        msg.toLowerCase().contains('失败') ||
        (resp is Map && (resp['code'] is int ? resp['code'] != 200 : false));
    if (bad) {
      throw Exception(msg.isEmpty ? '提交失败' : msg);
    }
  }

  String _extractMsg(dynamic resp) {
    final msgs = <String>[];
    dynamic v = resp;
    for (int i = 0; i < 6; i++) {
      if (v is Map) {
        final m =
            (v['msg'] ?? v['message'] ?? v['error'] ?? '')?.toString().trim();
        if (m != null && m.isNotEmpty) msgs.add(m);
        if (v.containsKey('data')) {
          v = v['data'];
          continue;
        }
      }
      break;
    }
    return msgs.isEmpty ? '' : msgs.last;
  }

  /// 登录后调用：把 pending / failed 都跑一次，成功删失败记失败
  Future<Map<String, int>> syncAllPending() async {
    final logger = AppLogger.logger;
    final list = await loadPendingQueue();
    final todo = list
        .where((e) =>
            e['status'] == 'pending' ||
            e['status'] == 'failed')
        .toList();
    int success = 0;
    int failed = 0;
    for (final item in todo) {
      final id = item['id'].toString();
      final retryCount = (item['retryCount'] as int? ?? 0) + 1;
      try {
        await _syncOne(item);
        await removePending(id);
        success++;
        logger.i('[离线售后登记] 同步成功 id=$id');
      } catch (e) {
        failed++;
        logger.e('[离线售后登记] 同步失败 id=$id: $e');
        await markFailed(id, e.toString(), retryCount);
      }
    }
    // 【优化】同步完成后统一清理一次孤儿图片（避免 N 次 removePending 内部 N 次全量扫盘）
    try {
      await cleanupOrphanImages();
    } catch (_) {}
    return <String, int>{'success': success, 'failed': failed};
  }

  /// 清理：同步成功后对应的沙盒图片（如队列中没其他项引用则删）
  Future<void> cleanupOrphanImages() async {
    try {
      final list = await loadPendingQueue();
      final keep = <String>{};
      for (final item in list) {
        final groups = item['groups'] as List? ?? [];
        for (final g in groups) {
          final m = g is Map ? g : <String, dynamic>{};
          final paths = (m['imagePaths'] as List? ?? []).cast<String>();
          keep.addAll(paths);
        }
      }
      final dir = Directory(await _ensureImagesDir());
      if (!await dir.exists()) return;
      final entities = await dir.list().toList();
      for (final e in entities) {
        if (e is File && !keep.contains(e.path)) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<int> pendingCount() async {
    final list = await loadPendingQueue();
    return pendingCountSync(list);
  }

  // ────────────────────────────────────────────
  // 4. 字典离线缓存（24h 过期，未登录/无网时使用）
  // ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> getDictCache(String key) async {
    if (key.isEmpty) return null;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('$_kDictPrefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final savedAt = decoded['savedAt'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - savedAt > _kDictTtlMs) {
        return null;
      }
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setDictCache(String key, List<Map<String, dynamic>> data) async {
    if (key.isEmpty || data.isEmpty) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await sp.setString('$_kDictPrefix$key', jsonEncode(payload));
    } catch (_) {}
  }
}
