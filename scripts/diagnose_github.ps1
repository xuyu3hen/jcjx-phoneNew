# GitHub 连接诊断脚本
# 使用方法: .\scripts\diagnose_github.ps1

Write-Host "=== GitHub 连接诊断 ===" -ForegroundColor Cyan

# 1. 检查远程仓库配置
Write-Host ""
Write-Host "1. 远程仓库配置:" -ForegroundColor Yellow
git remote -v

# 2. 测试 DNS 解析
Write-Host ""
Write-Host "2. DNS 解析测试:" -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName github.com -ErrorAction Stop
    Write-Host "✓ DNS 解析成功: $($dns[0].IPAddress)" -ForegroundColor Green
} catch {
    Write-Host "✗ DNS 解析失败: $_" -ForegroundColor Red
}

# 3. 测试端口连接
Write-Host ""
Write-Host "3. HTTPS 端口连接测试 (443):" -ForegroundColor Yellow
$test = Test-NetConnection -ComputerName github.com -Port 443 -WarningAction SilentlyContinue
if ($test.TcpTestSucceeded) {
    Write-Host "✓ 端口 443 连接成功" -ForegroundColor Green
} else {
    Write-Host "✗ 端口 443 连接失败" -ForegroundColor Red
    Write-Host "  这可能是因为防火墙或网络限制" -ForegroundColor Yellow
}

# 4. 测试 SSH 连接（端口 22）
Write-Host ""
Write-Host "4. SSH 端口测试 (22):" -ForegroundColor Yellow
$test22 = Test-NetConnection -ComputerName github.com -Port 22 -WarningAction SilentlyContinue
if ($test22.TcpTestSucceeded) {
    Write-Host "✓ 端口 22 连接成功" -ForegroundColor Green
    Write-Host "  可以尝试使用 SSH 方式推送" -ForegroundColor Yellow
} else {
    Write-Host "✗ 端口 22 连接失败" -ForegroundColor Red
}

# 5. 检查代理设置
Write-Host ""
Write-Host "5. Git 代理设置:" -ForegroundColor Yellow
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
Write-Host ""
Write-Host "6. 未推送的提交:" -ForegroundColor Yellow
try {
    $unpushed = git log --oneline github/main..main 2>&1
    if ($unpushed -and $unpushed.Count -gt 0) {
        Write-Host "有 $($unpushed.Count) 个提交未推送:" -ForegroundColor Yellow
        $unpushed | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "✓ 所有提交已推送" -ForegroundColor Green
    }
} catch {
    Write-Host "无法检查未推送的提交（可能需要先 fetch）" -ForegroundColor Yellow
}

# 7. 测试 Git 连接
Write-Host ""
Write-Host "7. Git 远程连接测试:" -ForegroundColor Yellow
try {
    $result = git ls-remote github 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git 远程连接成功" -ForegroundColor Green
    } else {
        Write-Host "✗ Git 远程连接失败" -ForegroundColor Red
        Write-Host "  错误信息已显示 above" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Git 远程连接测试失败" -ForegroundColor Red
}

# 8. 建议
Write-Host ""
Write-Host "=== 建议 ===" -ForegroundColor Cyan
if (-not $test.TcpTestSucceeded) {
    Write-Host "1. HTTPS 端口 443 无法连接，建议：" -ForegroundColor Yellow
    Write-Host "   - 配置 Personal Access Token（可能仍能工作）" -ForegroundColor White
    Write-Host "   - 尝试使用 SSH 方式（如果端口 22 可用）" -ForegroundColor White
    Write-Host "   - 配置代理服务器" -ForegroundColor White
    Write-Host "   - 使用 VPN 或更换网络" -ForegroundColor White
} else {
    Write-Host "1. 网络连接正常，可能是认证问题" -ForegroundColor Yellow
    Write-Host "   - 配置 Personal Access Token" -ForegroundColor White
    Write-Host "   - 检查仓库权限" -ForegroundColor White
}

Write-Host ""
Write-Host "2. 详细解决方案请查看: docs/GITHUB_PUSH_FIX.md" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== 诊断完成 ===" -ForegroundColor Cyan
