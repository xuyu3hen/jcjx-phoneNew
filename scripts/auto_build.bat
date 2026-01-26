@echo off
REM 设置代码页为 UTF-8，避免中文乱码
chcp 65001 >nul 2>&1
REM 本地自动打包（自动更新版本号 + 打包）
REM 使用方法: scripts\auto_build.bat [env] [version_type]
REM 示例: scripts\auto_build.bat release patch
REM 注意: 在 PowerShell 中执行时，请使用以下方法之一：
REM   方法1: cmd /c scripts\auto_build.bat release patch
REM   方法2: .\scripts\auto_build.bat release patch (如果仍有问题，使用方法1)

setlocal enabledelayedexpansion

REM 默认参数
set ENV=%1
if "%ENV%"=="" set ENV=release

set VERSION_TYPE=%2
if "%VERSION_TYPE%"=="" set VERSION_TYPE=patch

REM 验证环境参数
if not "%ENV%"=="dev" if not "%ENV%"=="test" if not "%ENV%"=="release" (
    echo 错误: 无效的环境参数 '%ENV%'
    echo 可用环境: dev, test, release
    exit /b 1
)

echo ========================================
echo 本地自动打包（自动更新版本号）
echo ========================================
echo 环境: %ENV%
echo 版本类型: %VERSION_TYPE%
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
echo [1/4] 正在更新版本号...
dart scripts\bump_version.dart %VERSION_TYPE% 2>nul
if errorlevel 1 (
    echo 错误: 版本号更新失败
    exit /b 1
)

REM 读取新版本号 - 使用临时文件避免管道问题
set NEW_VERSION=
set TEMP_FILE=%TEMP%\version_line_%RANDOM%.txt
findstr /b /c:"version:" pubspec.yaml > "%TEMP_FILE%" 2>nul
for /f "usebackq tokens=2 delims=: " %%a in ("%TEMP_FILE%") do set NEW_VERSION=%%a
if exist "%TEMP_FILE%" del "%TEMP_FILE%" >nul 2>&1
if not defined NEW_VERSION (
    echo 错误: 无法读取版本号
    echo 尝试从 pubspec.yaml 读取版本号...
    findstr /b /c:"version:" pubspec.yaml
    exit /b 1
)
for /f "tokens=1 delims=+" %%a in ("!NEW_VERSION!") do set VERSION_NAME=%%a
for /f "tokens=2 delims=+" %%a in ("!NEW_VERSION!") do set BUILD_NUMBER=%%a
echo 版本号已更新为: !NEW_VERSION! (版本名: !VERSION_NAME!, 构建号: !BUILD_NUMBER!)
echo.

REM 2. 清理并获取依赖
echo [2/4] 清理并获取依赖...
call flutter clean >nul 2>&1
if errorlevel 1 (
    echo 警告: flutter clean 执行失败，继续执行...
)
call flutter pub get
if errorlevel 1 (
    echo 错误: 依赖获取失败
    exit /b 1
)
echo ✓ 依赖已获取
echo.

REM 3. 构建 APK
echo [3/4] 构建 APK...
echo 正在构建，请稍候...
call flutter build apk --flavor !FLAVOR! -t !MAIN_FILE! --target-platform android-arm,android-arm64 --no-tree-shake-icons --release
if errorlevel 1 (
    echo 错误: APK 构建失败
    exit /b 1
)
echo ✓ APK 构建成功

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

REM 4. 完成（不提交到Git，仅本地构建）
echo [4/4] 构建完成！
echo.

echo ========================================
echo 自动打包完成！
echo ========================================
echo APK 文件: !APK_NEW_PATH!
echo 版本号: !NEW_VERSION!
echo 环境: %ENV%
echo.
echo 提示: 
echo   - APK 文件已生成，可以进行测试或上传到分发服务器
echo   - 版本号已更新但未提交到 Git（本地构建，不自动提交）
echo   - 如需提交版本号，请手动执行: git add pubspec.yaml ^&^& git commit -m "chore: 构建版本 !NEW_VERSION!"
