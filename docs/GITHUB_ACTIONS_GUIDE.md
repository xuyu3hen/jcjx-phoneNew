# GitHub Actions 使用指南

本指南详细介绍如何使用 GitHub Actions 进行自动化构建和发布。

## 📋 目录

- [快速开始](#快速开始)
- [触发方式](#触发方式)
- [查看构建结果](#查看构建结果)
- [下载构建产物](#下载构建产物)
- [配置说明](#配置说明)
- [常见问题](#常见问题)

## 🚀 快速开始

### 1. 确保配置文件存在

GitHub Actions 配置文件位于：`.github/workflows/build-and-release.yml`

如果文件不存在，请确保：
- 文件路径正确：`.github/workflows/build-and-release.yml`
- 文件已提交到 Git 仓库

### 2. 推送代码到 GitHub

```bash
# 确保配置文件已提交
git add .github/workflows/build-and-release.yml
git commit -m "添加 GitHub Actions 配置"
git push
```

### 3. 启用 GitHub Actions

1. 登录 GitHub，进入你的仓库
2. 点击 **Actions** 标签页
3. 如果是第一次使用，点击 **I understand my workflows, go ahead and enable them**
4. 现在 GitHub Actions 已启用

## 🎯 触发方式

GitHub Actions 支持两种触发方式：

### 方式一：推送版本标签（自动触发）

当推送版本标签（格式：`v*.*.*`）时，会自动触发构建：

```bash
# 1. 创建版本标签
git tag -a v1.1.8 -m "发布版本 1.1.8"

# 2. 推送标签
git push origin v1.1.8
# 或推送所有标签
git push --tags
```

**触发后会自动：**
- ✅ 构建 APK/AAB
- ✅ 上传构建产物
- ✅ 创建 GitHub Release

### 方式二：手动触发（推荐用于测试）

1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签页
3. 在左侧选择 **构建和发布** 工作流
4. 点击右侧的 **Run workflow** 按钮
5. 选择参数：
   - **构建环境**: dev / test / release
   - **构建平台**: android / ios
   - **构建类型**: apk / appbundle / ipa
6. 点击 **Run workflow** 开始构建

## 📊 查看构建结果

### 1. 查看构建状态

**在仓库主页：**
- 查看提交记录旁边的 ✓ 或 ✗ 图标
- 绿色 ✓ 表示构建成功
- 红色 ✗ 表示构建失败

**在 Actions 页面：**
1. 点击 **Actions** 标签页
2. 查看工作流运行列表
3. 点击某个运行查看详情

### 2. 查看构建日志

1. 进入 **Actions** 页面
2. 点击要查看的运行
3. 点击左侧的 **构建** 任务
4. 展开各个步骤查看详细日志

**日志包含：**
- Flutter 环境设置
- 依赖安装
- 版本号解析
- 构建过程
- 上传结果

### 3. 构建状态说明

| 状态 | 图标 | 说明 |
|------|------|------|
| 成功 | ✓ | 构建完成，可以下载 |
| 失败 | ✗ | 构建失败，查看日志 |
| 进行中 | ⏳ | 正在构建中 |
| 已取消 | ⊘ | 构建被取消 |

## 📦 下载构建产物

### 方式一：从 Artifacts 下载

1. 进入 **Actions** 页面
2. 点击成功的构建运行
3. 滚动到页面底部的 **Artifacts** 部分
4. 点击构建产物名称下载
5. 下载的是 ZIP 文件，解压后得到 APK/AAB 文件

**Artifacts 保留时间：** 30 天（可在配置文件中修改）

### 方式二：从 Release 下载

如果推送了版本标签，会自动创建 Release：

1. 进入仓库主页
2. 点击右侧的 **Releases** 链接
3. 找到对应的版本
4. 在 **Assets** 部分下载文件

**Release 优势：**
- 永久保存
- 可以添加发布说明
- 更好的版本管理

## ⚙️ 配置说明

### 修改 Flutter 版本

编辑 `.github/workflows/build-and-release.yml`：

```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # 修改为你需要的版本
```

### 修改构建参数

配置文件中的关键参数：

```yaml
# 触发条件
on:
  push:
    tags:
      - 'v*.*.*'  # 版本标签格式

# 环境变量
env:
  FLUTTER_VERSION: '3.24.0'

# 构建产物保留时间
retention-days: 30  # 修改保留天数
```

### 添加构建步骤

可以在配置文件中添加自定义步骤：

```yaml
- name: 自定义步骤
  run: |
    echo "执行自定义操作"
    # 你的命令
```

## 🔧 常见问题

### Q1: Actions 没有自动触发？

**检查清单：**
1. ✅ 配置文件路径是否正确：`.github/workflows/build-and-release.yml`
2. ✅ 文件是否已提交到仓库
3. ✅ GitHub Actions 是否已启用
4. ✅ 标签格式是否正确（必须是 `v*.*.*` 格式）

**解决方法：**
```bash
# 检查文件是否存在
ls -la .github/workflows/

# 检查文件内容
cat .github/workflows/build-and-release.yml

# 确保已提交
git status
git add .github/workflows/build-and-release.yml
git commit -m "添加 GitHub Actions"
git push
```

### Q2: 构建失败怎么办？

**常见原因：**

1. **Flutter 版本不匹配**
   - 检查 `FLUTTER_VERSION` 配置
   - 确保版本号正确

2. **依赖问题**
   - 查看构建日志中的错误信息
   - 检查 `pubspec.yaml` 中的依赖

3. **代码错误**
   - 检查代码是否有语法错误
   - 运行 `flutter analyze` 检查

4. **权限问题**
   - 确保有推送权限
   - 检查仓库设置

**调试步骤：**
1. 查看构建日志，找到失败步骤
2. 复制错误信息
3. 在本地复现问题
4. 修复后重新推送

### Q3: 如何查看详细的构建日志？

1. 进入 **Actions** 页面
2. 点击失败的构建
3. 点击失败的步骤
4. 查看详细错误信息

**关键信息：**
- 错误堆栈跟踪
- 命令执行结果
- 环境变量值

### Q4: 构建产物找不到？

**可能原因：**
1. 构建失败，没有生成产物
2. 产物已过期（超过保留时间）
3. 路径配置错误

**解决方法：**
1. 检查构建是否成功
2. 查看 **Artifacts** 部分
3. 如果已过期，重新触发构建

### Q5: 如何修改构建命令？

编辑 `.github/workflows/build-and-release.yml` 中的构建步骤：

```yaml
- name: 构建 Android APK
  run: |
    flutter build apk \
      --flavor ${{ steps.build.outputs.flavor }} \
      -t ${{ steps.build.outputs.main_file }} \
      --target-platform android-arm,android-arm64 \
      --no-tree-shake-icons \
      --release
```

### Q6: 如何添加环境变量或密钥？

1. 进入仓库 **Settings**
2. 点击 **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 添加密钥名称和值
5. 在配置文件中使用：

```yaml
env:
  MY_SECRET: ${{ secrets.MY_SECRET }}
```

### Q7: 如何只构建特定环境？

**方法一：手动触发**
- 在手动触发时选择环境

**方法二：修改触发条件**
编辑配置文件，添加分支过滤：

```yaml
on:
  push:
    branches:
      - main  # 只对 main 分支触发
    tags:
      - 'v*.*.*'
```

### Q8: 构建时间太长怎么办？

**优化建议：**
1. 使用缓存加速依赖安装
2. 并行构建多个平台
3. 只构建必要的产物

**添加缓存示例：**
```yaml
- name: 缓存 Flutter 依赖
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      .dart_tool
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
```

## 📝 最佳实践

### 1. 版本标签规范

使用语义化版本标签：
- ✅ `v1.1.8` - 正确
- ❌ `1.1.8` - 缺少 `v` 前缀
- ❌ `version-1.1.8` - 格式不正确

### 2. 提交信息规范

```bash
# 功能更新
git commit -m "feat: 添加新功能"

# Bug 修复
git commit -m "fix: 修复登录问题"

# 版本更新
git commit -m "chore: 更新版本号到 1.1.8"
```

### 3. 发布流程

1. ✅ 确保代码已测试
2. ✅ 更新版本号
3. ✅ 提交代码
4. ✅ 创建标签
5. ✅ 推送标签触发构建
6. ✅ 等待构建完成
7. ✅ 下载并测试构建产物
8. ✅ 发布 Release

### 4. 监控构建

- 定期检查构建状态
- 设置邮件通知（GitHub 设置中）
- 关注构建失败通知

## 🔗 相关资源

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Flutter Action 文档](https://github.com/subosito/flutter-action)
- [工作流语法参考](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [发布流程文档](RELEASE_PROCESS.md)

## 💡 提示

1. **首次使用**：建议先手动触发一次，确认配置正确
2. **测试环境**：先在 test 环境测试，再发布到 release
3. **构建时间**：首次构建可能需要 10-15 分钟，后续会更快
4. **资源限制**：免费账户有使用限制，注意控制构建频率

## 🆘 需要帮助？

如果遇到问题：
1. 查看本文档的常见问题部分
2. 查看 GitHub Actions 日志
3. 检查配置文件语法
4. 参考 GitHub Actions 官方文档
