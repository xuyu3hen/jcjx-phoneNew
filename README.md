# jcjx_phone

机车检修手持机客户端

## Description

本项目是一个专门**面向安卓手持机**定制开发的机车检修系统客户端。基于 Flutter 框架开发，主要用于满足机务段的日常移动作业需求。

## 🚀 快速开始

### 开发环境启动

项目支持三种环境：`env_dev`（开发）、`env_test`（测试）、`env_release`（生产）

以 `env_release` 为例：

```bash
# 代码启动
flutter run --flavor env_dev -t lib/main_env_dev.dart 

# 代码打包
flutter build apk --target-platform android-arm --flavor env_release -t lib/main_env_release.dart --no-tree-shake-icons
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

| 环境 | Flavor      | 主文件                | 应用ID                 |
| ---- | ----------- | --------------------- | ---------------------- |
| 开发 | env_dev     | main_env_dev.dart     | com.jcjx_phone_dev     |
| 测试 | env_test    | main_env_test.dart    | com.jcjx_phone_test    |
| 生产 | env_release | main_env_release.dart | com.jcjx_phone_release |

## 📅 最近更新日志

- **2026-04-15** feat(production): 支持调车计划查询与撤销并优化施修方案显示逻辑 (e436994)
- **2026-04-14** feat(调车): 支持批量提交调车计划并重构防溜资源UI (3d8760c)
- **2026-04-13** feat: 更新应用版本并优化调车计划接口及界面显示 (79be30e)
- **2026-04-13** feat: 添加APK文件大小与MD5显示并简化调车计划时间 (6435165)
- **2026-04-09** feat(售后临修登记): 重构故障组UI并支持附件分组上传 (3d494f6)
- **2026-04-09** feat: 新增售后临修登记功能并优化权限控制 (f42437f)
- **2026-04-03** feat: 新增入段细录功能并优化登录体验 (bfaac88)
- **2026-04-02** feat: 优化维修任务加载逻辑并添加入段细录权限控制 (1c123aa)
- **2026-04-01** test: 添加消息详情页调车通知测试用例 (5bf9233)
- **2026-04-01** fix: 增加调车终点位置验证并优化消息中心状态筛选 (d9b90cc)
- **2026-03-31** feat: 新增检修调令页面并扩展车号显示支持端部信息 (91f28d7)
- **2026-03-27** feat: 调整生产环境API路径并优化构建配置 (3ae9b04)
- **2026-03-25** feat: 新增调车计划查询功能并支持按日期筛选 (f6f3bd0)
- **2026-03-25** feat(调车): 新增连拍相机功能并优化防溜图片管理 (1a78645)
- **2026-03-25** fix: 修复消息中心已读逻辑和车号查询弹窗关闭条件 (572c9ab)
