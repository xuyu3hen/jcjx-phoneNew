# GitHub Actions 快速参考

## 🚀 快速开始

### 1. 启用 GitHub Actions
```
仓库 → Actions → Enable workflows
```

### 2. 触发构建

#### 方式一：推送标签（自动）
```bash
git tag -a v1.1.8 -m "发布版本 1.1.8"
git push --tags
```

#### 方式二：手动触发
```
Actions → 构建和发布 → Run workflow → 选择参数 → Run workflow
```

## 📍 关键位置

| 功能 | 位置 |
|------|------|
| 查看构建 | 仓库 → **Actions** 标签页 |
| 下载产物 | Actions → 选择构建 → **Artifacts** |
| 查看 Release | 仓库 → **Releases** |
| 配置文件 | `.github/workflows/build-and-release.yml` |

## 🎯 常用操作

### 查看构建状态
```
仓库主页 → 提交记录旁的 ✓/✗ 图标
```

### 下载 APK
```
Actions → 选择构建 → Artifacts → 下载 ZIP → 解压
```

### 查看构建日志
```
Actions → 选择构建 → 点击任务 → 展开步骤
```

### 手动触发构建
```
Actions → 构建和发布 → Run workflow
参数：
  - 环境: release
  - 平台: android
  - 类型: apk
```

## ⚡ 常见问题速查

| 问题 | 解决方法 |
|------|----------|
| 没有自动触发 | 检查标签格式是否为 `v*.*.*` |
| 构建失败 | 查看 Actions 日志，找到错误步骤 |
| 找不到产物 | 检查构建是否成功，查看 Artifacts |
| 如何修改配置 | 编辑 `.github/workflows/build-and-release.yml` |

## 📚 详细文档

- [完整使用指南](GITHUB_ACTIONS_GUIDE.md) - 详细说明和故障排除
- [发布流程文档](RELEASE_PROCESS.md) - 完整发布流程
