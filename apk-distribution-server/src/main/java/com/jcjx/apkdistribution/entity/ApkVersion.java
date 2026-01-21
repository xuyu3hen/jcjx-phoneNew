package com.jcjx.apkdistribution.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * APK版本信息实体
 */
@Entity
@Table(name = "apk_versions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApkVersion {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    /**
     * APK文件名
     */
    @Column(nullable = false)
    private String fileName;
    
    /**
     * 版本名称 (如: 1.0.0)
     */
    @Column(nullable = false)
    private String version;
    
    /**
     * 构建号 (如: 1)
     */
    @Column(nullable = false)
    private Integer buildNumber;
    
    /**
     * 环境 (dev, test, release)
     */
    @Column(nullable = false)
    private String env;
    
    /**
     * 文件大小 (字节)
     */
    private Long fileSize;
    
    /**
     * MD5 值
     */
    private String md5;
    
    /**
     * 下载URL
     */
    @Column(nullable = false)
    private String downloadUrl;
    
    /**
     * 更新描述
     */
    @Column(columnDefinition = "TEXT")
    private String description;
    
    /**
     * 是否强制更新x
     */
    @Column(nullable = false)
    private Boolean isForceUpdate = false;
    
    /**
     * 创建时间
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createTime;
    
    /**
     * 更新时间
     */
    private LocalDateTime updateTime;
    
    @PrePersist
    protected void onCreate() {
        createTime = LocalDateTime.now();
        updateTime = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updateTime = LocalDateTime.now();
    }
}
