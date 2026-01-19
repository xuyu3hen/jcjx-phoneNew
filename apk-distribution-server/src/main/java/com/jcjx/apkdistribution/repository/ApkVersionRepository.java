package com.jcjx.apkdistribution.repository;

import com.jcjx.apkdistribution.entity.ApkVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ApkVersionRepository extends JpaRepository<ApkVersion, Long> {
    
    /**
     * 根据环境查找最新版本
     */
    @Query("SELECT a FROM ApkVersion a WHERE a.env = :env ORDER BY a.buildNumber DESC, a.createTime DESC")
    Optional<ApkVersion> findLatestByEnv(@Param("env") String env);
    
    /**
     * 根据环境和应用ID查找最新版本
     */
    @Query("SELECT a FROM ApkVersion a WHERE a.env = :env ORDER BY a.buildNumber DESC, a.createTime DESC")
    Optional<ApkVersion> findLatestByEnvAndAppId(@Param("env") String env, @Param("appId") String appId);
    
    /**
     * 根据环境查找所有版本（按时间倒序）
     */
    List<ApkVersion> findByEnvOrderByCreateTimeDesc(String env);
    
    /**
     * 根据版本号和构建号查找
     */
    Optional<ApkVersion> findByVersionAndBuildNumberAndEnv(String version, Integer buildNumber, String env);
}
