package com.jcjx.apkdistribution.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * APK版本信息DTO（用于API响应）
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApkVersionDTO {
    private String name;
    private String version;
    private String url;
    private String dec;
    private String id;
    private String createTime;
    
    // 扩展字段
    private Integer buildNumber;
    private Boolean isForceUpdate;
    private Long fileSize;
    private String md5;
    private String updateType; // full(全量) / incremental(增量)
}
