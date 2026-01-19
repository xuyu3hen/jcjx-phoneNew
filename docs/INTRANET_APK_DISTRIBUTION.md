# 内网 APK 自动分发系统使用指南

## 📋 概述

本系统实现了内网环境下的 APK 自动打包、版本管理和分发功能，支持 HTTPS 安全传输。

## 🏗️ 系统架构

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  本地开发环境    │         │  Java分发服务器   │         │   Flutter应用    │
│                 │         │                  │         │                 │
│ 1. 自动打包脚本  │ ────►   │  HTTPS API       │ ◄────── │  检查更新        │
│ 2. 版本号升级    │         │  - 上传APK       │         │  下载更新        │
│ 3. 上传APK      │         │  - 版本查询      │         │                 │
│                 │         │  - 文件下载      │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
```

## 🚀 快速开始

### 1. 部署 Java 分发服务器

#### 1.1 生成 HTTPS 证书

```bash
cd apk-distribution-server
keytool -genkeypair -alias apk-server -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore src/main/resources/keystore.p12 \
  -validity 365 -storepass changeit
```

**注意**: 
- 证书密码: `changeit`
- 生产环境请使用内网 CA 签发的正式证书

#### 1.2 配置服务器地址

编辑 `apk-distribution-server/src/main/resources/application.yml`:

```yaml
server:
  port: 8443
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: changeit

apk:
  storage:
    path: ./apk-files  # APK存储目录
```

#### 1.3 启动服务器

```bash
cd apk-distribution-server
mvn spring-boot:run
```

服务器将在 `https://10.102.12.211:8443` 启动（根据配置调整）。

### 2. 配置 Flutter 应用

#### 2.1 更新 API 地址

编辑 `lib/api/update.dart`，修改服务器地址：

```dart
static String get distributionServerUrl {
  switch (F.appFlavor) {
    case Flavor.env_dev:
      return 'https://10.102.12.211:8443';  // 修改为实际服务器地址
    // ...
  }
}
```

#### 2.2 重新生成模型代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. 使用自动打包脚本

#### Windows

```powershell
# 基本用法
scripts\auto_build_and_upload.bat release patch https://10.102.12.211:8443

# 参数说明:
# - release: 环境 (dev/test/release)
# - patch: 版本类型 (patch/minor/major/build)
# - https://...: 服务器地址
```

#### Linux/macOS

```bash
chmod +x scripts/auto_build_and_upload.sh
./scripts/auto_build_and_upload.sh release patch https://10.102.12.211:8443
```

## 📝 详细使用说明

### 自动打包流程

1. **版本号自动升级**
   - 脚本会自动调用 `bump_version.dart` 升级版本号
   - 支持 patch/minor/major/build 四种类型

2. **构建 APK**
   - 自动清理旧构建
   - 获取依赖
   - 构建指定环境的 APK

3. **上传到服务器**
   - 自动上传到 Java 分发服务器
   - 包含版本信息、构建号、环境等元数据

4. **Git 提交（可选）**
   - 可选择是否提交版本号变更到 Git

### API 接口说明

#### 1. 上传 APK

```bash
POST /api/apk/upload
Content-Type: multipart/form-data

参数:
- file: APK文件
- version: 版本号 (如: 1.0.0)
- buildNumber: 构建号 (如: 1)
- env: 环境 (dev/test/release)
- description: 更新描述 (可选)
- isForceUpdate: 是否强制更新 (可选)
```

**示例**:
```bash
curl -k -X POST https://10.102.12.211:8443/api/apk/upload \
  -F "file=@app-release.apk" \
  -F "version=1.0.0" \
  -F "buildNumber=1" \
  -F "env=release" \
  -F "description=修复bug" \
  -F "isForceUpdate=false"
```

#### 2. 获取最新版本

```bash
GET /api/apk/version/last?env=release&id=com.jcjx_phone_release
```

**响应格式**:
```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "name": "jcjx-phone-1.0.0-build1-release.apk",
    "version": "1.0.0",
    "url": "/api/apk/download/release/jcjx-phone-1.0.0-build1-release.apk",
    "dec": "修复bug",
    "id": "1",
    "createTime": "2024-01-01T12:00:00",
    "buildNumber": 1,
    "isForceUpdate": false,
    "fileSize": 52428800,
    "md5": "abc123...",
    "updateType": "full"
  }
}
```

#### 3. 下载 APK

```bash
GET /api/apk/download/{env}/{fileName}
```

### Flutter 应用更新流程

1. **应用启动时检查更新**
   - 在 `login.dart` 的 `getLastUpdate()` 方法中
   - 自动比较当前版本和服务器版本

2. **版本比较逻辑**
   - 支持语义化版本号比较 (如: 1.0.0 vs 1.0.1)
   - 同时比较构建号

3. **更新提示**
   - 使用 `flutter_xupdate` 显示更新对话框
   - 支持强制更新和可选更新

## 🔧 配置说明

### 服务器配置

#### 修改端口

编辑 `application.yml`:
```yaml
server:
  port: 8443  # 修改为所需端口
```

#### 修改存储路径

```yaml
apk:
  storage:
    path: /data/apk-files  # 修改为实际路径
```

#### 使用 MySQL（可选）

1. 添加 MySQL 依赖到 `pom.xml`
2. 修改 `application.yml`:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/apk_distribution
    username: root
    password: your_password
```

### Flutter 应用配置

#### 修改服务器地址

编辑 `lib/api/update.dart`:
```dart
static String get distributionServerUrl {
  return 'https://your-server-ip:8443';
}
```

#### 配置 HTTPS 证书信任

如果使用自签名证书，Flutter 应用已配置自动信任（仅开发环境）。

生产环境建议：
1. 使用内网 CA 签发的正式证书
2. 或将证书添加到应用的信任列表

## 🔒 安全建议

1. **使用正式证书**
   - 生产环境使用内网 CA 签发的证书
   - 避免使用自签名证书

2. **配置访问控制**
   - 可以添加 Spring Security 进行身份验证
   - 配置 IP 白名单

3. **定期备份**
   - 定期备份数据库
   - 备份 APK 文件

4. **监控日志**
   - 监控服务器日志
   - 检查异常上传和下载

## ❓ 常见问题

### Q: 上传 APK 失败？

**可能原因**:
1. 服务器未启动
2. 证书配置错误
3. 存储目录权限不足
4. 文件大小超过限制

**解决方法**:
- 检查服务器日志
- 确认 `apk.storage.path` 目录存在且有写入权限
- 检查 `spring.servlet.multipart.max-file-size` 配置

### Q: Flutter 应用无法连接服务器？

**可能原因**:
1. 服务器地址配置错误
2. 网络不通
3. 证书验证失败

**解决方法**:
- 检查 `UpdateApi.distributionServerUrl` 配置
- 测试网络连接: `ping 10.102.12.211`
- 检查证书配置

### Q: 版本比较不正确？

**解决方法**:
- 确保版本号格式正确 (如: 1.0.0)
- 检查构建号是否正确传递
- 查看应用日志确认版本信息

### Q: 如何回退版本？

1. 在服务器数据库中删除或标记旧版本
2. 或上传旧版本的 APK 文件

## 📚 相关文档

- [Java 服务器 README](../apk-distribution-server/README.md)
- [版本管理文档](RELEASE_PROCESS.md)
- [构建脚本说明](../scripts/README.md)

## 🎯 最佳实践

1. **版本号管理**
   - 使用语义化版本号 (Major.Minor.Patch)
   - 每次发布递增构建号

2. **环境隔离**
   - 不同环境使用不同的 `env` 参数
   - 确保测试环境不影响生产环境

3. **更新策略**
   - 重要更新使用强制更新
   - 普通更新允许用户选择

4. **监控和日志**
   - 定期检查服务器日志
   - 监控 APK 上传和下载情况

## 📞 技术支持

如有问题，请查看：
- 服务器日志: `apk-distribution-server/logs/`
- Flutter 应用日志: 使用 `AppLogger.logger`
- 数据库: 访问 `https://server:8443/h2-console` (H2 数据库)
