package com.jcjx.apkdistribution.controller;

import com.jcjx.apkdistribution.dto.ApiResponse;
import com.jcjx.apkdistribution.dto.ApkVersionDTO;
import com.jcjx.apkdistribution.entity.ApkVersion;
import com.jcjx.apkdistribution.service.ApkVersionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

/**
 * APK分发控制器
 */
@RestController
@RequestMapping("/api/apk")
@RequiredArgsConstructor
@Slf4j
public class ApkController {
    
    private final ApkVersionService apkVersionService;
    
    /**
     * 上传APK文件
     * POST /api/apk/upload
     */
    @PostMapping("/upload")
    public ApiResponse<ApkVersionDTO> uploadApk(
            @RequestParam("file") MultipartFile file,
            @RequestParam("version") String version,
            @RequestParam("buildNumber") Integer buildNumber,
            @RequestParam("env") String env,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "isForceUpdate", required = false) Boolean isForceUpdate) {
        
        try {
            // 验证文件
            if (file.isEmpty()) {
                return ApiResponse.error(400, "文件不能为空");
            }
            
            if (!file.getOriginalFilename().endsWith(".apk")) {
                return ApiResponse.error(400, "文件必须是APK格式");
            }
            
            // 上传并保存
            ApkVersion apkVersion = apkVersionService.uploadApk(
                file, version, buildNumber, env, description, isForceUpdate
            );
            
            // 转换为DTO
            ApkVersionDTO dto = new ApkVersionDTO();
            dto.setName(apkVersion.getFileName());
            dto.setVersion(apkVersion.getVersion());
            dto.setUrl(apkVersion.getDownloadUrl());
            dto.setDec(apkVersion.getDescription());
            dto.setId(apkVersion.getId().toString());
            dto.setCreateTime(apkVersion.getCreateTime().toString());
            dto.setBuildNumber(apkVersion.getBuildNumber());
            dto.setIsForceUpdate(apkVersion.getIsForceUpdate());
            dto.setFileSize(apkVersion.getFileSize());
            dto.setMd5(apkVersion.getMd5());
            dto.setUpdateType("full");
            
            log.info("APK上传成功: {} (版本: {}, 构建号: {}, 环境: {})", 
                apkVersion.getFileName(), version, buildNumber, env);
            
            return ApiResponse.success("APK上传成功", dto);
            
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (IOException e) {
            log.error("APK上传失败", e);
            return ApiResponse.error(500, "文件保存失败: " + e.getMessage());
        } catch (Exception e) {
            log.error("APK上传失败", e);
            return ApiResponse.error(500, "上传失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取最新版本信息
     * GET /api/apk/version/last
     */
    @GetMapping("/version/last")
    public ApiResponse<ApkVersionDTO> getLatestVersion(
            @RequestParam(value = "id", required = false) String appId,
            @RequestParam(value = "env", required = false, defaultValue = "release") String env) {
        
        Optional<ApkVersionDTO> version = apkVersionService.getLatestVersion(env, appId);
        
        if (version.isEmpty()) {
            return ApiResponse.error(404, "未找到版本信息");
        }
        
        return ApiResponse.success(version.get());
    }
    
    /**
     * 下载APK文件
     * GET /api/apk/download/{env}/{fileName}
     */
    @GetMapping("/download/{env}/{fileName:.+}")
    public ResponseEntity<Resource> downloadApk(
            @PathVariable String env,
            @PathVariable String fileName) {
        
        try {
            Path filePath = apkVersionService.getApkFilePath(env, fileName);
            
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }
            
            Resource resource = new FileSystemResource(filePath);
            String contentType = Files.probeContentType(filePath);
            if (contentType == null) {
                contentType = "application/vnd.android.package-archive";
            }
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, 
                        "attachment; filename=\"" + fileName + "\"")
                    .body(resource);
                    
        } catch (Exception e) {
            log.error("下载APK失败", e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    /**
     * 删除APK版本
     * DELETE /api/apk/{id}
     */
    @DeleteMapping("/{id}")
    public ApiResponse<String> deleteApk(@PathVariable Long id) {
        try {
            boolean deleted = apkVersionService.deleteApkVersion(id);
            
            if (!deleted) {
                return ApiResponse.error(404, "未找到指定的APK版本");
            }
            
            log.info("APK删除成功: ID={}", id);
            return ApiResponse.success("APK删除成功");
            
        } catch (IOException e) {
            log.error("删除APK文件失败", e);
            return ApiResponse.error(500, "删除文件失败: " + e.getMessage());
        } catch (Exception e) {
            log.error("删除APK失败", e);
            return ApiResponse.error(500, "删除失败: " + e.getMessage());
        }
    }
    
    /**
     * 健康检查
     * GET /api/apk/health
     */
    @GetMapping("/health")
    public ApiResponse<String> health() {
        return ApiResponse.success("服务运行正常");
    }
}
