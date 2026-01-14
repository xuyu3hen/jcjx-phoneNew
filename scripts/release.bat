@echo off
REM 自动化发布流程脚本 (Windows)
REM 使用方法: scripts\release.bat [version_type]
REM version_type: patch, minor, major (默认: patch)

setlocal enabledelayedexpansion

set VERSION_TYPE=%1
if "%VERSION_TYPE%"=="" set VERSION_TYPE=patch

echo ========================================
echo 自动化发布流程
echo ========================================
echo.

REM 1. 检查工作区是否干净
echo [1/6] 检查 Git 工作区...
git diff --quiet
if errorlevel 1 (
    echo 错误: 工作区有未提交的更改
    echo 请先提交或暂存所有更改
    exit /b 1
)
echo ✓ 工作区干净
echo.

REM 2. 运行测试（如果有）
echo [2/6] 运行测试...
if exist test\all_test.dart (
    call flutter test
    if errorlevel 1 (
        echo 测试失败，请修复后再发布
        exit /b 1
    )
    echo ✓ 测试通过
) else (
    echo ⚠ 未找到测试文件，跳过测试
)
echo.

REM 3. 更新版本号
echo [3/6] 更新版本号...
dart scripts\bump_version.dart %VERSION_TYPE%
for /f "tokens=2" %%a in ('findstr /r "^version:" pubspec.yaml') do set NEW_VERSION=%%a
echo ✓ 版本号已更新为: !NEW_VERSION!
echo.

REM 4. 提交版本号变更
echo [4/6] 提交版本号变更...
git add pubspec.yaml
git commit -m "chore: 更新版本号到 !NEW_VERSION!"
if errorlevel 1 (
    echo ⚠ 没有版本号变更需要提交
)
echo ✓ 版本号已提交
echo.

REM 5. 创建 Git 标签
echo [5/6] 创建 Git 标签...
for /f "tokens=1 delims=+" %%a in ("!NEW_VERSION!") do set VERSION_NAME=%%a
set TAG_NAME=v!VERSION_NAME!
git tag -a !TAG_NAME! -m "发布版本 !VERSION_NAME!"
if errorlevel 1 (
    echo 错误: 标签可能已存在
    exit /b 1
)
echo ✓ 标签已创建: !TAG_NAME!
echo.

REM 6. 推送代码和标签
echo [6/6] 推送代码和标签...
set /p PUSH="是否推送到远程仓库? (y/n) "
if /i "!PUSH!"=="y" (
    git push
    git push --tags
    echo ✓ 代码和标签已推送
    echo.
    echo ========================================
    echo 发布流程完成！
    echo ========================================
    echo.
    echo 下一步:
    echo 1. CI/CD 将自动触发构建
    echo 2. 检查构建状态
    echo 3. 下载构建产物并测试
    echo 4. 如果一切正常，创建 Release
) else (
    echo ⚠ 已跳过推送，请稍后手动推送
    echo 推送命令:
    echo   git push
    echo   git push --tags
)
