# APK 内网分发服务器

基于 Spring Boot 的内网 APK 分发服务器，支持 HTTPS 和自动版本管理。

## 功能特性

- ✅ APK 文件上传和管理
- ✅ 版本信息查询（支持按环境）
- ✅ APK 文件下载
- ✅ HTTPS 支持
- ✅ 自动计算文件 MD5
- ✅ 强制更新标记
- ✅ 多环境支持（dev/test/release）

## 快速开始

### 1. 生成 HTTPS 证书

```bash
# 生成自签名证书（用于内网）
keytool -genkeypair -alias apk-server -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore src/main/resources/keystore.p12 \
  -validity 365 -storepass changeit
```

**注意**: 生产环境请使用正式的 SSL 证书。

### 2. 配置数据库

默认使用 H2 内嵌数据库，数据文件存储在 `./data/apk-distribution.mv.db`。

如需使用 MySQL，修改 `application.yml`:

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/apk_distribution?useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: your_password
    driver-class-name: com.mysql.cj.jdbc.Driver
```

### 3. 运行服务器

```bash
# 使用 Maven
mvn spring-boot:run

# 或打包后运行
mvn clean package
java -jar target/apk-distribution-server-1.0.0.jar
```

服务器将在 `https://localhost:8443` 启动。

### 4. 配置 APK 存储路径

在 `application.yml` 中配置：

```yaml
apk:
  storage:
    path: ./apk-files  # APK文件存储目录
```

## API 接口

### 1. 上传 APK

```bash
POST /api/apk/upload
Content-Type: multipart/form-data

参数:
- file: APK文件
- version: 版本号 (如: 1.0.0)
- buildNumber: 构建号 (如: 1)
- env: 环境 (dev/test/release)
- description: 更新描述 (可选)
- isForceUpdate: 是否强制更新 (可选, 默认false)
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

### 2. 获取最新版本

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

### 3. 下载 APK

```bash
GET /api/apk/download/{env}/{fileName}
```

**示例**:
```bash
curl -k -O https://10.102.12.211:8443/api/apk/download/release/jcjx-phone-1.0.0-build1-release.apk
```

### 4. 健康检查

```bash
GET /api/apk/health
```

## 与 Flutter 应用集成

Flutter 应用需要修改更新 API 地址为 HTTPS：

```dart
// lib/api/update.dart
var r = await AppApi.dio.get(
  "https://10.102.12.211:8443/api/apk/version/last",
  queryParameters: {
    'id': F.id,
    'env': 'release', // 根据环境选择
  },
);
```

## 部署说明

### 内网部署

1. **配置防火墙**: 开放 8443 端口（HTTPS）
2. **配置证书**: 使用内网 CA 签发的证书，或配置客户端信任自签名证书
3. **配置存储**: 确保 `apk.storage.path` 目录有写入权限
4. **配置数据库**: 生产环境建议使用 MySQL/PostgreSQL

### 使用 systemd 管理（Linux）

创建服务文件 `/etc/systemd/system/apk-distribution.service`:

```ini
[Unit]
Description=APK Distribution Server
After=network.target

[Service]
Type=simple
User=apkuser
WorkingDirectory=/opt/apk-distribution
ExecStart=/usr/bin/java -jar /opt/apk-distribution/apk-distribution-server-1.0.0.jar
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务:
```bash
sudo systemctl enable apk-distribution
sudo systemctl start apk-distribution
```

## 安全建议

1. **使用正式证书**: 生产环境使用内网 CA 签发的证书
2. **配置认证**: 可以添加 Spring Security 进行身份验证
3. **限制上传**: 可以添加 IP 白名单或 API Key 验证
4. **定期备份**: 定期备份数据库和 APK 文件

## 故障排查

### 证书问题

如果客户端提示证书错误，需要：
1. 将服务器证书添加到客户端信任列表
2. 或在 Flutter 应用中配置信任自签名证书（仅开发环境）

### 文件上传失败

检查：
1. `apk.storage.path` 目录权限
2. 文件大小限制（`spring.servlet.multipart.max-file-size`）
3. 磁盘空间

### 数据库连接失败

检查：
1. 数据库配置是否正确
2. 数据库服务是否运行
3. 网络连接是否正常

## 许可证

MIT License
