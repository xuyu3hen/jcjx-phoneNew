# 从 Gitee 迁移到 GitHub 指南

本指南将帮助您将项目从 Gitee 完整迁移到 GitHub。

## 📋 目录

- [迁移前准备](#迁移前准备)
- [迁移步骤](#迁移步骤)
- [迁移后配置](#迁移后配置)
- [验证迁移](#验证迁移)
- [常见问题](#常见问题)

## 🔍 迁移前准备

### 1. 检查当前 Git 配置

```bash
# 查看当前远程仓库
git remote -v

# 查看当前分支
git branch -a

# 查看所有标签
git tag -l

# 查看提交历史
git log --oneline -10
```

### 2. 确保代码已提交

```bash
# 检查工作区状态
git status

# 如果有未提交的更改，先提交
git add .
git commit -m "迁移前最终提交"
```

### 3. 备份重要数据

- ✅ 代码仓库（已有 Git 历史）
- ✅ 配置文件
- ✅ 文档
- ✅ Issues（如果需要，可以导出）

## 🚀 迁移步骤

### 方法一：保留完整 Git 历史（推荐）

#### 步骤 1: 在 GitHub 创建新仓库

1. 登录 GitHub
2. 点击右上角 **+** → **New repository**
3. 填写仓库信息：
   - **Repository name**: `jcjx-phone`（或你想要的名称）
   - **Description**: 机车检修手持机项目
   - **Visibility**: 选择 Public 或 Private
   - ⚠️ **不要**勾选 "Initialize this repository with a README"
   - ⚠️ **不要**添加 .gitignore 或 license（已有）
4. 点击 **Create repository**

#### 步骤 2: 添加 GitHub 远程仓库

在本地项目目录执行：

```bash
# 查看当前远程仓库
git remote -v

# 添加 GitHub 远程仓库（替换 YOUR_USERNAME 和 REPO_NAME）
git remote add github https://github.com/YOUR_USERNAME/jcjx-phone.git

# 或者使用 SSH（推荐，如果已配置 SSH 密钥）
git remote add github git@github.com:YOUR_USERNAME/jcjx-phone.git

# 验证添加成功
git remote -v
```

**示例：**
```bash
# HTTPS 方式
git remote add github https://github.com/yourusername/jcjx-phone.git

# SSH 方式（推荐）
git remote add github git@github.com:yourusername/jcjx-phone.git
```

#### 步骤 3: 推送所有分支到 GitHub

```bash
# 推送所有分支
git push github --all

# 推送所有标签
git push github --tags
```

**如果遇到问题，可以逐个推送：**

```bash
# 查看所有分支
git branch -a

# 推送主分支
git push github main

# 推送其他分支
git push github develop
git push github feature/xxx

# 推送所有标签
git push github --tags
```

#### 步骤 4: 设置 GitHub 为默认远程仓库（可选）

```bash
# 查看当前远程仓库
git remote -v

# 删除旧的 Gitee 远程仓库（可选，建议先保留一段时间）
# git remote remove origin

# 将 GitHub 设置为 origin
git remote rename github origin

# 或者保留两个远程仓库，分别命名为 gitee 和 github
git remote rename origin gitee
git remote rename github origin
```

### 方法二：使用 GitHub 导入功能（简单但不保留所有历史）

1. 登录 GitHub
2. 点击右上角 **+** → **Import repository**
3. 填写信息：
   - **Your old repository's clone URL**: `https://gitee.com/YOUR_USERNAME/jcjx-phone.git`
   - **Your new repository details**: 填写仓库名称和描述
4. 点击 **Begin import**
5. 等待导入完成

⚠️ **注意**：此方法可能不会保留所有 Git 历史，建议使用方法一。

## ⚙️ 迁移后配置

### 1. 更新远程仓库 URL（如果已设置为 origin）

```bash
# 查看当前远程仓库
git remote -v

# 更新 origin 为 GitHub
git remote set-url origin https://github.com/YOUR_USERNAME/jcjx-phone.git

# 或使用 SSH
git remote set-url origin git@github.com:YOUR_USERNAME/jcjx-phone.git
```

### 2. 验证 GitHub Actions 配置

```bash
# 检查配置文件是否存在
ls -la .github/workflows/

# 如果不存在，确保已提交
git add .github/workflows/build-and-release.yml
git commit -m "添加 GitHub Actions 配置"
git push origin main
```

### 3. 启用 GitHub Actions

1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签页
3. 如果是第一次使用，点击 **I understand my workflows, go ahead and enable them**

### 4. 配置仓库设置

1. 进入仓库 **Settings**
2. 配置以下选项：
   - **General** → **Features**: 启用 Issues、Wiki 等（如果需要）
   - **Secrets and variables** → **Actions**: 添加必要的密钥（如果有）
   - **Branches**: 设置默认分支和保护规则

### 5. 更新文档中的链接

检查并更新以下文件中的链接：

- `README.md` - 更新仓库链接
- `docs/` 目录下的文档 - 更新相关链接
- CI/CD 配置文件中的链接（如果有）

```bash
# 搜索 Gitee 链接
grep -r "gitee.com" .

# 替换为 GitHub 链接
# 使用编辑器批量替换或手动更新
```

## ✅ 验证迁移

### 1. 验证代码完整性

```bash
# 在 GitHub 上检查
# - 所有分支是否存在
# - 所有标签是否存在
# - 提交历史是否完整
```

### 2. 验证 GitHub Actions

```bash
# 推送一个测试标签
git tag -a v1.0.0-test -m "测试标签"
git push origin v1.0.0-test

# 在 GitHub Actions 中查看是否触发构建
```

### 3. 验证文件完整性

在 GitHub 上检查：
- ✅ 所有文件都已上传
- ✅ 配置文件正确
- ✅ 文档完整

## 🔧 常见问题

### Q1: 推送时提示认证失败？

**解决方法：**

```bash
# 使用 Personal Access Token（推荐）
# 1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. 生成新 token，勾选 repo 权限
# 3. 使用 token 作为密码

# 或配置 SSH 密钥（更安全）
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 添加到 GitHub
# GitHub → Settings → SSH and GPG keys → New SSH key

# 3. 使用 SSH URL
git remote set-url origin git@github.com:YOUR_USERNAME/jcjx-phone.git
```

### Q2: 推送时提示分支冲突？

**解决方法：**

```bash
# 强制推送（谨慎使用）
git push github --all --force

# 或先拉取再推送
git fetch github
git merge github/main
git push github --all
```

### Q3: 如何保留两个远程仓库？

```bash
# 保留 Gitee 和 GitHub 两个远程仓库
git remote add gitee https://gitee.com/YOUR_USERNAME/jcjx-phone.git
git remote add github https://github.com/YOUR_USERNAME/jcjx-phone.git

# 推送到 Gitee
git push gitee main

# 推送到 GitHub
git push github main
```

### Q4: 如何迁移 Issues？

GitHub 不直接支持从 Gitee 导入 Issues，可以：

1. **手动迁移**：在 GitHub 上手动创建 Issues
2. **使用工具**：使用第三方工具（如 `github-issue-migrator`）
3. **导出导入**：从 Gitee 导出，在 GitHub 上批量创建

### Q5: 如何迁移 Pull Requests？

Pull Requests 无法直接迁移，建议：

1. 在 GitHub 上重新创建 PR
2. 在 PR 描述中引用原 Gitee PR
3. 关闭原 Gitee PR 并添加迁移说明

### Q6: 迁移后如何通知团队成员？

1. 更新团队文档中的仓库地址
2. 发送通知邮件或消息
3. 更新 CI/CD 配置（如果有）
4. 更新部署脚本中的仓库地址

## 📝 迁移检查清单

迁移完成后，请确认：

- [ ] 所有分支已推送到 GitHub
- [ ] 所有标签已推送到 GitHub
- [ ] 提交历史完整
- [ ] 所有文件已上传
- [ ] GitHub Actions 已启用
- [ ] 文档链接已更新
- [ ] 团队成员已通知
- [ ] CI/CD 配置已更新（如果有）
- [ ] 部署脚本已更新（如果有）

## 🔄 后续操作

### 1. 更新本地配置

```bash
# 更新远程仓库 URL
git remote set-url origin https://github.com/YOUR_USERNAME/jcjx-phone.git

# 验证
git remote -v
```

### 2. 团队成员迁移

通知团队成员执行：

```bash
# 更新远程仓库 URL
git remote set-url origin https://github.com/YOUR_USERNAME/jcjx-phone.git

# 拉取最新代码
git fetch origin
git pull origin main
```

### 3. 更新 CI/CD 配置

如果有外部 CI/CD 系统（如 Jenkins），需要更新：
- 仓库地址
- 认证信息
- Webhook URL

### 4. 更新部署配置

如果有自动部署脚本，需要更新：
- 仓库地址
- 分支名称
- 认证信息

## 🔗 相关资源

- [GitHub 官方文档](https://docs.github.com/)
- [Git 远程仓库管理](https://git-scm.com/book/zh/v2/Git-基础-远程仓库的使用)
- [GitHub Actions 使用指南](GITHUB_ACTIONS_GUIDE.md)

## 💡 提示

1. **保留 Gitee 仓库一段时间**：建议保留 1-3 个月，确保迁移成功
2. **逐步迁移**：可以先迁移代码，再逐步迁移 Issues、Wiki 等
3. **通知团队**：及时通知团队成员更新仓库地址
4. **测试验证**：迁移后进行全面测试，确保一切正常

## 🆘 需要帮助？

如果遇到问题：
1. 查看本文档的常见问题部分
2. 查看 GitHub 官方文档
3. 检查 Git 配置和权限
4. 联系 GitHub 支持
