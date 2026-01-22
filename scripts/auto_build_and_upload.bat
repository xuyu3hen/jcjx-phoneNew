@echo off
chcp 65001 >nul
REM 本地自动打包并上传到内网分发服务器 (Windows)
REM 使用方法: scripts\auto_build_and_upload.bat [env] [version_type] [server_url]
REM 示例: scripts\auto_build_and_upload.bat release patch https://10.102.12.211:8443

setlocal enabledelayedexpansion

REM 默认参数
set ENV=%1
if "%ENV%"=="" set ENV=release

set VERSION_TYPE=%2
if "%VERSION_TYPE%"=="" set VERSION_TYPE=patch

set SERVER_URL=%3
if "%SERVER_URL%"=="" set SERVER_URL=https://10.102.12.211:8443

REM 验证环境参数
if not "%ENV%"=="dev" if not "%ENV%"=="test" if not "%ENV%"=="release" (
    echo 错误: 无效的环境参数 '%ENV%'
    echo 可用环境: dev, test, release
    exit /b 1
)

echo ========================================
echo 本地自动打包并上传到内网服务器
echo ========================================
echo 环境: %ENV%
echo 版本类型: %VERSION_TYPE%
echo 服务器地址: %SERVER_URL%
echo.

REM 设置环境变量
if "%ENV%"=="dev" (
    set FLAVOR=env_dev
    set MAIN_FILE=lib/main_env_dev.dart
    set APP_NAME=机车检修(本地)
) else if "%ENV%"=="test" (
    set FLAVOR=env_test
    set MAIN_FILE=lib/main_env_test.dart
    set APP_NAME=机车检修(测试)
) else (
    set FLAVOR=env_release
    set MAIN_FILE=lib/main_env_release.dart
    set APP_NAME=机车检修
)

REM 1. 更新版本号
echo [1/5] 更新版本号...
dart scripts\bump_version.dart %VERSION_TYPE%
if errorlevel 1 (
    echo 错误: 版本号更新失败
    exit /b 1
)

REM 读取新版本号
for /f "tokens=2" %%a in ('findstr /r "^version:" pubspec.yaml') do set NEW_VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("!NEW_VERSION!") do set VERSION_NAME=%%a
for /f "tokens=2 delims=+" %%a in ("!NEW_VERSION!") do set BUILD_NUMBER=%%a
echo ✓ 版本号已更新为: !NEW_VERSION! (版本名: !VERSION_NAME!, 构建号: !BUILD_NUMBER!)
echo.

REM 2. 清理并获取依赖
echo [2/5] 清理并获取依赖...
call flutter clean >nul 2>&1
call flutter pub get
if errorlevel 1 (
    echo 错误: 依赖获取失败
    exit /b 1
)
echo ✓ 依赖已获取
echo.

REM 3. 构建 APK
echo [3/5] 构建 APK...
call flutter build apk --flavor !FLAVOR! -t !MAIN_FILE! --target-platform android-arm,android-arm64 --no-tree-shake-icons --release
if errorlevel 1 (
    echo 错误: APK 构建失败
    exit /b 1
)

REM 确定输出文件路径
set APK_FILE=build\app\outputs\flutter-apk\app-!FLAVOR!-release.apk
if not exist "!APK_FILE!" (
    echo 错误: 找不到构建的 APK 文件: !APK_FILE!
    exit /b 1
)

REM 生成带版本号的文件名
set APK_NAME=jcjx-phone-!VERSION_NAME!-build!BUILD_NUMBER!-!ENV!.apk
set APK_NEW_PATH=build\app\outputs\flutter-apk\!APK_NAME!

copy "!APK_FILE!" "!APK_NEW_PATH!" >nul
echo ✓ APK 构建完成: !APK_NEW_PATH!
echo.

REM 4. 上传到服务器
echo [4/5] 上传 APK 到服务器...
echo 提示: 需要配置服务器地址和认证信息
echo.

REM 使用 PowerShell 上传文件（需要配置服务器URL和认证）
powershell -Command "$ErrorActionPreference='Stop'; try { $filePath = '!APK_NEW_PATH!'; $fileName = '!APK_NAME!'; $serverUrl = '%SERVER_URL%/api/apk/upload'; $boundary = [System.Guid]::NewGuid().ToString(); $fileBytes = [System.IO.File]::ReadAllBytes($filePath); $fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetBytes($fileName); $enc = [System.Text.Encoding]::GetEncoding('UTF-8'); $newline = \"`r`n\"; $bodyLines = ( @('--' + $boundary, 'Content-Disposition: form-data; name=\"file\"; filename=\"' + $fileName + '\"', 'Content-Type: application/vnd.android.package-archive', '', [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes), '--' + $boundary, 'Content-Disposition: form-data; name=\"version\"', '', '!VERSION_NAME!', '--' + $boundary, 'Content-Disposition: form-data; name=\"buildNumber\"', '', '!BUILD_NUMBER!', '--' + $boundary, 'Content-Disposition: form-data; name=\"env\"', '', '%ENV%', '--' + $boundary, 'Content-Disposition: form-data; name=\"description\"', '', '自动构建上传', '--' + $boundary + '--' ) | ForEach-Object { if ($_ -is [string]) { $enc.GetBytes($_ + $newline) } else { $_ } } ); $body = $bodyLines | ForEach-Object { $_ }; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $response = Invoke-RestMethod -Uri $serverUrl -Method Post -Body $body -ContentType \"multipart/form-data; boundary=$boundary\" -ErrorAction Stop; Write-Host '✓ 上传成功' -ForegroundColor Green; Write-Host \"响应: $($response | ConvertTo-Json -Depth 3)\" } catch { Write-Host \"错误: $_\" -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo.
    echo ⚠ 自动上传失败，请手动上传
    echo APK 文件位置: !APK_NEW_PATH!
    echo 服务器地址: %SERVER_URL%/api/apk/upload
    echo.
    echo 可以使用以下 curl 命令手动上传:
    echo curl -k -X POST "%SERVER_URL%/api/apk/upload" ^
    echo   -F "file=@!APK_NEW_PATH!" ^
    echo   -F "version=!VERSION_NAME!" ^
    echo   -F "buildNumber=!BUILD_NUMBER!" ^
    echo   -F "env=%ENV%" ^
    echo   -F "description=自动构建上传"
) else (
    echo ✓ APK 已上传到服务器
)
echo.

REM 5. 提交版本号变更（可选，默认不提交）
echo [5/5] 提交版本号变更到 Git（可选）...
echo 提示: 本地构建默认不提交到 Git，如需提交请手动操作
set /p COMMIT="是否提交版本号变更到 Git? (y/n，默认n): "
if /i "!COMMIT!"=="y" (
    git add pubspec.yaml
    git commit -m "chore: 自动构建版本 !NEW_VERSION! (%ENV%环境)"
    echo ✓ 版本号已提交到 Git
) else (
    echo ⚠ 已跳过 Git 提交（本地构建，不自动提交）
)
echo.

echo ========================================
echo 自动打包完成！
echo ========================================
echo APK 文件: !APK_NEW_PATH!
echo 版本号: !NEW_VERSION!
echo 服务器: %SERVER_URL%
echo.
echo 提示: 请在内网服务器上验证 APK 是否已成功上传
