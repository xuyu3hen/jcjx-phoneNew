package com.jcjx.apkdistribution.service;

import com.jcjx.apkdistribution.dto.ApkVersionDTO;
import com.jcjx.apkdistribution.entity.ApkVersion;
import com.jcjx.apkdistribution.repository.ApkVersionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApkVersionService {
    
    private final ApkVersionRepository apkVersionRepository;
    
    @Value("${apk.storage.path:./apk-files}")
    private String storagePath;
    
    /**
     * 上传APK文件
     */
    @Transactional
    public ApkVersion uploadApk(MultipartFile file, String version, Integer buildNumber, 
                                 String env, String description, Boolean isForceUpdate) throws IOException {
        // 验证环境
        if (!isValidEnv(env)) {
            throw new IllegalArgumentException("无效的环境: " + env);
        }
        
        // 创建存储目录
        Path storageDir = Paths.get(storagePath, env);
        Files.createDirectories(storageDir);
        
        // 生成文件名
        String fileName = String.format("jcjx-phone-%s-build%d-%s.apk", version, buildNumber, env);
        Path filePath = storageDir.resolve(fileName);
        
        // 保存文件
        file.transferTo(filePath.toFile());
        
        // 计算文件大小和MD5
        long fileSize = Files.size(filePath);
        String md5 = calculateMD5(filePath);
        
        // 检查是否已存在相同版本
        Optional<ApkVersion> existing = apkVersionRepository
            .findByVersionAndBuildNumberAndEnv(version, buildNumber, env);
        
        ApkVersion apkVersion;
        if (existing.isPresent()) {
            // 更新现有记录
            apkVersion = existing.get();
            apkVersion.setFileName(fileName);
            apkVersion.setFileSize(fileSize);
            apkVersion.setMd5(md5);
            apkVersion.setDescription(description);
            apkVersion.setIsForceUpdate(isForceUpdate != null ? isForceUpdate : false);
        } else {
            // 创建新记录
            apkVersion = new ApkVersion();
            apkVersion.setFileName(fileName);
            apkVersion.setVersion(version);
            apkVersion.setBuildNumber(buildNumber);
            apkVersion.setEnv(env);
            apkVersion.setFileSize(fileSize);
            apkVersion.setMd5(md5);
            apkVersion.setDownloadUrl(generateDownloadUrl(env, fileName));
            apkVersion.setDescription(description);
            apkVersion.setIsForceUpdate(isForceUpdate != null ? isForceUpdate : false);
        }
        
        return apkVersionRepository.save(apkVersion);
    }
    
    /**
     * 获取最新版本
     */
    public Optional<ApkVersionDTO> getLatestVersion(String env, String appId) {
        Optional<ApkVersion> apkVersion = apkVersionRepository.findLatestByEnv(env);
        
        if (apkVersion.isEmpty()) {
            return Optional.empty();
        }
        
        ApkVersion version = apkVersion.get();
        ApkVersionDTO dto = convertToDTO(version);
        return Optional.of(dto);
    }
    
    /**
     * 转换为DTO
     */
    private ApkVersionDTO convertToDTO(ApkVersion version) {
        ApkVersionDTO dto = new ApkVersionDTO();
        dto.setName(version.getFileName());
        dto.setVersion(version.getVersion());
        dto.setUrl(version.getDownloadUrl());
        dto.setDec(version.getDescription());
        dto.setId(version.getId().toString());
        dto.setCreateTime(version.getCreateTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        dto.setBuildNumber(version.getBuildNumber());
        dto.setIsForceUpdate(version.getIsForceUpdate());
        dto.setFileSize(version.getFileSize());
        dto.setMd5(version.getMd5());
        dto.setUpdateType("full"); // 默认全量更新
        return dto;
    }
    
    /**
     * 生成下载URL
     */
    private String generateDownloadUrl(String env, String fileName) {
        return String.format("/api/apk/download/%s/%s", env, fileName);
    }
    
    /**
     * 验证环境
     */
    private boolean isValidEnv(String env) {
        return env != null && (env.equals("dev") || env.equals("test") || env.equals("release"));
    }
    
    /**
     * 计算MD5
     */
    private String calculateMD5(Path filePath) throws IOException {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] fileBytes = Files.readAllBytes(filePath);
            byte[] digest = md.digest(fileBytes);
            
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            log.error("计算MD5失败", e);
            return "";
        }
    }
    
    /**
     * 获取APK文件路径
     */
    public Path getApkFilePath(String env, String fileName) {
        return Paths.get(storagePath, env, fileName);
    }
}
