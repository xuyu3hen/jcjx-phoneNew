@echo off
REM Flutter 多环境构建脚本 (Windows)
REM 使用方法: scripts\build.bat [env] [platform] [type]
REM 示例: scripts\build.bat release android apk

setlocal enabledelayedexpansion

REM 默认参数
set ENV=%1
if "%ENV%"=="" set ENV=release

set PLATFORM=%2
if "%PLATFORM%"=="" set PLATFORM=android

set BUILD_TYPE=%3
if "%BUILD_TYPE%"=="" set BUILD_TYPE=apk

REM 验证环境参数
if not "%ENV%"=="dev" if not "%ENV%"=="test" if not "%ENV%"=="release" (
    echo 错误: 无效的环境参数 '%ENV%'
    echo 可用环境: dev, test, release
    exit /b 1
)

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

echo ========================================
echo 开始构建 Flutter 应用
echo ========================================
echo 环境: %ENV% (%FLAVOR%)
echo 平台: %PLATFORM%
echo 类型: %BUILD_TYPE%
echo 主文件: %MAIN_FILE%
echo.

REM 清理旧的构建
echo 清理旧的构建文件...
call flutter clean

REM 获取依赖
echo 获取 Flutter 依赖...
call flutter pub get

REM 构建
echo 开始构建...

if "%PLATFORM%"=="android" (
    if "%BUILD_TYPE%"=="apk" (
        REM 构建 APK
        call flutter build apk --flavor %FLAVOR% -t %MAIN_FILE% --target-platform android-arm,android-arm64 --no-tree-shake-icons --release
        set OUTPUT_DIR=build\app\outputs\flutter-apk\
    ) else if "%BUILD_TYPE%"=="appbundle" (
        REM 构建 App Bundle
        call flutter build appbundle --flavor %FLAVOR% -t %MAIN_FILE% --no-tree-shake-icons --release
        set OUTPUT_DIR=build\app\outputs\bundle\%FLAVOR%Release\
    ) else (
        echo 错误: 不支持的构建类型 '%BUILD_TYPE%'
        echo Android 支持的构建类型: apk, appbundle
        exit /b 1
    )
) else (
    echo 错误: iOS 构建需要 macOS 环境
    exit /b 1
)

echo.
echo ========================================
echo 构建完成！
echo ========================================
echo 输出目录: %OUTPUT_DIR%
echo.
echo 提示: 构建文件已生成，可以开始分发
