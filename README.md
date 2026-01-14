# jcjx_phone

一个flutter客户端项目

## Description

一个机车检修手持机项目 项目说明：
1、项目使用flutter框架开发，跨平台，支持安卓、ios、web、macos、windows、linux等平台。用于实现机务段要求。

## 🚀 快速开始

### 开发环境启动

项目支持三种环境：`env_dev`（开发）、`env_test`（测试）、`env_release`（生产）

以 `env_dev` 为例：

```bash
# 代码启动
flutter run --flavor env_dev -t lib/main_env_dev.dart 

# 代码打包
flutter build apk --target-platform android-arm --flavor env_test -t lib/main_env_test.dart --no-tree-shake-icons
```

### 使用构建脚本（推荐）

#### Windows
```bash
# 构建 release 环境的 APK
scripts\build.bat release android apk

# 构建 release 环境的 App Bundle
scripts\build.bat release android appbundle
```

#### Linux/macOS
```bash
# 赋予执行权限（首次）
chmod +x scripts/build.sh

# 构建 release 环境的 APK
./scripts/build.sh release android apk
```

## 📦 自动化发布流程

项目已配置完整的自动化发布流程，包括：

- ✅ 版本号自动管理
- ✅ 自动化构建脚本
- ✅ CI/CD 配置（GitHub Actions / GitLab CI）
- ✅ 自动化发布脚本

### 快速发布

#### Windows
```bash
# 自动化发布（递增修订版本号）
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

# 自动化发布
./scripts/release.sh
```

### 版本号管理

```bash
# 递增修订版本号（默认）
dart scripts/bump_version.dart

# 递增次版本号
dart scripts/bump_version.dart minor

# 递增主版本号
dart scripts/bump_version.dart major

# 只递增构建号
dart scripts/bump_version.dart build
```

## 📚 详细文档

- [从 Gitee 迁移到 GitHub 指南](docs/MIGRATE_TO_GITHUB.md) - **迁移完整指南**
- [GitHub Actions 使用指南](docs/GITHUB_ACTIONS_GUIDE.md) - GitHub Actions 详细使用说明
- [GitHub Actions 快速参考](docs/GITHUB_ACTIONS_QUICK_REF.md) - 快速查阅
- [发布流程文档](docs/RELEASE_PROCESS.md) - 完整的发布流程说明
- [快速开始指南](docs/QUICK_START.md) - 快速上手
- [CI/CD 配置](.github/workflows/build-and-release.yml) - GitHub Actions 配置文件
- [GitLab CI 配置](.gitlab-ci.yml) - GitLab CI 配置文件

## 🔧 环境说明

| 环境 | Flavor | 主文件 | 应用ID |
|------|--------|--------|--------|
| 开发 | env_dev | main_env_dev.dart | com.jcjx_phone_dev |
| 测试 | env_test | main_env_test.dart | com.jcjx_phone_test |
| 生产 | env_release | main_env_release.dart | com.jcjx_phone_release |
