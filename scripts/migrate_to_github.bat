@echo off
REM 从 Gitee 迁移到 GitHub 的辅助脚本 (Windows)
REM 使用方法: scripts\migrate_to_github.bat [github_repo_url]

setlocal enabledelayedexpansion

set GITHUB_URL=%1

echo ========================================
echo Gitee 到 GitHub 迁移助手
echo ========================================
echo.

REM 检查参数
if "%GITHUB_URL%"=="" (
    echo 请输入 GitHub 仓库 URL
    echo 使用方法: scripts\migrate_to_github.bat https://github.com/USERNAME/REPO.git
    echo.
    set /p GITHUB_URL="GitHub 仓库 URL: "
)

echo [1/6] 检查 Git 状态...
git status --porcelain >nul 2>&1
if errorlevel 1 (
    echo 警告: 工作区有未提交的更改
    set /p CONTINUE="是否继续? (y/n) "
    if /i not "!CONTINUE!"=="y" exit /b 1
)
echo ✓ Git 状态检查完成
echo.

echo [2/6] 查看当前远程仓库...
git remote -v
echo.

echo [3/6] 检查是否已存在 github 远程仓库...
git remote | findstr /C:"github" >nul
if errorlevel 1 (
    git remote add github "%GITHUB_URL%"
    echo ✓ 已添加 github 远程仓库
) else (
    echo 已存在 github 远程仓库
    set /p UPDATE="是否更新? (y/n) "
    if /i "!UPDATE!"=="y" (
        git remote set-url github "%GITHUB_URL%"
        echo ✓ 已更新 github 远程仓库 URL
    )
)
echo.

echo [4/6] 验证远程仓库连接...
git ls-remote --heads github >nul 2>&1
if errorlevel 1 (
    echo 错误: 无法连接到 GitHub 仓库
    echo 请检查:
    echo   1. URL 是否正确
    echo   2. 是否有访问权限
    echo   3. 是否已配置认证
    exit /b 1
) else (
    echo ✓ GitHub 仓库连接成功
)
echo.

echo [5/6] 查看所有分支和标签...
echo 本地分支:
git branch
echo.
echo 远程分支:
git branch -r
echo.
echo 标签:
git tag -l
echo.

echo [6/6] 准备推送...
set /p PUSH="是否推送所有分支和标签到 GitHub? (y/n) "
if /i "!PUSH!"=="y" (
    echo 推送所有分支...
    git push github --all
    if errorlevel 1 (
        echo 推送分支时出现问题，请手动检查
    )
    
    echo 推送所有标签...
    git push github --tags
    if errorlevel 1 (
        echo 推送标签时出现问题，请手动检查
    )
    
    echo.
    echo ========================================
    echo 迁移完成！
    echo ========================================
    echo.
    echo 下一步:
    echo 1. 在 GitHub 上验证所有分支和标签
    echo 2. 启用 GitHub Actions
    echo 3. 更新文档中的链接
    echo 4. 通知团队成员更新仓库地址
) else (
    echo 已取消推送
    echo.
    echo 手动推送命令:
    echo   git push github --all      # 推送所有分支
    echo   git push github --tags     # 推送所有标签
)

echo.
echo 当前远程仓库配置:
git remote -v
