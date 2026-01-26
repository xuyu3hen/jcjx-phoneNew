# PowerShell Auto Build Script
# Usage: .\scripts\auto_build.ps1 [env] [version_type]
# Example: .\scripts\auto_build.ps1 release patch

param(
    [string]$env = "release",
    [string]$versionType = "patch"
)

# Validate environment parameter
if ($env -notin @("dev", "test", "release")) {
    Write-Host "Error: Invalid environment parameter '$env'" -ForegroundColor Red
    Write-Host "Available environments: dev, test, release" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "本地自动打包（自动更新版本号）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "环境: $env"
Write-Host "版本类型: $versionType"
Write-Host ""

# Set environment variables
$flavor = switch ($env) {
    "dev" { "env_dev"; break }
    "test" { "env_test"; break }
    "release" { "env_release"; break }
}

$mainFile = switch ($env) {
    "dev" { "lib/main_env_dev.dart"; break }
    "test" { "lib/main_env_test.dart"; break }
    "release" { "lib/main_env_release.dart"; break }
}

# Step 1: Update version
Write-Host "[1/4] 正在更新版本号..." -ForegroundColor Yellow
& dart scripts\bump_version.dart $versionType 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 版本号更新失败" -ForegroundColor Red
    exit 1
}

# Read new version
$pubspecContent = Get-Content "pubspec.yaml" -Raw -Encoding UTF8
$versionMatch = [regex]::Match($pubspecContent, 'version:\s*([\d.]+)\+(\d+)')
if (-not $versionMatch.Success) {
    Write-Host "错误: 无法读取版本号" -ForegroundColor Red
    exit 1
}

$newVersion = $versionMatch.Groups[0].Value -replace 'version:\s*', ''
$versionName = $versionMatch.Groups[1].Value
$buildNumber = $versionMatch.Groups[2].Value

Write-Host "版本号已更新为: $newVersion (版本名: $versionName, 构建号: $buildNumber)" -ForegroundColor Green
Write-Host ""

# Step 2: Clean and get dependencies
Write-Host "[2/4] 清理并获取依赖..." -ForegroundColor Yellow
& flutter clean 2>$null | Out-Null
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 依赖获取失败" -ForegroundColor Red
    exit 1
}
Write-Host "✓ 依赖已获取" -ForegroundColor Green
Write-Host ""

# Step 3: Build APK
Write-Host "[3/4] 构建 APK..." -ForegroundColor Yellow
Write-Host "正在构建，请稍候..." -ForegroundColor Gray
& flutter build apk --flavor $flavor -t $mainFile --target-platform android-arm,android-arm64 --no-tree-shake-icons --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: APK 构建失败" -ForegroundColor Red
    exit 1
}
Write-Host "✓ APK 构建成功" -ForegroundColor Green

# Determine output file path
$apkFile = "build\app\outputs\flutter-apk\app-$flavor-release.apk"
if (-not (Test-Path $apkFile)) {
    Write-Host "错误: 找不到构建的 APK 文件: $apkFile" -ForegroundColor Red
    exit 1
}

# Generate versioned filename
$apkName = "jcjx-phone-$versionName-build$buildNumber-$env.apk"
$apkNewPath = "build\app\outputs\flutter-apk\$apkName"

Copy-Item $apkFile $apkNewPath -Force | Out-Null
Write-Host "✓ APK 构建完成: $apkNewPath" -ForegroundColor Green
Write-Host ""

# Step 4: Complete
Write-Host "[4/4] 构建完成！" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "自动打包完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "APK 文件: $apkNewPath" -ForegroundColor Green
Write-Host "版本号: $newVersion"
Write-Host "环境: $env"
Write-Host ""
Write-Host "提示:" -ForegroundColor Yellow
Write-Host "  - APK 文件已生成，可以进行测试或上传到分发服务器"
Write-Host "  - 版本号已更新但未提交到 Git（本地构建，不自动提交）"
Write-Host "  - 如需提交版本号，请手动执行以下命令:"
Write-Host "    git add pubspec.yaml"
Write-Host "    git commit -m 'chore: 构建版本 $newVersion'"
