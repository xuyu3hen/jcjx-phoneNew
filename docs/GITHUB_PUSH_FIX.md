# GitHub 推送失败问题解决方案

## 🔴 当前错误

```
fatal: unable to access 'https://github.com/xuyu3hen/jcjx-phoneNew.git/': 
Failed to connect to github.com port 443 after 21085 ms: Could not connect to server
```

## 🔍 问题分析

这是一个**网络连接问题**，无法连接到 GitHub 的 443 端口（HTTPS）。

### 可能原因：
1. ❌ 网络防火墙阻止了 GitHub 连接
2. ❌ 需要配置代理服务器
3. ❌ 网络环境限制（公司网络、学校网络等）
4. ❌ DNS 解析问题
5. ❌ GitHub 服务暂时不可达

## ✅ 解决方案

### 方案一：使用 Personal Access Token（推荐，即使网络有问题也能解决认证）

即使网络连接有问题，配置 Token 后重试可能成功：

#### 步骤 1: 生成 Personal Access Token

1. 访问：https://github.com/settings/tokens
2. 点击 **Generate new token** → **Generate new token (classic)**
3. 填写信息：
   - **Note**: `jcjx-phone push`
   - **Expiration**: 选择过期时间（建议 90 天或 No expiration）
   - **Select scopes**: 勾选 `repo`（完整仓库权限）
4. 点击 **Generate token**
5. **重要**：立即复制 token（只显示一次）

#### 步骤 2: 配置 Git 使用 Token

```powershell
# 使用 token 配置远程仓库（替换 YOUR_TOKEN 为刚才复制的 token）
git remote set-url github https://YOUR_TOKEN@github.com/xuyu3hen/jcjx-phoneNew.git

# 例如：
# git remote set-url github https://ghp_xxxxxxxxxxxxxxxxxxxx@github.com/xuyu3hen/jcjx-phoneNew.git
```

#### 步骤 3: 重试推送

```powershell
git push github main
```

### 方案二：配置代理（如果在公司/学校网络）

如果网络需要代理才能访问外网：

```powershell
# 设置代理（替换为你的代理地址和端口）
git config --global http.proxy http://proxy.example.com:8080
git config --global https.proxy https://proxy.example.com:8080

# 如果需要认证
git config --global http.proxy http://username:password@proxy.example.com:8080

# 然后重试推送
git push github main
```

### 方案三：使用 SSH（如果 HTTPS 被阻止）

如果 HTTPS 端口 443 被阻止，可以尝试 SSH（端口 22）：

```powershell
# 1. 切换到 SSH URL
git remote set-url github git@github.com:xuyu3hen/jcjx-phoneNew.git

# 2. 测试 SSH 连接
ssh -T git@github.com

# 3. 如果连接成功，推送
git push github main
```

**注意**：需要先配置 SSH 密钥（参考 `docs/GITHUB_PUSH_GUIDE.md`）

### 方案四：检查并修复网络连接

```powershell
# 1. 测试 GitHub 连接
Test-NetConnection -ComputerName github.com -Port 443

# 2. 测试 DNS 解析
Resolve-DnsName github.com

# 3. 检查防火墙设置
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Git*"}

# 4. 尝试使用不同的 DNS
# 可以临时使用 8.8.8.8 (Google DNS) 或 114.114.114.114
```

### 方案五：使用 VPN 或更换网络

如果以上方案都不行：
1. 使用 VPN 连接
2. 使用手机热点
3. 更换网络环境

### 方案六：在 GitHub 网页上手动操作

如果推送一直失败，可以：

1. **导出补丁文件**:
   ```powershell
   git format-patch github/main..main -o patches
   ```

2. **使用 GitHub CLI**（如果已安装）:
   ```powershell
   gh auth login
   git push github main
   ```

3. **在 GitHub 网页上手动创建文件**（不推荐，会丢失 Git 历史）

## 🔧 快速诊断脚本

创建一个诊断脚本 `scripts/diagnose_github.ps1`:

```powershell
Write-Host "=== GitHub 连接诊断 ===" -ForegroundColor Cyan

# 1. 检查远程仓库配置
Write-Host "`n1. 远程仓库配置:" -ForegroundColor Yellow
git remote -v

# 2. 测试 DNS 解析
Write-Host "`n2. DNS 解析测试:" -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName github.com -ErrorAction Stop
    Write-Host "✓ DNS 解析成功: $($dns[0].IPAddress)" -ForegroundColor Green
} catch {
    Write-Host "✗ DNS 解析失败: $_" -ForegroundColor Red
}

# 3. 测试端口连接
Write-Host "`n3. 端口连接测试 (443):" -ForegroundColor Yellow
$test = Test-NetConnection -ComputerName github.com -Port 443 -WarningAction SilentlyContinue
if ($test.TcpTestSucceeded) {
    Write-Host "✓ 端口 443 连接成功" -ForegroundColor Green
} else {
    Write-Host "✗ 端口 443 连接失败" -ForegroundColor Red
}

# 4. 测试 SSH 连接（端口 22）
Write-Host "`n4. SSH 端口测试 (22):" -ForegroundColor Yellow
$test22 = Test-NetConnection -ComputerName github.com -Port 22 -WarningAction SilentlyContinue
if ($test22.TcpTestSucceeded) {
    Write-Host "✓ 端口 22 连接成功" -ForegroundColor Green
} else {
    Write-Host "✗ 端口 22 连接失败" -ForegroundColor Red
}

# 5. 检查代理设置
Write-Host "`n5. Git 代理设置:" -ForegroundColor Yellow
$httpProxy = git config --global --get http.proxy
$httpsProxy = git config --global --get https.proxy
if ($httpProxy) {
    Write-Host "HTTP 代理: $httpProxy" -ForegroundColor Yellow
} else {
    Write-Host "HTTP 代理: 未设置" -ForegroundColor Gray
}
if ($httpsProxy) {
    Write-Host "HTTPS 代理: $httpsProxy" -ForegroundColor Yellow
} else {
    Write-Host "HTTPS 代理: 未设置" -ForegroundColor Gray
}

# 6. 检查未推送的提交
Write-Host "`n6. 未推送的提交:" -ForegroundColor Yellow
$unpushed = git log --oneline github/main..main 2>&1
if ($unpushed) {
    Write-Host "有 $($unpushed.Count) 个提交未推送" -ForegroundColor Yellow
    $unpushed | Select-Object -First 5
} else {
    Write-Host "所有提交已推送" -ForegroundColor Green
}

Write-Host "`n=== 诊断完成 ===" -ForegroundColor Cyan
```

## 📝 推荐操作步骤

1. **首先尝试方案一**（使用 Personal Access Token）
   - 这是最可能成功的方案
   - 即使网络有问题，配置 Token 后也可能成功

2. **如果方案一失败，运行诊断脚本**：
   ```powershell
   .\scripts\diagnose_github.ps1
   ```

3. **根据诊断结果选择对应方案**

4. **如果所有方案都失败**：
   - 检查是否在公司/学校网络（可能需要代理）
   - 尝试使用 VPN
   - 尝试使用手机热点
   - 联系网络管理员

## 🆘 紧急方案

如果急需推送代码，可以：

1. **导出所有更改**：
   ```powershell
   git bundle create backup.bundle github/main..main
   ```

2. **在其他网络环境下**：
   ```powershell
   git clone https://github.com/xuyu3hen/jcjx-phoneNew.git
   git pull backup.bundle
   git push origin main
   ```

## 📚 相关文档

- [GitHub 推送配置指南](GITHUB_PUSH_GUIDE.md)
- [从 Gitee 迁移到 GitHub](MIGRATE_TO_GITHUB.md)
