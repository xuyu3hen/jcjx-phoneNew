# 自动化发布流程文档

本文档描述了机车检修 App 的自动化发布流程。

## 📋 目录

- [版本号规范](#版本号规范)
- [发布流程](#发布流程)
- [CI/CD 配置](#cicd-配置)
- [手动构建](#手动构建)
- [常见问题](#常见问题)

## 📌 版本号规范

项目使用语义化版本号（Semantic Versioning）格式：`主版本号.次版本号.修订版本号+构建号`

- **主版本号（Major）**: 不兼容的 API 修改
- **次版本号（Minor）**: 向下兼容的功能新增
- **修订版本号（Patch）**: 向下兼容的问题修正
- **构建号（Build）**: 每次构建递增

示例：`1.1.8+18` 表示版本 1.1.8，构建号 18

## 🚀 发布流程

### 自动化发布（推荐）

使用自动化脚本进行发布：

#### Windows
```bash
# 递增修订版本号（默认）
scripts\release.bat

# 递增次版本号
scripts\release.bat minor

# 递增主版本号
scripts\release.bat major
```

#### Linux/macOS
```bash
# 赋予执行权限（首次）
chmod +x scripts/release.sh

# 递增修订版本号（默认）
./scripts/release.sh

# 递增次版本号
./scripts/release.sh minor

# 递增主版本号
./scripts/release.sh major
```

**自动化发布流程包括：**
1. ✅ 检查 Git 工作区是否干净
2. ✅ 运行测试（如果有）
3. ✅ 自动递增版本号
4. ✅ 提交版本号变更
5. ✅ 创建 Git 标签
6. ✅ 推送代码和标签（可选）
7. ✅ 触发 CI/CD 自动构建

### 手动发布

如果需要手动控制发布流程：

#### 1. 更新版本号

```bash
# 使用脚本自动递增
dart scripts/bump_version.dart [patch|minor|major|build]

# 或手动编辑 pubspec.yaml
version: 1.1.8+18
```

#### 2. 提交版本号变更

```bash
git add pubspec.yaml
git commit -m "chore: 更新版本号到 1.1.8+18"
```

#### 3. 创建 Git 标签

```bash
git tag -a v1.1.8 -m "发布版本 1.1.8"
```

#### 4. 推送代码和标签

```bash
git push
git push --tags
```

#### 5. CI/CD 自动构建

推送标签后，CI/CD 系统会自动：
- 构建 APK/AAB/IPA
- 上传构建产物
- 创建 Release（如果配置）

## 🔧 CI/CD 配置

### GitHub Actions

项目已配置 GitHub Actions，位于 `.github/workflows/build-and-release.yml`

**触发方式：**
- 推送版本标签（如 `v1.1.8`）
- 手动触发（GitHub Actions 界面）

**构建产物：**
- 自动上传到 GitHub Actions Artifacts
- 如果推送了标签，会自动创建 GitHub Release

**详细使用指南：** 请查看 [GitHub Actions 使用指南](GITHUB_ACTIONS_GUIDE.md)

### GitLab CI

项目已配置 GitLab CI，配置文件为 `.gitlab-ci.yml`

**触发方式：**
- 推送到特定分支（develop, test, main）
- 推送标签

**构建产物：**
- 自动上传到 GitLab Artifacts
- 可手动创建 GitLab Release

## 🛠️ 手动构建

### 使用构建脚本

#### Windows
```bash
# 构建 release 环境的 APK
scripts\build.bat release android apk

# 构建 release 环境的 App Bundle
scripts\build.bat release android appbundle

# 构建 test 环境的 APK
scripts\build.bat test android apk
```

#### Linux/macOS
```bash
# 赋予执行权限（首次）
chmod +x scripts/build.sh

# 构建 release 环境的 APK
./scripts/build.sh release android apk

# 构建 release 环境的 App Bundle
./scripts/build.sh release android appbundle
```

### 直接使用 Flutter 命令

```bash
# 开发环境
flutter build apk --flavor env_dev -t lib/main_env_dev.dart --target-platform android-arm,android-arm64 --no-tree-shake-icons

# 测试环境
flutter build apk --flavor env_test -t lib/main_env_test.dart --target-platform android-arm,android-arm64 --no-tree-shake-icons

# 生产环境
flutter build apk --flavor env_release -t lib/main_env_release.dart --target-platform android-arm,android-arm64 --no-tree-shake-icons

# 生产环境 App Bundle
flutter build appbundle --flavor env_release -t lib/main_env_release.dart --no-tree-shake-icons
```

## 📦 构建产物位置

- **APK**: `build/app/outputs/flutter-apk/app-{flavor}-release.apk`
- **App Bundle**: `build/app/outputs/bundle/{flavor}Release/app-{flavor}-release.aab`
- **iOS IPA**: `build/ios/ipa/*.ipa`

## 🔍 环境说明

项目支持三个构建环境：

| 环境 | Flavor | 主文件 | 应用ID | 说明 |
|------|--------|--------|--------|------|
| 开发 | env_dev | main_env_dev.dart | com.jcjx_phone_dev | 本地开发环境 |
| 测试 | env_test | main_env_test.dart | com.jcjx_phone_test | 测试环境 |
| 生产 | env_release | main_env_release.dart | com.jcjx_phone_release | 生产环境 |

## ❓ 常见问题

### Q: 如何只递增构建号而不改变版本号？

```bash
dart scripts/bump_version.dart build
```

### Q: CI/CD 构建失败怎么办？

1. 检查 GitHub Actions / GitLab CI 日志
2. 确认 Flutter 版本是否正确
3. 检查依赖是否完整
4. 确认构建命令是否正确

### Q: 如何回退版本？

```bash
# 1. 修改 pubspec.yaml 中的版本号
# 2. 删除错误的标签
git tag -d v1.1.9
git push origin :refs/tags/v1.1.9
# 3. 重新创建正确的标签
git tag -a v1.1.8 -m "发布版本 1.1.8"
git push --tags
```

### Q: 如何查看当前版本？

```bash
# 查看 pubspec.yaml
grep "^version:" pubspec.yaml

# 或在代码中
# VersionManager.version
```

### Q: 构建产物在哪里下载？

- **GitHub**: Releases 页面或 Actions Artifacts
- **GitLab**: CI/CD → Pipelines → 选择构建 → Artifacts
- **本地**: `build/app/outputs/` 目录

## 📝 发布检查清单

发布前请确认：

- [ ] 代码已通过所有测试
- [ ] 版本号已正确更新
- [ ] CHANGELOG.md 已更新（如果有）
- [ ] 代码已提交到 Git
- [ ] Git 标签已创建
- [ ] 已推送到远程仓库
- [ ] CI/CD 构建成功
- [ ] 构建产物已下载并测试
- [ ] Release 已创建（如果使用）

## 🔗 相关资源

- [GitHub Actions 使用指南](GITHUB_ACTIONS_GUIDE.md) - **详细的使用说明**
- [快速开始指南](QUICK_START.md) - 快速上手
- [Flutter 构建文档](https://docs.flutter.dev/deployment/android)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [GitLab CI 文档](https://docs.gitlab.com/ee/ci/)
