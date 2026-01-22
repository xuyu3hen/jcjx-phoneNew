# 线上环境打包指南（带版本号）

本文档说明如何为线上环境（release）打包APK，并自动带上版本号。

## 📋 快速开始

### Windows 系统

#### 方式一：仅打包（不自动上传）

```bash
# 打包线上环境，自动递增修订版本号（patch）
scripts\auto_build.bat release patch

# 打包线上环境，递增次版本号（minor）
scripts\auto_build.bat release minor

# 打包线上环境，递增主版本号（major）
scripts\auto_build.bat release major

# 只递增构建号，不改变版本号
scripts\auto_build.bat release build
```

#### 方式二：打包并自动上传到服务器

```bash
# 打包并上传到默认服务器
scripts\auto_build_and_upload.bat release patch

# 打包并上传到指定服务器
scripts\auto_build_and_upload.bat release patch https://10.102.12.211:8443
```

### Linux/macOS 系统

```bash
# 赋予执行权限（首次）
chmod +x scripts/auto_build.sh
chmod +x scripts/auto_build_and_upload.sh

# 仅打包
./scripts/auto_build.sh release patch

# 打包并上传
./scripts/auto_build_and_upload.sh release patch https://10.102.12.211:8443
```

## 🔄 打包流程说明

打包脚本会自动执行以下步骤：

1. **更新版本号**
   - 从 `pubspec.yaml` 读取当前版本号
   - 根据版本类型（patch/minor/major/build）自动递增
   - 更新 `pubspec.yaml` 中的版本号

2. **清理并获取依赖**
   - 执行 `flutter clean`
   - 执行 `flutter pub get`

3. **构建 APK**
   - 使用 `env_release` flavor 构建
   - 目标平台：android-arm, android-arm64
   - 构建类型：release

4. **重命名 APK 文件**
   - 原始文件：`app-env_release-release.apk`
   - 重命名为：`jcjx-phone-{版本号}-build{构建号}-release.apk`
   - 例如：`jcjx-phone-1.0.20-build21-release.apk`

5. **上传到服务器**（如果使用 `auto_build_and_upload`）
   - 自动上传到内网分发服务器
   - 包含版本号、构建号、环境等信息

## 📦 版本号格式

版本号格式：`主版本号.次版本号.修订版本号+构建号`

- **主版本号（Major）**: 不兼容的 API 修改，例如：1.0.0 → 2.0.0
- **次版本号（Minor）**: 向下兼容的功能新增，例如：1.0.0 → 1.1.0
- **修订版本号（Patch）**: 向下兼容的问题修正，例如：1.0.0 → 1.0.1
- **构建号（Build）**: 每次构建自动递增

示例：
- 当前版本：`1.0.20+21`
- 执行 `patch`：`1.0.21+22`
- 执行 `minor`：`1.1.0+22`
- 执行 `major`：`2.0.0+22`
- 执行 `build`：`1.0.20+22`

## 📁 输出文件位置

打包完成后，APK 文件位于：

```
build/app/outputs/flutter-apk/jcjx-phone-{版本号}-build{构建号}-release.apk
```

例如：
```
build/app/outputs/flutter-apk/jcjx-phone-1.0.20-build21-release.apk
```

## 🔍 验证版本号

打包完成后，可以通过以下方式验证版本号：

1. **查看文件名**
   - APK 文件名包含版本号和构建号

2. **查看 pubspec.yaml**
   ```yaml
   version: 1.0.20+21
   ```

3. **查看构建日志**
   - 脚本会输出更新后的版本号信息

## ⚙️ 环境参数说明

| 参数 | 说明 | 可选值 |
|------|------|--------|
| `env` | 构建环境 | `dev`, `test`, `release` |
| `version_type` | 版本类型 | `patch`, `minor`, `major`, `build` |

## 📝 使用示例

### 示例 1：发布小版本更新（bug修复）

```bash
# 自动递增修订版本号并打包
scripts\auto_build_and_upload.bat release patch
```

### 示例 2：发布新功能版本

```bash
# 递增次版本号并打包
scripts\auto_build_and_upload.bat release minor
```

### 示例 3：发布重大版本更新

```bash
# 递增主版本号并打包
scripts\auto_build_and_upload.bat release major
```

### 示例 4：仅重新构建（不改变版本号）

```bash
# 只递增构建号
scripts\auto_build.bat release build
```

## 🔧 手动指定版本号

如果需要手动指定版本号，可以：

1. **直接编辑 pubspec.yaml**
   ```yaml
   version: 1.0.20+21
   ```

2. **然后执行打包**
   ```bash
   scripts\auto_build.bat release
   ```

注意：手动指定版本号时，脚本不会自动递增版本号。

## ⚠️ 注意事项

1. **版本号提交**
   - 打包脚本会自动更新 `pubspec.yaml` 中的版本号
   - 建议将版本号变更提交到 Git：
     ```bash
     git add pubspec.yaml
     git commit -m "chore: 构建版本 1.0.20+21 (release环境)"
     ```

2. **服务器上传**
   - 如果自动上传失败，可以手动上传：
     ```bash
     curl -k -X POST https://10.102.12.211:8443/api/apk/upload \
       -F "file=@build/app/outputs/flutter-apk/jcjx-phone-1.0.20-build21-release.apk" \
       -F "version=1.0.20" \
       -F "buildNumber=21" \
       -F "env=release" \
       -F "description=线上环境发布"
     ```

3. **构建前检查**
   - 确保 Git 工作区干净（建议）
   - 确保 Flutter 环境配置正确
   - 确保有足够的磁盘空间

## 🐛 常见问题

### Q1: 打包失败，提示找不到文件
**A:** 确保在项目根目录执行脚本，或使用完整路径。

### Q2: 版本号没有更新
**A:** 检查 `pubspec.yaml` 中的版本号格式是否正确：`version: 1.0.0+1`

### Q3: APK 文件名没有版本号
**A:** 检查脚本是否成功读取了版本号，查看构建日志。

### Q4: 上传失败
**A:** 
- 检查服务器地址是否正确
- 检查网络连接
- 检查服务器证书（使用 `-k` 参数忽略证书验证）

## 📚 相关文档

- [发布流程文档](./RELEASE_PROCESS.md)
- [内网APK分发系统使用指南](./INTRANET_APK_DISTRIBUTION.md)
- [快速开始指南](./QUICK_START.md)
