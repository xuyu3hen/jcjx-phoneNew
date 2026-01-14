# GitHub 推送配置指南

## 问题：无法推送到 GitHub

如果遇到连接失败或认证问题，可以使用以下方法：

## 方案一：使用 Personal Access Token（推荐）

### 1. 生成 Personal Access Token

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单 → **Developer settings**
4. 点击 **Personal access tokens** → **Tokens (classic)**
5. 点击 **Generate new token** → **Generate new token (classic)**
6. 填写信息：
   - **Note**: `jcjx-phone push token`
   - **Expiration**: 选择过期时间（建议 90 天或 No expiration）
   - **Select scopes**: 勾选 `repo`（完整仓库权限）
7. 点击 **Generate token**
8. **重要**：复制生成的 token（只显示一次）

### 2. 配置 Git 使用 Token

```bash
# 使用 token 配置远程仓库 URL
git remote set-url github https://YOUR_TOKEN@github.com/xuyu3hen/jcjx-phoneNew.git

# 替换 YOUR_TOKEN 为刚才复制的 token
# 例如：
# git remote set-url github https://ghp_xxxxxxxxxxxx@github.com/xuyu3hen/jcjx-phoneNew.git
```

### 3. 推送标签

```bash
git push github v1.0.0-test
```

## 方案二：配置 SSH 密钥

### 1. 检查是否已有 SSH 密钥

```bash
# Windows
dir %USERPROFILE%\.ssh

# 或
ls ~/.ssh
```

### 2. 生成 SSH 密钥（如果没有）

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"

# 按提示操作：
# - 保存位置：直接回车（使用默认位置）
# - 密码：可以设置密码或直接回车（不设置）
```

### 3. 添加 SSH 密钥到 GitHub

1. 复制公钥内容：
   ```bash
   # Windows
   type %USERPROFILE%\.ssh\id_ed25519.pub
   
   # Linux/macOS
   cat ~/.ssh/id_ed25519.pub
   ```

2. 登录 GitHub → **Settings** → **SSH and GPG keys**
3. 点击 **New SSH key**
4. 填写：
   - **Title**: `My Computer`（任意名称）
   - **Key**: 粘贴刚才复制的公钥
5. 点击 **Add SSH key**

### 4. 测试 SSH 连接

```bash
ssh -T git@github.com
```

如果看到 "Hi xuyu3hen! You've successfully authenticated..." 说明配置成功。

### 5. 推送标签

```bash
git push github v1.0.0-test
```

## 方案三：使用 GitHub CLI（gh）

### 1. 安装 GitHub CLI

下载：https://cli.github.com/

### 2. 登录

```bash
gh auth login
```

### 3. 推送

```bash
git push github v1.0.0-test
```

## 方案四：在 GitHub 网页上手动触发（最简单）

如果推送有问题，可以直接在 GitHub 网页上手动触发构建：

1. 访问：https://github.com/xuyu3hen/jcjx-phoneNew
2. 点击 **Actions** 标签页
3. 选择 **构建和发布** 工作流
4. 点击 **Run workflow**
5. 选择参数并运行

## 常见问题

### Q: 提示 "Host key verification failed"

**解决方法：**
```bash
# 添加 GitHub 到 known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Windows PowerShell
ssh-keyscan github.com | Out-File -FilePath $env:USERPROFILE\.ssh\known_hosts -Append
```

### Q: 提示 "Permission denied"

**解决方法：**
- 检查 SSH 密钥是否正确添加到 GitHub
- 检查 token 是否有正确的权限
- 确认仓库访问权限

### Q: 提示 "Connection timeout"

**解决方法：**
- 检查网络连接
- 检查防火墙设置
- 尝试使用代理：
  ```bash
  git config --global http.proxy http://proxy.example.com:8080
  git config --global https.proxy https://proxy.example.com:8080
  ```

## 推荐方案

对于 Windows 用户，推荐使用 **方案一（Personal Access Token）**，最简单直接。
