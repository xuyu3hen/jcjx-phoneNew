@echo off
chcp 65001 >nul
REM 本地自动打包（自动更新版本号 + 打包）
REM 使用方法: scripts\auto_build.bat [env] [version_type]
REM 示例: scripts\auto_build.bat release patch

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
echo [1/4] 更新版本号...
dart scripts\bump_version.dart %VERSION_TYPE%
if errorlevel 1 (
    echo 错误: 版本号更新失败
    exit /b 1
)

REM 读取新版本号
for /f "tokens=2" %%a in ('findstr /r "^version:" pubspec.yaml') do (
    set NEW_VERSION=%%a
)
if not defined NEW_VERSION (
    echo 错误: 无法读取版本号
    echo 尝试从 pubspec.yaml 读取版本号...
    type pubspec.yaml | findstr /r "^version:"
    exit /b 1
)
for /f "tokens=1 delims=+" %%a in ("!NEW_VERSION!") do set VERSION_NAME=%%a
for /f "tokens=2 delims=+" %%a in ("!NEW_VERSION!") do set BUILD_NUMBER=%%a
echo ✓ 版本号已更新为: !NEW_VERSION! (版本名: !VERSION_NAME!, 构建号: !BUILD_NUMBER!)
echo.

REM 2. 清理并获取依赖
echo [2/4] 清理并获取依赖...
call flutter clean >nul 2>&1
call flutter pub get
if errorlevel 1 (
    echo 错误: 依赖获取失败
    exit /b 1
)
echo ✓ 依赖已获取
echo.

REM 3. 构建 APK
echo [3/4] 构建 APK...
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

REM 4. 提交版本号变更（可选）
echo [4/4] 提交版本号变更到 Git...
set /p COMMIT="是否提交版本号变更到 Git? (y/n) "
if /i "!COMMIT!"=="y" (
    git add pubspec.yaml
    git commit -m "chore: 自动构建版本 !NEW_VERSION! (%ENV%环境)"
    echo ✓ 版本号已提交到 Git
) else (
    echo ⚠ 已跳过 Git 提交
)
echo.

echo ========================================
echo 自动打包完成！
echo ========================================
echo APK 文件: !APK_NEW_PATH!
echo 版本号: !NEW_VERSION!
echo.
echo 提示: APK 文件已生成，可以进行测试或上传到分发服务器
